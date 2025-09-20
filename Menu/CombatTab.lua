-- CombatTab module.
local CombatTab = {}

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Features.Combat.Defense
local Defense = require("Features/Combat/Defense")

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
---@param tab table
function CombatTab.initCombatWhitelistSection(tab)
	local usernameList = tab:AddDropdown("UsernameList", {
		Text = "Username List",
		Values = {},
		SaveValues = true,
		Multi = true,
		AllowNull = true,
	})

	local usernameInput = tab:AddInput("UsernameInput", {
		Text = "Username Input",
		Placeholder = "Display name or username.",
	})

	tab:AddButton("Add Username To Whitelist", function()
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

	tab:AddButton("Remove Selected Usernames", function()
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

	autoDefenseDepBox:AddToggle("DeflectBlockFallback", {
		Text = "Deflect Block Fallback",
		Default = false,
		Tooltip = "If enabled, the auto defense will fallback to block frames if parry action and/or fallback is not available.",
	})

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

	afDepBox:AddSlider("FakeMistimeRate", {
		Text = "Fake Parry Mistime Rate",
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
		},
		Multi = true,
		AllowNull = true,
		Default = {},
	})

	autoDefenseDepBox:SetupDependencies({
		{ autoDefenseToggle, true },
	})
end

-- Initialize feint detection section.
---@param groupbox table
function CombatTab.initFeintDetectionSection(groupbox) end

-- Initialize attack assistance section.
---@param groupbox table
function CombatTab.initAttackAssistanceSection(groupbox)
	groupbox:AddToggle("FeintM1WhileDefending", {
		Text = "Feint M1 While Defending",
		Default = false,
		Tooltip = "If you are attacking while attempting to defend, feint your M1s so you can perform actions.",
	})

	groupbox:AddToggle("FeintMantrasWhileDefending", {
		Text = "Feint Mantras While Defending",
		Default = false,
		Tooltip = "If you are attacking while attempting to defend, feint your mantras so you can perform actions.",
	})

	groupbox:AddDropdown("BlockInputOptions", {
		Text = "Block Input Options",
		Values = {
			"Punishable M1s",
			"Punishable Criticals",
			"Punishable Mantras",
		},
		Multi = true,
		AllowNull = true,
		Default = {},
	})

	groupbox:AddSlider("DefaultPunishableWindow", {
		Text = "Default Punishable Window",
		Min = 0,
		Max = 2,
		Default = 0.7,
		Suffix = "s",
		Rounding = 1,
	})

	groupbox:AddSlider("DefaultAfterWindow", {
		Text = "Default After Window",
		Min = 0,
		Max = 1,
		Default = 0.1,
		Suffix = "s",
		Rounding = 1,
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

	groupbox:AddToggle("AutoGoldenTongue", {
		Text = "Auto Golden Tongue",
		Default = false,
		Tooltip = "Automatically say a hidden message when your 'Golden Tongue' talent is on cooldown.",
	})

	groupbox:AddToggle("AutoFlowState", {
		Text = "Auto Flow State",
		Default = false,
		Tooltip = "Detect what Silentheart moves would be thrown out and use flow-state beforehand.",
	})

	groupbox:AddToggle("M1Hold", {
		Text = "M1 Hold",
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
	CombatTab.initFeintDetectionSection(tab:AddDynamicGroupbox("Feint Detection"))
	CombatTab.initAttackAssistanceSection(tab:AddDynamicGroupbox("Attack Assistance"))
	CombatTab.initCombatAssistance(tab:AddDynamicGroupbox("Combat Assistance"))
end

-- Return CombatTab module.
return CombatTab
