-- Neuron is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- Copyright (c) 2026 Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Neuron = addonTable.Neuron

local NeuronGUI = Neuron.NeuronGUI

local AceGUI = LibStub("AceGUI-3.0")

--the appearance settings for xp, rep, cast and mirror bars are AceConfig options, laid out by Layout.lua
function NeuronGUI:ButtonStatusEditPanel(tabFrame)
	Neuron.ToggleButtonEditMode(true)
	if not Neuron.currentButton then
		return
	end

	local optionsContainer = AceGUI:Create("SimpleGroup")
	optionsContainer:SetLayout("Fill")
	optionsContainer:SetFullWidth(true)
	optionsContainer:SetFullHeight(true)
	tabFrame:AddChild(optionsContainer)

	NeuronGUI:OpenStatusOptions(optionsContainer)
end
