-- Neuron is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- Copyright (c) 2026 Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Neuron = addonTable.Neuron

local NeuronGUI = Neuron.NeuronGUI

local L = LibStub("AceLocale-3.0"):GetLocale("Neuron")
local AceGUI = LibStub("AceGUI-3.0")

local Spec = addonTable.utilities.Spec

-----------------------------------------------------------------------------
--------------------------Button Editor Window-------------------------------
-----------------------------------------------------------------------------
--a button's macros as spec > default or form > modifier pages.
--the buttons on a row share their modifiers

local window
local render
--lets a delayed scroll tell its widgets were released
local renderCount = 0

--kept while the window is open, so clicking another button keeps the place
local selected = {}

--blizzard's action bars take over the buttons in these, so there is no macro to edit
local ACTION_BAR_STATES = {vehicle = true, dragonriding = true, possess = true, override = true, extrabar = true}

local HOME_STATE_ORDER = {paged = 1, stance = 2, pet = 3}

--AceGUI's List with 5px between the rows
AceGUI:RegisterLayout("NeuronSpacedList", function(content, children)
	local height = 0
	local width = content.width or content:GetWidth() or 0
	for i = 1, #children do
		local child = children[i]

		local frame = child.frame
		frame:ClearAllPoints()
		frame:Show()
		if i == 1 then
			frame:SetPoint("TOPLEFT", content)
		else
			frame:SetPoint("TOPLEFT", children[i-1].frame, "BOTTOMLEFT", 0, -5)
			height = height + 5
		end

		if child.width == "fill" then
			child:SetWidth(width)
			frame:SetPoint("RIGHT", content)

			if child.DoLayout then
				child:DoLayout()
			end
		elseif child.width == "relative" then
			child:SetWidth(width * child.relWidth)

			if child.DoLayout then
				child:DoLayout()
			end
		end

		height = height + (frame.height or frame:GetHeight() or 0)
	end
	if content.obj.LayoutFinished then
		content.obj:LayoutFinished(nil, height)
	end
end)

--list on the left, macros filling the rest, both from the top.
--Flow centers a row, which pushes the macros out of the window once they are taller than the list
AceGUI:RegisterLayout("NeuronColumns", function(content, children)
	local width = content.width or content:GetWidth() or 0
	local left, right = children[1], children[2]

	if left then
		local leftWidth = width * (left.relWidth or 0.3)
		left.frame:ClearAllPoints()
		left.frame:SetPoint("TOPLEFT", content)
		left.frame:Show()
		left:SetWidth(leftWidth)
		if left.DoLayout then
			left:DoLayout()
		end

		if right then
			right.frame:ClearAllPoints()
			right.frame:SetPoint("TOPLEFT", left.frame, "TOPRIGHT", 5, 0)
			right.frame:SetPoint("BOTTOMRIGHT", content)
			right.frame:Show()
			right:SetWidth(width - leftWidth - 5)
			right:SetHeight(content.height or content:GetHeight() or 0)
			if right.DoLayout then
				right:DoLayout()
			end
		end
	end
end)

--location, divider and modifier list. the location lines up with the list's title, which InlineGroup indents 14px
AceGUI:RegisterLayout("NeuronLeftColumn", function(content, children)
	local width = content.width or content:GetWidth() or 0
	local location, divider, list = children[1], children[2], children[3]
	local height = 0

	if location then
		location.frame:ClearAllPoints()
		location.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 14, -5)
		location.frame:Show()
		location:SetWidth(width - 14)
		height = 5 + (location.frame:GetHeight() or 0)
	end

	if divider then
		divider.frame:ClearAllPoints()
		divider.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -height)
		divider.frame:Show()
		divider:SetWidth(width)
		height = height + (divider.frame:GetHeight() or 0)
	end

	if list then
		list.frame:ClearAllPoints()
		list.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -height)
		list.frame:Show()
		list:SetWidth(width)
		if list.DoLayout then
			list:DoLayout()
		end
		height = height + (list.frame:GetHeight() or 0)
	end

	if content.obj.LayoutFinished then
		content.obj:LayoutFinished(nil, height)
	end
end)

--data is what to do on yes
StaticPopupDialogs["NEURON_REMOVE_MODIFIER"] = {
	text = L["ButtonEditor_RemoveModifier"],
	button1 = YES,
	button2 = NO,
	OnAccept = function(_, onAccept) onAccept() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

local function hasMacro(data)
	return data ~= nil and ((data.macro_Text ~= nil and data.macro_Text ~= "") or not not data.actionID)
end

--rebuilding releases the widget whose callback is running, so wait a frame
local function deferRender()
	C_Timer.After(0, render)
end

---the bar's forms or pages and every modifier, enabled on the bar or not.
---unnamed states are dropped, which drops stance slots the class doesn't have
---@param bar Bar
---@return string[]
local function getStateList(bar)
	local barData = bar.data

	local stateList = {}
	for barState, stateInfo in pairs(Neuron.MANAGED_BAR_STATES) do
		if (barData[barState] or Neuron.MANAGED_SECONDARY_STATES[barState])
			and barState ~= "custom"
			and not ACTION_BAR_STATES[barState]
			--a rogue's stealth is a stance
			and not (Neuron.class == "ROGUE" and barState == "stealth")
		then
			local driver = stateInfo.states
			if barData.remap and (barState == "paged" or barState == "stance") then
				driver = driver.."; "..bar:BuildStateMap(barState)
			end

			local seen = {}
			for state in driver:gmatch("%a+%d+") do
				if not seen[state]
					and state:match("^"..barState.."%d+$")
					and (state ~= stateInfo.homestate or Neuron.Bar.FormsArePages(barState))
					and Neuron.STATES[state]
				then
					seen[state] = true
					table.insert(stateList, {state = state, barState = barState, num = tonumber(state:match("%d+$"))})
				end
			end
		end
	end

	table.sort(stateList, function(a, b)
		local orderA, orderB = HOME_STATE_ORDER[a.barState] or 99, HOME_STATE_ORDER[b.barState] or 99
		if orderA ~= orderB then
			return orderA < orderB
		elseif a.barState ~= b.barState then
			return a.barState < b.barState
		end
		return a.num < b.num
	end)

	local states = {}
	for _, entry in ipairs(stateList) do
		table.insert(states, entry.state)
	end
	return states
end

local function stateName(state)
	if state == "homestate" then
		return L["Default"]
	end
	return Neuron.STATES[state] or state
end

local function pageName(state)
	local form, modifier = state:match("^(stance%d+)_(.+)$")
	if form then
		return stateName(form).." - "..stateName(modifier)
	end
	return stateName(state)
end

---with multiSpec the default tree is only there until a spec is picked, see Button:MoveDefaultToSpec.
---Forever always has it, as spec 1
---@param bar Bar
local function getSpecs(bar)
	local multiSpec = bar:GetMultiSpec()
	local activeSpec = Spec.active(multiSpec)

	local specs = {}
	if not multiSpec or Neuron.isWoWForever or activeSpec == "default" then
		table.insert(specs, {index = "default", name = Neuron.isWoWForever and L["Spec 1"] or L["Default"]})
	end

	if multiSpec then
		--Forever only names its second
		local names = Spec.names(multiSpec)
		for index = 1, 4 do
			if names[index] then
				table.insert(specs, {index = index, name = names[index]})
			end
		end
	end

	return specs, activeSpec
end

---place in the row and row, from the top. the top row holds the leftovers, see Bar:SetObjectLoc.
---circle shapes have no rows
---@return number, number|nil
local function buttonPosition(button)
	local bar = button.bar
	local count, columns = #bar.buttons, bar:GetColumns() or 0

	if bar:GetBarShape():find("circle") then
		return button.id, nil
	elseif columns == 0 or columns >= count then
		return button.id, 1
	end

	local topRow = count % columns
	if topRow == 0 then
		topRow = columns
	end

	if button.id <= topRow then
		return button.id, 1
	end
	local after = button.id - topRow - 1
	return after % columns + 1, math.floor(after / columns) + 2
end

--the page an empty page takes its macro from, see Button:GetResolvedData
local function sourceName(button, specData, specName, data)
	for state, stateData in pairs(specData) do
		if stateData == data then
			return specData == button.DB.default and pageName(state) or specName.." - "..pageName(state)
		end
	end
	for state, stateData in pairs(button.DB.default) do
		if stateData == data then
			return L["Default"].." - "..pageName(state)
		end
	end
end

--gold border over the group's own. made once per group and hidden on release, groups are recycled
local function highlight(group)
	if not group.neuronHighlight then
		local border = group.content:GetParent()
		group.neuronHighlight = CreateFrame("Frame", nil, border)
		group.neuronHighlight:SetAllPoints(border)
		group.neuronHighlight:SetFrameLevel(border:GetFrameLevel() + 5)

		--the border art doesn't get thicker when scaled, so draw it twice
		for inset = 0, 2, 2 do
			local line = CreateFrame("Frame", nil, group.neuronHighlight, "BackdropTemplate")
			line:SetPoint("TOPLEFT", inset, -inset)
			line:SetPoint("BOTTOMRIGHT", -inset, inset)
			line:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16})
			line:SetBackdropBorderColor(1, 0.82, 0)
		end
	end
	group.neuronHighlight:Show()

	group:SetCallback("OnRelease", function(widget)
		widget.neuronHighlight:Hide()
	end)
end

---@param onRemove? fun() @only modifier pages can be removed
local function pageEditor(button, specIndex, specName, page, onRemove)
	local bar = button.bar
	local multiSpec = bar:GetMultiSpec()
	local specData = button.DB[specIndex]
	local own = rawget(specData, page)

	local editor = AceGUI:Create("InlineGroup")
	editor:SetTitle(specIndex == "default" and pageName(page) or specName.." - "..pageName(page))
	editor:SetFullWidth(true)
	editor:SetLayout("Flow")

	local function update(fields)
		local data = specData[page]
		for k, v in pairs(fields) do
			data[k] = v
		end

		if specIndex ~= "default" and Spec.active(multiSpec) ~= specIndex then
			-- don't update the button if the modified spec isn't active
			return
		end

		-- for some reason we need to do a full bar load or the buttons don't update
		bar:Load()
	end

	if not hasMacro(own) then
		local fallback = button:GetResolvedData(page, specData)
		local notice = AceGUI:Create("Label")
		notice:SetFullWidth(true)
		notice:SetColor(0.6, 0.6, 0.6)
		local source = hasMacro(fallback) and sourceName(button, specData, specName, fallback)
		notice:SetText(source and string.format(L["ButtonEditor_Inherits"], source) or L["ButtonEditor_Empty"])
		editor:AddChild(notice)
	end

	local icon = AceGUI:Create("Icon")
	icon:SetImageSize(48, 48)
	icon:SetWidth(60)
	local function refreshIcon()
		local data = rawget(specData, page)
		if not hasMacro(data) then
			data = button:GetResolvedData(page, specData)
		end
		icon:SetImage(button:GetAppearance(data) or "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK")
	end
	refreshIcon()
	editor:AddChild(icon)

	local labelBox = AceGUI:Create("EditBox")
	labelBox:SetLabel("Edit Label")
	labelBox:SetRelativeWidth(0.75)
	labelBox:SetText(own and own.macro_Name or "")
	labelBox:DisableButton(true)
	labelBox:SetCallback("OnTextChanged", function(_, _, text)
		update{macro_Name = text}
	end)
	editor:AddChild(labelBox)

	local macroBox = AceGUI:Create("MultiLineEditBox")
	macroBox:SetLabel("Edit Macro")
	macroBox:SetFullWidth(true)
	macroBox:SetNumLines(4)
	macroBox:SetText(own and type(own.macro_Text) == "string" and own.macro_Text or "")
	macroBox:DisableButton(true)
	macroBox:SetCallback("OnTextChanged", function(_, _, text)
		update{macro_Text = text}
		refreshIcon()
	end)
	editor:AddChild(macroBox)

	local resetIconButton = AceGUI:Create("Button")
	resetIconButton:SetText("Reset Icon")
	resetIconButton:SetWidth(140)
	resetIconButton:SetCallback("OnClick", function()
		update{macro_Icon = false}
		refreshIcon()
	end)
	editor:AddChild(resetIconButton)

	if onRemove then
		local removeButton = AceGUI:Create("Button")
		removeButton:SetText(L["Remove Modifier"])
		removeButton:SetWidth(140)
		removeButton:SetCallback("OnClick", onRemove)
		editor:AddChild(removeButton)
	end

	return editor
end

--alt1 on the default, stance1_alt1 on a form
local function pageState(tab, modifier)
	return tab == "homestate" and modifier or tab.."_"..modifier
end

---the default's or a form's own page, then a page per modifier the row uses
local function fillTab(container, button, specIndex, specName, forms, modifiers)
	local bar = button.bar
	local multiSpec = bar:GetMultiSpec()
	local tab = selected.tab
	local tabStates = {"homestate", unpack(forms)}

	--a circle's buttons are all one row
	local position, row = buttonPosition(button)
	local rowButtons = {}
	for _, other in ipairs(bar.buttons) do
		if select(2, buttonPosition(other)) == row then
			table.insert(rowButtons, other)
		end
	end

	--added modifiers by row and spec, data.modifiers["2"]["1"].alt1 = true, so they show before they have a macro
	local rowKey, specKey = tostring(row or 1), tostring(specIndex)
	local added = bar.data.modifiers and bar.data.modifiers[rowKey] and bar.data.modifiers[rowKey][specKey] or {}

	--leaves no empty tables behind
	local function setAdded(modifier, value)
		local rows = bar.data.modifiers or {}
		local specs = rows[rowKey] or {}
		local rowAdded = specs[specKey] or {}
		rowAdded[modifier] = value
		specs[specKey] = next(rowAdded) and rowAdded or nil
		rows[rowKey] = next(specs) and specs or nil
		bar.data.modifiers = next(rows) and rows or nil
	end

	local function inUse(modifier)
		if added[modifier] then
			return true
		end
		for _, rowButton in ipairs(rowButtons) do
			for _, tabState in ipairs(tabStates) do
				if hasMacro(rawget(rowButton.DB[specIndex], pageState(tabState, modifier))) then
					return true
				end
			end
		end
		return false
	end

	local pages, modifierOf = {tab}, {}
	local available, availableOrder = {}, {}
	for _, modifier in ipairs(modifiers) do
		if inUse(modifier) then
			local state = pageState(tab, modifier)
			table.insert(pages, state)
			modifierOf[state] = modifier
		else
			available[modifier] = stateName(modifier)
			table.insert(availableOrder, modifier)
		end
	end

	if not tContains(pages, selected.page) then
		selected.page = tab
	end

	-------------------------------- page list --------------------------------
	local leftColumn = AceGUI:Create("SimpleGroup")
	leftColumn:SetRelativeWidth(0.28)
	leftColumn:SetLayout("NeuronLeftColumn")

	local location = AceGUI:Create("Label")
	local font, size, flags = GameFontNormal:GetFont()
	location:SetFont(font, size + 2, flags)
	location:SetColor(NORMAL_FONT_COLOR:GetRGB())
	location:SetText(row and string.format(L["ButtonEditor_Location"], position, row) or string.format(L["ButtonEditor_Button"], position))
	leftColumn:AddChild(location)

	local divider = AceGUI:Create("Heading")
	divider:SetText("")
	leftColumn:AddChild(divider)

	local pageList = AceGUI:Create("InlineGroup")
	pageList:SetTitle(L["Modifiers"])
	pageList:SetLayout("NeuronSpacedList")

	for _, page in ipairs(pages) do
		local item = AceGUI:Create("InteractiveLabel")
		item:SetFullWidth(true)
		--labels set a color on creation, which covers the font's gold
		item:SetFontObject(GameFontNormal)
		if page == selected.page then
			item:SetColor(1, 1, 1)
		else
			item:SetColor(NORMAL_FONT_COLOR:GetRGB())
		end
		item:SetText(stateName(modifierOf[page] or tab))
		item:SetHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		item:SetCallback("OnClick", function()
			selected.page = page
			deferRender()
		end)
		pageList:AddChild(item)
	end

	if #availableOrder > 0 then
		local addDropdown = AceGUI:Create("Dropdown")
		addDropdown:SetFullWidth(true)
		addDropdown:SetLabel(L["Add Modifier"])
		addDropdown:SetList(available, availableOrder)
		addDropdown:SetCallback("OnValueChanged", function(_, _, modifier)
			--the pages only work with the modifier on for the bar
			local barState = modifier:match("^%a+")
			if not bar.data[barState] then
				bar:SetState(barState, true, true)
			end

			setAdded(modifier, true)
			selected.page = pageState(tab, modifier)
			deferRender()
		end)
		pageList:AddChild(addDropdown)
	end

	leftColumn:AddChild(pageList)
	container:AddChild(leftColumn)

	-------------------------------- macros --------------------------------
	local macros = AceGUI:Create("SimpleGroup")
	macros:SetLayout("Fill")
	container:AddChild(macros)

	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow")
	macros:AddChild(scroll)

	local selectedEditor
	for _, page in ipairs(pages) do
		--clears the modifier on every button in the row, the default and every form
		local modifier = modifierOf[page]
		local onRemove = modifier and function()
			StaticPopup_Show("NEURON_REMOVE_MODIFIER", stateName(modifier), string.format(L["ButtonEditor_RowOfSpec"], row or 1, specName), function()
				for _, rowButton in ipairs(rowButtons) do
					for _, tabState in ipairs(tabStates) do
						rowButton.DB[specIndex][pageState(tabState, modifier)] = nil
					end
				end
				setAdded(modifier, nil)
				selected.page = tab

				if specIndex == "default" or Spec.active(multiSpec) == specIndex then
					bar:Load()
				end
				render()
			end)
		end or nil

		local editor = pageEditor(button, specIndex, specName, page, onRemove)
		if page == selected.page then
			highlight(editor)
			selectedEditor = editor
		end
		scroll:AddChild(editor)
	end

	--once the layout has its height
	if selectedEditor and selected.page ~= tab then
		local count = renderCount
		C_Timer.After(0, function()
			if count ~= renderCount then
				return
			end
			local viewHeight, height = scroll.scrollframe:GetHeight(), scroll.content:GetHeight()
			if height > viewHeight then
				local offset = scroll.content:GetTop() - selectedEditor.frame:GetTop()
				scroll.scrollbar:SetValue(math.min(1000, math.floor(offset / (height - viewHeight) * 1000)))
			end
		end)
	end
end

function render()
	if not window then
		return
	end
	renderCount = renderCount + 1
	window:ReleaseChildren()

	local button = Neuron.currentButton
	if not button or button.bar.class ~= "ActionBar" then
		window:SetStatusText(L["ButtonEditor_SelectButton"])
		local label = AceGUI:Create("Label")
		label:SetFullWidth(true)
		label:SetText(L["ButtonEditor_SelectButton"])
		window:AddChild(label)
		return
	end

	local bar = button.bar
	window:SetStatusText(string.format(L["ButtonEditor_Status"], bar:GetBarName(), button.id))

	-------------------------------- spec --------------------------------
	local specs, activeSpec = getSpecs(bar)
	local spec, active
	for _, candidate in ipairs(specs) do
		if candidate.index == selected.spec then
			spec = candidate
		end
		if candidate.index == activeSpec then
			active = candidate
		end
	end
	spec = spec or active or specs[1]
	selected.spec = spec.index

	if #specs > 1 then
		local list, order = {}, {}
		for _, candidate in ipairs(specs) do
			list[tostring(candidate.index)] = candidate.name
			table.insert(order, tostring(candidate.index))
		end

		local specDropdown = AceGUI:Create("Dropdown")
		specDropdown:SetLabel(L["Specialization"])
		specDropdown:SetWidth(220)
		specDropdown:SetList(list, order)
		specDropdown:SetValue(tostring(spec.index))
		specDropdown:SetCallback("OnValueChanged", function(_, _, key)
			for _, candidate in ipairs(specs) do
				if tostring(candidate.index) == key then
					selected.spec = candidate.index
				end
			end
			deferRender()
		end)
		window:AddChild(specDropdown)
	end

	-------------------------------- default and forms --------------------------------
	local forms, modifiers = {}, {}
	for _, state in ipairs(getStateList(bar)) do
		if state:match("^stance%d+$") then
			table.insert(forms, state)
		else
			table.insert(modifiers, state)
		end
	end

	local tabs = {{text = L["Default"], value = "homestate"}}
	for _, form in ipairs(forms) do
		table.insert(tabs, {text = stateName(form), value = form})
	end

	if not tContains(forms, selected.tab) then
		selected.tab = "homestate"
	end

	if #tabs > 1 then
		local tabGroup = AceGUI:Create("TabGroup")
		tabGroup:SetFullWidth(true)
		tabGroup:SetFullHeight(true)
		tabGroup:SetLayout("NeuronColumns")
		tabGroup:SetTabs(tabs)
		tabGroup:SetCallback("OnGroupSelected", function(container, _, value)
			if value ~= selected.tab then
				selected.tab = value
				selected.page = nil
			end
			container:ReleaseChildren()
			fillTab(container, button, spec.index, spec.name, forms, modifiers)
		end)
		window:AddChild(tabGroup)
		tabGroup:SelectTab(selected.tab)
	else
		local group = AceGUI:Create("SimpleGroup")
		group:SetFullWidth(true)
		group:SetFullHeight(true)
		group:SetLayout("NeuronColumns")
		window:AddChild(group)
		fillTab(group, button, spec.index, spec.name, forms, modifiers)
	end
end

function NeuronGUI:OpenButtonEditor()
	if not Neuron.buttonEditMode then
		Neuron:ToggleButtonEditMode(true)
	end

	if not window then
		window = AceGUI:Create("Frame")
		window:SetTitle(L["Button Editor"])
		window:EnableResize(true)
		if window.frame.SetResizeBounds then -- WoW 10.0
			window.frame:SetResizeBounds(560, 420)
		else
			window.frame:SetMinResize(560, 420)
		end
		window:SetWidth(660)
		window:SetHeight(520)
		window:SetLayout("Flow")
		window:SetCallback("OnClose", function(widget)
			window = nil
			_G.NeuronButtonEditorFrame = nil
			AceGUI:Release(widget)

			if Neuron.buttonEditMode then
				Neuron:ToggleButtonEditMode(false)
			end
		end)

		--closable with escape
		_G.NeuronButtonEditorFrame = window.frame
		if not tContains(UISpecialFrames, "NeuronButtonEditorFrame") then
			tinsert(UISpecialFrames, "NeuronButtonEditorFrame")
		end
	end

	render()
end

function NeuronGUI:RefreshButtonEditor()
	if window then
		render()
	end
end

function NeuronGUI:CloseButtonEditor()
	if window then
		window:Hide() --fires OnClose
	end
end
