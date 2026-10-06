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
local Array = addonTable.utilities.Array


---@return Frame @a group containing checkboxes
local function actionHomeStateOptions()
  local homeStatesContainer = AceGUI:Create("SimpleGroup")
  homeStatesContainer:SetFullWidth(true)
  homeStatesContainer:SetLayout("Flow")

  for _,state in ipairs({"paged", "stance", "pet"}) do
    local checkbox = AceGUI:Create("CheckBox")
    checkbox:SetLabel(Neuron.MANAGED_HOME_STATES[state].localizedName)
    checkbox:SetValue(Neuron.currentBar.data[state])
    checkbox:SetCallback("OnValueChanged", function(_,_,value)
      --only one of these can be active, so SetState turns the others off
      Neuron.currentBar:SetState(state, true, value)
      NeuronGUI:RefreshEditor()
    end)
    homeStatesContainer:AddChild(checkbox)
  end

  return homeStatesContainer
end

---@return Frame @a group containing checkboxes
local function actionSecondaryStateOptions()
  local stateList =
    Array.map(
      function(state) return state[1] end,
    Array.fromIterator(pairs(Neuron.MANAGED_SECONDARY_STATES)))

	--Might want to add some checks for states like stealth for classes that
  --don't have stealth. But for now it doesn't break anything to have it show
  --generically
  if Neuron.class == "ROGUE" then
    stateList = Array.filter(function (state) return state ~= "stealth" end, stateList)
  end

	local secondaryStatesContainer = AceGUI:Create("SimpleGroup")
	secondaryStatesContainer:SetFullWidth(true)
	secondaryStatesContainer:SetLayout("Flow")

  for _,state in ipairs(stateList) do
    local checkbox = AceGUI:Create("CheckBox")
    checkbox:SetLabel(Neuron.MANAGED_SECONDARY_STATES[state].localizedName)
    checkbox:SetValue(Neuron.currentBar.data[state])
    checkbox:SetCallback("OnValueChanged", function(_,_,value)
      Neuron.currentBar:SetState(state, true, value)
    end)
    secondaryStatesContainer:AddChild(checkbox)
  end

  return secondaryStatesContainer
end

---@param tabFrame Frame
function NeuronGUI:BarStatesPanel(tabFrame)
  -- weird stuff happens if we don't wrap this in a group
  -- like dropdowns showing at the bottom of the screen and stuff
	local settingContainer = AceGUI:Create("SimpleGroup")
	settingContainer:SetFullWidth(true)
	settingContainer:SetLayout("Flow")

  settingContainer:AddChild(actionHomeStateOptions())
  settingContainer:AddChild(actionSecondaryStateOptions())

  tabFrame:AddChild(settingContainer)
end
