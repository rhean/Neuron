-- Neuron is a World of Warcraft® user interface addon.
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- Copyright (c) 2026 Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Neuron = addonTable.Neuron

local L = LibStub("AceLocale-3.0"):GetLocale("Neuron")
local Array = addonTable.utilities.Array

-- reading a missing key makes AceDB fill in its defaults, so the '*' and '**' wildcards keep working.
local function mergeIntoDB(dest, src)
	for k, v in pairs(src) do
		if type(v) == "table" and type(dest[k]) == "table" then
			mergeIntoDB(dest[k], v)
		else
			dest[k] = v
		end
	end
end

--- this function has no business existing
--- database defaults should be in the database
--- but we have them scattered between neuron-defaults and neuron-db-defaults
function Neuron:InitializeEmptyDatabase(DB)
	DB.firstRun = false

	--initialize default bars using the skeleton data in defaultProfile
	--and pulling from registeredBarData
	for barClass, registeredData in pairs(Neuron.registeredBarData) do
		mergeIntoDB(registeredData.barDB, addonTable.defaultProfile[barClass] or {})
	end
end

function Neuron:CreateBarsAndButtons(profileData)
	-- remove blizzard controlled bars from the list of bars we will create
	-- but still keep neuron action bars regardless
	local neuronBars =
		Array.filter(
			function (barPair)
				local bar, _ = unpack(barPair)
			  return not profileData.blizzBars[bar] or bar == "ActionBar"
			end,
		Array.fromIterator(pairs(Neuron.registeredBarData)))

	-- make the frames for the bars now
	for _, barData in pairs (neuronBars) do
		local barClass, barClassData = unpack(barData)
		for id,data in pairs(barClassData.barDB) do
			if data ~= nil then
				local newBar = Neuron.Bar.new(barClass, id) --this calls the bar constructor

				--create all the saved button objects for a given bar
				for buttonID=1,#newBar.data.buttons do
					newBar.objTemplate.new(newBar, buttonID) --newBar.objTemplate is something like ActionButton or ExtraButton, we just need to code it agnostic
				end
			end
		end
	end
end
