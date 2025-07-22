-- AutomationTab module.
local AutomationTab = {}

---@module Features.Automation.EchoFarm
local EchoFarm = require("Features/Automation/EchoFarm")

---Attribute section.
---@param groupbox table
function AutomationTab.initAttributeSection(groupbox)
	groupbox
		:AddToggle("AutoCharisma", {
			Text = "Auto Charisma Farm",
			Default = false,
			Tooltip = "Using the 'How To Make Friends' book, the script will automatically train the 'Charisma' attribute.",
		})
		:AddKeyPicker("AutoCharismaKeybind", {
			Default = "N/A",
			SyncToggleState = true,
			Text = "Auto Charisma Farm",
		})

	groupbox:AddInput("CharismaCap", {
		Text = "Charisma Cap",
		Tooltip = "When this cap is reached, the farm will stop training the 'Charisma' attribute.",
		Numeric = true,
		MaxLength = 3,
		Default = "75",
	})

	groupbox
		:AddToggle("AutoIntelligence", {
			Text = "Auto Intelligence Farm",
			Tooltip = "Using the 'Math Textbook' book, the script will automatically train the 'Intelligence' attribute.",
			Default = false,
		})
		:AddKeyPicker("AutoIntelligenceKeybind", {
			Default = "N/A",
			SyncToggleState = true,
			Text = "Auto Intelligence",
		})

	groupbox:AddInput("IntelligenceCap", {
		Text = "Intelligence Cap",
		Tooltip = "When this cap is reached, the farm will stop training the 'Intelligence' attribute.",
		Numeric = true,
		MaxLength = 3,
		Default = "75",
	})
end

---Initialize Fish Farm section.
---@param groupbox table
function AutomationTab.initFishFarmSection(groupbox)
	groupbox
		:AddToggle("AutoFish", {
			Text = "Auto Fish Farm",
			Tooltip = "Automatically farm fish. Non-AFKable yet. Work-in progress.",
			Default = false,
		})
		:AddKeyPicker("AutoFishKeybind", {
			Default = "N/A",
			SyncToggleState = true,
			Text = "Auto Fish Farm",
		})
end

---Initialize Echo Farm section.
---@param groupbox table
function AutomationTab.initEchoFarmSection(groupbox)
	groupbox:AddButton({
		Text = "Start Echo Farm",
		Tooltip = "Quickly stop at any time with the '0' key on your keyboard.",
		DoubleClick = true,
		DoubleClickText = "Wipe the current slot?",
		Func = EchoFarm.start,
	})

	groupbox:AddButton("Stop Echo Farm", EchoFarm.stop)
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
	AutomationTab.initFishFarmSection(tab:AddDynamicGroupbox("Fish Farm"))
	AutomationTab.initEchoFarmSection(tab:AddDynamicGroupbox("Echo Farm"))
	AutomationTab.initAttributeSection(tab:AddDynamicGroupbox("Attribute Farm"))
	AutomationTab.initEffectAutomation(tab:AddDynamicGroupbox("Effect Automation"))
end

-- Return AutomationTab module.
return AutomationTab
