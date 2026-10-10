-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Photon = addonTable.Photon

local L = LibStub("AceLocale-3.0"):GetLocale("Photon")

local Array = addonTable.utilities.Array

-- The bar editor's settings in AceConfig's option format, keyed by id. BarConfigLayout.lua places them.

--layout names are plain English, use the translation when there is one
local function localized(text)
	return rawget(L, text) or text
end

-----------------------------------------------------------------------------
--------------------------Bar Settings---------------------------------------
-----------------------------------------------------------------------------

local function bar()
	return Photon.currentBar
end

--hidden function for options that only some bar types have, see RegisteredGUIData.lua
local function unlessOption(kind, flag)
	return function()
		local data = Photon:RegisterGUI()[bar().class]
		return not (data and data[kind] and data[kind][flag])
	end
end

local function barToggle(name, getter, setter, hidden)
	return {
		type = "toggle",
		name = name,
		hidden = hidden,
		get = function() return not not bar()[getter](bar()) end,
		set = function(_, value) bar()[setter](bar(), value) end,
	}
end

local function barColor(name, getter, setter, hidden)
	return {
		type = "color",
		name = name,
		hidden = hidden,
		get = function() return unpack(bar()[getter](bar())) end,
		set = function(_, r, g, b, a) bar()[setter](bar(), {r, g, b, a}) end,
	}
end

local function barSelect(name, values, sorting, getter, setter, fallback, hidden)
	return {
		type = "select",
		name = name,
		values = values,
		sorting = sorting,
		hidden = hidden,
		get = function() return bar()[getter](bar()) or fallback end,
		set = function(_, value) bar()[setter](bar(), value) end,
	}
end

local function barRange(name, min, max, step, isPercent, getter, setter)
	return {
		type = "range",
		name = name,
		min = min,
		max = max,
		step = step,
		isPercent = isPercent,
		get = function() return bar()[getter](bar()) end,
		set = function(_, value) bar()[setter](bar(), value) end,
	}
end

--checked means the bar hides in that state, it is on the hide list
local function visibilityToggle(state)
	return {
		type = "toggle",
		name = Photon.VISIBILITY_STATES[state],
		--rogues get stealth as their home stance state instead
		hidden = Photon.class == "ROGUE" and state:match("^stealth") ~= nil,
		get = function() return not not bar().data.hidestates:find(state) end,
		set = function(_, value) bar():SetVisibility(state, not value) end,
	}
end

--a state the bar switches its buttons on
local function barStateToggle(state, name)
	return {
		type = "toggle",
		name = name,
		--states only apply to action bars. rogues get stealth as their home stance state instead
		hidden = function()
			return bar().class ~= "ActionBar" or (Photon.class == "ROGUE" and state == "stealth")
		end,
		get = function() return not not bar().data[state] end,
		set = function(_, value) bar():SetState(state, true, value) end,
	}
end

--what each class calls the things on its stance bar, for {form} in the hover text. the rest say stance
local FORM_WORDS = {
	DRUID = "BarDesc_FormWord",
	PRIEST = "BarDesc_FormWord",
	PALADIN = "BarDesc_AuraWord",
	ROGUE = "BarDesc_StealthWord",
	DEATHKNIGHT = "BarDesc_PresenceWord",
}

--built each time the options are shown, so ranges follow the current bar
local function barDefinitions()
	local numObjects = bar():GetNumObjects()
	--a menu bar is either empty or holds every micro button, a partial menu leaves blizzard's menu half taken
	local allOrNothing = bar().class == "MenuBar"

	local definitions = {
		barName = {
			type = "input",
			name = L["Name"],
			get = function() return bar():GetBarName() end,
			set = function(_, value) bar():SetBarName(value) end,
		},

		autoHide = barToggle(L["Auto-Hide"], "GetAutoHide", "SetAutoHide", unlessOption("generalOptions", "AUTOHIDE")),
		showGrid = barToggle(L["Show Grid"], "GetShowGrid", "SetShowGrid", unlessOption("generalOptions", "SHOWGRID")),
		snapTo = barToggle(L["SnapTo"], "GetSnapTo", "SetSnapTo", unlessOption("generalOptions", "SNAPTO")),
		multiSpec = barToggle(Photon.isWoWForever and L["Dual Spec"] or L["Multi Spec"], "GetMultiSpec", "SetMultiSpec", unlessOption("generalOptions", "MULTISPEC")),
		pages = barStateToggle("paged", Photon.MANAGED_HOME_STATES.paged.localizedName),
		hidden = barToggle(L["Hidden"], "GetBarConceal", "SetBarConceal", unlessOption("generalOptions", "HIDDEN")),
		lockActions = barSelect(L["Lock Actions"],
			{none = L["None"], shift = L["Shift"], ctrl = L["Ctrl"], alt = L["Alt"]},
			{"none", "shift", "ctrl", "alt"},
			"GetBarLock", "SetBarLock", "none", unlessOption("generalOptions", "LOCKBAR")),
		clickMode = barSelect(L["Click Mode"],
			{UpClick = L["On Release"], DownClick = L["On Click"]},
			{"UpClick", "DownClick"},
			"GetClickMode", "SetClickMode", nil, unlessOption("generalOptions", "CLICKMODE")),

		numButtons = {
			type = "range",
			name = L["Buttons"],
			min = 0,
			max = bar().objMax or 132,
			softMax = math.min(bar().objMax or 132, 24),
			step = allOrNothing and (bar().objMax or 1) or 1,
			get = function() return bar():GetNumObjects() end,
			set = function(_, value)
				while bar():GetNumObjects() < value do
					local before = bar():GetNumObjects()
					bar():AddObjectToBar()
					if bar():GetNumObjects() == before then break end --reached the bar's maximum
				end
				while bar():GetNumObjects() > value do
					bar():RemoveObjectFromBar()
				end
			end,
		},
		columns = barRange(L["Columns"], 0, math.max(numObjects, 1), 1, false, "GetColumns", "SetColumns"),
		scale = barRange(L["Scale"], 0.1, 2, 0.05, true, "GetBarScale", "SetBarScale"),
		shape = barSelect(L["Shape"],
			{linear = L["Linear"], circle = L["Circle"], ["circle + one"] = L["Circle + One"]},
			{"linear", "circle", "circle + one"},
			"GetBarShape", "SetBarShape"),
		horizontalPadding = barRange(L["Horizontal Padding"], -200, 200, 1, false, "GetHorizontalPad", "SetHorizontalPad"),
		verticalPadding = barRange(L["Vertical Padding"], -200, 200, 1, false, "GetVerticalPad", "SetVerticalPad"),
		alpha = barRange(L["Alpha"], 0.01, 1, 0.01, true, "GetBarAlpha", "SetBarAlpha"),
		alphaUp = barSelect(L["AlphaUp"],
			{off = L["Off"], mouseover = L["Mouseover"], combat = L["Combat"], ["combat + mouseover"] = L["Combat + Mouseover"]},
			{"off", "mouseover", "combat", "combat + mouseover"},
			"GetAlphaUp", "SetAlphaUp"),
		alphaUpSpeed = barRange(L["AlphaUp Speed"], 0.01, 1, 0.01, true, "GetAlphaUpSpeed", "SetAlphaUpSpeed"),
		strata = barSelect(L["Strata"],
			{[2] = L["Low"], [3] = L["Medium"], [4] = L["High"], [5] = L["Dialog"], [6] = L["Tooltip"]},
			{2, 3, 4, 5, 6},
			"GetStrata", "SetStrata"),

		keybindLabel = barToggle(L["Keybind Label"], "GetShowBindText", "SetShowBindText", unlessOption("visualOptions", "BINDTEXT")),
		keybindColor = barColor(L["Color"], "GetBindColor", "SetBindColor", unlessOption("visualOptions", "BINDTEXT")),
		buttonName = barToggle(L["Button Name"], "GetShowButtonText", "SetShowButtonText", unlessOption("visualOptions", "BUTTONTEXT")),
		buttonNameColor = barColor(L["Color"], "GetMacroColor", "SetMacroColor", unlessOption("visualOptions", "BUTTONTEXT")),
		stackCharge = barToggle(L["Stack/Charge"], "GetShowCountText", "SetShowCountText", unlessOption("visualOptions", "COUNTTEXT")),
		stackChargeColor = barColor(L["Color"], "GetCountColor", "SetCountColor", unlessOption("visualOptions", "COUNTTEXT")),
		outOfRange = barToggle(L["Out-of-Range"], "GetShowRangeIndicator", "SetShowRangeIndicator", unlessOption("visualOptions", "RANGEIND")),
		outOfRangeColor = barColor(L["Color"], "GetRangeColor", "SetRangeColor", unlessOption("visualOptions", "RANGEIND")),
		cooldownCounter = barToggle(L["CD Counter"], "GetShowCooldownText", "SetShowCooldownText", unlessOption("visualOptions", "CDTEXT")),
		cooldownColor1 = barColor(L["Color"].." 1", "GetCooldownColor1", "SetCooldownColor1", unlessOption("visualOptions", "CDTEXT")),
		cooldownColor2 = barColor(L["Color"].." 2", "GetCooldownColor2", "SetCooldownColor2", unlessOption("visualOptions", "CDTEXT")),
		cooldownAlpha = barToggle(L["Cooldown Alpha"], "GetShowCooldownAlpha", "SetShowCooldownAlpha", unlessOption("visualOptions", "CDALPHA")),
		spellAlerts = barSelect(L["Spell Alerts"],
			{none = L["None"], alternate = L["Subdued Alert"], default = L["Default Alert"]},
			{"none", "alternate", "default"},
			"GetSpellGlow", "SetSpellGlow", "none", unlessOption("visualOptions", "SPELLGLOW")),
		tooltips = barSelect(L["Enable Tooltips"],
			{off = L["Off"], minimal = L["Minimal"], normal = L["Normal"]},
			{"off", "minimal", "normal"},
			"GetTooltipOption", "SetTooltipOption", "off", unlessOption("visualOptions", "TOOLTIPS")),
		tooltipsInCombat = barToggle(L["Tooltips in Combat"], "GetTooltipCombat", "SetTooltipCombat", unlessOption("visualOptions", "TOOLTIPS")),
		borderStyle = barToggle(L["Show Border Style"], "GetShowBorderStyle", "SetShowBorderStyle", unlessOption("visualOptions", "BORDERSTYLE")),

		deleteBar = {
			type = "execute",
			name = L["Delete Bar"],
			confirm = function() return L["DeleteBar_Confirm"] end,
			func = function() bar():DeleteBar() end,
		},

		applyReload = {
			type = "execute",
			name = L["Apply"],
			desc = L["ReloadUI"],
			func = ReloadUI,
		},
	}

	for state in pairs(Photon.VISIBILITY_STATES) do
		definitions["visibility_"..state] = visibilityToggle(state)
	end

	for state, info in pairs(Photon.MANAGED_HOME_STATES) do
		definitions["state_"..state] = barStateToggle(state, info.localizedName)
	end
	--named after its page, as in the button editor. the game's bars have no page
	local gameBars = {vehicle = true, dragonriding = true, possess = true, override = true}
	for state, info in pairs(Photon.MANAGED_SECONDARY_STATES) do
		local name = not gameBars[state] and Photon.STATES[state.."1"] or info.localizedName
		definitions["state_"..state] = barStateToggle(state, name)
	end

	--the hover text, see the BarDesc_ entries in the locale
	local formWord = L[FORM_WORDS[Photon.class] or "BarDesc_StanceWord"]
	for id, option in pairs(definitions) do
		local desc = rawget(L, "BarDesc_"..id)
		option.desc = option.desc or (desc and desc:gsub("{form}", formWord))
	end

	return definitions
end

-----------------------------------------------------------------------------
--------------------------Status Bar Appearance------------------------------
-----------------------------------------------------------------------------

local CAST_UNITS = {"player", "pet", "target", "targettarget", "focus", "mouseover", "party1", "party2", "party3", "party4"}

--the status bar button being edited: the selected one when it is on the selected bar,
--else the selected bar's own, so a bar picked without clicking it edits itself
local function button()
	local bar, current = Photon.currentBar, Photon.currentButton
	if current and current.bar == bar then
		return current
	end
	return bar and bar.buttons and bar.buttons[1] or current
end

local function notCastBar()
	return Photon.currentBar.barType ~= "CastBar"
end

local function statusSelect(name, values, configKey, updater)
	return {
		type = "select",
		name = name,
		values = values,
		get = function() return button().config[configKey] end,
		set = function(_, value) button()[updater](button(), value) end,
	}
end

local function statusRange(name, min, max, configKey, updater)
	return {
		type = "range",
		name = name,
		min = min,
		max = max,
		step = 1,
		get = function() return button().config[configKey] end,
		set = function(_, value) button()[updater](button(), value) end,
	}
end

local function statusDefinitions()
	local textValues = Array.map(function(sbString) return sbString[1] end, button().sbStrings)

	return {
		width = statusRange(L["Width"], 10, 1000, "width", "UpdateWidth"),
		height = statusRange(L["Height"], 4, 200, "height", "UpdateHeight"),
		orientation = statusSelect(L["Orientation"], Photon.BAR_ORIENTATIONS, "orientation", "UpdateOrientation"),
		barFill = statusSelect(L["Bar Fill"], Array.map(function(fill) return fill[3] end, Photon.BAR_TEXTURES), "texture", "UpdateBarFill"),
		border = statusSelect(L["Border"], Array.map(function(border) return border[1] end, Photon.BAR_BORDERS), "border", "UpdateBorder"),
		centerText = statusSelect(L["Center Text"], textValues, "cIndex", "UpdateCenterText"),
		leftText = statusSelect(L["Left Text"], textValues, "lIndex", "UpdateLeftText"),
		rightText = statusSelect(L["Right Text"], textValues, "rIndex", "UpdateRightText"),
		mouseoverText = statusSelect(L["Mouseover Text"], textValues, "mIndex", "UpdateMouseover"),
		tooltipText = statusSelect(L["Tooltip Text"], textValues, "tIndex", "UpdateTooltip"),

		castIcon = {
			type = "toggle",
			name = L["Cast Icon"],
			hidden = notCastBar,
			get = function() return not not button().config.showIcon end,
			set = function(_, value) button():SetShowIcon(value) end,
		},
		castUnit = {
			type = "select",
			name = L["Unit"],
			values = CAST_UNITS,
			hidden = notCastBar,
			get = function() return Array.find(function(unit) return unit == button().config.unit end, CAST_UNITS) end,
			set = function(_, index) button():SetUnit(CAST_UNITS[index]) end,
		},

		applyReload = {
			type = "execute",
			name = L["Apply"],
			desc = L["ReloadUI"],
			func = ReloadUI,
		},
	}
end

-----------------------------------------------------------------------------
--------------------------For the Bar Editor---------------------------------
-----------------------------------------------------------------------------

local function isHidden(option)
	if type(option.hidden) == "function" then
		return option.hidden()
	end
	return option.hidden
end

--an element added in the layout editor that has no definition here yet. it shows in
--the editor greyed out until a definition with the same id is added
local function placeholder(item)
	local option = {
		type = item.type,
		name = localized(item.name or item.id),
		desc = "Not wired up yet: add a definition for \""..item.id.."\" in GUI/Options.lua",
		disabled = true,
		get = function() end,
		set = function() end,
	}
	if item.type == "select" then
		option.values = {}
	elseif item.type == "range" then
		option.min, option.max, option.step = 0, 100, 1
		option.get = function() return 0 end
	elseif item.type == "execute" then
		option.func = function() end
		option.get, option.set = nil, nil
	elseif item.type == "color" then
		option.get = function() return 1, 1, 1 end
	elseif item.type == "input" then
		option.get = function() return "" end
	end
	return option
end

local PLACEHOLDER_TYPES = {toggle = true, select = true, range = true, input = true, color = true, execute = true}

--the settings for the bar editor, see BarConfigWindow.lua
addonTable.optionDefinitions = {
	localized = localized,
	isHidden = isHidden,
	placeholder = placeholder,
	PLACEHOLDER_TYPES = PLACEHOLDER_TYPES,

	---the selected bar's settings, built each time so ranges follow the bar. nil without a bar
	bar = function()
		if not bar() then
			return
		end
		return barDefinitions()
	end,

	---the selected status bar button's appearance settings, nil without one
	status = function()
		if not button() or not button().config then
			return
		end
		return statusDefinitions()
	end,
}
