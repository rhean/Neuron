-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- Copyright (c) 2026 Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Photon = addonTable.Photon

local L = LibStub("AceLocale-3.0"):GetLocale("Photon")

function Photon:RegisterBars(DB)
  local allBars = {
    ActionBar = {
      class = "ActionBar",
      barType = "ActionBar",
      barLabel = L["Action Bar"],
      objType = "ActionButton",
      barDB = DB.ActionBar,
      objTemplate = Photon.ActionButton,
      objMax = 250
    },
    BagBar = {
      class = "BagBar",
      barType = "BagBar",
      barLabel = L["Bag Bar"],
      objType = "BagButton",
      barDB = DB.BagBar,
      objTemplate = Photon.BagButton,
      objMax = Photon.NUM_BAG_BUTTONS
    },
    MenuBar = {
      class = "MenuBar",
      barType = "MenuBar",
      barLabel = L["Menu Bar"],
      objType = "MenuButton",
      barDB = DB.MenuBar,
      objTemplate = Photon.MenuButton,
      objMax = Photon.NUM_MENU_BUTTONS
    },
    PetBar = {
      class = "PetBar",
      barType = "PetBar",
      barLabel = L["Pet Bar"],
      objType = "PetButton",
      barDB = DB.PetBar,
      objTemplate = Photon.PetButton,
      objMax = 10
    },
    XPBar = {
      class = "XPBar",
      barType = "XPBar",
      barLabel = L["XP Bar"],
      objType = "ExpButton",
      barDB = DB.XPBar,
      objTemplate = Photon.ExpButton,
      objMax = 10
    },
    RepBar = {
      class = "RepBar",
      barType = "RepBar",
      barLabel = L["Rep Bar"],
      objType = "RepButton",
      barDB = DB.RepBar,
      objTemplate = Photon.RepButton,
      objMax = 10
    },
    CastBar = {
      class = "CastBar",
      barType = "CastBar",
      barLabel = L["Cast Bar"],
      objType = "CastButton",
      barDB = DB.CastBar,
      objTemplate = Photon.CastButton,
      objMax = 10
    },
    MirrorBar = {
      class = "MirrorBar",
      barType = "MirrorBar",
      barLabel = L["Mirror Bar"],
      objType = "MirrorButton",
      barDB = DB.MirrorBar,
      objTemplate = Photon.MirrorButton,
      objMax = 10
    },
    ZoneAbilityBar = {
      class = "ZoneAbilityBar",
      barType = "ZoneAbilityBar",
      barLabel = L["Zone Action Bar"],
      objType = "ZoneActionButton",
      barDB = DB.ZoneAbilityBar,
      objTemplate = Photon.ZoneAbilityButton,
      objMax = 5, true
    },
    ExtraBar = {
      class = "ExtraBar",
      barType = "ExtraBar",
      barLabel = L["Extra Action Bar"],
      objType = "ExtraActionButton",
      barDB = DB.ExtraBar,
      objTemplate = Photon.ExtraButton,
      objMax = 1
    },
    ExitBar = {
      class = "ExitBar",
      barType = "ExitBar",
      barLabel = L["Vehicle Exit Bar"],
      objType = "VehicleExitButton",
      barDB = DB.ExitBar,
      objTemplate = Photon.ExitButton,
      objMax = 1
    },
  }

  --Forever has no vehicles, extra action buttons or zone abilities
  if Photon.isWoWForever then
    allBars.ExitBar = nil
    allBars.ExtraBar = nil
    allBars.ZoneAbilityBar = nil
  end

  return allBars
end
