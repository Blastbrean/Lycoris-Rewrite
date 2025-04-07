-- CombatTab module.
local CombatTab = {}

---@module Utility.Logger
local Logger = require("Utility/Logger")

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

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
		Text = "Check Targeting Value",
		Default = false,
		Tooltip = "If found with a valid target, the script will check if we're currently being targeted.",
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
	})

	autoDefenseDepBox:AddToggle("RollOnParryCooldown", {
		Text = "Roll On Parry Cooldown",
		Default = false,
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

	autoDefenseDepBox:AddToggle("CheckHoldingBlockInput", {
		Text = "Check If Holding Block Input",
		Tooltip = "If we are holding the block input, stop the auto defense from proceeding.",
		Default = false,
	})

	autoDefenseDepBox:AddToggle("CheckWindowActive", {
		Text = "Check If Window Is Active",
		Tooltip = "If Roblox isn't the active window, stop the auto defense from proceeding.",
		Default = false,
	})

	autoDefenseDepBox:AddToggle("CheckTextboxFocused", {
		Text = "Check If Textbox Is Focused",
		Tooltip = "If a textbox is focused, stop the auto defense from proceeding.",
		Default = false,
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
	})

	groupbox:AddToggle("FeintMantrasWhileDefending", {
		Text = "Feint Mantras While Defending",
		Default = false,
	})

	groupbox:AddToggle("BlockPunishableM1s", {
		Text = "Block Punishable M1s",
		Default = false,
	})

	groupbox:AddToggle("BlockPunishableCriticals", {
		Text = "Block Punishable Criticals",
		Default = false,
	})

	groupbox:AddToggle("BlockPunishableMantras", {
		Text = "Block Punishable Mantras",
		Default = false,
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

-- Initialize input assistance section.
---@param groupbox table
function CombatTab.initInputAssistance(groupbox)
	groupbox:AddToggle("M1Hold", {
		Text = "M1 Hold",
		Default = false,
	})
end

-- Initialize combat assistance section.
---@param groupbox table
function CombatTab.initCombatAssistance(groupbox)
	groupbox:AddToggle("PerfectMantraCast", {
		Text = "Perfect Mantra Cast",
		Default = false,
	})

	local unisyncToggle = groupbox:AddToggle("AnimationUnisync", {
		Text = "Animation Unisync",
		Tooltip = "Secretly and quickly 'unisync' your character's animations which break other auto-defense solutions.",
		Default = false,
	})

	unisyncToggle:AddKeyPicker(
		"AnimationUnisyncKeybind",
		{ Default = "N/A", SyncToggleState = true, Text = "Animation Unisync" }
	)

	local unisyncDepBox = groupbox:AddDependencyBox()

	unisyncDepBox:AddSlider("AnimationUnisyncWeight", {
		Text = "Animation Unisync Weight",
		Tooltip = "The weight of the animation that will be unisynced.",
		Min = -100.0,
		Max = 100.0,
		Default = 0.0,
		Rounding = 1,
		Suffix = "w",
	})

	unisyncDepBox:AddSlider("AnimationUnisyncSpeed", {
		Text = "Animation Unisync Speed",
		Tooltip = "The speed of the animation that will be unisynced.",
		Min = -100.0,
		Max = 100.0,
		Default = -10.0,
		Rounding = 1,
		Suffix = "s",
	})

	unisyncDepBox:SetupDependencies({
		{ unisyncToggle, true },
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
	CombatTab.initInputAssistance(tab:AddDynamicGroupbox("Input Assistance"))
	CombatTab.initCombatAssistance(tab:AddDynamicGroupbox("Combat Assistance"))
end

-- Return CombatTab module.
return CombatTab
