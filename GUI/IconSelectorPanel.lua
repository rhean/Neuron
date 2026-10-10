-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- Copyright (c) 2026 Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Photon = addonTable.Photon

local PhotonGUI = Photon.PhotonGUI

local UI = addonTable.ui
local Style = UI.Style

-----------------------------------------------------------------------------
--------------------------Icon Selector--------------------------------------
-----------------------------------------------------------------------------
--a grid of every spell, item and macro icon. only the rows in view have
--buttons, scrolling gives them other icons

local ICON_SIZE = 36
local SPACING = 4
local STEP = ICON_SIZE + SPACING

local window, search, grid, bar
--every icon, {icon, names}. names are the known spells and items using it, lowercased, for searching
local allIcons = {}
--the ones matching the search
local iconList = {}
local buttons = {}
local firstRow = 0
local onPick

--how many spells and items the list was built with, it is built again when that changes
local builtFor

local function generateIconList()
	local known = 0
	for _ in pairs(Photon.spellCache) do
		known = known + 1
	end
	for _ in pairs(Photon.itemCache) do
		known = known + 1
	end
	if known == builtFor then
		return
	end
	builtFor = known

	wipe(allIcons)
	local byIcon = {}
	local function add(icon, name)
		if not icon then
			return
		end
		local entry = byIcon[icon]
		if not entry then
			entry = {icon = icon, names = ""}
			byIcon[icon] = entry
			table.insert(allIcons, entry)
		end
		if name then
			entry.names = entry.names.."\n"..name:lower()
		end
	end

	--a spell is in the cache under its name and name()
	local seen = {}
	for _, spell in pairs(Photon.spellCache) do
		if not seen[spell] then
			seen[spell] = true
			add(spell.icon, spell.spellName)
		end
	end
	--item names to item ids
	for name, itemID in pairs(Photon.itemCache) do
		add(C_Item.GetItemIconByID(itemID), name)
	end

	--blizzard's macro icons have no names, they only show without a search
	local macroIcons = {}
	GetLooseMacroIcons(macroIcons)
	GetLooseMacroItemIcons(macroIcons)
	GetMacroIcons(macroIcons)
	GetMacroItemIcons(macroIcons)
	for _, icon in ipairs(macroIcons) do
		add(icon)
	end
end

local function applySearch()
	wipe(iconList)
	local text = search:GetText():lower()
	for _, entry in ipairs(allIcons) do
		if text == "" or entry.names:find(text, 1, true) then
			table.insert(iconList, entry.icon)
		end
	end
end

local function createIcon()
	local button = UI.IconButton(grid, ICON_SIZE)
	button:SetScript("OnClick", function(self)
		local pick = onPick
		window:Hide()
		pick(self.texture)
	end)
	return button
end

--lays the grid's buttons out for its size and fills them from firstRow
local updating
local laidOut
local function refresh()
	if updating then
		return
	end
	updating = true

	local columns = math.max(1, math.floor((grid:GetWidth() + SPACING) / STEP))
	local rows = math.max(1, math.floor((grid:GetHeight() + SPACING) / STEP))
	local maxFirst = math.max(0, math.ceil(#iconList / columns) - rows)
	firstRow = math.min(firstRow, maxFirst)

	bar:SetMinMaxValues(0, maxFirst)
	bar:SetValue(firstRow)
	bar:SetShown(maxFirst > 0)

	--scrolling only changes the textures
	local size = columns..":"..rows
	local relayout = size ~= laidOut
	laidOut = size

	for i = 1, columns * rows do
		local button = buttons[i]
		if not button then
			button = createIcon()
			buttons[i] = button
		end
		if relayout then
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", ((i - 1) % columns) * STEP, -math.floor((i - 1) / columns) * STEP)
		end

		local texture = iconList[firstRow * columns + i]
		button.texture = texture
		button.icon:SetTexture(texture)
		button:SetShown(texture ~= nil)
	end
	for i = columns * rows + 1, #buttons do
		buttons[i]:Hide()
	end

	updating = false
end

local function createWindow()
	window = UI.Window("PhotonIconSelectorFrame", "Select an icon")
	window:SetSize(610, 500)
	window:SetMinSize(300, 250)

	--by spell or item name
	search = UI.EditBox(window.content, function()
		applySearch()
		firstRow = 0
		refresh()
	end)
	search:SetPoint("TOPLEFT")
	search:SetPoint("TOPRIGHT")
	search:SetPlaceholder(SEARCH)

	grid = CreateFrame("Frame", nil, window.content)
	grid:SetPoint("TOPLEFT", search, "BOTTOMLEFT", 0, -Style.padding)
	grid:SetPoint("BOTTOMRIGHT", -12, 0)
	grid:SetScript("OnSizeChanged", refresh)

	bar = UI.ScrollBar(window.content)
	bar:SetPoint("TOPRIGHT", grid, "TOPRIGHT", 12, 0)
	bar:SetPoint("BOTTOMRIGHT")
	bar:SetValueStep(1)
	bar:SetObeyStepOnDrag(true)
	bar:SetScript("OnValueChanged", function(_, value)
		value = math.floor(value + 0.5)
		if value ~= firstRow then
			firstRow = value
			refresh()
		end
	end)

	window.content:EnableMouseWheel(true)
	window.content:SetScript("OnMouseWheel", function(_, delta)
		bar:SetValue(firstRow - delta * 2)
	end)
end

---shows every icon and calls pick with the one clicked
---@param pick fun(icon: number|string)
function PhotonGUI:OpenIconSelector(pick)
	if not window then
		createWindow()
	end
	onPick = pick
	generateIconList()
	search:SetText("")
	applySearch()
	firstRow = 0
	window:Show()
	window:Raise()
	refresh()
end

function PhotonGUI:CloseIconSelector()
	if window then
		window:Hide()
	end
end
