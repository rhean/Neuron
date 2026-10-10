-- Photon is a World of Warcraft® user interface addon.
-- Copyright (c) 2026- Linus Olsson
-- Copyright (c) 2017-2023 Britt W. Yazel
-- Copyright (c) 2006-2014 Connor H. Chenoweth
-- This code is licensed under the MIT license (see LICENSE for details)

local L = LibStub("AceLocale-3.0"):NewLocale("Photon", "enUS", true)

if not L then return end

L["General Options"] = true
L["Size and Shape"] = true
L["Visuals"] = true


L["Command List"] = true

L["Menu"] = true
L["Menu_Description"] = "Open the main menu"

L["Create"] = true
L["Create_Description"] = "Create a blank bar of the given type"

L["Select"] = true
L["Select_Description"] = "Switch the currently selected bar"

L["Delete"] = true
L["Delete_Description"] = "Delete the currently selected bar"

L["Config"] = true
L["Config_Description"] = "Toggle configuration mode for all bars"

L["Add"] = true
L["Add_Description"] = "Adds buttons to the currently selected bar"

L["Remove"] = true
L["Remove_Description"] = "Removes buttons from the currently selected bar"

L["Edit"] = true
L["Edit_Description"] = "Toggle edit mode for all buttons"

L["Bind"] = true
L["Bind_Description"] = "Toggle binding mode for all buttons"

L["Scale"] = true
L["Scale_Description"] = "Scale a bar to the desired size"

L["SnapTo"] = true
L["SnapTo_Description"] = "Toggle SnapTo for current bar"

L["AutoHide"] = true
L["AutoHide_Description"] = "Toggle AutoHide for current bar"

L["Conceal"] = true
L["Conceal_Description"] = "Toggle if current bar is shown or concealed at all times"

L["Shape"] = true
L["Shape_Description"] = "Change current bar's shape"

L["Name"] = true
L["Name_Description"] = "Change current bar's name"

L["Strata"] = true
L["Strata_Description"] = "Change current bar's frame strata"

L["Alpha"] = true
L["Alpha_Description"] = "Change current bar's alpha (transparency)"

L["AlphaUp"] = true
L["AlphaUp_Description"] = "Set current bar's conditions to 'alpha up'"

L["ArcStart"] = true
L["ArcStart_Description"] = "Set current bar's starting arc location (in degrees)"

L["ArcLen"] = true
L["ArcLen_Description"] = "Set current bar's arc length (in degrees)"

L["Columns"] = true
L["Columns_Description"] = "Set the number of columns for the current bar (for shape Multi-Column)"

L["PadH"] = true
L["PadH_Description"] = "Set current bar's horizontal padding"

L["PadV"] = true
L["PadV_Description"] = "Set current bar's vertical padding"

L["PadHV"] = true
L["PadHV_Description"] = "Adjust both horizontal and vertical padding of the current bar incrementally"

L["X"] = true
L["X_Description"] = "Change current bar's horizontal axis position"

L["Y"] = true
L["Y_Description"] = "Change current bar's vertical axis position"

L["State"] = true
L["State_Description"] = "Toggle an action state for the current bar"

L["Vis"] = true
L["Vis_Description"] = "Toggle visibility states for the current bar"

L["ShowGrid"] = true
L["ShowGrid_Description"] = "Toggle the current bar's showgrid flag"

L["Lock"] = true
L["Lock_Description"] = "Toggle bar lock."

L["Tooltips"] = true
L["Tooltips_Description"] = "Toggle tooltips for the current bar's action buttons"

L["SpellGlow"] = true
L["SpellGlow_Description"] = "Toggle spell activation animations on the current bar"

L["BindText"] = true
L["BindText_Description"] = "Toggle keybind text on the current bar"

L["MacroText"] = true
L["MacroText_Description"] = "Toggle macro name text on the current bar"

L["CountText"] = true
L["CountText_Description"] = "Toggle spell/item count text on the current bar"

L["CDText"] = true
L["CDText_Description"] = "Toggle cooldown counts text on the current bar"

L["CDAlpha"] = true
L["CDAlpha_Description"] = "Toggle a button's transparancy while on cooldown"

L["UpClick"] = true
L["UpClick_Description"] = "Toggle if buttons on the current bar respond to up clicks"

L["DownClick"] = true
L["DownClick_Description"] = "Toggle if buttons on the current bar respond to down clicks"

L["TimerLimit"] = true
L["TimerLimit_Description"] = "Sets the minimum time in seconds to begin showing text timers"

L["StateList"] = true
L["StateList_Description"] = "Print a list of valid states"

L["BarTypes"] = true
L["BarTypes_Description"] = "Print a list of available bar types to make"

L["BlizzUI"] = true
L["BlizzUI_Description"] = "Toggle Blizzard's DefaultUI"

L["MoveSpecButtons"] = true
L["MoveSpecButtons_Description"] = "Copies the buttons from one spec to a second"



-----------------------------------------------
------------------General----------------------
-----------------------------------------------

L["How to use"] = true
L["Command"] = true
L["Option"] = true

L["No bar selected or command invalid"] = true

L["Custom_Option"] = "For custom states, add a desired state string (/photon state custom <state string>) where <state string> is a semicolon seperated list of state conditions"



L["Low"] = true
L["Medium"] = true
L["High"] = true
L["Dialog"] = true
L["Tooltip"] = true

L["Valid States"]=true
L["Invalid index"] = true


L["Hide"] = true
L["Show"] = true

L["Home State"] = true
L["Last State"] = true

L["Auto-Hide"] = true


L["Paged"] = true
L["Stance"] = true
L["Pet"] = true
L["Alt"] = true
L["Ctrl"] = true
L["Shift"] = true
L["Stealth"] = true
L["Reaction"] = true
L["Combat"]  = true
L["Group"] = true
L["Fishing"] = true
L["Vehicle"] = true
L["Custom"] = true
L["Possess"] = true
L["Override"] = true
L["Extrabar"] = true


L["Page 1"] = true
L["Page 2"] = true
L["Page 3"] = true
L["Page 4"] = true
L["Page 5"] = true
L["Page 6"] = true


L["No Pet"] = true
L["Pet Exists"] = true

L["Alt Up"] = true
L["Alt Down"] = true
L["Control Up"] = true
L["Control Down"] = true
L["Shift Up"] = true
L["Shift Down"] = true
L["Alt Pressed"] = true
L["Control Pressed"] = true
L["Shift Pressed"] = true
L["Friendly Target"] = true
L["Hostile Target"] = true
L["Raid"] = true
L["Party"] = true

L["Vanish"] = true
L["Shapeshift"] = true
L["No Stealth"] = true
L["Friendly"] = true
L["Hostile"] = true
L["Out of Combat"] = true
L["In Combat"] = true

L["No Group"] = true
L["Group: Raid"] = true
L["Group: Party"] = true
L["No Fishing Pole"] = true
L["Fishing Pole"] = true

L["No Dragon Riding"] = true
L["Dragon Riding"] = true
L["No Vehicle"] = true
L["Vehicle"] = true
L["No Possess"] = true
L["Possess"] = true
L["No Override Bar"] = true
L["Override Bar"] = true
L["No Extra Bar"] = true
L["Extra Bar"] = true

L["Vehicle Exit Bar"] = true

L["Custom States"] = true


---class specific state names
L["Caster Form"] = true
L["No Form"] = true
L["No Stance"] = true
L["Healer Form"] = true
L["Melee"] = true
L["Shadow Dance"] = true


L["Left-Click"] = true
L["Right-Click"] = true

L["Configure Bars"] = true
L["Configure Buttons"] = true
L["Configure Buttons"] = true
L["Configure Appearance"] = true

---button editor window
L["Bar Config"] = true
L["Button Editor"] = true
L["Specialization"] = true
L["Modifiers"] = true
L["ButtonEditor_Location"] = "Button %d - Row %d"
L["ButtonEditor_Button"] = "Button %d"
L["Add Modifier"] = true
L["Remove Modifier"] = true
L["ButtonEditor_RemoveModifier"] = "Removing the modifier removes it from the whole bar and deletes its contents."
L["ButtonEditor_RowOfSpec"] = "row %d of %s"
L["ButtonEditor_Status"] = "|cffffd200%s|r|cFFFFFFFF button %d is selected. Click another button to edit it."
L["ButtonEditor_SelectButton"] = "Click an action button to edit it."
L["ButtonEditor_Inherits"] = "No macro of its own, this page uses %s. Type a macro to give it one."
L["ButtonEditor_Empty"] = "No macro yet. Type one below."

L["Toggle Keybind Mode"] = true
L["Open the Interface Menu"] = true


L["Keybind_Tooltip_1"] = "Press a key to bind it to"
L["Keybind_Tooltip_2"] = "Current Binding(s)"
L["Keybind_Tooltip_3"] = "Left-Click to lock the current binding(s)"
L["Keybind_Tooltip_4"] = "Right-Click to give these bindings maximum priority"
L["Keybind_Tooltip_5"] = "Hit ESC to clear the current binding(s)"

L["Empty Button"] = true
L["Edit Bindings"] = true
L["None"] = true

L["Locked"] = true
L["Priority"] = true
L["Bindings_Locked_Notice"]	= "This button's bindings are locked.\nLeft-Click button to unlock."

L["Off"] = true
L["Combat"] = true
L["Mouseover"] = true
L["Combat + Mouseover"] = true

L["Bar_Shapes_List"] = "\n1=Linear\n2=Circle\n3=Circle + One"
L["Linear"] = true
L["Circle"] = true
L["Circle + One"] = true
L["Bar_Strata_List"] = "\n1=BACKGROUND\n2=LOW\n3=MEDIUM\n4=HIGH\n5=DIALOG"
L["Bar_Alpha_Instructions"] = "Alpha value must be between zero(0) and one(1)"
L["Bar_ArcStart_Instructions"] = "Arc start must be between 0 and 359"
L["Bar_ArcLength_Instructions"] = "Arc length must be between 0 and 359"
L["Bar_Column_Instructions"] = "Enter a number of desired columns for the bar higher than zero(0)\nOmit number to turn off columns"
L["Horozontal_Padding_Instructions"] = "Enter a valid number for desired horizontal button padding"
L["Vertical_Padding_Instructions"] = "Enter a valid number for desired vertical button padding"
L["Horozontal_and_Vertical_Padding_Instructions"] = "Enter a valid number to increase/decrease both the horizontal and vertical button padding"
L["X_Position_Instructions"] = "Enter a valid number for desired x position offset"
L["Y_Position_Instructions"] = "Enter a valid number for desired y position offset"

L["Bar_Lock_Modifier_Instructions"] = "Valid mod keys:\n\nalt: unlock bar when the <alt> key is down\nctrl: unlock bar when the <ctrl> key is down\nshift: unlock bar when the <shift> key is down"
L["Tooltip_Instructions"] = "Valid options:\n\nenhanced: display additional ability info\ncombat: hide/show tooltips while in combat"
L["Spellglow_Instructions"] = "Valid options:\n\ndefault: use Blizzard default spell glow animation\nalt: use alternate subdued spell glow animation"

L["Timer_Limit_Set_Message"] = "Timer limit set to %d seconds"
L["Timer_Limit_Invalid_Message"] = "Invalid timer limit"

L["DragDrop_Error_Message"] = "Sorry, we were unable to place that ability or item."
L["DragDrop_Inherited_Message"] = "This button inherits its ability from another page. You can override it in the button editor"


L["Attack"] = true
L["Follow"] = true
L["Move To"] = true
L["Assist"] = true
L["Defensive"] = true
L["Passive"] = true


L["Apply"] = true
L["Cancel"] = true
L["Done"] = true
L["Create New Bar"] = true
L["Delete Current Bar"] = true
L["Select Bar Type"] = true
L["Confirm"] = true
L["Yes"] = true
L["No"] = true
L["General Options"] = true
L["Bar States"] = true
L["Object Editor"] = true
L["Macro Data"] = true
L["Action Data"] = true
L["Options"] = true
L["Revert"] = true
L["ReloadUI"] = "This action will cause the UI to reload."

L["Click here to edit macro note"] = true
L["Use macro note as button tooltip"] = true

L["Count"] = true
L["Search"] = true
L["Custom Icon"] = true
L["Path"] = true

L["Show Grid"] = true
L["Hidden"] = true
L["Click Mode"] = true
L["On Click"] = true
L["On Release"] = true
L["Multi Spec"] = true
L["Dual Spec"] = true

-- New for the updated GUI
L["Color"] = true
L["Delete Bar"] = true
L["DeleteBar_Confirm"] = "Warning, will permanently delete the bar and all stored data"
L["General Configuration"] = true
L["Bar Visibility"] = true
L["Secondary States"] = true
L["Text"] = true
L["Dangerous"] = true

L["Spec 1"] = true
L["Spec 2"] = true
L["No Spec"] = true
L["Spell Alerts"] = true
L["Default Alert"] = true
L["Subdued Alert"] = true
L["Lock Actions"] = true
L["Unlock on SHIFT"] = true
L["Unlock on CTRL"] = true
L["Unlock on ALT"] = true
L["Enable Tooltips"] = true
L["Normal"] = true
L["Minimal"] = true
L["Tooltips in Combat"] = true
L["Show Border Style"] = true

L["Preset Action States"] = true
L["Custom Action States"] = true


L["Select a stance to remap:"] = true
L["Remap selected stance to:"] = true


L["Scale"] = true
L["Alpha"] = true
L["AlphaUp Speed"] = true
L["Strata"] = true
L["Shape"] = true
L["Horizontal Padding"] = true
L["Vertical Padding"] = true
L["Columns"] = true
L["Arc Start"] = true
L["Arc Length"] = true

L["Keybind Label"] = true
L["Keybind Label Color"] = true
L["Button Name"] = true
L["Stack/Charge"] = true
L["Out-of-Range"] = true
L["CD Counter"] = true
L["Cooldown Alpha"] = true

L["Point"] = true
L["X Position"] = true
L["Y Position"] = true

L["Display the Blizzard UI"] = true
L["Shows / Hides the Default Blizzard UI"] = true

L["Display Minimap Button"] = true
L["Toggles the minimap button."] = true

L["Bar Visibility Toggles"] = true
L["Target"] = true
L["Has Target"] = true
L["No Target"] = true
L["Indoors"] = true
L["Outdoors"] = true
L["Mounted"] = true
L["Flying"] = true
L["Resting"] = true
L["Swimming"] = true
L["Harm"] = true
L["Help"] = true
L["Not Mounted"] = true
L["Not Resting"] = true
L["Not Swimming"] = true
L["Display button for specialization 1"] = true
L["Display button for specialization 2"] = true
L["Display button for specialization 3"] = true
L["Display button for specialization 4"] = true


L["Spell Target Options"] = true

L["Self-Cast by modifier"] = true
L["Toggle the use of the modifier-based self-cast functionality."] = true
L["Select the Self-Cast Modifier"] = true

L["Focus-Cast by modifier"] = true
L["Toggle the use of the modifier-based focus-cast functionality."] = true
L["Select the Focus-Cast Modifier"] = true

L["Right-click Self-Cast"] = true
L["Toggle the use of the right-click self-cast functionality."] = true

L["Mouse-Over Casting"] = true
L["Toggle the use of the modifier-based mouse-over cast functionality."] = true
L["Select a modifier for Mouse-Over Casting"] = true
L["Mouse-Over Casting Modifier"] = true

L["Select the Self-Cast Modifier"] = true

L["Spell_Targeting_Modifier_None_Reminder"] = "\"None\" as modifier for Self & Focus Casting means its disabled. \nFor Mouse-Over Casting it means its always active, and no modifier is required."

L["Action Bar"] = true
L["Zone Action Bar"] = true
L["Stance Bar"] = true
L["Extra Action Bar"] = true
L["Bag Bar"] = true
L["Pet Bar"] = true
L["Menu Bar"] = true
L["XP Bar"] = true
L["Rep Bar"] = true
L["Cast Bar"] = true
L["Mirror Bar"] = true

L["Track Character XP"] = true
L["Track Covenant Renown"] = true
L["Track Azerite Power"] = true
L["Track Honor Points"] = true

L["Width"] = true
L["Height"] = true
L["Bar Fill"] = true
L["Border"] = true
L["Orientation"] = true

L["Center Text"] = true
L["Left Text"] = true
L["Right Text"] = true
L["Mouseover Text"] = true
L["Tooltip Text"] = true

L["Unit"] = true
L["Cast Icon"] = true

L["Spell"] = true
L["Timer"] = true
L["Current/Next"] = true
L["Rested Levels"] = true
L["Percent"] = true
L["Bubbles"] = true
L["Faction"] = true
L["Current Level/Rank"] = true
L["Type"] = true
L["Levels"] = true
L["Level"] = true
L["Points"] = true
L["Prestige"] = true


L["Auto Select"] = true

L["Default"] = true
L["Contrast"] = true
L["Carpaint"] = true
L["Gel"] = true
L["Glassed"] = true
L["Soft"] = true
L["Velvet"] = true

L["Tooltip"] = true
L["Slider"] = true
L["Dialog"] = true

L["Horizontal"] = true
L["Vertical"] = true

L["Buttons"] = true

L["Reward"] = true
L["Close"] = true
L["Select an Option"] = true

L["Item"] = true
L["Spell"] = true
L["Mount"] = true
L["Companion"] = true
L["Profession"] = true
L["Fun"] = true
L["Favorite"] = true
L["Keys"] = true
L["Attach Point"] = true
L["Relative To"] = true
L["Radius"] = true
L["Show On"] = true
L["Save"] = true
L["Output"] = true
L["Flyout Options"] = true

L["Left"] = true
L["Right"] = true
L["Top"] = true
L["Bottom"] = true
L["Top-Left"] = true
L["Top-Right"] = true
L["Bottom-Left"] = true
L["Bottom-Right"] = true
L["Center"] = true

L["Click"] = true
L["Generate Macro"] = true
L["Copy and Paste the text below"] = true

L["Pet Actions can not be added to Photon bars at this time."] = true


L["Profile"] = true
L["Import"] = true
L["Export"] = true
L["Import or Export the current profile:"] = true
L["ImportExport_Desc"] = [[

Below you will find a text representation of your Photon profile.

To export this profile, select and copy all of the text below and paste it somewhere safe.

To import a profile, replace all of the text below with the text from a previously exported profile.

]]
L["ImportExport_WarningDesc"] = [[

Copying and pasting profile data can be a time consuming experience. It may stall your game for multiple seconds.

WARNING: This will overwrite the current profile, and any changes you have made will be lost.
]]
L["ImportWarning"] = "Are you absolutely certain you wish to import this profile? The current profile will be overwritten."
L["No data to import."] = true
L["Decoding failed."] = true
L["Decompression failed."] = true
L["Data import Failed."] = true
L["Aborting."] = true

L["Experimental"] = true
L["Experimental Options"] = true
L["Experimental_Options_Warning"] = [[

Warning:

Here you will fill find experimental and potentially dangerous options.

Use at your own risk.

]]


-----------------------------------------------
---------------Bar Settings Tooltips-----------
-----------------------------------------------
-- the hover text for each setting in the bar editor, keyed BarDesc_<setting id> (see GUI/Options.lua)
-- {form} becomes the class's word for what is on its stance bar, stance for the classes not listed
L["BarDesc_FormWord"] = "form" --druid, priest
L["BarDesc_AuraWord"] = "aura" --paladin
L["BarDesc_StealthWord"] = "stealth" --rogue
L["BarDesc_PresenceWord"] = "presence" --death knight
L["BarDesc_StanceWord"] = "stance" --warrior, monk and the rest

-- General Configuration
L["BarDesc_deleteBar"] = "Permanently deletes this bar and all the buttons on it."

-- Enabled Functions
L["BarDesc_multiSpec"] = "Gives the bar a page for each specialization."
L["BarDesc_pages"] = "Gives the bar a page for each of the base games pages."
L["BarDesc_state_stance"] = "Gives the bar a page for each {form}."
L["BarDesc_state_pet"] = "Gives the bar a page for when you have a pet out."

-- General Options
L["BarDesc_autoHide"] = "Fades the bar out until you move the mouse over it."
L["BarDesc_hidden"] = "Hides the bar completely. It still shows while editing bars."
L["BarDesc_showGrid"] = "Shows the outline of empty buttons."
L["BarDesc_lockActions"] = "Locks the buttons so abilities can't be dragged on or off them, pick a key to unlock them."
L["BarDesc_clickMode"] = "Whether a button fires when the mouse button is pressed down or when it is released."

-- Size and Shape
L["BarDesc_numButtons"] = "How many buttons the bar has."
L["BarDesc_columns"] = "How many buttons per row."
L["BarDesc_scale"] = "The size of the bar and its buttons."
L["BarDesc_horizontalPadding"] = "The space between buttons side by side."
L["BarDesc_verticalPadding"] = "The space between rows of buttons."
L["BarDesc_shape"] = "How the buttons are laid out."
L["BarDesc_alpha"] = "How transparent the bar is normally."
L["BarDesc_alphaUp"] = "When the bar becomes fully visible: on mouseover, in combat, or both."
L["BarDesc_alphaUpSpeed"] = "How fast the bar fades in and out."
L["BarDesc_strata"] = "Which layer the bar is drawn on."

-- Visuals
L["BarDesc_keybindLabel"] = "Shows the key bound to each button."
L["BarDesc_buttonName"] = "Shows the macro name on each button."
L["BarDesc_stackCharge"] = "Shows item stack counts and ability charges on each button."
L["BarDesc_outOfRange"] = "Tints the button when your target is out of range."
L["BarDesc_cooldownCounter"] = "Shows the time left on cooldowns as numbers on the button."
L["BarDesc_cooldownColor1"] = "The color of the cooldown counter."
L["BarDesc_cooldownColor2"] = "The color of the cooldown counter in the last 5 seconds."
L["BarDesc_cooldownAlpha"] = "Fades the button while its ability is on cooldown."
L["BarDesc_tooltips"] = "Which tooltip to show when hovering a button: none, a short, or the full tooltip."
L["BarDesc_tooltipsInCombat"] = "Also shows button tooltips while you are in combat."
L["BarDesc_spellAlerts"] = "The glow shown on a button when its ability procs or is highlighted by the game."
L["BarDesc_borderStyle"] = "Shows the game's decorative border art around the button (extra action and zone ability buttons)."

-- Active Bar States: the bar gets a page for the state, set its abilities in the button editor
L["BarDesc_state_shift"] = "Gives the bar a page for when Shift is held."
L["BarDesc_state_ctrl"] = "Gives the bar a page for when Control is held."
L["BarDesc_state_alt"] = "Gives the bar a page for when Alt is held."
L["BarDesc_state_target"] = "Gives the bar a page for when you have a target."
L["BarDesc_state_harm"] = "Gives the bar a page for when your target is hostile."
L["BarDesc_state_help"] = "Gives the bar a page for when your target is friendly."
L["BarDesc_state_stealth"] = "Gives the bar a page for when you are stealthed."
L["BarDesc_state_combat"] = "Gives the bar a page for when you are in combat."
L["BarDesc_state_party"] = "Gives the bar a page for when you are in a party."
L["BarDesc_state_raid"] = "Gives the bar a page for when you are in a raid."
L["BarDesc_state_mounted"] = "Gives the bar a page for when you are mounted."
L["BarDesc_state_swimming"] = "Gives the bar a page for when you are swimming."
L["BarDesc_state_vehicle"] = "Shows the vehicle's abilities on the bar when you are in a vehicle."
L["BarDesc_state_possess"] = "Shows the possessed creature's abilities on the bar when you possess something."
L["BarDesc_state_override"] = "Shows the game's override abilities on the bar when it gives you some (special encounters and quests)."
L["BarDesc_state_dragonriding"] = "Shows your skyriding abilities on the bar while skyriding."
L["BarDesc_state_resting"] = "Gives the bar a page for when you are resting in a city or inn."
L["BarDesc_state_indoors"] = "Gives the bar a page for when you are indoors."
L["BarDesc_state_outdoors"] = "Gives the bar a page for when you are outdoors."
L["BarDesc_state_fishing"] = "Gives the bar a page for when you have a fishing pole equipped."

-- Hidden Bar States: checked hides the bar in that state
L["BarDesc_visibility_paged1"] = "Hides the bar on action bar page 1."
L["BarDesc_visibility_paged2"] = "Hides the bar on action bar page 2."
L["BarDesc_visibility_paged3"] = "Hides the bar on action bar page 3."
L["BarDesc_visibility_paged4"] = "Hides the bar on action bar page 4."
L["BarDesc_visibility_paged5"] = "Hides the bar on action bar page 5."
L["BarDesc_visibility_paged6"] = "Hides the bar on action bar page 6."
L["BarDesc_visibility_shift0"] = "Hides the bar while Shift is not held."
L["BarDesc_visibility_shift1"] = "Hides the bar while Shift is held."
L["BarDesc_visibility_ctrl0"] = "Hides the bar while Control is not held."
L["BarDesc_visibility_ctrl1"] = "Hides the bar while Control is held."
L["BarDesc_visibility_alt0"] = "Hides the bar while Alt is not held."
L["BarDesc_visibility_alt1"] = "Hides the bar while Alt is held."
L["BarDesc_visibility_target0"] = "Hides the bar when you have no target."
L["BarDesc_visibility_target1"] = "Hides the bar when you have a target."
L["BarDesc_visibility_harm1"] = "Hides the bar when your target is one you can attack."
L["BarDesc_visibility_help1"] = "Hides the bar when your target is one you can help."
L["BarDesc_visibility_reaction0"] = "Hides the bar when your target is friendly."
L["BarDesc_visibility_reaction1"] = "Hides the bar when your target is hostile."
L["BarDesc_visibility_stealth0"] = "Hides the bar when you are not stealthed."
L["BarDesc_visibility_stealth1"] = "Hides the bar when you are stealthed."
L["BarDesc_visibility_stance0"] = "Hides the bar when you are not in any {form}."
L["BarDesc_visibility_combat0"] = "Hides the bar when you are out of combat."
L["BarDesc_visibility_combat1"] = "Hides the bar when you are in combat."
L["BarDesc_visibility_group0"] = "Hides the bar when you are not in a group."
L["BarDesc_visibility_group2"] = "Hides the bar when you are in a party."
L["BarDesc_visibility_group1"] = "Hides the bar when you are in a raid."
L["BarDesc_visibility_pet0"] = "Hides the bar when you have no pet."
L["BarDesc_visibility_pet1"] = "Hides the bar when you have a pet."
L["BarDesc_visibility_mounted0"] = "Hides the bar when you are not mounted."
L["BarDesc_visibility_mounted1"] = "Hides the bar when you are mounted."
L["BarDesc_visibility_swimming0"] = "Hides the bar when you are not swimming."
L["BarDesc_visibility_swimming1"] = "Hides the bar when you are swimming."
L["BarDesc_visibility_vehicle0"] = "Hides the bar when you are not in a vehicle."
L["BarDesc_visibility_vehicle1"] = "Hides the bar when you are in a vehicle."
L["BarDesc_visibility_extrabar0"] = "Hides the bar when there is no extra action button."
L["BarDesc_visibility_extrabar1"] = "Hides the bar when there is an extra action button."
L["BarDesc_visibility_possess0"] = "Hides the bar when you are not possessing anything."
L["BarDesc_visibility_possess1"] = "Hides the bar when you are possessing something."
L["BarDesc_visibility_override0"] = "Hides the bar when there is no override bar."
L["BarDesc_visibility_override1"] = "Hides the bar when the game shows an override bar."
L["BarDesc_visibility_dragonriding0"] = "Hides the bar when you are not skyriding."
L["BarDesc_visibility_dragonriding1"] = "Hides the bar while skyriding."
L["BarDesc_visibility_resting0"] = "Hides the bar when you are not resting."
L["BarDesc_visibility_resting1"] = "Hides the bar when you are resting in a city or inn."
L["BarDesc_visibility_indoors1"] = "Hides the bar when you are indoors."
L["BarDesc_visibility_outdoors1"] = "Hides the bar when you are outdoors."
L["BarDesc_visibility_fishing0"] = "Hides the bar when you have no fishing pole equipped."
L["BarDesc_visibility_fishing1"] = "Hides the bar when you have a fishing pole equipped."
