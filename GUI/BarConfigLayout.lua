-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...

-- Where each setting is placed in the bar editor (BarConfigWindow.lua).
-- Only placement lives here, the settings themselves are defined in Options.lua
-- and referenced by id. This file can be edited by hand or with Tools/BarConfigEditor.
--
-- apps: bar = Bar Settings tab, status = Configure Appearance tab
--  tabs: { id, name, groups, childGroups }
--   childGroups is optional: "tab" or "tree" shows each box as its own page
--   groups: { id, name, slots, rows } shown as an inline box, name may be empty.
--    slots is how many slots wide the box's grid is, 8 when left out
--    rows: a list of rows, each row starts on a new line
--     items: { id, width } width is "half", "normal", "double", "full" or a multiplier
--      name is optional and replaces the setting's own label
--     or { header = "Text" } for a divider with a title
--     or { text = "Text", width } for a line of text, left out when none of its row's settings show
--     or { id, box = true, name, border, light, width, rows } for a box inside the box, as many
--      slots wide inside as it takes. border = false leaves out its background and border,
--      light = true gives it a lighter background
--   a group with a single items list instead of rows is one row
--
-- names are run through the locale when a matching entry exists

addonTable.barConfigLayout = {
	bar = {
		{ id = "general", name = "General Configuration", groups = {
			{ id = "bar", name = "", rows = {
				{
					{ id = "barName", width = "double" },
					{ spacer = true, width = "normal" },
					{ id = "deleteBar", width = "normal" },
				},
			}},
			{ id = "enabledFunctions", name = "Enabled Functions", rows = {
				{
					{ id = "multiSpec", width = "normal" },
					{ id = "pages", width = "normal" },
					{ id = "state_stance", width = "normal" },
					{ id = "state_pet", width = "normal" },
				},
			}},
			{ id = "generalOptions", name = "General Options", rows = {
				{
					{ id = "autoHide", width = "normal" },
					{ id = "hidden", width = "normal" },
				},
				{
					{ id = "showGrid", width = "normal" },
					{ id = "snapTo", width = "normal" },
				},
				{
					{ id = "lockActions", width = "normal" },
					{ id = "clickMode", width = "normal" },
				},
			}},
			{ id = "sizeAndShape", name = "Size and Shape", slots = 6, rows = {
				{
					{ id = "numButtons", width = "normal" },
					{ id = "columns", width = "normal" },
					{ id = "scale", width = "normal" },
				},
				{
					{ id = "horizontalPadding", width = "normal" },
					{ id = "verticalPadding", width = "normal" },
					{ id = "shapeBox", box = true, name = "", light = true, width = "normal", rows = {
						{
							{ id = "shape", width = "normal" },
						},
					}},
				},
				{
					{ id = "alpha", width = "normal" },
					{ id = "alphaUpBox", box = true, name = "", light = true, width = "normal", rows = {
						{
							{ id = "alphaUp", width = "normal" },
						},
					}},
					{ id = "alphaUpSpeed", width = "normal" },
				},
				{
					{ id = "strataBox", box = true, name = "", light = true, width = "normal", rows = {
						{
							{ id = "strata", width = "normal" },
						},
					}},
				},
			}},
			{ id = "visuals", name = "Visuals", rows = {
				{
					{ id = "visualsLeft", box = true, name = "", border = false, width = 1.5, rows = {
						{
							{ id = "keybindBox", box = true, name = "", light = true, width = 1.5, rows = {
								{
									{ id = "keybindLabel", width = "normal" },
									{ id = "keybindColor", width = "half" },
								},
							}},
						},
						{
							{ id = "buttonNameBox", box = true, name = "", light = true, width = 1.5, rows = {
								{
									{ id = "buttonName", width = "normal" },
									{ id = "buttonNameColor", width = "half" },
								},
							}},
						},
						{
							{ id = "stackChargeBox", box = true, name = "", light = true, width = 1.5, rows = {
								{
									{ id = "stackCharge", width = "normal" },
									{ id = "stackChargeColor", width = "half" },
								},
							}},
						},
					}},
					{ id = "visualsRight", box = true, name = "", border = false, width = 1.5, rows = {
						{
							{ id = "outOfRangeBox", box = true, name = "", light = true, width = 1.5, rows = {
								{
									{ id = "outOfRange", width = "normal" },
									{ id = "outOfRangeColor", width = "half" },
								},
							}},
						},
						{
							{ id = "cooldownCounterBox", box = true, name = "", light = true, width = 1.5, rows = {
								{
									{ id = "cooldownCounter", width = "normal" },
									{ id = "cooldownColor1", width = "half" },
									{ id = "cooldownColor2", width = "half" },
								},
							}},
						},
						{
							{ id = "cooldownAlphaBox", box = true, name = "", light = true, width = 1.5, rows = {
								{
									{ id = "cooldownAlpha", width = "normal" },
								},
							}},
						},
					}},
				},
				{
					{ id = "tooltipsBox", box = true, name = "", light = true, width = 1.5, rows = {
						{
							{ id = "tooltips", width = 1.5 },
						},
						{
							{ id = "tooltipsInCombat", width = "normal" },
						},
					}},
					{ id = "spellAlertsBox", box = true, name = "", light = true, width = 1.5, rows = {
						{
							{ id = "spellAlerts", width = 1.5 },
						},
					}},
				},
				{
					{ id = "borderStyle", width = "normal" },
				},
			}},
		}},
		{ id = "visibility", name = "Bar Visibility", groups = {
			{ id = "states", name = "Active Bar States", rows = {
				{
					{ id = "statesBox1", box = true, name = "", light = true, width = "full", rows = {
						{
							{ id = "state_shift", width = "normal" },
							{ id = "state_ctrl", width = "normal" },
							{ id = "state_alt", width = "normal" },
						},
					}},
				},
				{
					{ id = "statesBox2", box = true, name = "", light = true, width = "full", rows = {
						{
							{ id = "state_target", width = "normal" },
							{ id = "state_harm", width = "normal" },
							{ id = "state_help", width = "normal" },
						},
					}},
				},
				{
					{ id = "statesBox3", box = true, name = "", light = true, width = "full", rows = {
						{
							{ id = "state_stealth", width = "normal" },
							{ id = "state_combat", width = "normal" },
							{ id = "state_party", width = "normal" },
							{ id = "state_raid", width = "normal" },
						},
					}},
				},
				{
					{ id = "statesBox4", box = true, name = "", light = true, width = "full", rows = {
						{
							{ id = "state_mounted", width = "normal" },
							{ id = "state_swimming", width = "normal" },
						},
					}},
				},
				{
					{ id = "statesBox5", box = true, name = "", light = true, width = "full", rows = {
						{
							{ id = "state_vehicle", width = "normal" },
							{ id = "state_possess", width = "normal" },
							{ id = "state_override", width = "normal" },
							{ id = "state_dragonriding", width = "normal" },
						},
					}},
				},
				{
					{ id = "statesBox6", box = true, name = "", light = true, width = "full", rows = {
						{
							{ id = "state_resting", width = "normal" },
							{ id = "state_indoors", width = "normal" },
							{ id = "state_outdoors", width = "normal" },
							{ id = "state_fishing", width = "normal" },
						},
					}},
				},
			}},
			{ id = "visibility", name = "Hidden Bar States", rows = {
				{
					{ id = "pagedRow", box = true, name = "", light = true, width = "full", rows = {
						{
							{ text = "Page", width = "normal" },
							{ id = "visibility_paged1", name = "1", width = "half" },
							{ id = "visibility_paged2", name = "2", width = "half" },
							{ id = "visibility_paged3", name = "3", width = "half" },
							{ id = "visibility_paged4", name = "4", width = "half" },
							{ id = "visibility_paged5", name = "5", width = "half" },
							{ id = "visibility_paged6", name = "6", width = "half" },
						},
					}},
				},
				{
					{ id = "shiftRow", box = true, name = "", light = true, width = "full", rows = {
						{
							{ text = "Shift", width = "normal" },
							{ id = "visibility_shift0", name = "Up", width = "half" },
							{ id = "visibility_shift1", name = "Down", width = "half" },
						},
						{
							{ text = "Control", width = "normal" },
							{ id = "visibility_ctrl0", name = "Up", width = "half" },
							{ id = "visibility_ctrl1", name = "Down", width = "half" },
						},
						{
							{ text = "Alt", width = "normal" },
							{ id = "visibility_alt0", name = "Up", width = "half" },
							{ id = "visibility_alt1", name = "Down", width = "half" },
						},
					}},
				},
				{
					{ id = "targetRow", box = true, name = "", light = true, width = "full", rows = {
						{
							{ text = "Target", width = "normal" },
							{ id = "visibility_target0", name = "None", width = "half" },
							{ id = "visibility_target1", name = "Has", width = "half" },
						},
						{
							{ text = "Target Type", width = "normal" },
							{ id = "visibility_harm1", name = "Harm", width = "half" },
							{ id = "visibility_help1", name = "Help", width = "half" },
						},
						{
							{ text = "Reaction", width = "normal" },
							{ id = "visibility_reaction0", name = "Friendly", width = "half" },
							{ id = "visibility_reaction1", name = "Hostile", width = "half" },
						},
					}},
				},
				{
					{ id = "stealthRow", box = true, name = "", light = true, width = "full", rows = {
						{
							{ text = "Stealth", width = "normal" },
							{ id = "visibility_stealth0", name = "No", width = "half" },
							{ id = "visibility_stealth1", name = "Yes", width = "half" },
						},
						{
							{ text = "Stance", width = "normal" },
							{ id = "visibility_stance0", name = "Default", width = "half" },
						},
						{
							{ text = "Combat", width = "normal" },
							{ id = "visibility_combat0", name = "Out", width = "half" },
							{ id = "visibility_combat1", name = "In", width = "half" },
						},
						{
							{ text = "Group", width = "normal" },
							{ id = "visibility_group0", name = "None", width = "half" },
							{ id = "visibility_group2", name = "Party", width = "half" },
							{ id = "visibility_group1", name = "Raid", width = "half" },
						},
					}},
				},
				{
					{ id = "petRow", box = true, name = "", light = true, width = "full", rows = {
						{
							{ text = "Pet", width = "normal" },
							{ id = "visibility_pet0", name = "None", width = "half" },
							{ id = "visibility_pet1", name = "Exists", width = "half" },
						},
						{
							{ text = "Mounted", width = "normal" },
							{ id = "visibility_mounted0", name = "No", width = "half" },
							{ id = "visibility_mounted1", name = "Yes", width = "half" },
						},
						{
							{ text = "Swimming", width = "normal" },
							{ id = "visibility_swimming0", name = "No", width = "half" },
							{ id = "visibility_swimming1", name = "Yes", width = "half" },
						},
					}},
				},
				{
					{ id = "vehicleRow", box = true, name = "", light = true, width = "full", rows = {
						{
							{ text = "Vehicle", width = "normal" },
							{ id = "visibility_vehicle0", name = "No", width = "half" },
							{ id = "visibility_vehicle1", name = "Yes", width = "half" },
						},
						{
							{ text = "Extra Bar", width = "normal" },
							{ id = "visibility_extrabar0", name = "No", width = "half" },
							{ id = "visibility_extrabar1", name = "Yes", width = "half" },
						},
						{
							{ text = "Possess", width = "normal" },
							{ id = "visibility_possess0", name = "No", width = "half" },
							{ id = "visibility_possess1", name = "Yes", width = "half" },
						},
						{
							{ text = "Override Bar", width = "normal" },
							{ id = "visibility_override0", name = "No", width = "half" },
							{ id = "visibility_override1", name = "Yes", width = "half" },
						},
						{
							{ text = "Dragon Riding", width = "normal" },
							{ id = "visibility_dragonriding0", name = "No", width = "half" },
							{ id = "visibility_dragonriding1", name = "Yes", width = "half" },
						},
					}},
				},
				{
					{ id = "restingRow", box = true, name = "", light = true, width = "full", rows = {
						{
							{ text = "Resting", width = "normal" },
							{ id = "visibility_resting0", name = "No", width = "half" },
							{ id = "visibility_resting1", name = "Yes", width = "half" },
						},
						{
							{ text = "Location", width = "normal" },
							{ id = "visibility_indoors1", name = "Indoors", width = "half" },
							{ id = "visibility_outdoors1", name = "Outdoors", width = "normal" },
						},
						{
							{ text = "Fishing Pole", width = "normal" },
							{ id = "visibility_fishing0", name = "No", width = "half" },
							{ id = "visibility_fishing1", name = "Yes", width = "half" },
						},
					}},
				},
			}},
			{ id = "apply", name = "", rows = {
				{
					{ id = "applyReload", width = "normal" },
					{ spacer = true, width = "normal" },
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
