-- Neuron is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- Copyright (c) 2026 Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...

-- Where each setting is placed in the editor. Only placement lives here, the
-- settings themselves are defined in Options.lua and referenced by id.
-- This file can be edited by hand or with the Neuron layout editor.
--
-- apps: bar = Bar Settings tab, status = Configure Appearance tab
--  tabs: { id, name, groups, childGroups }
--   childGroups is optional: "tab" or "tree" shows each box as its own page
--   groups: { id, name, rows } shown as an inline box, name may be empty
--    rows: a list of rows, each row starts on a new line
--     items: { id, width } width is "half", "normal", "double", "full" or a multiplier
--     or { header = "Text" } for a divider with a title
--   a group with a single items list instead of rows is one row
--
-- names are run through the locale when a matching entry exists

addonTable.guiLayout = {
	bar = {
		{ id = "general", name = "General Configuration", groups = {
			{ id = "bar", name = "", rows = {
				{
					{ id = "barName", width = "double" },
				},
				{
					{ spacer = true, width = "normal" },
				},
				{
					{ text = "Test", width = "full" },
				},
			}},
			{ id = "generalOptions", name = "General Options", rows = {
				{
					{ id = "autoHide", width = "normal" },
					{ id = "showGrid", width = "normal" },
					{ id = "snapTo", width = "normal" },
					{ id = "multiSpec", width = "normal" },
					{ id = "hidden", width = "normal" },
					{ id = "lockActions", width = "normal" },
					{ id = "clickMode", width = "normal" },
				},
				{},
				{},
			}},
			{ id = "sizeAndShape", name = "Size and Shape", rows = {
				{
					{ id = "numButtons", width = "normal" },
					{ id = "columns", width = "normal" },
					{ id = "scale", width = "normal" },
					{ id = "shape", width = "normal" },
					{ id = "horizontalPadding", width = "normal" },
					{ id = "verticalPadding", width = "normal" },
					{ id = "alpha", width = "normal" },
					{ id = "alphaUp", width = "normal" },
					{ id = "alphaUpSpeed", width = "normal" },
					{ id = "strata", width = "normal" },
				},
			}},
			{ id = "visuals", name = "Visuals", rows = {
				{
					{ id = "keybindLabel", width = "normal" },
					{ id = "keybindColor", width = "half" },
					{ id = "buttonName", width = "normal" },
					{ id = "buttonNameColor", width = "half" },
					{ id = "stackCharge", width = "normal" },
					{ id = "stackChargeColor", width = "half" },
					{ id = "outOfRange", width = "normal" },
					{ id = "outOfRangeColor", width = "half" },
					{ id = "cooldownCounter", width = "normal" },
					{ id = "cooldownColor1", width = "half" },
					{ id = "cooldownColor2", width = "half" },
					{ id = "cooldownAlpha", width = "normal" },
					{ id = "spellAlerts", width = "normal" },
					{ id = "tooltips", width = "normal" },
					{ id = "tooltipsInCombat", width = "normal" },
					{ id = "borderStyle", width = "normal" },
				},
			}},
			{ id = "dangerous", name = "Dangerous", rows = {
				{
					{ id = "deleteBar", width = "normal" },
				},
			}},
		}},
		{ id = "states", name = "Bar States", groups = {
			{ id = "states", name = "", rows = {
				{
					{ id = "barStates", width = "normal" },
				},
			}},
		}},
		{ id = "visibility", name = "Bar Visibility", groups = {
			{ id = "visibility", name = "", rows = {
				{
					{ id = "visibilityStates", width = "normal" },
				},
			}},
			{ id = "apply", name = "", rows = {
				{
					{ id = "applyReload", width = "normal" },
				},
			}},
		}},
	},

	status = {
		{ id = "appearance", name = "Configure Appearance", groups = {
			{ id = "size", name = "Size and Shape", rows = {
				{
					{ id = "width", width = "normal" },
					{ id = "height", width = "normal" },
					{ id = "orientation", width = "normal" },
				},
			}},
			{ id = "look", name = "Visuals", rows = {
				{
					{ id = "barFill", width = "normal" },
					{ id = "border", width = "normal" },
				},
			}},
			{ id = "text", name = "Text", rows = {
				{
					{ id = "centerText", width = "normal" },
					{ id = "leftText", width = "normal" },
					{ id = "rightText", width = "normal" },
					{ id = "mouseoverText", width = "normal" },
					{ id = "tooltipText", width = "normal" },
				},
			}},
			{ id = "cast", name = "", rows = {
				{
					{ id = "castIcon", width = "normal" },
					{ id = "castUnit", width = "normal" },
				},
			}},
			{ id = "apply", name = "", rows = {
				{
					{ id = "applyReload", width = "normal" },
				},
			}},
		}},
	},
}
