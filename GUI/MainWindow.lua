-- Neuron is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Neuron = addonTable.Neuron

Neuron.NeuronGUI = Neuron.NeuronGUI or {}
local NeuronGUI = Neuron.NeuronGUI

local L = LibStub("AceLocale-3.0"):GetLocale("Neuron")
local AceGUI = LibStub("AceGUI-3.0")

local Array = addonTable.utilities.Array

local currentTab = "bar" --remember which tab we were using between refreshes

-----------------------------------------------------------------------------
--------------------------Main Window----------------------------------------
-----------------------------------------------------------------------------

function NeuronGUI:RefreshEditor(defaultTab)
	--popups can call this after the editor window was closed
	if not addonTable.NeuronEditor then
		return
	end

	addonTable.NeuronEditor:ReleaseChildren()

	if defaultTab then
		currentTab = defaultTab
	end

	--re-add all the stuff to the editor window
	NeuronGUI:PopulateEditorWindow()

	if Neuron.currentBar then
		addonTable.NeuronEditor:SetStatusText("|cffffd200" .. Neuron.currentBar:GetBarName().."|cFFFFFFFF is currently selected. Left-click a different bar to change your selection.")
	else
		addonTable.NeuronEditor:SetStatusText("|cFFFFFFFFWelcome to the Neuron editor, please select a bar to begin")
	end
end


function NeuronGUI:CreateEditor(defaultTab)
	addonTable.NeuronEditor = AceGUI:Create("Frame") --add it to our base addon table to reference later

	addonTable.NeuronEditor:SetTitle("Neuron Editor")
	addonTable.NeuronEditor:EnableResize(true)
	if addonTable.NeuronEditor.frame.SetResizeBounds then -- WoW 10.0
		addonTable.NeuronEditor.frame:SetResizeBounds(760,600)
	else
		addonTable.NeuronEditor.frame:SetMinResize(760,600)
	end
	-- assuming that 720p is a reasonable minimum target for what people will be using
	addonTable.NeuronEditor:SetWidth("760")
	addonTable.NeuronEditor:SetHeight(GetScreenHeight() > 850 and "850" or "700")
	if Neuron.currentBar then
		addonTable.NeuronEditor:SetStatusText("|cffffd200" .. Neuron.currentBar:GetBarName().."|cFFFFFFFF is currently selected. Left-click a different bar to change your selection.")
	else
		addonTable.NeuronEditor:SetStatusText("|cFFFFFFFFWelcome to the Neuron editor, please select a bar to begin")
	end
	addonTable.NeuronEditor:SetCallback("OnClose", function() NeuronGUI:DestroyEditor() end)
	addonTable.NeuronEditor:SetLayout("Fill")

	-- make the thing closable with escape
	_G.NeuronEditorMainFrame = addonTable.NeuronEditor
	tinsert(UISpecialFrames, "NeuronEditorMainFrame")

	if defaultTab then
		currentTab = defaultTab
	end
	--add all the stuff to the editor window
	NeuronGUI:PopulateEditorWindow()
end

function NeuronGUI:DestroyEditor()
	if addonTable.NeuronEditor then
		AceGUI:Release(addonTable.NeuronEditor)
		addonTable.NeuronEditor = nil
	end

	Neuron:ToggleBarEditMode()
	Neuron:ToggleButtonEditMode()
end

function NeuronGUI:PopulateEditorWindow()
	local tabs ={{text="Bar Settings", value="bar"}}
	--no bar is selected right after a bar is deleted, the bar tab then picks one
	local barType = Neuron.currentBar and Neuron.currentBar.barType
	if barType == "ActionBar" then
		-- only action bars have editable buttons
		table.insert(tabs, {text=L["Configure Buttons"], value="button"})
	elseif barType == "XPBar" then
		table.insert(tabs, {text=L["Configure Appearance"], value="status"})
	elseif barType == "RepBar" then
		table.insert(tabs, {text=L["Configure Appearance"], value="status"})
	elseif barType == "CastBar" then
		table.insert(tabs, {text=L["Configure Appearance"], value="status"})
	elseif barType == "MirrorBar" then
		table.insert(tabs, {text=L["Configure Appearance"], value="status"})
	end

	-- make sure that we switch to the bar tab
	-- when selecting a bar without the current tab
	currentTab = Array.foldl(
		function(current, candidate)
			return candidate.value == currentTab and currentTab or current
		end,
		"bar",
		tabs
	)

	--Tab group that will contain all of our settings to configure
	local tabFrame = AceGUI:Create("TabGroup")
	tabFrame:SetLayout("Flow")
	tabFrame:SetTabs(tabs)
	tabFrame:SetCallback("OnGroupSelected", function(frame, _, value) NeuronGUI:SelectTab(frame, _, value) end)
	addonTable.NeuronEditor:AddChild(tabFrame)
	tabFrame:SelectTab(currentTab)
end


function NeuronGUI:SelectTab(tabFrame, _, value)
	tabFrame:ReleaseChildren()
	if value == "bar" then
		NeuronGUI:BarEditPanel(tabFrame)
	elseif value == "button" then
		-- whenever we change a button, RefreshEditor is called upstream
		-- so we don't need to keep track of updating currentButton here
		NeuronGUI:ButtonsEditPanel(tabFrame)
	elseif value == "status" then
		NeuronGUI:ButtonStatusEditPanel(tabFrame)
	else
		return -- if we get here we forgot to add a tab!
	end
	currentTab = value
end
