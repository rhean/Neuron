-- Neuron is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- Copyright (c) 2026 Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Neuron = addonTable.Neuron


---@class MenuButton : Button @define class MenuButton inherits from class Button
local MenuButton = setmetatable({}, {__index = Neuron.Button})
Neuron.MenuButton = MenuButton

--the micro buttons differ between clients, these orders match the default UI
local MENU_BUTTON_NAMES = Neuron.isWoWForever and {
	"CharacterMicroButton", "ProfessionMicroButton", "SpellbookMicroButton", "TalentMicroButton", "LegacyMicroButton",
	"QuestLogMicroButton", "GuildMicroButton", "LFDMicroButton", "CollectionsMicroButton", "StoreMicroButton", "MainMenuMicroButton",
} or {
	"CharacterMicroButton", "ProfessionMicroButton", "PlayerSpellsMicroButton", "AchievementMicroButton", "QuestLogMicroButton",
	"HousingMicroButton", "GuildMicroButton", "LFDMicroButton", "CollectionsMicroButton", "EJMicroButton",
	"StoreMicroButton", "MainMenuMicroButton",
}

--only the buttons this client actually has
local blizzMenuButtons = {}
for _, name in ipairs(MENU_BUTTON_NAMES) do
	if _G[name] then
		table.insert(blizzMenuButtons, _G[name])
	end
end

Neuron.NUM_MENU_BUTTONS = #blizzMenuButtons

--every MenuButton holding a blizzard button, so they can be taken back after blizzard moves them
local activeMenuButtons = {}

--HelpMicroButton shares the store's spot and is only shown when the store isn't, park it
--out of sight and put it on the store's spot once the store button is on our bar
local helpParking = CreateFrame("Frame")
helpParking:Hide()
local storeHolder --the MenuButton holding StoreMicroButton

local function StashHelpButton()
	if not HelpMicroButton then
		return
	end
	if storeHolder then
		--only move it when blizzard has taken it, moving it makes blizzard lay out its menu again
		if HelpMicroButton:GetParent() ~= storeHolder then
			HelpMicroButton:SetParent(storeHolder)
			HelpMicroButton:ClearAllPoints()
			HelpMicroButton:SetAllPoints(StoreMicroButton)
		end
		HelpMicroButton:SetShown(not StoreMicroButton:IsShown())
	elseif HelpMicroButton:GetParent() ~= helpParking then
		HelpMicroButton:SetParent(helpParking)
	end
end

--reparenting a micro button makes blizzard re-run MicroMenu:Layout right away, which calls this again.
--without the guard every reclaim starts another reclaim and the client hangs
local reclaiming = false
local function ReclaimMenuButtons()
	if reclaiming then
		return
	end
	reclaiming = true
	StashHelpButton()
	for menuButton in pairs(activeMenuButtons) do
		menuButton:AnchorHookedButton()
	end
	reclaiming = false
end

--blizzard moves the micro buttons to its own menu, the vehicle bar or the pet battle frame.
--let it keep them for vehicles and pet battles, take them back otherwise
local function TakeOverFromMicroMenu()
	if UpdateMicroButtonsParent then
		hooksecurefunc("UpdateMicroButtonsParent", function(parent)
			local borrowed = parent and (parent == OverrideActionBar or (PetBattleFrame and parent == PetBattleFrame.BottomFrame.MicroButtonFrame))
			if not borrowed then
				ReclaimMenuButtons()
			end
		end)
	end
	if MicroMenu and MicroMenu.Layout then
		hooksecurefunc(MicroMenu, "Layout", ReclaimMenuButtons)
	end

	--blizzard's empty menu keeps drawing its frame art, a small box at the bottom of the screen
	if MicroMenu and MicroMenu.BackgroundArt then
		MicroMenu.BackgroundArt:Hide()
	end
	if MicroMenu and MicroMenu.BorderArt then
		MicroMenu.BorderArt:Hide()
	end
end
local tookOver = false

---------------------------------------------------------

---Constructor: Create a new Neuron Button object (this is the base object for all Neuron button types)
---@param bar Bar @Bar Object this button will be a child of
---@param buttonID number @Button ID that this button will be assigned
---@param defaults table @Default options table to be loaded onto the given button
---@return MenuButton @ A newly created MenuButton object
function MenuButton.new(bar, buttonID, defaults)
	---call the parent object constructor with the provided information specific to this button type
	local newButton = Neuron.Button.new(bar, buttonID, MenuButton, "MenuBar", "MenuButton", "NeuronAnchorButtonTemplate")

	if defaults then
		newButton:SetDefaults(defaults)
	end

	return newButton
end

---------------------------------------------------------

function MenuButton:InitializeButton()
	if not tookOver then
		TakeOverFromMicroMenu()
		tookOver = true
	end

	if blizzMenuButtons[self.id] then
		self:SetWidth(blizzMenuButtons[self.id]:GetWidth()-2)
		self:SetHeight(blizzMenuButtons[self.id]:GetHeight()-2)

		self:SetHitRectInsets(self:GetWidth()/2, self:GetWidth()/2, self:GetHeight()/2, self:GetHeight()/2)

		self.hookedButton = blizzMenuButtons[self.id]
		--a micro button can only sit on one bar, the newest menu bar takes it or two bars keep taking it from each other
		for other in pairs(activeMenuButtons) do
			if other ~= self and other.hookedButton == self.hookedButton then
				activeMenuButtons[other] = nil
				other.hookedButton = nil
			end
		end
		activeMenuButtons[self] = true
		self:AnchorHookedButton()
	end

	self:InitializeButtonSettings()
end

---put the blizzard micro button back inside this button
--TEMP DEBUG: find the menu bar freeze, remove once fixed
local debugCalls, debugTime = 0, 0
function MenuButton:AnchorHookedButton()
	if not self.hookedButton then
		return
	end

	--help has to leave blizzard's menu before any other button does, see StashHelpButton
	StashHelpButton()

	--already in place, moving it again would make blizzard lay out its menu again
	local _, relativeTo = self.hookedButton:GetPoint()
	if self.hookedButton:GetParent() == self and relativeTo == self and self.hookedButton:GetNumPoints() == 1 and self.hookedButton:GetScale() == 1 then
		return
	end

	if debugTime ~= GetTime() then
		debugTime, debugCalls = GetTime(), 0
	end
	debugCalls = debugCalls + 1
	if debugCalls >= 500 then
		activeMenuButtons = {} --stop reclaiming so the client doesn't hang after the error
		error("MenuButton freeze: AnchorHookedButton called 500 times in one frame")
	end

	self.hookedButton:SetParent(self)
	self.hookedButton:ClearAllPoints()
	self.hookedButton:SetPoint("CENTER", self, "CENTER")
	self.hookedButton:SetScale(1)
	if self.hookedButton == StoreMicroButton then
		storeHolder = self
		StashHelpButton()
	end
end

function MenuButton:InitializeButtonSettings()
	self:SetFrameStrata(Neuron.STRATAS[self.bar:GetStrata()-1])
	self:SetScale(self.bar:GetBarScale())
	self.isShown = true
end

-----------------------------------------------------
--------------------- Overrides ---------------------
-----------------------------------------------------

--overwrite function in parent class Button
function MenuButton:UpdateStatus()
	-- empty --
end
--overwrite function in parent class Button
function MenuButton:UpdateIcon()
	-- empty --
end
--overwrite function in parent class Button
function MenuButton:UpdateUsable()
	-- empty --
end
--overwrite function in parent class Button
function MenuButton:UpdateCount()
	-- empty --
end
--overwrite function in parent class Button
function MenuButton:UpdateCooldown()
	-- empty --
end
--overwrite function in parent class Button
function MenuButton:UpdateTooltip()
	-- empty --
end
