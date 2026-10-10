-- Neuron is a World of Warcraft® user interface addon.
-- Copyright (c) 2026 Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...

-----------------------------------------------------------------------------
--------------------------------- Style -------------------------------------
-----------------------------------------------------------------------------
--the flat look of Neuron's own widgets, see Widgets.lua.
--colors are {r, g, b, a}

local Style = {
	window = {0.15, 0.15, 0.16, 0.96},
	panel = {0.12, 0.12, 0.13, 1},
	panelLight = {0.19, 0.19, 0.2, 1},
	box = {0.13, 0.13, 0.14, 1},
	strip = {0.1, 0.1, 0.11, 1},
	field = {0.04, 0.04, 0.05, 1},
	border = {0, 0, 0, 1},
	clear = {0, 0, 0, 0},
	hover = {1, 1, 1, 0.06},
	selected = {1, 1, 1, 0.12},
	accent = {1, 0.82, 0, 1},
	focus = {0.5, 0.5, 0.5, 1},
	text = {0.9, 0.9, 0.9, 1},
	dim = {0.55, 0.55, 0.55, 1},
	placeholder = {0.42, 0.42, 0.42, 1},

	font = "GameFontHighlight",
	fontSmall = "GameFontHighlightSmall",
	fontLarge = "GameFontHighlightLarge",

	padding = 8,
	--inside a light box
	lightInset = {left = 7, top = 7, right = 4, bottom = 4},
	gap = 6,
	rowHeight = 22,
	stripHeight = 20,
}

local SIDES = {"TOP", "BOTTOM", "LEFT", "RIGHT"}

---a filled background with a 1px border, made once per frame
---@param color? table @Style.panel when left out
---@param borderColor? table @Style.border when left out
function Style.Flat(frame, color, borderColor)
	local skin = frame.neuronFlat
	if not skin then
		skin = {bg = frame:CreateTexture(nil, "BACKGROUND", nil, -8)}
		skin.bg:SetAllPoints()
		for _, side in ipairs(SIDES) do
			skin[side] = frame:CreateTexture(nil, "BORDER", nil, -8)
		end
		skin.TOP:SetPoint("TOPLEFT")
		skin.TOP:SetPoint("TOPRIGHT")
		skin.TOP:SetHeight(1)
		skin.BOTTOM:SetPoint("BOTTOMLEFT")
		skin.BOTTOM:SetPoint("BOTTOMRIGHT")
		skin.BOTTOM:SetHeight(1)
		skin.LEFT:SetPoint("TOPLEFT")
		skin.LEFT:SetPoint("BOTTOMLEFT")
		skin.LEFT:SetWidth(1)
		skin.RIGHT:SetPoint("TOPRIGHT")
		skin.RIGHT:SetPoint("BOTTOMRIGHT")
		skin.RIGHT:SetWidth(1)
		frame.neuronFlat = skin
	end

	skin.bg:SetColorTexture(unpack(color or Style.panel))
	Style.SetBorder(frame, borderColor or Style.border)
end

---recolors the border Style.Flat made
function Style.SetBorder(frame, color)
	for _, side in ipairs(SIDES) do
		frame.neuronFlat[side]:SetColorTexture(unpack(color))
	end
end

---shows or hides the background and border Style.Flat made
---@param borderShown? boolean @the border on its own, like shown when left out
function Style.SetFlatShown(frame, shown, borderShown)
	if borderShown == nil then
		borderShown = shown
	end
	frame.neuronFlat.bg:SetShown(shown)
	for _, side in ipairs(SIDES) do
		frame.neuronFlat[side]:SetShown(borderShown)
	end
end

addonTable.ui = addonTable.ui or {}
addonTable.ui.Style = Style
