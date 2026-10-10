-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- Copyright (c) 2026 Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Photon = addonTable.Photon

--Photon MinimapIcon makes use of LibDBIcon and LibDataBroker to make sure we play
--nicely with LDB addons and to simplify dramatically the minimap button

local L = LibStub("AceLocale-3.0"):GetLocale("Photon")

local DB
local photonIconLDB
local icon

-------------------------------------------------------------------------
-------------------------------------------------------------------------
function Photon:Minimap_IconInitialize()
	DB = Photon.db.profile

	--show new compartment icon even when minimap icon is disabled
	DB.PhotonIcon.showInCompartment = true

	photonIconLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Photon", {
		type = "launcher",
		text = "Photon",
		icon = "Interface\\AddOns\\Photon\\Images\\static_icon",
		OnClick = function(_, button) Photon:Minimap_OnClickHandler(button) end,
		OnTooltipShow = function(tooltip) Photon:Minimap_TooltipHandler(tooltip) end,
	})

	icon = LibStub("LibDBIcon-1.0")
	icon:Register("Photon", photonIconLDB, DB.PhotonIcon)
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function Photon:Minimap_OnClickHandler(button)
	if InCombatLockdown() then
		return
	end

	PlaySound(SOUNDKIT.IG_CHAT_SCROLL_DOWN)

	if button == "LeftButton" then
		if IsShiftKeyDown() then
			if not Photon.bindingMode then
				Photon:ToggleBindingMode(true)
			else
				Photon:ToggleBindingMode(false)
			end
		else
			--the bar editor starts bar edit mode, and closing it ends it
			if not Photon.barEditMode then
				Photon.PhotonGUI:OpenBarConfig()
			else
				Photon:ToggleBarEditMode(false)
				Photon.PhotonGUI:CloseBarConfig()
			end
		end
	elseif button == "RightButton" then
		if IsShiftKeyDown() then
			if SettingsPanel and SettingsPanel:IsShown() then
				SettingsPanel:Hide()
			elseif InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then --this is for pre-dragonflight compatibility
				InterfaceOptionsFrame:Hide();
			else
				Photon:ToggleMainMenu()
			end
		else
			if not Photon.buttonEditMode then
				Photon.PhotonGUI:OpenButtonEditor()
			else
				Photon:ToggleButtonEditMode(false)
				Photon.PhotonGUI:CloseButtonEditor()
			end
		end
	end
end

function Photon:Minimap_TooltipHandler(tooltip)
	tooltip:SetText("Photon", 1, 1, 1)
	--the formatting for the following strings is such that the key combo is in yellow, and the description is in white. This helps it be more readable at a glance
	--another route would be to use AddDoubleLine, to have a left justified string and a right justified string on the same line
	tooltip:AddLine(L["Left-Click"] .. ": " .. "|cFFFFFFFF"..L["Configure Bars"])
	tooltip:AddLine(L["Right-Click"] .. ": " .. "|cFFFFFFFF"..L["Configure Buttons"])
	tooltip:AddLine(L["Shift"] .. " + " .. L["Left-Click"] .. ": " .. "|cFFFFFFFF"..L["Toggle Keybind Mode"])
	tooltip:AddLine(L["Shift"] .. " + " .. L["Right-Click"] .. ": " .. "|cFFFFFFFF"..L["Open the Interface Menu"])

	tooltip:Show()
end

function Photon:Minimap_ToggleIcon()
	if DB.PhotonIcon.hide == false then
		icon:Hide("Photon")
		DB.PhotonIcon.hide = true
	elseif DB.PhotonIcon.hide == true then
		icon:Show("Photon")
		DB.PhotonIcon.hide = false
	end
end