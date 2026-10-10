-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...
local Photon = addonTable.Photon

local L = LibStub("AceLocale-3.0"):GetLocale("Photon")

function Photon.UpdateStanceStrings()
	-- these are the results of the visibility macro conditional in the MANAGED_SECONDARY_STATES table
	Photon.VISIBILITY_STATES = {
		paged1 = L["Page 1"],
		paged2 = L["Page 2"],
		paged3 = L["Page 3"],
		paged4 = L["Page 4"],
		paged5 = L["Page 5"],
		paged6 = L["Page 6"],
		pet0 = L["No Pet"],
		pet1 = L["Pet Exists"],
		alt0 = L["Alt Up"],
		alt1 = L["Alt Down"],
		ctrl0 = L["Control Up"],
		ctrl1 = L["Control Down"],
		shift0 = L["Shift Up"],
		shift1 = L["Shift Down"],
		stance0 = L["Default"],
		stealth0 = L["No Stealth"],
		stealth1 = L["Stealth"],
		reaction0 = L["Friendly"],
		reaction1 = L["Hostile"],
		combat0 = L["Out of Combat"],
		combat1 = L["In Combat"],
		group0 = L["No Group"],
		group1 = L["Group: Raid"],
		group2 = L["Group: Party"],
		dragonriding0 = L["No Dragon Riding"],
		dragonriding1 = L["Dragon Riding"],
		fishing0 = L["No Fishing Pole"],
		fishing1 = L["Fishing Pole"],
		vehicle0 = L["No Vehicle"],
		vehicle1 = L["Vehicle"],
		possess0 = L["No Possess"],
		possess1 = L["Possess"],
		override0 = L["No Override Bar"],
		override1 = L["Override Bar"],
		extrabar0 = L["No Extra Bar"],
		extrabar1 = L["Extra Bar"],
		indoors1 = L["Indoors"],
		outdoors1 = L["Outdoors"],
		mounted0 = L["Not Mounted"],
		mounted1 = L["Mounted"],
		help1 = L["Help"],
		harm1 = L["Harm"],
		target0 = L["No Target"],
		target1 = L["Has Target"],
		resting0 = L["Not Resting"],
		resting1 = L["Resting"],
		swimming0 = L["Not Swimming"],
		swimming1 = L["Swimming"],
	}
	Photon.STATES = {
		homestate = L["Home State"],
		laststate = L["Last State"],
		custom0 = L["Custom States"],
		-- the pet bar state uses pet2 for "pet exists", unlike the visibility pet1
		pet2 = L["Pet Exists"],
	}
	MergeTable(Photon.STATES, Photon.VISIBILITY_STATES)

	-- a secondary state's page, named the same in the button editor and the bar config
	MergeTable(Photon.STATES, {
		alt1 = L["Alt Pressed"],
		ctrl1 = L["Control Pressed"],
		shift1 = L["Shift Pressed"],
		help1 = L["Friendly Target"],
		harm1 = L["Hostile Target"],
		raid1 = L["Raid"],
		party1 = L["Party"],
	})


	--- this is actually a lot of classes. rogues stealth, paladins have
	--- devo aura, priests have shadowform, etc
	for i=1,GetNumShapeshiftForms() do
		local _, _, _, spellID = GetShapeshiftFormInfo(i)
		Photon.STATES["stance"..i] = C_Spell.GetSpellName(spellID) --Get the string name of the shapeshift form (now that shapeshifts are considered spells)
	end

	-- out of form is a page too, see Bar.FormsArePages
	if Photon.class == "DRUID" then
		Photon.STATES["stance0"] = L["No Form"]
	else
		Photon.STATES["stance0"] = L["No Stance"]
	end

	-- stealth shows up with the GetShapeshiftFormInfo, but not the others
	-- Melee is special cased just because that's the way it's been historically
	if Photon.class == "ROGUE" then
		Photon.STATES["stance0"] = L["Melee"]
		Photon.STATES["stance2"] = L["Vanish"]
		Photon.STATES["stance3"] = L["Shadow Dance"] --for Subelty Rogues
	end


	-- the "states" and "visibility" fields are macro conditionals. they will
	-- pass the result of the conditional as "message" into the attribute driver
	-- See "RegisterAttributeDriver" and "SetAttribute"
	-- example: if a priest is in shadowform (stance1) then
	-- "[stance0] noshadow; [stance1] shadow" will make message="shadow"
	Photon.MANAGED_HOME_STATES = {
		paged = {
			modifier = "paged",
			homestate = "paged1",
			states = "[bar:1] paged1; [bar:2] paged2; [bar:3] paged3; [bar:4] paged4; [bar:5] paged5; [bar:6] paged6",
			visibility = "[bar:1] paged1; [bar:2] paged2; [bar:3] paged3; [bar:4] paged4; [bar:5] paged5; [bar:6] paged6",
			rangeStart = 2,
			rangeStop = 6,
			localizedName = L["Paged"],
		},

		stance = {
			modifier = "stance",
			homestate = "stance0",
			-- the class with the maximum "stances" is the druid with 6. no need for more than this
			states = "[stance:0] stance0; [stance:1] stance1; [stance:2] stance2; [stance:3] stance3; [stance:4] stance4; [stance:5] stance5; [stance:6] stance6;",
			visibility = "[stance:0] stance0; [stance:1] stance1; [stance:2] stance2; [stance:3] stance3; [stance:4] stance4; [stance:5] stance5; [stance:6] stance6;",
			rangeStart = 1,
			rangeStop = 8,
			localizedName =
				(Photon.class == "ROGUE" and L["Stealth"]) or
				(Photon.class == "DRUID" and L["Shapeshift"]) or
				(Photon.class == "SHAMAN" and L["Shapeshift"]) or
				L["Stance"],
		},

		pet = {
			modifier = "pet",
			homestate = "pet1",
			states = "[nopet] pet1; [@pet,exists,nodead] pet2",
			visibility = "[vehicleui] pet0; [possessbar] pet0; [overridebar] pet0; [nopet] pet0; [pet] pet1",
			rangeStart = 2,
			rangeStop = 3,
			localizedName = L["Pet"],
		},
	}
	Photon.MANAGED_SECONDARY_STATES = {
		alt = {
			modifier = "alt",
			states = "[mod:alt] alt1; laststate",
			visibility = "[nomod:alt] alt0; [mod:alt] alt1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Alt"],
		},

		ctrl = {
			modifier = "ctrl",
			states = "[mod:ctrl] ctrl1; laststate",
			visibility = "[nomod:ctrl] ctrl0; [mod:ctrl] ctrl1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Ctrl"],
		},

		shift = {
			modifier = "shift",
			states = "[mod:shift] shift1; laststate",
			visibility = "[nomod:shift] shift0; [mod:shift] shift1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Shift"],
		},

		stealth = {
			modifier = "stealth",
			states = "[stealth] stealth1; laststate",
			visibility = "[nostealth] stealth0; [stealth] stealth1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Stealth"],
		},

		dragonriding = {
			modifier = "dragonriding",
			states = "[bonusbar:5,nopossessbar] dragonriding1; laststate",
			visibility = "[possessbar] dragonriding0; [nobonusbar:5] dragonriding0; [bonusbar:5] dragonriding1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Dragon Riding"],
		},

		vehicle = {
			modifier = "vehicle",
			states = "[vehicleui] vehicle1; laststate",
			visibility = "[novehicleui] vehicle0; [vehicleui] vehicle1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Vehicle"],
		},

		raid = {
			modifier = "raid",
			states = "[group:raid] raid1; laststate",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Raid"],
		},

		party = {
			modifier = "party",
			-- a raid is a party too, the raid state has that
			states = "[group:raid] laststate; [group:party] party1; laststate",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Party"],
		},

		fishing = {
			modifier = "fishing",
			states = "[worn:fishing poles] fishing1; laststate",
			visibility = "[noworn:fishing poles] fishing0; [worn:fishing poles] fishing1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Fishing"],
		},

		combat = {
			modifier = "combat",
			states = "[combat] combat1; laststate",
			visibility = "[nocombat] combat0; [combat] combat1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Combat"],
		},

		possess = {
			modifier = "possess",
			states = "[possessbar] possess1; laststate",
			visibility = "[nopossessbar] possess0; [possessbar] possess1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Possess"],
		},

		override = {
			modifier = "override",
			states = "[overridebar] override1; laststate",
			visibility = "[nooverridebar] override0; [overridebar] override1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Override"],
		},

		target = {
			modifier = "target",
			states = "[exists] target1; laststate",
			visibility = "[noexists] target0; [exists] target1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Target"],
		},
		indoors = {
			modifier = "indoors",
			states = "[indoors] indoors1; laststate",
			visibility = "[noindoors] indoors0; [indoors] indoors1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Indoors"],
		},
		outdoors = {
			modifier = "outdoors",
			states = "[outdoors] outdoors1; laststate",
			visibility = "[nooutdoors] outdoors0; [outdoors] outdoors1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Outdoors"],
		},
		mounted = {
			modifier = "mounted",
			states = "[mounted] mounted1; laststate",
			visibility = "[nomounted] mounted0; [mounted] mounted1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Mounted"],
		},
		help = {
			modifier = "help",
			states = "[help] help1; laststate",
			visibility = "[nohelp] help0; [help] help1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Help"],
		},
		harm = {
			modifier = "harm",
			states = "[harm] harm1; laststate",
			visibility = "[noharm] harm0; [harm] harm1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Harm"],
		},
		resting = {
			modifier = "resting",
			states = "[resting] resting1; laststate",
			visibility = "[noresting] resting0; [resting] resting1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Resting"],
		},
		swimming = {
			modifier = "swimming",
			states = "[swimming] swimming1; laststate",
			visibility = "[noswimming] swimming0; [swimming] swimming1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Swimming"],
		},
	}

	Photon.MANAGED_OTHER_STATES = {
		custom = {
			modifier = "custom",
			states = "",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Custom"],
		},

		extrabar = {
			modifier = "extrabar",
			states = "[extrabar] extrabar1; laststate",
			visibility = "[noextrabar] extrabar0; [extrabar] extrabar1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Extrabar"],
		},

		-- only for hiding the bar now, split into raid and party for pages
		group = {
			modifier = "group",
			states = "[group:raid] group1; [group:party] group2; laststate",
			visibility = "[nogroup] group0; [group:raid] group1; [group:party] group2",
			rangeStart = 1,
			rangeStop = 2,
			localizedName = L["Group"],
		},

		-- only for hiding the bar now, harm is the same page
		reaction = {
			modifier = "reaction",
			states = "[@target,harm] reaction1; laststate",
			visibility = "[@target,help] reaction0; [@target,harm] reaction1",
			rangeStart = 1,
			rangeStop = 1,
			localizedName = L["Reaction"],
		},
	}

	--Forever has no vehicles or dragonriding or extra bars
	if Photon.isWoWForever then
		Photon.MANAGED_SECONDARY_STATES.dragonriding = nil
		Photon.VISIBILITY_STATES.dragonriding0 = nil
		Photon.VISIBILITY_STATES.dragonriding1 = nil
		Photon.STATES.dragonriding0 = nil
		Photon.STATES.dragonriding1 = nil
		Photon.MANAGED_SECONDARY_STATES.vehicle = nil
		Photon.VISIBILITY_STATES.vehicle0 = nil
		Photon.VISIBILITY_STATES.vehicle1 = nil
		Photon.STATES.vehicle0 = nil
		Photon.STATES.vehicle1 = nil
		Photon.MANAGED_OTHER_STATES.extrabar = nil
		Photon.VISIBILITY_STATES.extrabar0 = nil
		Photon.VISIBILITY_STATES.extrabar1 = nil
		Photon.STATES.extrabar0 = nil
		Photon.STATES.extrabar1 = nil
	end

	Photon.MANAGED_BAR_STATES = {}
	MergeTable(Photon.MANAGED_BAR_STATES, Photon.MANAGED_HOME_STATES)
	MergeTable(Photon.MANAGED_BAR_STATES, Photon.MANAGED_SECONDARY_STATES)
	MergeTable(Photon.MANAGED_BAR_STATES, Photon.MANAGED_OTHER_STATES)
end
