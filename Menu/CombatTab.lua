-- CombatTab module.
local CombatTab = {}

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Features.Combat.Defense
local Defense = require("Features/Combat/Defense")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module GUI.Library
local Library = require("GUI/Library")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

-- Initialize combat targeting section.
---@param tab table
function CombatTab.initCombatTargetingSection(tab)
	tab:AddDropdown("PlayerSelectionType", {
		Text = "Player Selection Type",
		Values = {
			"Closest In Distance",
			"Closest To Crosshair",
			"Least Health",
		},
		Default = 1,
	})

	tab:AddSlider("FOVLimit", {
		Text = "Player FOV Limit",
		Min = 0,
		Max = 180,
		Default = 180,
		Suffix = "°",
		Rounding = 0,
	})

	tab:AddSlider("DistanceLimit", {
		Text = "Distance Limit",
		Min = 0,
		Max = 10000,
		Default = 3000,
		Suffix = "s",
		Rounding = 0,
	})

	tab:AddSlider("MaxTargets", {
		Text = "Max Targets",
		Min = 1,
		Max = 64,
		Default = 4,
		Rounding = 0,
	})

	tab:AddToggle("CheckTargetingValue", {
		Text = "Check Mob Targeting Value",
		Default = false,
		Tooltip = "If a mob is found with a valid target, the script will check if we're currently being targeted.",
	})

	tab:AddToggle("IgnorePlayers", {
		Text = "Ignore Players",
		Default = false,
	})

	tab:AddToggle("IgnoreMobs", {
		Text = "Ignore Mobs",
		Default = false,
	})

	tab:AddToggle("IgnoreAllies", {
		Text = "Ignore Allies",
		Default = false,
	})
end

-- Initialize combat whitelist section.
---@param groupbox table
function CombatTab.initCombatWhitelistSection(groupbox)
	groupbox:AddToggle("PlayerListWhitelisting", {
		Text = "Player List Whitelisting",
		Tooltip = "Click your 'L' key on players in the player list to add/remove them from the whitelist.",
		Default = false,
	})

	local usernameList = groupbox:AddDropdown("UsernameList", {
		Text = "Username List",
		Values = {},
		SaveValues = true,
		Multi = true,
		AllowNull = true,
	})

	local usernameInput = groupbox:AddInput("UsernameInput", {
		Text = "Username Input",
		Placeholder = "Display name or username.",
	})

	groupbox:AddButton("Add Username To Whitelist", function()
		local username = usernameInput.Value
		if #username <= 0 then
			return Logger.longNotify("Please enter a valid username.")
		end

		local values = usernameList.Values
		if not table.find(values, username) then
			table.insert(values, username)
		end

		usernameList:SetValues(values)
		usernameList:SetValue({})
		usernameList:Display()
	end)

	groupbox:AddButton("Remove Selected Usernames", function()
		local values = usernameList.Values
		local value = usernameList.Value

		for selected, _ in next, value do
			local index = table.find(values, selected)
			if not index then
				continue
			end

			table.remove(values, index)
		end

		usernameList:SetValues(values)
		usernameList:SetValue({})
		usernameList:Display()
	end)
end

-- Initialize auto defense section.
---@param groupbox table
function CombatTab.initAutoDefenseSection(groupbox)
	local autoDefenseToggle = groupbox:AddToggle("EnableAutoDefense", {
		Text = "Enable Auto Defense",
		Default = false,
	})

	autoDefenseToggle:AddKeyPicker(
		"EnableAutoDefenseKeybind",
		{ Default = "N/A", SyncToggleState = true, Text = "Auto Defense" }
	)

	local autoDefenseDepBox = groupbox:AddDependencyBox()

	autoDefenseDepBox:AddToggle("EnableNotifications", {
		Text = "Enable Notifications",
		Default = false,
	})

	autoDefenseDepBox:AddToggle("EnableVisualizations", {
		Text = "Enable Visualizations",
		Default = false,
		Callback = Defense.visualizations,
	})

	autoDefenseDepBox:AddToggle("RollOnParryCooldown", {
		Text = "Roll On Parry Cooldown",
		Default = false,
	})

	autoDefenseDepBox:AddToggle("VentFallback", {
		Text = "Vent Fallback",
		Default = false,
		Tooltip = "This is used as a last resort which takes priority after 'Deflect Block Fallback' if it is on.",
	})

	autoDefenseDepBox:AddToggle("DeflectBlockFallback", {
		Text = "Deflect Block Fallback",
		Default = false,
		Tooltip = "If enabled, the auto defense will fallback to block frames if parry action and/or fallback is not available as a last resort.",
	})

	autoDefenseDepBox:AddToggle("UseIFrames", {
		Text = "Use Invincibility Frames",
		Default = false,
		Tooltip = "If enabled, the auto defense will ignore parry, block and dodge action if there's already an existing invincibility frame.",
	})

	autoDefenseDepBox:AddToggle("ValidateIncomingAnimations", {
		Text = "Validate Incoming Animations",
		Default = true,
		Tooltip = "If enabled, the auto defense will check the incoming attack's animation for any abnormalities to prevent AP breaking.",
	})

	autoDefenseDepBox:AddToggle("ParryOnly", {
		Text = "Parry Dodgeables",
		Default = false,
		Tooltip = "If enabled, the auto defense will change dodge actions to parry actions.",
	})

	autoDefenseDepBox:AddToggle("UsePrediction", {
		Text = "Use Prediction",
		Default = false,
		Tooltip = "Use Prediction mantra instead of parry/dodge when available and off cooldown. Can be used together with Punishment (Prediction takes priority).",
	})

	autoDefenseDepBox:AddToggle("UsePunishment", {
		Text = "Use Punishment",
		Default = false,
		Tooltip = "Use Punishment mantra instead of parry/dodge when available and off cooldown. Can be used together with Prediction (Prediction takes priority).",
	})

	local blatantRollToggle = autoDefenseDepBox:AddToggle("BlatantRoll", {
		Text = "Blatant Roll",
		Default = false,
		Tooltip = "If enabled, we will call the roll remotes directly without running any checks, specific-movement, etc.",
	})

	local rollCancelTgDepBox = autoDefenseDepBox:AddDependencyBox()

	local rollCancelToggle = autoDefenseDepBox:AddToggle("RollCancel", {
		Text = "Roll Cancel",
		Default = false,
	})

	local rollCancelDepBox = autoDefenseDepBox:AddDependencyBox()

	rollCancelDepBox:AddSlider("RollCancelDelay", {
		Text = "Roll Cancel Delay",
		Default = 0.05,
		Min = 0,
		Max = 2,
		Suffix = "s",
		Rounding = 2,
	})

	rollCancelDepBox:SetupDependencies({
		{ rollCancelToggle, true },
	})

	rollCancelTgDepBox:SetupDependencies({
		{ blatantRollToggle, true },
	})

	local afToggle = autoDefenseDepBox:AddToggle("AllowFailure", {
		Text = "Allow Failure",
		Default = false,
		Tooltip = "If enabled, the auto defense will sometimes intentionally fail to parry/deflect.",
	})

	local afDepBox = autoDefenseDepBox:AddDependencyBox()

	afDepBox:AddSlider("FailureRate", {
		Text = "Failure Rate",
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = "%",
		Rounding = 2,
	})

	afDepBox:AddSlider("DashInsteadOfParryRate", {
		Text = "Dash Instead Of Parry Rate",
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = "%",
		Rounding = 2,
	})

	afDepBox:AddSlider("IgnoreAnimationEndRate", {
		Text = "Ignore Animation End Rate",
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = "%",
		Rounding = 2,
	})

	afDepBox:SetupDependencies({
		{ afToggle, true },
	})

	autoDefenseDepBox:AddDropdown("AutoDefenseFilters", {
		Text = "Auto Defense Filters",
		Values = {
			"Filter Out M1s",
			"Filter Out Mantras",
			"Filter Out Criticals",
			"Filter Out Undefined",
			"Disable When Textbox Focused",
			"Disable When Window Not Active",
			"Disable While Holding Block",
			"Disable While Using Sightless Beam",
			"Disable During Chime Countdown",
		},
		Multi = true,
		AllowNull = true,
		Default = {},
	})

	autoDefenseDepBox:SetupDependencies({
		{ autoDefenseToggle, true },
	})
end

---Create timing override callback.
---@param callback function
---@return function
local function timingOverrideCallback(callback)
	return function()
		local overrideData = Library.OverrideData
		if not overrideData then
			return false
		end

		local selectedTo = Configuration.expectOptionValue("TimingOverrideList")
		if not selectedTo or #selectedTo == 0 then
			return false
		end

		local override = overrideData[selectedTo]
		if not override then
			return false
		end

		callback(override)
	end
end

---Refresh timing override list.
local function refreshTimingOverrideList()
	local overrideData = Library.OverrideData
	if not overrideData then
		return
	end

	local timingList = Options["TimingOverrideList"]
	if not timingList then
		return
	end

	local values = {}

	for rname, _ in next, overrideData do
		values[#values + 1] = rname
	end

	timingList:SetValues(values)
end

---Initialize timings section.
---@param groupbox table
function CombatTab:initTimingsSection(groupbox)
	self.tol = groupbox:AddDropdown("TimingOverrideList", {
		Text = "Timing Override List",
		Values = {},
		SaveValues = false,
		Multi = false,
		AllowNull = true,
		Callback = function()
			self.dashInsteadOfParryRate:SetRawValue(0)
			self.failureRate:SetRawValue(0)
			self.ignoreAnimationEndRate:SetRawValue(0)

			local overrideData = Library.OverrideData
			if not overrideData then
				return false
			end

			local selectedTo = Configuration.expectOptionValue("TimingOverrideList")
			if not selectedTo or #selectedTo == 0 then
				return false
			end

			local override = overrideData[selectedTo]
			if not override then
				return false
			end

			self.dashInsteadOfParryRate:SetRawValue(override.dipr or 0)
			self.failureRate:SetRawValue(override.fr or 0)
			self.ignoreAnimationEndRate:SetRawValue(override.iaer or 0)
		end,
	})

	groupbox:AddDivider()

	local names = {}
	local plist = { SaveManager.as, SaveManager.es, SaveManager.ss, SaveManager.ps }

	---@todo: There should be a specific method for this; I mean as far as I'm aware THERE IS ONE. But, I'm too lazy.
	for _, pair in next, plist do
		for _, timing in next, pair:list() do
			names[#names + 1] = PP_SCRAMBLE_STR(timing.name)
		end
	end

	table.sort(names)

	self.ti = groupbox:AddDropdown("TimingOverrideTimingList", {
		Text = "Timing List",
		Values = names,
		Multi = false,
		AllowNull = true,
	})

	groupbox:AddButton("Add Timing Override", function()
		if Library.OverrideData[self.ti.Value] then
			return Logger.notify("A timing override with that name already exists.")
		end

		-- Add data.
		local override = {
			fr = self.failureRate.Value,
			dipr = self.dashInsteadOfParryRate.Value,
			iaer = self.ignoreAnimationEndRate.Value,
		}

		Library.OverrideData[self.ti.Value] = override

		-- Refresh timing list.
		refreshTimingOverrideList()

		-- Set timing list value.
		self.tol:SetValue(self.ti.Value)
		self.tol:Display()
	end)

	groupbox:AddButton("Remove Selected Override", function()
		-- Remove data.
		Library.OverrideData[self.tol.Value] = nil

		-- Refresh timing list.
		refreshTimingOverrideList()

		-- Set timing list value.
		self.tol:SetValue(nil)
		self.tol:Display()
	end)

	-- Initial refresh.
	refreshTimingOverrideList()
end

---Initialize probabilities section.
---@param groupbox table
function CombatTab:initProbabilitiesSection(groupbox)
	self.failureRate = groupbox:AddSlider("TP_FailureRate", {
		Text = "Failure Rate",
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = "%",
		Rounding = 2,
		Callback = timingOverrideCallback(function(override)
			override.fr = self.failureRate.Value
		end),
	})

	self.dashInsteadOfParryRate = groupbox:AddSlider("TP_DashInsteadOfParryRate", {
		Text = "Dash Instead Of Parry Rate",
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = "%",
		Rounding = 2,
		Callback = timingOverrideCallback(function(override)
			override.dipr = self.dashInsteadOfParryRate.Value
		end),
	})

	self.ignoreAnimationEndRate = groupbox:AddSlider("TP_IgnoreAnimationEndRate", {
		Text = "Ignore Animation End Rate",
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = "%",
		Rounding = 2,
		Callback = timingOverrideCallback(function(override)
			override.iaer = self.ignoreAnimationEndRate.Value
		end),
	})
end

---Initialize attack assistance section.
---@param groupbox table
function CombatTab.initAttackAssistanceSection(groupbox)
	local afToggle = groupbox:AddToggle("AutoFeint", {
		Text = "Auto Feint",
		Default = false,
		Tooltip = "Attempt to automatically feint your attacks before the parry timing to prevent swing-throughs.",
	})

	local afDepBox = groupbox:AddDependencyBox()

	afDepBox:AddDropdown("AutoFeintType", {
		Text = "Auto Feint Type",
		Values = {
			"Passive",
			"Aggressive",
		},
		Default = 1,
	})

	afDepBox:SetupDependencies({
		{ afToggle, true },
	})
end

---Initialize combat assistance section.
---@param groupbox table
function CombatTab.initCombatAssistance(groupbox)
	local awToggle = groupbox:AddToggle("AutoWisp", {
		Text = "Auto Wisp",
		Default = false,
		Tooltip = "Automatically cast your Wisp for you without pressing the buttons.",
	})

	local awDepBox = groupbox:AddDependencyBox()

	awDepBox:AddSlider("AutoWispDelay", {
		Text = "Auto Wisp Delay",
		Default = 0.4,
		Min = 0,
		Max = 1,
		Suffix = "s",
		Rounding = 2,
	})

	awDepBox:SetupDependencies({
		{ awToggle, true },
	})

	local agtToggle = groupbox:AddToggle("AutoGoldenTongue", {
		Text = "Auto Golden Tongue",
		Default = false,
		Tooltip = "Automatically say a hidden message when your 'Golden Tongue' talent is on cooldown.",
	})

	local agtDepBox = groupbox:AddDependencyBox()

	agtDepBox:AddToggle("CheckIfInCombat", {
		Text = "Check If In Combat",
		Default = false,
		Tooltip = "Only send the message if we're currently in combat.",
	})

	agtDepBox:SetupDependencies({
		{ agtToggle, true },
	})

	local amfToggle = groupbox:AddToggle("AutoMantraFollowup", {
		Text = "Auto Mantra Followup",
		Default = false,
		Tooltip = "Automatically press the followup button while using a mantra.",
	})

	local amfDepBox = groupbox:AddDependencyBox()

	amfDepBox:AddToggle("CheckIfMoveHit", {
		Text = "Check If Move Hit",
		Default = false,
		Tooltip = "Only press the followup button if a 'DamagedAnother' effect is detected.",
	})

	amfDepBox:SetupDependencies({
		{ amfToggle, true },
	})

	groupbox:AddToggle("AutoArdour", {
		Text = "Auto Ardour",
		Default = false,
		Tooltip = "Automatically activate Ardour when you have a weapon equipped and the buff is not active. Requires the 'Murmur: Ardour' talent.",
	})

	groupbox:AddToggle("AutoFlowState", {
		Text = "Auto Flow State",
		Default = false,
		Tooltip = "Detect what Silentheart moves would be thrown out and use flow-state beforehand.",
	})

	groupbox:AddToggle("DelayedFeints", {
		Text = "Delayed Feints",
		Default = false,
		Tooltip = "When you feint during a move, it will attempt to delay it to be as late as possible.",
	})

	local ascToggle = groupbox:AddToggle("AnimationSpeedChanger", {
		Text = "Animation Speed Changer",
		Default = false,
		Tooltip = "Should we change the animation speed of animations when they play?",
	})

	local ascDepBox = groupbox:AddDependencyBox()

	ascDepBox:AddToggle("LimitToAPAnimations", {
		Text = "Limit To AP Animations",
		Default = false,
		Tooltip = "Only change the animation speed of animations that are inside of the 'Auto Parry' animations list.",
	})

	ascDepBox:AddToggle("SwitchBetweenSpeeds", {
		Text = "Switch Between Speeds",
		Default = false,
		Tooltip = "Only switch between values around minimum and maximum animation speeds instead of a random value in between.",
	})

	ascDepBox:AddSlider("AnimationSpeedMinimum", {
		Text = "Animation Speed Minimum",
		Default = 1.0,
		Min = 0.1,
		Max = 5,
		Suffix = "x",
		Rounding = 2,
	})

	ascDepBox:AddSlider("AnimationSpeedMaximum", {
		Text = "Animation Speed Maximum",
		Default = 1.25,
		Min = 0.1,
		Max = 5,
		Suffix = "x",
		Rounding = 2,
	})

	ascDepBox:SetupDependencies({
		{ ascToggle, true },
	})

	local arToggle = groupbox:AddToggle("ActionRolling", {
		Text = "Action Rolling",
		Default = false,
		Tooltip = "Automatically roll when performing certain actions.",
	})

	local arDepBox = groupbox:AddDependencyBox()

	arDepBox:AddDropdown("ActionRollingActions", {
		Text = "Action Rolling Actions",
		Values = {
			"Roll On M1",
			"Roll On Critical",
			"Roll On Cast",
			"Roll On Parry",
		},
		Multi = true,
		AllowNull = true,
		Default = {},
	})

	arDepBox:AddSlider("ActionRollCancelDelay", {
		Text = "Action Roll Cancel Delay",
		Default = 0.1,
		Min = 0,
		Max = 2,
		Suffix = "s",
		Rounding = 2,
	})

	arDepBox:AddSlider("ActionRollCooldown", {
		Text = "Action Roll Cooldown",
		Default = 2,
		Min = 0,
		Max = 5,
		Suffix = "s",
		Rounding = 2,
	})

	arDepBox:SetupDependencies({
		{ arToggle, true },
	})

	groupbox:AddToggle("M1Hold", {
		Text = "M1 Hold",
		Default = false,
	})

	groupbox:AddToggle("AutoRagdollRecover", {
		Text = "Auto Ragdoll Recover",
		Default = false,
		Tooltip = "Automatically recover from ragdoll state.",
	})

	groupbox:AddToggle("FeintFlourish", {
		Text = "Feint Flourish",
		Default = false,
		Tooltip = "Allow yourself to feint your flourish attacks. You need a mantra.",
	})
end

---Initialize debugging section.
---@param groupbox table
function CombatTab.initDebuggingSection(groupbox)
	groupbox:AddToggle("BlockParryState", {
		Text = "Block Parry State",
		Default = false,
	})

	groupbox:AddToggle("BlockDodgeState", {
		Text = "Block Dodge State",
		Default = false,
	})

	groupbox:AddToggle("BlockVentState", {
		Text = "Block Vent State",
		Default = false,
	})

	groupbox:AddToggle("NoBlockingState", {
		Text = "No Blocking State",
		Default = false,
	})
end

---Initialize tab.
---@param window table
function CombatTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Combat")

	-- Initialize sections.
	CombatTab.initAutoDefenseSection(tab:AddDynamicGroupbox("Auto Defense"))
	-- Create targeting section tab box.
	local tabbox = tab:AddDynamicTabbox()
	CombatTab.initCombatTargetingSection(tabbox:AddTab("Targeting"))
	CombatTab.initCombatWhitelistSection(tabbox:AddTab("Whitelisting"))

	-- Initialize other sections.
	CombatTab.initAttackAssistanceSection(tab:AddDynamicGroupbox("Attack Assistance"))
	CombatTab.initCombatAssistance(tab:AddDynamicGroupbox("Combat Assistance"))

	-- Create timing probability section tab box.
	local tpTabbox = tab:AddDynamicTabbox()
	CombatTab:initTimingsSection(tpTabbox:AddTab("Timings"))
	CombatTab:initProbabilitiesSection(tpTabbox:AddTab("Probabilities"))

	-- Initialize debugging section.
	if not LRM_UserNote then
		CombatTab.initDebuggingSection(tab:AddDynamicGroupbox("Debugging"))
	end
end

-- Return CombatTab module.
return CombatTab
