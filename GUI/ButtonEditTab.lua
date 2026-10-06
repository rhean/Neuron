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
local Array = addonTable.utilities.Array

-----------------------------------------------------------------------------
--------------------------Button Editor--------------------------------------
-----------------------------------------------------------------------------

local function refreshIconPreview(frame, data)
	--try to get the texture currently on the button itself
	local texture = Neuron.currentButton:GetAppearance(data)
	if texture then
		frame:SetImage(texture)
	else --fallback to question mark icon if nothing is found
		frame:SetImage("INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK")
	end
end

---take a parent frame and fills it with a child scroll frame
---@param parent Frame @parent frame--we need this because we want to abstract out the parent group, and only return the scroll frame
---@param height? number @the default zero does nothing
---@param layout? "Flow"|"List"|nil @"Flow" is the default
---@return Frame @the scroll frame
local function makeScrollFrame(parent, height, layout)
		local scrollContainer = AceGUI:Create("SimpleGroup")
		scrollContainer:SetFullWidth(true)
	if height then
		scrollContainer:SetHeight(height)
	else
		scrollContainer:SetFullHeight(true)
	end
		scrollContainer:SetLayout("Fill")

		parent:AddChild(scrollContainer)

		local scroll = AceGUI:Create("ScrollFrame")
		scroll:SetLayout(layout or "Flow")
		scrollContainer:AddChild(scroll)

		return scroll
end

--home bar states are listed first, the secondary ones after alphabetically
local HOME_STATE_ORDER = {paged = 1, stance = 2, pet = 3}

--our states are the results of the states field of every MANAGED_BAR_STATES
--entry enabled for the bar, minus its homestate. states without a name are
--dropped, which also drops stance slots the class doesn't have
local function getStateList()
	local bar = Neuron.currentButton.bar
	local barData = bar.data

	local stateList = {}
	for barState, stateInfo in pairs(Neuron.MANAGED_BAR_STATES) do
		if barData[barState] and barState ~= "custom" then
			local driver = stateInfo.states
			if barData.remap and (barState == "paged" or barState == "stance") then
				driver = driver.."; "..bar:BuildStateMap(barState)
			end

			local seen = {}
			for state in driver:gmatch("%a+%d+") do
				if not seen[state]
					and state:match("^"..barState.."%d+$")
					and state ~= stateInfo.homestate
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

	local visibilityStates = Array.map(function(entry) return entry.state end, stateList)

	--TODO: custom states? or nah?
	--[[
	if (bar and bar.data.customNames) then
		local i = 0
		for index,state in pairs(bar.data.customNames) do
			stateList[state] = index
			data[count] = state; count = count + 1
		end
	end
	]]

	return visibilityStates
end

---@param specData GenericSpecData
---@param update fun(data: GenericSpecData): nil
---@return Frame
local function buttonEditPanel(specData, update)
	--container to hold all of our widgets, added to our tab frame
	local settingContainer = AceGUI:Create("SimpleGroup")
	settingContainer:SetFullWidth(true)
	settingContainer:SetLayout("Flow")


	--edit box to show the macro label
	local labelEditFrame = AceGUI:Create("EditBox")
	labelEditFrame:SetLabel("Edit Label")
	labelEditFrame:SetRelativeWidth(1)
	labelEditFrame:SetText(type(specData.macro_Text) == "string" and specData.macro_Name or "")
	labelEditFrame:DisableButton(true)
	labelEditFrame:SetCallback("OnTextChanged", function(_, _, text)
		update{macro_Name = text}
	end)
	settingContainer:AddChild(labelEditFrame)

	local mainContainer = AceGUI:Create("SimpleGroup")
	mainContainer:SetFullWidth(true)
	mainContainer:SetLayout("Flow")
	mainContainer:SetHeight(200)

	--icon button that represents the currently selected icon
	local previewIconFrame=AceGUI:Create("Icon")
	refreshIconPreview(previewIconFrame, specData)
	previewIconFrame:SetImageSize(60,60)
	previewIconFrame:SetWidth(60)
	previewIconFrame:SetCallback("OnClick", function() NeuronGUI:IconFrame_OnClick() end)
	mainContainer:AddChild(previewIconFrame)
	local updateAndRefreshIcon = function(data)
		update(data)
		refreshIconPreview(previewIconFrame, specData)
	end

	--edit box to show the current macro
	local macroEditFrame = AceGUI:Create("MultiLineEditBox")
	macroEditFrame:SetLabel("Edit Macro")
	macroEditFrame:SetWidth(420)
	macroEditFrame:SetFullHeight(true)
	macroEditFrame:SetText(type(specData.macro_Text) == "string" and specData.macro_Text or "")
	macroEditFrame:DisableButton(true)
	macroEditFrame:SetCallback("OnTextChanged", function(_, _, text)
		updateAndRefreshIcon{macro_Text = text}
	end)
	mainContainer:AddChild(macroEditFrame)

	settingContainer:AddChild(mainContainer)

	local buttonContainer = AceGUI:Create("SimpleGroup")
	buttonContainer:SetFullWidth(true)
	buttonContainer:SetLayout("Flow")

	--reset icon button
	--disabled or now, until we have a real icon picker
	local resetIconButton = AceGUI:Create("Button")
	--resetIconButton:SetRelativeWidth(0.15)
	resetIconButton:SetText("Reset Icon")
	resetIconButton:SetCallback("OnClick", function()
		updateAndRefreshIcon{macro_Icon = false}
	end)
	buttonContainer:AddChild(resetIconButton)

	settingContainer:AddChild(buttonContainer)

	return settingContainer
end

function NeuronGUI:ButtonsEditPanel(topContainer)
	Neuron:ToggleButtonEditMode(true)

	if not Neuron.currentButton then
		return
	end

	topContainer = makeScrollFrame(topContainer)

	local multiSpec = Neuron.currentButton.bar:GetMultiSpec()

	--the default tree comes first. it is the fallback for every spec
	--and state below it, and the only tree when multiSpec is off
	local trees = {{index = "default", name = Neuron.isWoWForever and L["Spec 1"] or L["Default"]}}
	if multiSpec then
		for specIndex, specName in pairs(Spec.names(multiSpec)) do
			table.insert(trees, {index = specIndex, name = specName})
		end
	end

	for _, tree in ipairs(trees) do
		local specIndex, specName = tree.index, tree.name
		local specData = Neuron.currentButton.DB[specIndex]

		local buttonTree = {
			value = "homestate",
			text = specName,
			children = Array.map(
				function(state) return {value=state, text=Neuron.STATES[state]} end,
				getStateList()
			),
		}

		local specButtonTree = AceGUI:Create("TreeGroup")
		specButtonTree:SetFullWidth(true)
		specButtonTree:SetLayout("Flow")
		specButtonTree:SetTree({buttonTree})
		specButtonTree:SetCallback("OnGroupSelected", function(container, _, joinedState)
			container:ReleaseChildren()

			-- this seems unnecessarily complicated...that moment when you have to
			-- read the source of your library figure out...this? smh
			local splitState = {string.split("\001",joinedState)}
			local state = splitState[#splitState]

			local buttonEditor = buttonEditPanel(specData[state], function(data)
				for k,v in pairs(data) do
					specData[state][k] = v
				end

				if specIndex ~= "default" and Spec.active(multiSpec) ~= specIndex then
					-- don't update the button if the modified spec isn't active
					return
				end

				-- for some reason we need to do a full bar load or the buttons don't
				-- update. we can investigate further, but note that switching specs
				-- probably needs the same fix
				Neuron.currentButton.bar:Load()
				--Neuron.currentButton:LoadDataFromDatabase(specIndex, state)
				--Neuron.currentButton:UpdateAll()
			end)
			container:AddChild(buttonEditor)
		end)

		specButtonTree:SelectByValue("homestate")

		-- make sure to do this last, or the size of the scroll box
		-- might be smaller than it's contents
		topContainer:AddChild(specButtonTree)
	end
end
