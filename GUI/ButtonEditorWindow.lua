-- Neuron is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- Copyright (c) 2026 Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Neuron = addonTable.Neuron

local NeuronGUI = Neuron.NeuronGUI

local L = LibStub("AceLocale-3.0"):GetLocale("Neuron")

local Spec = addonTable.utilities.Spec
local UI = addonTable.ui
local Style = UI.Style

-----------------------------------------------------------------------------
--------------------------Button Editor Window-------------------------------
-----------------------------------------------------------------------------
--a button's macros as spec > default or form > modifier pages.
--the buttons on a row share their modifiers

local window
local render

--kept while the window is open, so clicking another button keeps the place
local selected = {}

--what is on show: pages in order, their editors by page, how to remove each modifier page
--and the modifiers that can be added
local view = {pages = {}, editors = {}, removers = {}, available = {}}

--modifier pages opened or folded by hand, by spec and page, while the same button is edited.
--the rest start folded when they have no text
local expanded, expandedButton = {}, nil

--made with the window, see createWindow
local specRow, specLabel, specDropdown, tabs, body, emptyText
local addButton, removeButton, rowPool
local editors, editorPool

--blizzard's action bars take over the buttons in these, so there is no macro to edit
local ACTION_BAR_STATES = {vehicle = true, dragonriding = true, possess = true, override = true, extrabar = true}

local HOME_STATE_ORDER = {paged = 1, stance = 2, pet = 3}

local ICON_SIZE = 42

--data is what to do on yes
StaticPopupDialogs["NEURON_REMOVE_MODIFIER"] = UI.RaisePopup{
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

--a macro or a label
local function hasText(data)
	return hasMacro(data) or (data ~= nil and data.macro_Name ~= nil and data.macro_Name ~= "")
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

--alt1 on the default, stance1_alt1 on a form
local function pageState(tab, modifier)
	return tab == "homestate" and modifier or tab.."_"..modifier
end

-------------------------------- selection --------------------------------

---marks the page in the list and its editor. scroll brings the editor to the top
local function selectPage(page, scroll)
	selected.page = page

	for _, row in ipairs(rowPool.used) do
		local isSelected = row.page == page
		row.bg:SetShown(isSelected)
		row.marker:SetShown(isSelected)
		row.label:SetTextColor(unpack(isSelected and Style.text or Style.dim))
	end

	for editorPage, editor in pairs(view.editors) do
		local isSelected = editorPage == page
		editor.selectedBg:SetShown(isSelected)
		editor.marker:SetShown(isSelected)
	end

	removeButton:SetEnabled(view.removers[page] ~= nil)

	if scroll and view.editors[page] then
		editors:ScrollTo(view.editors[page].offset)
	end
end

-------------------------------- page editor --------------------------------

local function createRow(parent)
	local row = CreateFrame("Button", nil, parent)
	row:SetHeight(Style.rowHeight)

	row.bg = row:CreateTexture(nil, "BACKGROUND")
	row.bg:SetAllPoints()
	row.bg:SetColorTexture(unpack(Style.selected))

	row.marker = row:CreateTexture(nil, "ARTWORK")
	row.marker:SetColorTexture(unpack(Style.accent))
	row.marker:SetPoint("TOPLEFT")
	row.marker:SetPoint("BOTTOMLEFT")
	row.marker:SetWidth(2)

	local hover = row:CreateTexture(nil, "HIGHLIGHT")
	hover:SetAllPoints()
	hover:SetColorTexture(unpack(Style.hover))

	row.label = UI.Text(row)
	row.label:SetPoint("LEFT", 8, 0)
	row.label:SetPoint("RIGHT", -4, 0)
	row.label:SetWordWrap(false)

	row:SetScript("OnClick", function(self)
		local editor = view.editors[self.page]
		if editor and editor.collapsed then
			editor.onToggle()
		end
		selectPage(self.page, true)
	end)
	return row
end

local function createPageEditor(parent)
	local editor = CreateFrame("Frame", nil, parent)
	Style.Flat(editor, Style.panel)

	--selected like a row in the page list
	editor.selectedBg = editor:CreateTexture(nil, "BACKGROUND", nil, -7)
	editor.selectedBg:SetAllPoints()
	editor.selectedBg:SetColorTexture(unpack(Style.selected))

	editor.marker = editor:CreateTexture(nil, "ARTWORK")
	editor.marker:SetColorTexture(unpack(Style.accent))
	editor.marker:SetPoint("TOPLEFT")
	editor.marker:SetPoint("BOTTOMLEFT")
	editor.marker:SetWidth(2)

	--the title row, which folds a modifier page away
	editor.header = CreateFrame("Button", nil, editor)
	editor.header:SetHeight(Style.rowHeight)
	editor.header:SetScript("OnClick", function()
		editor.onToggle()
	end)

	editor.arrow = UI.Text(editor.header, Style.fontLarge, Style.dim)
	editor.arrow:SetPoint("LEFT")
	editor.arrow:SetWidth(12)
	editor.arrow:SetJustifyH("CENTER")

	editor.title = UI.Text(editor.header, nil, Style.accent)
	editor.title:SetWordWrap(false)


	editor.notice = UI.Text(editor, Style.fontSmall, Style.dim)
	editor.notice:SetWordWrap(true)

	--opens the icon selector
	editor.iconFrame = CreateFrame("Button", nil, editor)
	Style.Flat(editor.iconFrame, Style.field)
	editor.iconFrame:SetSize(ICON_SIZE, ICON_SIZE)
	editor.icon = editor.iconFrame:CreateTexture(nil, "ARTWORK")
	editor.icon:SetPoint("TOPLEFT", 1, -1)
	editor.icon:SetPoint("BOTTOMRIGHT", -1, 1)
	local iconHover = editor.iconFrame:CreateTexture(nil, "HIGHLIGHT")
	iconHover:SetAllPoints()
	iconHover:SetColorTexture(unpack(Style.hover))
	editor.iconFrame:SetScript("OnClick", function()
		selectPage(editor.page)
		NeuronGUI:OpenIconSelector(function(icon)
			editor.onIcon(icon)
		end)
	end)

	editor.labelCaption = UI.Text(editor, Style.fontSmall, Style.dim)
	editor.labelCaption:SetText("Edit Label")
	editor.labelBox = UI.EditBox(editor, function(text)
		editor.onLabel(text)
	end)

	editor.macroCaption = UI.Text(editor, Style.fontSmall, Style.dim)
	editor.macroCaption:SetText("Edit Macro")
	editor.macroBox = UI.MultiLineEditBox(editor, 4, function(text)
		editor.onMacro(text)
	end)

	editor.resetIcon = UI.Button(editor, "Reset Icon", function()
		editor.onResetIcon()
	end)

	--everything under the title row
	editor.parts = {
		editor.notice, editor.iconFrame, editor.labelCaption, editor.labelBox,
		editor.macroCaption, editor.macroBox, editor.resetIcon,
	}

	---collapsible pages show + or - and fold on a click on their title
	function editor:SetCollapsed(collapsible, collapsed)
		self.collapsed = collapsible and collapsed
		self.arrow:SetShown(collapsible)
		self.arrow:SetText(self.collapsed and "+" or "-")
		self.header:EnableMouse(collapsible)
		if self.collapsed then
			self.labelBox:ClearFocus()
			self.macroBox.editBox:ClearFocus()
		end
	end

	--working in a page selects it, where it is
	for _, box in ipairs({editor.labelBox, editor.macroBox.editBox}) do
		box:HookScript("OnEditFocusGained", function()
			selectPage(editor.page)
		end)
	end
	editor:EnableMouse(true)
	editor:SetScript("OnMouseDown", function()
		selectPage(editor.page)
	end)

	function editor:OnRelease()
		self.labelBox:ClearFocus()
		self.macroBox.editBox:ClearFocus()
	end

	return editor
end

---places the editor's parts for a width and returns its height
local function layoutPageEditor(editor, width)
	local pad, gap = Style.padding, Style.gap
	local y = pad

	editor.header:ClearAllPoints()
	editor.header:SetPoint("TOPLEFT", pad, -y)
	editor.header:SetPoint("TOPRIGHT", -pad, -y)
	editor.title:ClearAllPoints()
	editor.title:SetPoint("LEFT", editor.header, "LEFT", editor.arrow:IsShown() and 16 or 0, 0)
	editor.title:SetPoint("RIGHT", editor.header, "RIGHT")
	y = y + Style.rowHeight

	for _, part in ipairs(editor.parts) do
		part:SetShown(not editor.collapsed)
	end
	if editor.collapsed then
		y = y + pad
		editor:SetHeight(y)
		return y
	end
	editor.notice:SetShown(editor.showNotice)
	y = y + gap

	if editor.showNotice then
		editor.notice:ClearAllPoints()
		editor.notice:SetPoint("TOPLEFT", pad, -y)
		editor.notice:SetWidth(width - 2 * pad)
		y = y + editor.notice:GetStringHeight() + gap
	end

	editor.iconFrame:ClearAllPoints()
	editor.iconFrame:SetPoint("TOPLEFT", pad, -y)
	editor.labelCaption:ClearAllPoints()
	editor.labelCaption:SetPoint("TOPLEFT", pad + ICON_SIZE + gap, -y)
	editor.labelBox:ClearAllPoints()
	editor.labelBox:SetPoint("TOPLEFT", editor.labelCaption, "BOTTOMLEFT", 0, -3)
	editor.labelBox:SetWidth(width - 2 * pad - ICON_SIZE - gap)
	y = y + ICON_SIZE + gap

	editor.macroCaption:ClearAllPoints()
	editor.macroCaption:SetPoint("TOPLEFT", pad, -y)
	y = y + editor.macroCaption:GetStringHeight() + 3
	editor.macroBox:ClearAllPoints()
	editor.macroBox:SetPoint("TOPLEFT", pad, -y)
	editor.macroBox:SetWidth(width - 2 * pad)
	y = y + editor.macroBox:GetHeight() + gap

	editor.resetIcon:ClearAllPoints()
	editor.resetIcon:SetPoint("TOPLEFT", pad, -y)
	y = y + Style.rowHeight + pad

	editor:SetHeight(y)
	return y
end

---stacks the editors in the scroll area, remembering where each starts
local function layoutEditors()
	local width = editors:GetContentWidth()
	local y = 0
	for _, page in ipairs(view.pages) do
		local editor = view.editors[page]
		editor:ClearAllPoints()
		editor:SetPoint("TOPLEFT", 0, -y)
		editor:SetWidth(width)
		editor.offset = y
		y = y + layoutPageEditor(editor, width) + Style.gap
	end
	editors:SetContentHeight(math.max(0, y - Style.gap))
end

---@param collapsible boolean @modifier pages fold
local function bindPageEditor(editor, button, specIndex, specName, page, collapsible)
	local bar = button.bar
	local multiSpec = bar:GetMultiSpec()
	local specData = button.DB[specIndex]
	local own = rawget(specData, page)

	editor.page = page
	editor.title:SetText(specIndex == "default" and pageName(page) or specName.." - "..pageName(page))

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

	local function refreshIcon()
		local data = rawget(specData, page)
		if not hasMacro(data) then
			data = button:GetResolvedData(page, specData)
		end
		editor.icon:SetTexture(button:GetAppearance(data) or "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK")
	end
	refreshIcon()

	--without a macro of its own, the one it uses shows grayed out
	local fallback
	editor.showNotice = not hasMacro(own)
	if editor.showNotice then
		fallback = button:GetResolvedData(page, specData)
		local source = hasMacro(fallback) and sourceName(button, specData, specName, fallback)
		editor.notice:SetText(source and string.format(L["ButtonEditor_Inherits"], source) or L["ButtonEditor_Empty"])
		if not source then
			fallback = nil
		end
	end

	editor.labelBox:SetText(own and own.macro_Name or "")
	editor.labelBox:SetPlaceholder(fallback and fallback.macro_Name)
	editor.macroBox:SetText(own and type(own.macro_Text) == "string" and own.macro_Text or "")
	editor.macroBox:SetPlaceholder(fallback and type(fallback.macro_Text) == "string" and fallback.macro_Text)

	editor.onLabel = function(text)
		update{macro_Name = text}
	end
	editor.onMacro = function(text)
		update{macro_Text = text}
		refreshIcon()
	end
	editor.onResetIcon = function()
		update{macro_Icon = false}
		refreshIcon()
	end
	editor.onIcon = function(icon)
		update{macro_Icon = icon}
		refreshIcon()
	end
	--modifier pages fold, and start folded without text
	local key = specIndex..":"..page
	local isExpanded = expanded[key]
	if isExpanded == nil then
		isExpanded = hasText(own)
	end
	editor:SetCollapsed(collapsible, not isExpanded)
	editor.onToggle = function()
		expanded[key] = editor.collapsed
		editor:SetCollapsed(true, not editor.collapsed)
		layoutEditors()
		selectPage(page)
	end
end

-------------------------------- tab --------------------------------

---the default's or a form's own page, then a page per modifier the row uses
local function fillTab(button, specIndex, specName, forms, modifiers)
	local bar = button.bar
	local multiSpec = bar:GetMultiSpec()
	local tab = selected.tab
	local tabStates = {"homestate", unpack(forms)}

	--a circle's buttons are all one row
	local _, row = buttonPosition(button)
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
	view.available = {}
	for _, modifier in ipairs(modifiers) do
		if inUse(modifier) then
			local state = pageState(tab, modifier)
			table.insert(pages, state)
			modifierOf[state] = modifier
		else
			table.insert(view.available, modifier)
		end
	end
	view.pages = pages

	if not tContains(pages, selected.page) then
		selected.page = tab
	end

	view.addModifier = function(modifier)
		--the pages only work with the modifier on for the bar
		local barState = modifier:match("^%a+")
		if not bar.data[barState] then
			bar:SetState(barState, true, true)
		end

		setAdded(modifier, true)
		selected.page = pageState(tab, modifier)
		expanded[specIndex..":"..selected.page] = true
		render()
	end

	-------------------------------- page list --------------------------------
	local previous
	for _, page in ipairs(pages) do
		local item = rowPool:Acquire()
		item.page = page
		item.label:SetText(stateName(modifierOf[page] or tab))
		if previous then
			item:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -2)
			item:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -2)
		else
			item:SetPoint("TOPLEFT")
			item:SetPoint("TOPRIGHT")
		end
		previous = item
	end

	addButton:SetEnabled(#view.available > 0)

	-------------------------------- macros --------------------------------
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

		local editor = editorPool:Acquire()
		bindPageEditor(editor, button, specIndex, specName, page, modifier ~= nil)
		view.editors[page] = editor
		view.removers[page] = onRemove
	end

	layoutEditors()
	selectPage(selected.page, true)
end

-------------------------------- window --------------------------------

---the tabs are only there when there are forms
local function placeBody()
	local top = 0
	if specRow:IsShown() then
		top = top + specRow:GetHeight() + Style.gap
	end
	if tabs:IsShown() then
		tabs:ClearAllPoints()
		tabs:SetPoint("TOPLEFT", 0, -top)
		tabs:SetPoint("TOPRIGHT", 0, -top)
		top = top + tabs:GetHeight() + Style.gap
	end
	body:ClearAllPoints()
	body:SetPoint("TOPLEFT", 0, -top)
	body:SetPoint("BOTTOMRIGHT")
end

local function createWindow()
	window = UI.Window("NeuronButtonEditorFrame", L["Button Editor"])
	window:SetSize(660, 700)
	window:SetMinSize(560, 420)
	window:SetScript("OnHide", function()
		NeuronGUI:CloseIconSelector()
		if Neuron.buttonEditMode then
			Neuron:ToggleButtonEditMode(false)
		end
	end)

	local content = window.content

	emptyText = UI.Text(content, nil, Style.dim)
	emptyText:SetPoint("TOPLEFT")
	emptyText:SetText(L["ButtonEditor_SelectButton"])

	-------------------------------- spec and modifiers --------------------------------
	specRow = CreateFrame("Frame", nil, content)
	specRow:SetPoint("TOPLEFT")
	specRow:SetPoint("TOPRIGHT")
	specRow:SetHeight(Style.rowHeight)

	specLabel = UI.Text(specRow, nil, Style.dim)
	specLabel:SetPoint("LEFT")
	specLabel:SetText(L["Specialization"])

	specDropdown = UI.Dropdown(specRow, function(value)
		selected.spec = value
		render()
	end)
	specDropdown:SetPoint("LEFT", specLabel, "RIGHT", Style.gap * 2, 0)
	specDropdown:SetWidth(220)

	addButton = UI.MenuButton(specRow, L["Add Modifier"], function(root)
		for _, modifier in ipairs(view.available) do
			root:CreateButton(stateName(modifier), function()
				view.addModifier(modifier)
			end)
		end
	end)
	--room for the arrow
	addButton:SetWidth(addButton:GetFontString():GetStringWidth() + 40)

	--removes the selected page's modifier
	removeButton = UI.Button(specRow, L["Remove Modifier"], function()
		view.removers[selected.page]()
	end)
	removeButton:SetPoint("LEFT", addButton, "RIGHT", Style.gap, 0)

	-------------------------------- default and forms --------------------------------
	tabs = UI.Tabs(content, function(value)
		selected.tab = value
		selected.page = nil
		render()
	end)

	body = CreateFrame("Frame", nil, content)

	-------------------------------- page list --------------------------------
	local left = CreateFrame("Frame", nil, body)
	left:SetPoint("TOPLEFT")
	left:SetPoint("BOTTOMLEFT")

	rowPool = UI.Pool(function()
		return createRow(left)
	end)

	-------------------------------- macros --------------------------------
	editors = UI.ScrollArea(body)
	editors:SetPoint("TOPLEFT", left, "TOPRIGHT", Style.padding, 0)
	editors:SetPoint("BOTTOMRIGHT")
	editorPool = UI.Pool(function()
		return createPageEditor(editors.child)
	end)

	--the selected page stays in view as the window gets its size
	editors.OnResize = function()
		layoutEditors()
		if selected.page then
			selectPage(selected.page, true)
		end
	end

	body:SetScript("OnSizeChanged", function(_, width)
		left:SetWidth(math.floor(width * 0.28))
	end)
end

function render()
	if not window or not window:IsShown() then
		return
	end

	--a pick would go to a page that is no longer on show
	NeuronGUI:CloseIconSelector()

	rowPool:ReleaseAll()
	editorPool:ReleaseAll()
	wipe(view.editors)
	wipe(view.removers)
	view.pages = {}

	local button = Neuron.currentButton
	if not button or button.bar.class ~= "ActionBar" then
		window:SetStatus(L["ButtonEditor_SelectButton"])
		specRow:Hide()
		tabs:Hide()
		body:Hide()
		emptyText:Show()
		return
	end

	emptyText:Hide()
	body:Show()

	if button ~= expandedButton then
		wipe(expanded)
		expandedButton = button
	end

	local bar = button.bar
	window:SetStatus(string.format(L["ButtonEditor_Status"], bar:GetBarName(), button.id))

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

	local hasSpecs = #specs > 1
	if hasSpecs then
		local items = {}
		for _, candidate in ipairs(specs) do
			table.insert(items, {value = candidate.index, text = candidate.name})
		end
		specDropdown:SetItems(items)
		specDropdown:SetValue(spec.index)
	end
	specLabel:SetShown(hasSpecs)
	specDropdown:SetShown(hasSpecs)
	specRow:Show()

	--right of the spec, or first in the row without one
	addButton:ClearAllPoints()
	if hasSpecs then
		addButton:SetPoint("LEFT", specDropdown, "RIGHT", Style.gap * 2, 0)
	else
		addButton:SetPoint("LEFT")
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

	if not tContains(forms, selected.tab) then
		selected.tab = "homestate"
	end

	if #forms > 0 then
		local tabList = {{text = L["Default"], value = "homestate"}}
		for _, form in ipairs(forms) do
			table.insert(tabList, {text = stateName(form), value = form})
		end
		tabs:SetTabs(tabList, selected.tab)
		tabs:Show()
	else
		tabs:Hide()
	end

	placeBody()
	fillTab(button, spec.index, spec.name, forms, modifiers)
end

function NeuronGUI:OpenButtonEditor()
	if not Neuron.buttonEditMode then
		Neuron:ToggleButtonEditMode(true)
	end

	if not window then
		createWindow()
	end
	window:Show()

	render()
end

function NeuronGUI:RefreshButtonEditor()
	render()
end

function NeuronGUI:CloseButtonEditor()
	if window then
		window:Hide() --leaves button edit mode, see createWindow
	end
end
