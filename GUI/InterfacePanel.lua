-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local addonName, addonTable = ...
local Photon = addonTable.Photon

local PhotonGUI = Photon.PhotonGUI

local UI = addonTable.ui
local Style = UI.Style

local L = LibStub("AceLocale-3.0"):GetLocale("Photon")

-----------------------------------------------------------------------------
--------------------------Interface Menu-------------------------------------
-----------------------------------------------------------------------------
-- This is the file that manages this addons main configuration screen
-- this is not the file the manages bars and buttons
--
-- each fooOptions function sets up a separate configuration panel
-- these panels are then loaded via PhotonGUI:LoadInterfaceOptions

local function profileOptions()
	local options = LibStub("AceDBOptions-3.0"):GetOptionsTable(Photon.db)

	--enhance the database object with per spec profile features
	--LibDualSpec only loads on WOW_PROJECT_MAINLINE, so it's missing on Forever builds that report WOW_PROJECT_CAMELOT
	local LibDualSpec = LibStub('LibDualSpec-1.0', true)
	if LibDualSpec then
		LibDualSpec:EnhanceDatabase(Photon.db, addonName)
		LibDualSpec:EnhanceOptions(options, Photon.db) -- enhance the profiles config panel with per spec profile features
	end
	return options
end

local function experimentalOptions()
	return {
		name = L["Experimental"],
		desc = L["Experimental Options"],
		type = "group",
		order = 1001,
		args = {

			Header = {
				order = 1,
				name = L["Experimental Options"],
				type = "header",
			},

			Warning = {
				order = 2,
				type = "description",
				name = DIM_RED_FONT_COLOR:WrapTextInColorCode(L["Experimental_Options_Warning"]),
				fontSize = "large",
			},
			importexport={
				name = L["Profile"].." "..L["Import"].."/"..L["Export"],
				type = "group",
				order = 1,
				args={

					Header = {
						order = 1,
						name = L["Profile"].." "..L["Import"].."/"..L["Export"],
						type = "header",
					},

					Instructions = {
						order = 2,
						name = L["ImportExport_Desc"],
						type = "description",
						fontSize = "medium",
					},

					TextBox = {
						order = 3,
						name = L["Import or Export the current profile:"],
						desc = DIM_RED_FONT_COLOR:WrapTextInColorCode(L["ImportExport_WarningDesc"]),
						type = "input",
						multiline = 22,
						confirm = function() return L["ImportWarning"] end,
						validate = false,
						set = function(self, input) Photon:SetSerializedAndCompressedProfile(input) end,
						get = function() return Photon:GetSerializedAndCompressedProfile() end,
						width = "full",
					},
				},
			},
		},
	}
end

local function guiOptions()
	local DB = Photon.db.profile
	local changes = CopyTable(DB.blizzBars)
	local args = {
		RevertButton = {
			order = 3,
			name = L["Revert"],
			type = "execute",
			width = "half",
			disabled = function()
				return tCompare(DB.blizzBars, changes)
			end,
			func = function()
				changes = CopyTable(DB.blizzBars)
			end
		},
		ApplyButton = {
			order = 4,
			name = L["Apply"],
			desc = L["ReloadUI"],
			type = "execute",
			confirm = true,
			width = "half",
			disabled = function()
				return tCompare(DB.blizzBars, changes)
			end,
			func = function()
				Photon:ToggleBlizzUI(changes)
				ReloadUI()
			end
		},
	}
	for bar, _ in pairs(changes) do
		--skip bars that aren't registered on this client, like the vehicle exit bar on Forever
		if Photon.registeredBarData[bar] then
		args[bar] = {
			order = 2,
			name = Photon.registeredBarData[bar].barLabel,
			desc = L["Shows / Hides the Default Blizzard UI"],
			type = "toggle",
			set = function(_, value)
				changes[bar] = value
			end,
			get = function()
				return changes[bar]
			end,
			width = "full",
		}
		end
	end

	--the editors work over the game, so the settings window closes
	local function openEditor(open)
		return function()
			if InCombatLockdown() then
				return
			end
			SettingsPanel:Hide()
			open(PhotonGUI)
		end
	end
	args.BarConfig = {
		order = -2,
		name = L["Bar Config"],
		type = "execute",
		disabled = InCombatLockdown,
		func = openEditor(PhotonGUI.OpenBarConfig),
	}
	args.ButtonEditor = {
		order = -1,
		name = L["Button Editor"],
		type = "execute",
		disabled = InCombatLockdown,
		func = openEditor(PhotonGUI.OpenButtonEditor),
	}

	args.PhotonMinimapButton = {
		order = 0,
		name = L["Display Minimap Button"],
		desc = L["Toggles the minimap button."],
		type = "toggle",
		set =  function() Photon:Minimap_ToggleIcon() end,
		get = function() return not DB.PhotonIcon.hide end,
		width = "full"
	}
	args.PhotonOverrides = {
		name = L["Display the Blizzard UI"],
		desc = L["Shows / Hides the Default Blizzard UI"],
		type = "header",
		order = 1,
	}
	return {
		name = L["Options"],
		type = "group",
		order = 0,
		args=args
	}
end

-----------------------------------------------------------------------------
--------------------------Panels---------------------------------------------
-----------------------------------------------------------------------------
--the option tables above, drawn with the bar editor's controls in boxes

--AceConfig members that are text as a string, a string anywhere else names a method of the handler
local LITERAL = {name = true, desc = true, width = true, usage = true}
--taken from the groups above when the option has none
local INHERITED = {get = true, set = true, func = true, confirm = true, validate = true, disabled = true, hidden = true}
--AceConfig's widths, in normal widths
local WIDTHS = {half = 0.5, normal = 1, double = 2}
local NORMAL_WIDTH = 180
local CONTROL_TYPES = {toggle = true, select = true, input = true, range = true, execute = true, header = true, description = true, color = true}

---an AceConfig option as the controls take it, every member a value or a function.
---groups are the groups it is in from the top, path the keys down to it
local function adapt(groups, path, option, refresh)
	local handler
	for _, group in ipairs(groups) do
		handler = group.handler or handler
	end
	local info = {options = groups[1], option = option, arg = option.arg, handler = handler, type = option.type, uiType = "dialog", uiName = addonName}
	for i, key in ipairs(path) do
		info[i] = key
	end

	local function member(field, ...)
		local value = option[field]
		if value == nil and INHERITED[field] then
			for i = #groups, 1, -1 do
				if groups[i][field] ~= nil then
					value = groups[i][field]
					break
				end
			end
		end
		if type(value) == "function" then
			return value(info, ...)
		elseif type(value) == "string" and not LITERAL[field] then
			return handler[value](handler, info, ...)
		end
		return value
	end

	--runs after a yes when the option asks for one
	local function confirmed(run, ...)
		local confirm = member("confirm", ...)
		if not confirm then
			run()
			return
		end
		local text = type(confirm) == "string" and confirm or option.confirmText
		if not text then
			local desc = member("desc")
			text = member("name")..(desc and " - "..desc or "")
		end
		StaticPopup_Show("NEURON_BARCONFIG_CONFIRM", text, nil, function()
			run()
			refresh()
		end)
	end

	return {
		type = option.type,
		width = option.width,
		multiline = option.multiline,
		min = option.min,
		max = option.max,
		step = option.step,
		softMax = option.softMax,
		isPercent = option.isPercent,
		sorting = member("sorting"),
		hidden = member("hidden") or option.guiHidden or option.dialogHidden,
		name = function() return member("name") end,
		desc = function() return member("desc") end,
		disabled = function() return member("disabled") end,
		values = function() return member("values") end,
		get = function() return member("get") end,
		set = function(_, ...)
			local count, values = select("#", ...), {...}
			local valid = member("validate", ...)
			if valid == false or type(valid) == "string" then
				UIErrorsFrame:AddMessage(type(valid) == "string" and valid or option.usage or ERROR_CAPS, 1, 0.1, 0.1)
				return
			end
			confirmed(function()
				member("set", unpack(values, 1, count))
			end, ...)
		end,
		func = function()
			confirmed(function()
				member("func")
			end)
		end,
	}
end

--a multiline input: its text, set with Accept
local function createMultiline(parent, lines)
	local control = CreateFrame("Frame", nil, parent)
	control.label = UI.Text(control)
	control.label:SetPoint("TOPLEFT")
	control.label:SetPoint("TOPRIGHT")
	control.box = UI.MultiLineEditBox(control, lines)
	control.box:SetPoint("TOPLEFT", control.label, "BOTTOMLEFT", 0, -3)
	control.box:SetPoint("TOPRIGHT", control.label, "BOTTOMRIGHT", 0, -3)
	control.accept = UI.Button(control, ACCEPT, function()
		control.option.set({}, control.box:GetText())
		control.changed()
	end)
	control.accept:SetPoint("TOPLEFT", control.box, "BOTTOMLEFT", 0, -Style.gap)

	function control:Bind(option)
		self.label:SetText(option.name() or "")
		self.box:SetText(option.get() or "")
		self.accept:SetEnabled(not option.disabled())
	end

	function control:Measure()
		return self.label:GetStringHeight() + 3 + self.box:GetHeight() + Style.gap + Style.rowHeight
	end

	return control
end

local function sortedKeys(group)
	local keys = {}
	for key in pairs(group.args or {}) do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		local orderA, orderB = group.args[a].order or 100, group.args[b].order or 100
		if orderA == orderB then
			return tostring(a) < tostring(b)
		end
		return orderA < orderB
	end)
	return keys
end

---a settings panel drawing an AceConfig group, its groups inside each in a box of their own
local function createPanel(options)
	local panel = CreateFrame("Frame")
	panel:Hide()
	local scroll = UI.ScrollArea(panel)
	scroll:SetPoint("TOPLEFT", 10, -10)
	scroll:SetPoint("BOTTOMRIGHT", -10, 10)

	local boxPool = UI.Pool(function()
		return UI.Box(scroll.child)
	end)
	local pools = {}
	local render, renderPending

	local function refresh()
		if renderPending then
			return
		end
		renderPending = true
		C_Timer.After(0, function()
			renderPending = false
			if panel:IsShown() then
				render()
			end
		end)
	end

	local function acquire(kind, option)
		local lines = kind == "multiline" and (tonumber(option.multiline) or 4)
		local key = lines and kind..lines or kind
		pools[key] = pools[key] or UI.Pool(function()
			return lines and createMultiline(scroll.child, lines) or PhotonGUI.CreateOptionControl(kind, scroll.child)
		end)
		local control = pools[key]:Acquire()
		control.changed = refresh
		control.option = option
		control:Bind(option)
		return control
	end

	function render()
		for _, pool in pairs(pools) do
			pool:ReleaseAll()
		end
		boxPool:ReleaseAll()

		local width = scroll:GetContentWidth()
		local y = 0

		local function addBox(group, groups, path)
			local box = boxPool:Acquire()
			box.title:SetText(group.name or "")
			local left = box.edge + Style.padding
			local inner = width - 2 * left
			local top = box.edge + Style.stripHeight + Style.padding
			groups = {unpack(groups)}
			table.insert(groups, group)

			--a line's settings share its bottom, like the bar editor's
			local line, lineWidth = {}, 0
			local function endLine()
				local height = 0
				for _, control in ipairs(line) do
					height = math.max(height, control.height)
				end
				for _, control in ipairs(line) do
					control:SetPoint("TOPLEFT", box, "TOPLEFT", left + control.x, -(top + height - control.height))
				end
				if #line > 0 then
					top = top + height + Style.gap
				end
				line, lineWidth = {}, 0
			end

			local inside = {}
			for _, key in ipairs(sortedKeys(group)) do
				local option = group.args[key]
				local optionPath = {unpack(path)}
				table.insert(optionPath, key)

				if option.type == "group" then
					table.insert(inside, {option, optionPath})
				elseif CONTROL_TYPES[option.type] then
					local adapted = adapt(groups, optionPath, option, refresh)
					if not adapted.hidden then
						local kind = option.type == "input" and option.multiline and "multiline" or option.type
						local full = option.width == "full" or kind == "description" or kind == "header" or kind == "multiline"
						local controlWidth = full and inner or math.min(inner, NORMAL_WIDTH * (tonumber(option.width) or WIDTHS[option.width] or 1))
						if full or lineWidth + controlWidth > inner then
							endLine()
						end

						local control = acquire(kind, adapted)
						control:SetParent(box)
						control:SetWidth(controlWidth)
						control.height = control:Measure(controlWidth)
						control:SetHeight(control.height)
						control.x = lineWidth
						table.insert(line, control)
						lineWidth = lineWidth + controlWidth + Style.gap
						if full then
							endLine()
						end
					end
				end
			end
			endLine()

			box:SetPoint("TOPLEFT", 0, -y)
			box:SetWidth(width)
			box:SetHeight(top - Style.gap + Style.padding + box.edge)
			y = y + box:GetHeight() + Style.gap

			for _, sub in ipairs(inside) do
				addBox(sub[1], groups, sub[2])
			end
		end

		addBox(options, {}, {})
		scroll:SetContentHeight(y - Style.gap)
	end

	panel:SetScript("OnShow", render)
	scroll.OnResize = refresh
	--the settings window calls these on its panels
	panel.OnCommit = function() end
	panel.OnDefault = function() end
	panel.OnRefresh = refresh
	return panel
end

---This is the main entry point
function PhotonGUI:LoadInterfaceOptions()
	local category = Settings.RegisterCanvasLayoutCategory(createPanel(guiOptions()), addonName)
	Settings.RegisterAddOnCategory(category)
	--keep the category ID so Photon:ToggleMainMenu() can open the panel with Settings.OpenToCategory
	Photon.optionsCategoryID = category.ID

	for _, options in ipairs({profileOptions(), experimentalOptions()}) do
		Settings.RegisterCanvasLayoutSubcategory(category, createPanel(options), options.name)
	end
end
