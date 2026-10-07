-- Neuron is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- Copyright (c) 2026 Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Neuron = addonTable.Neuron

local NeuronGUI = Neuron.NeuronGUI

local L = LibStub("AceLocale-3.0"):GetLocale("Neuron")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local Array = addonTable.utilities.Array

-- The settings shown in the editor, as AceConfig options keyed by id.
-- Where they appear is decided by Layout.lua, not here.

local BAR_APP = "NeuronBarOptions"
local STATUS_APP = "NeuronStatusOptions"

--layout names are plain English, use the translation when there is one
local function localized(text)
	return rawget(L, text) or text
end

--rebuilding the editor from inside an AceConfig callback would release the
--widget that is still being used, so wait for the next frame
local function refreshEditorLater()
	C_Timer.After(0, function() NeuronGUI:RefreshEditor() end)
end

-----------------------------------------------------------------------------
--------------------------Bar Settings---------------------------------------
-----------------------------------------------------------------------------

local function bar()
	return Neuron.currentBar
end

--hidden function for options that only some bar types have, see RegisteredGUIData.lua
local function unlessOption(kind, flag)
	return function()
		local data = Neuron:RegisterGUI()[bar().class]
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

--built each time the options are shown, so ranges follow the current bar
local function barDefinitions()
	local numObjects = bar():GetNumObjects()
	--a menu bar is either empty or holds every micro button, a partial menu leaves blizzard's menu half taken
	local allOrNothing = bar().class == "MenuBar"

	return {
		barName = {
			type = "input",
			name = L["Name"],
			get = function() return bar():GetBarName() end,
			set = function(_, value)
				bar():SetBarName(value)
				refreshEditorLater() --the bar list and status line show the name
			end,
		},

		autoHide = barToggle(L["Auto-Hide"], "GetAutoHide", "SetAutoHide", unlessOption("generalOptions", "AUTOHIDE")),
		showGrid = barToggle(L["Show Grid"], "GetShowGrid", "SetShowGrid", unlessOption("generalOptions", "SHOWGRID")),
		snapTo = barToggle(L["SnapTo"], "GetSnapTo", "SetSnapTo", unlessOption("generalOptions", "SNAPTO")),
		multiSpec = barToggle(Neuron.isWoWForever and L["Dual Spec"] or L["Multi Spec"], "GetMultiSpec", "SetMultiSpec", unlessOption("generalOptions", "MULTISPEC")),
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
			confirm = function() return L["Delete Bar"]..": "..bar():GetBarName().."?" end,
			func = function()
				bar():DeleteBar()
				refreshEditorLater()
			end,
		},

		applyReload = {
			type = "execute",
			name = L["Apply"],
			desc = L["ReloadUI"],
			func = ReloadUI,
		},
	}
end

--settings that expand into one option per state, as {key, option} pairs
local barDynamic = {
	--only one home state can be active, SetState turns the others off
	homeStates = function()
		return Array.map(function(state)
			return {"home_"..state, {
				type = "toggle",
				name = Neuron.MANAGED_HOME_STATES[state].localizedName,
				get = function() return not not bar().data[state] end,
				set = function(_, value) bar():SetState(state, true, value) end,
			}}
		end, {"paged", "stance", "pet"})
	end,

	secondaryStates = function()
		local states = {}
		for state, info in pairs(Neuron.MANAGED_SECONDARY_STATES) do
			--rogues get stealth as their home stance state instead
			if not (Neuron.class == "ROGUE" and state == "stealth") then
				table.insert(states, {state = state, name = info.localizedName})
			end
		end
		table.sort(states, function(a, b) return a.name < b.name end)

		return Array.map(function(entry)
			return {"secondary_"..entry.state, {
				type = "toggle",
				name = entry.name,
				get = function() return not not bar().data[entry.state] end,
				set = function(_, value) bar():SetState(entry.state, true, value) end,
			}}
		end, states)
	end,

	--checked means the bar shows in that state, unchecked adds it to the hide list
	visibilityStates = function()
		local states = {}
		for state in pairs(Neuron.VISIBILITY_STATES) do
			if not (Neuron.class == "ROGUE" and state:match("^stealth")) then
				table.insert(states, state)
			end
		end
		table.sort(states)

		return Array.map(function(state)
			return {"visibility_"..state, {
				type = "toggle",
				name = Neuron.VISIBILITY_STATES[state],
				get = function() return not bar().data.hidestates:find(state) end,
				set = function(_, value) bar():SetVisibility(state, value) end,
			}}
		end, states)
	end,
}

-----------------------------------------------------------------------------
--------------------------Status Bar Appearance------------------------------
-----------------------------------------------------------------------------

local CAST_UNITS = {"player", "pet", "target", "targettarget", "focus", "mouseover", "party1", "party2", "party3", "party4"}

local function button()
	return Neuron.currentButton
end

local function notCastBar()
	return Neuron.currentBar.barType ~= "CastBar"
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
		orientation = statusSelect(L["Orientation"], Neuron.BAR_ORIENTATIONS, "orientation", "UpdateOrientation"),
		barFill = statusSelect(L["Bar Fill"], Array.map(function(fill) return fill[3] end, Neuron.BAR_TEXTURES), "texture", "UpdateBarFill"),
		border = statusSelect(L["Border"], Array.map(function(border) return border[1] end, Neuron.BAR_BORDERS), "border", "UpdateBorder"),
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
--------------------------Builder--------------------------------------------
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

local function allHidden(options)
	for _, option in ipairs(options) do
		if not isHidden(option) then
			return false
		end
	end
	return true
end

---turn one tab of Layout.lua into AceConfig args
---@param asPages boolean @true when the tab shows its boxes as sub-tabs or a tree instead of inline boxes
local function buildGroups(groups, definitions, dynamic, asPages)
	local args = {}

	for groupIndex, group in ipairs(groups) do
		local groupArgs = {}
		local settings = {} --the real settings in this box, not the headers and row breaks
		local order = 0

		local function add(key, option)
			order = order + 1
			option.order = order
			groupArgs[key] = option
		end

		--a box is a list of rows, an old style items list is a single row
		local rows = group.rows or {group.items or {}}

		for rowIndex, row in ipairs(rows) do
			local rowSettings = {}

			for itemIndex, item in ipairs(row) do
				local key = rowIndex.."_"..itemIndex
				if item.header then
					add("header"..key, {type = "header", name = localized(item.header)})
				elseif item.text then
					add("text"..key, {type = "description", name = localized(item.text), fontSize = "medium", width = item.width or "full"})
				elseif item.spacer then
					add("spacer"..key, {type = "description", name = " ", width = item.width})
				else
					local entries
					if dynamic and dynamic[item.id] then
						entries = dynamic[item.id]()
					elseif definitions[item.id] then
						entries = {{item.id, definitions[item.id]}}
					elseif PLACEHOLDER_TYPES[item.type] then
						entries = {{item.id, placeholder(item)}}
					else
						entries = {} --unknown id, most likely a typo in Layout.lua
					end

					for _, entry in ipairs(entries) do
						entry[2].width = item.width
						add(entry[1], entry[2])
						table.insert(rowSettings, entry[2])
						table.insert(settings, entry[2])
					end
				end
			end

			--start the next row on a new line, unless nothing in this row is shown
			if rowIndex < #rows then
				add("break"..rowIndex, {
					type = "description",
					name = "",
					width = "full",
					hidden = function() return allHidden(rowSettings) end,
				})
			end
		end

		args[group.id] = {
			type = "group",
			inline = not asPages,
			name = localized((group.name ~= "" and group.name) or (asPages and group.id) or ""),
			order = groupIndex,
			args = groupArgs,
			--don't leave an empty box when this bar type has none of the group's settings
			--a box with only text or headers is always shown
			hidden = function() return #settings > 0 and allHidden(settings) end,
		}
	end

	return args
end

---turn a whole app of Layout.lua into an AceConfig options table
local function buildApp(tabs, definitions, dynamic, hiddenTabs)
	--a single tab doesn't need a tab bar
	--a tab's childGroups ("tab" or "tree") shows its boxes as separate pages
	if #tabs == 1 then
		local tab = tabs[1]
		return {type = "group", name = "", childGroups = tab.childGroups, args = buildGroups(tab.groups, definitions, dynamic, tab.childGroups ~= nil)}
	end

	local args = {}
	for tabIndex, tab in ipairs(tabs) do
		args[tab.id] = {
			type = "group",
			name = localized(tab.name),
			order = tabIndex,
			hidden = hiddenTabs and hiddenTabs[tab.id],
			childGroups = tab.childGroups,
			args = buildGroups(tab.groups, definitions, dynamic, tab.childGroups ~= nil),
		}
	end

	return {type = "group", name = "", childGroups = "tab", args = args}
end

--AceConfigDialog refreshes once more after a setting changes
local EMPTY_OPTIONS = {type = "group", name = "", args = {}}

AceConfigRegistry:RegisterOptionsTable(BAR_APP, function()
	if not bar() then
		return EMPTY_OPTIONS
	end
	return buildApp(addonTable.guiLayout.bar, barDefinitions(), barDynamic, {
		--states only apply to action bars
		states = function() return bar().class ~= "ActionBar" end,
	})
end)

AceConfigRegistry:RegisterOptionsTable(STATUS_APP, function()
	if not button() or not button().config then
		return EMPTY_OPTIONS
	end
	return buildApp(addonTable.guiLayout.status, statusDefinitions())
end)

---show the settings for the selected bar inside an AceGUI container
function NeuronGUI:OpenBarOptions(container)
	AceConfigDialog:Open(BAR_APP, container)
end

---show the appearance settings for the selected status bar button inside an AceGUI container
function NeuronGUI:OpenStatusOptions(container)
	AceConfigDialog:Open(STATUS_APP, container)
end
