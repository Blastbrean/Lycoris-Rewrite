-- AutomationTab module.
local AutomationTab = {}

---Attribute section.
---@param groupbox table
function AutomationTab.initAttributeSection(groupbox)
	groupbox:AddToggle("AutoCharisma", {
		Text = "Auto Charisma Farm",
		Default = false,
		Tooltip = "Using the 'How To Make Friends' book, the script will automatically train the 'Charisma' attribute.",
	})

	local charismaDepbox = groupbox:AddDependencyBox()

	charismaDepbox:AddInput("CharismaCap", {
		Text = "Charisma Cap",
		Tooltip = "When this cap is reached, the farm will stop training the 'Charisma' attribute.",
		Numeric = true,
		MaxLength = 3,
		Default = "75",
	})

	groupbox:AddToggle("AutoIntelligence", {
		Text = "Auto Intelligence",
		Tooltip = "Using the 'Math Textbook' book, the script will automatically train the 'Intelligence' attribute.",
		Default = false,
	})

	local intelDepBox = groupbox:AddDependencyBox()

	intelDepBox:AddInput("IntelligenceCap", {
		Text = "Intelligence Cap",
		Tooltip = "When this cap is reached, the farm will stop training the 'Intelligence' attribute.",
		Numeric = true,
		MaxLength = 3,
		Default = "75",
	})

	charismaDepbox:SetupDependencies({
		{ Toggles.AutoCharisma, true },
	})

	intelDepBox:SetupDependencies({
		{ Toggles.AutoIntelligence, true },
	})
end

---Fishing section.
---@param groupbox table
function AutomationTab.initFishingSection(groupbox)
	groupbox:AddToggle("AutoFish", {
		Text = "Auto Fish",
		Tooltip = "Using the 'Fishing Rod' item, the script will automatically fish for you.",
		Default = false,
	})

	local fishDepBox = groupbox:AddDependencyBox()

	fishDepBox:AddSlider("AutoFishDelay", {
		Text = "Hold Time",
		Tooltip = "How long should we hold the fishing input(s) for?",
		Default = 0.1,
		Min = 0,
		Max = 0.5,
		Rounding = 1,
		Suffix = "sec",
	})

	fishDepBox:AddToggle("AutoFishKill", {
		Text = "Kill Caught Mudskippers",
		Tooltip = "When a mudskipper is caught - should we kill it or not?",
		Default = false,
	})

	fishDepBox:AddToggle("AutoFishWebhookSend", {
		Text = "Auto Fish Webhook Notification",
		Tooltip = "Send a notification to a Webhook when the 'AutoFish' looting is finished.",
		Default = false,
	})

	local fishWhSubDepBox = fishDepBox:AddDependencyBox()

	fishWhSubDepBox:AddInput("AutoFishWebhook", {
		Text = "Auto Fish Webhook",
		Tooltip = "The webhook that will receive 'AutoFish' looting data.",
		Placeholder = "Enter your webhook link here.",
		Numeric = false,
	})

	fishWhSubDepBox:SetupDependencies({
		{ Toggles.AutoFishWebhookSend, true },
	})

	fishDepBox:SetupDependencies({
		{ Toggles.AutoFish, true },
	})
end

---Maestro section.
---@param groupbox table
function AutomationTab.initMaestroSection(groupbox)
	groupbox:AddToggle("AutoMaestro", {
		Text = "Auto Maestro",
		Tooltip = "Automatically fight 'Maestro' for you. You have to already have fought him once before using this feature.",
		Default = false,
	})

	local maestroDepBox = groupbox:AddDependencyBox()

	maestroDepBox:AddToggle("MaestroUseCritical", {
		Text = "Use Critical",
		Tooltip = "In the 'Maestro' fight, the 'Auto Maestro' fight will spam your weapon's critical.",
		Default = false,
	})

	maestroDepBox:AddToggle("MaestroVoid", {
		Text = "Gremorian Spear Void",
		Tooltip = "Using the Gremorian Spear, it will attempt to void 'Maestro' in the fight instead.",
		Default = false,
	})

	maestroDepBox:AddToggle("NotifyMaestro", {
		Text = "Maestro Webhook Notification",
		Tooltip = "Send a notification to a Webhook when the 'Maestro' looting is finished.",
		Default = false,
	})

	local maestroNotifySubDepBox = maestroDepBox:AddDependencyBox()

	maestroNotifySubDepBox:AddInput("MaestroWebhook", {
		Text = "Maestro Webhook",
		Tooltip = "The webhook that will receive 'Maestro' looting data.",
		Numeric = false,
		Finished = false,
		Placeholder = "Enter your webhook here.",
	})

	maestroNotifySubDepBox:SetupDependencies({
		{ Toggles.NotifyAstral, true },
	})

	maestroDepBox:SetupDependencies({
		{ Toggles.AutoMaestro, true },
	})
end

---Astral section.
---@param groupbox table
function AutomationTab.initAstralSection(groupbox)
	groupbox:AddToggle("AutoAstral", {
		Text = "Auto Astral Farm",
		Toolip = "You must be in the 'Void Sea' and have 'Carnivore' or 'Food' in your inventory to use this feature.",
		Default = false,
	})

	local astralDepBox = groupbox:AddDependencyBox()

	astralDepBox:AddSlider("AstralSpeed", {
		Text = "Astral Speed",
		Tooltip = "How fast should we move while farming?",
		Default = 100,
		Min = 10,
		Max = 200,
		Rounding = 0,
		Suffix = "/s",
	})

	astralDepBox:AddToggle("AstralCarnivore", {
		Text = "Use Carnivore",
		Tooltip = "Kill mobs to get food instead of using food in your inventory.",
		Default = false,
	})

	astralDepBox:AddSlider("AstralHungerLevel", {
		Text = "Hunger Level",
		Tooltip = "At what percentage of hunger should we eat food?",
		Default = 33,
		Min = 0,
		Max = 100,
		Rounding = 0,
		Suffix = "%",
	})

	astralDepBox:AddSlider("AstralWaterLevel", {
		Text = "Water Level",
		Tooltip = "At what percentage of water should we drink water?",
		Default = 33,
		Min = 0,
		Max = 100,
		Rounding = 0,
		Suffix = "%",
	})

	astralDepBox:AddToggle("NotifyAstral", {
		Text = "Astral Webhook Notification",
		Tooltip = "Send a notification to a Webhook when the 'Astral' event is detected.",
		Default = false,
	})

	local astralNotifySubDepBox = astralDepBox:AddDependencyBox()

	astralNotifySubDepBox:AddInput("AstralWebhook", {
		Text = "Astral Webhook",
		Tooltip = "The webhook that will receive 'Astral' notifications.",
		Numeric = false,
		Finished = false,
		Placeholder = "Enter your webhook here.",
	})

	astralDepBox:SetupDependencies({
		{ Toggles.AutoAstral, true },
	})

	astralNotifySubDepBox:SetupDependencies({
		{ Toggles.NotifyAstral, true },
	})
end

---Initialize Effect Automation section.
---@param groupbox table
function AutomationTab.initEffectAutomation(groupbox)
	groupbox:AddToggle("AutoExtinguishFire", {
		Text = "Auto Extinguish Fire",
		Tooltip = "Attempt to remove 'Burning' effects through automatic sliding.",
		Default = false,
	})
end

---Initialize tab.
---@param window table
function AutomationTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Auto")

	-- Initialize sections.
	--AutomationTab.initAstralSection(tab:AddDynamicGroupbox("Astral Farm"))
	--AutomationTab.initMaestroSection(tab:AddDynamicGroupbox("Maestro Farm"))
	--AutomationTab.initFishingSection(tab:AddDynamicGroupbox("Fish Farm"))
	AutomationTab.initAttributeSection(tab:AddDynamicGroupbox("Attribute Farm"))
	AutomationTab.initEffectAutomation(tab:AddDynamicGroupbox("Effect Automation"))

	---@todo: Make the echo farm and wipe farm later.
end

-- Return AutomationTab module.
return AutomationTab
