-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Photon = addonTable.Photon

---@class BagButton : Button @class BagButton inherits from class Button
local BagButton = setmetatable({}, {__index = Photon.Button})
Photon.BagButton = BagButton

--the blizzard bag buttons this client has, Forever has a keyring but no reagent bag
local blizzBagButtons = {}
for _, name in ipairs({"KeyRingButton", "CharacterReagentBag0Slot","CharacterBag3Slot", "CharacterBag2Slot", "CharacterBag1Slot", "CharacterBag0Slot", "MainMenuBarBackpackButton"}) do
	if _G[name] then
		table.insert(blizzBagButtons, _G[name])
	end
end

Photon.NUM_BAG_BUTTONS = #blizzBagButtons

local Skin = LibStub("Masque", true)

--the same size as an action button, see PhotonActionButtonTemplate
local BAG_BUTTON_SIZE = 43

local function inset(texture, button, offset)
	texture:ClearAllPoints()
	texture:SetPoint("TOPLEFT", button, "TOPLEFT", offset, -offset)
	texture:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -offset, offset)
	texture:SetTexCoord(0, 1, 0, 1)
end

--blizzard redraws its round bag art on every bag update, so this runs again after each one.
--these are the same textures and insets PhotonActionButtonTemplate uses
local function ApplyActionButtonFrame(button)
	--the backpack has no item icon, blizzard draws the backpack as part of its round frame art
	if button == MainMenuBarBackpackButton and button.icon then
		button.icon:SetTexture("Interface\\Buttons\\Button-Backpack-Up")
	end

	if Skin then
		return --masque draws the frame instead
	end

	local normal = button:GetNormalTexture()
	normal:SetTexture("Interface\\Buttons\\UI-Quickslot2")
	inset(normal, button, -11)

	local pushed = button:GetPushedTexture()
	pushed:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	inset(pushed, button, 2)

	local highlight = button:GetHighlightTexture()
	highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	highlight:SetBlendMode("ADD")
	highlight:SetAlpha(1)
	inset(highlight, button, 2)

	--shown while the bag is open, like a checked action button
	if button.SlotHighlightTexture then
		button.SlotHighlightTexture:SetTexture("Interface\\Buttons\\CheckButtonHilight")
		button.SlotHighlightTexture:SetBlendMode("ADD")
		inset(button.SlotHighlightTexture, button, 3)
	end
end

---make a blizzard bag button look like one of our action buttons: same size, square icon and frame
local function RestyleBagButton(button)
	button:SetSize(BAG_BUTTON_SIZE, BAG_BUTTON_SIZE)

	--the bag icons are drawn through a round mask, take it off to get a square icon
	if button.CircleMask then
		for _, key in ipairs({"icon", "searchOverlay", "ItemContextOverlay"}) do
			if button[key] then
				button[key]:RemoveMaskTexture(button.CircleMask)
			end
		end
	end

	if button.icon then
		inset(button.icon, button, 3)
		button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) --trim the icon's own border, like action icons
	end

	--the backpack's free slot count sits where an action button shows its count
	if button.Count then
		button.Count:ClearAllPoints()
		button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
	end

	ApplyActionButtonFrame(button)
	if button.UpdateTextures then
		hooksecurefunc(button, "UpdateTextures", ApplyActionButtonFrame)
	end
end

--every BagButton holding a blizzard button, so they can be put back after blizzard moves them
local activeBagButtons = {}

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

--BagsBar lays out and collapses the bag buttons on its own, which pulls them out of our bar
local function TakeOverFromBagsBar()
	for _, button in ipairs(blizzBagButtons) do
		button.SetBarExpanded = function() end
		if button == KeyRingButton then
			button:SetScript("OnShow", nil) --blizzard re-anchors the keyring whenever it's shown
		else
			RestyleBagButton(button) --the keyring is a narrow key, not a square slot, leave it as it is
		end
	end

	if BagsBar and BagsBar.Layout then
		hooksecurefunc(BagsBar, "Layout", function()
			for bagButton in pairs(activeBagButtons) do
				bagButton:AnchorHookedButton()
			end
		end)
		EventRegistry:UnregisterCallback("MainMenuBarManager.OnExpandChanged", BagsBar)
	end

	--blizzard's bag bar is left with just its expand arrow and frame art, Forever draws the art as a box around where the bags used to be.
	if BagBarExpandToggle then
		BagBarExpandToggle:UnregisterAllEvents()
		BagBarExpandToggle:SetParent(hiddenParent)
	end
	if BagsBar then
		BagsBar:UnregisterAllEvents()
		if BagsBar.HideBase then
			BagsBar:HideBase()
		else
			BagsBar:Hide()
		end
		BagsBar:SetParent(hiddenParent)
	end
end
local tookOver = false

---------------------------------------------------------

---Constructor: Create a new Photon Button object (this is the base object for all Photon button types)
---@param bar Bar @Bar Object this button will be a child of
---@param buttonID number @Button ID that this button will be assigned
---@param defaults table @Default options table to be loaded onto the given button
---@return BagButton @ A newly created BagButton object
function BagButton.new(bar, buttonID, defaults)
	--call the parent object constructor with the provided information specific to this button type
	local newButton = Photon.Button.new(bar, buttonID, BagButton, "BagBar", "BagButton", "PhotonAnchorButtonTemplate")

	if defaults then
		newButton:SetDefaults(defaults)
	end

	return newButton
end

--------------------------------------------------------

function BagButton:InitializeButton()
	if not tookOver then
		TakeOverFromBagsBar()
		tookOver = true
	end

	if blizzBagButtons[self.id] then
		self.hookedButton = blizzBagButtons[self.id]
		self:SetSize(BAG_BUTTON_SIZE, BAG_BUTTON_SIZE)
		--a bag button can only sit on one bar, the newest bag bar takes it or two bars keep taking it from each other
		for other in pairs(activeBagButtons) do
			if other ~= self and other.hookedButton == self.hookedButton then
				activeBagButtons[other] = nil
				other.hookedButton = nil
			end
		end
		activeBagButtons[self] = true
		self:AnchorHookedButton()
	end

	self:InitializeButtonSettings()
end

---put the blizzard bag button back inside this button
function BagButton:AnchorHookedButton()
	if not self.hookedButton then
		return
	end
	self.hookedButton:SetParent(self)
	self.hookedButton:ClearAllPoints()
	self.hookedButton:SetPoint("CENTER", self, "CENTER")
	self.hookedButton:Show()
end

function BagButton:InitializeButtonSettings()
	self:SetFrameStrata(Photon.STRATAS[self.bar:GetStrata()-1])
	self:SetScale(self.bar:GetBarScale())
	self:SetSkinned()
	self.isShown = true
end

---simplified SetSkinned for the Bag Buttons. They're unique in that they contain buttons inside of the buttons,
---so masque skins the blizzard bag button we hold instead of our own frame
function BagButton:SetSkinned()
	if Skin and self.hookedButton and self.hookedButton ~= KeyRingButton then
		local btnData = {
			Normal = self.hookedButton:GetNormalTexture(),
			Icon = self.hookedButton.icon,
			Count = self.hookedButton.Count,
			Pushed = self.hookedButton:GetPushedTexture(),
			Disabled = self.hookedButton:GetDisabledTexture(),
			Checked = self.hookedButton.SlotHighlightTexture, --blizzard in 8.1.5 took away GetCheckedTexture from the bag buttons for ~some~ reason. This is now the explicit location the element we want
			Highlight = self.hookedButton:GetHighlightTexture(),
			Border = self.hookedButton.IconBorder,
		}
		Skin:Group("Photon", self.bar.data.name):AddButton(self.hookedButton, btnData, "Item")
	end
end


-----------------------------------------------------
--------------------- Overrides ---------------------
-----------------------------------------------------

--overwrite function in parent class Button
function BagButton:UpdateStatus()
	-- empty --
end
--overwrite function in parent class Button
function BagButton:UpdateIcon()
	-- empty --
end
--overwrite function in parent class Button
function BagButton:UpdateUsable()
	-- empty --
end
--overwrite function in parent class Button
function BagButton:UpdateCount()
	-- empty --
end
--overwrite function in parent class Button
function BagButton:UpdateCooldown()
	-- empty --
end
--overwrite function in parent class Button
function BagButton:UpdateTooltip()
	-- empty --
end
