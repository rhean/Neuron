-- Neuron is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- Copyright (c) 2026 Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
addonTable.utilities = addonTable.utilities or {}

local L = LibStub("AceLocale-3.0"):GetLocale("Neuron")
local Array = addonTable.utilities.Array

local Spec; Spec = {
  --- get the currently active spec
  -- bool -> int, string
  --
  -- @param bool indicating whether we want multispec
  -- @return the spec index and name
  active = function (multiSpec)
    --Forever has dual spec talent groups instead. group 1 is the default tree
    if addonTable.Neuron.isWoWForever then
      if multiSpec and C_SpecializationInfo.GetActiveSpecGroup() == 2 then
        return 2, L["Spec 2"]
      end
      return "default"
    end

    local index = C_SpecializationInfo.GetSpecialization()
    local _, name = C_SpecializationInfo.GetSpecializationInfo(index)

    index = multiSpec and index or 1

    return index, name
  end,

  --- get a list of spec names
  -- boolean -> string[]
  --
  -- @param bool indicating whether we want multispec
  -- @return the names
  names = function(multiSpec)
    if addonTable.Neuron.isWoWForever then
      return multiSpec and {[2] = L["Spec 2"]} or {}
    end

    local names = Array.initialize(
      GetNumSpecializations(),
      function(i) return select(2, C_SpecializationInfo.GetSpecializationInfo(i)) end
    )

    return multiSpec and names or {""}
  end
}

addonTable.utilities.Spec = Spec
