-- AutomationTab module.
local AutomationTab = {}

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Features.Automation.EchoFarm
local EchoFarm = require("Features/Automation/EchoFarm")

---@module Game.ServerHop
local ServerHop = require("Game/ServerHop")

---@module Features.Game.Interactions
local Interactions = require("Features/Game/Interactions")

---@module Game.Wipe
local Wipe = require("Game/Wipe")

---@module Features.Game.Tweening
local Tweening = require("Features/Game/Tweening")

---@module Utility.Finder
local Finder = require("Utility/Finder")

-- Services.
local players = game:GetService("Players")

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

---Initialize Auto Loot section.
---@param groupbox table
function AutomationTab.initAutoLootSection(groupbox)
	groupbox
		:AddToggle("AutoLoot", {
			Text = "Auto Loot",
			Tooltip = "Automatically loot items from choice prompts with filtering options.",
			Default = false,
		})
		:AddKeyPicker("AutoLootKeybind", {
			Default = "N/A",
			SyncToggleState = true,
			Text = "Auto Loot",
		})

	local autoLootDepBox = groupbox:AddDependencyBox()

	autoLootDepBox:AddToggle("AutoLootAll", {
		Text = "Loot All Items",
		Tooltip = "Loot all items from choice prompts. This will ignore filtering options.",
		Default = false,
	})

	local autoLootAllDepBox = autoLootDepBox:AddDependencyBox()

	autoLootAllDepBox:AddSlider("AutoLootStarsMin", {
		Text = "Minimum Stars",
		Tooltip = "The minimum number of stars an item must have to be looted.",
		Min = 0,
		Max = 3,
		Rounding = 0,
		Suffix = "★",
		Default = 0,
	})

	autoLootAllDepBox:AddSlider("AutoLootStarsMax", {
		Text = "Maximum Stars",
		Tooltip = "The maximum number of stars an item can have to be looted.",
		Min = 0,
		Max = 3,
		Rounding = 0,
		Suffix = "★",
		Default = 0,
	})

	local itemNameList = autoLootAllDepBox:AddDropdown("ItemNameList", {
		Text = "Item Name List",
		Values = {},
		SaveValues = true,
		Multi = true,
		AllowNull = true,
	})

	local itemNameInput = autoLootAllDepBox:AddInput("ItemNameInput", {
		Text = "Item Name Input",
		Placeholder = "Exact or partial names.",
	})

	autoLootAllDepBox:AddButton("Add Item Name To Filter", function()
		local itemName = itemNameInput.Value
		if #itemName <= 0 then
			return Logger.longNotify("Please enter a valid item name.")
		end

		local values = itemNameList.Values
		if not table.find(values, itemName) then
			table.insert(values, itemName)
		end

		itemNameList:SetValues(values)
		itemNameList:SetValue({})
		itemNameList:Display()
	end)

	autoLootAllDepBox:AddButton("Remove Selected Item Names", function()
		local values = itemNameList.Values
		local value = itemNameList.Value

		for selected, _ in next, value do
			local index = table.find(values, selected)
			if not index then
				continue
			end

			table.remove(values, index)
		end

		itemNameList:SetValues(values)
		itemNameList:SetValue({})
		itemNameList:Display()
	end)

	autoLootAllDepBox:SetupDependencies({
		{ Toggles.AutoLootAll, false },
	})

	autoLootDepBox:SetupDependencies({
		{ Toggles.AutoLoot, true },
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

---Initialize Debugging section.
---@param groupbox table
function AutomationTab.initDebuggingSection(groupbox)
	-- groupbox:AddButton("Start Echo Farm", EchoFarm.invoke)
	-- groupbox:AddButton("Stop Echo Farm", EchoFarm.stop)
end

---Initialize tab.
---@param window table
function AutomationTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Auto")

	-- Initialize sections.
	AutomationTab.initFishFarmSection(tab:AddDynamicGroupbox("Fish Farm"))
	AutomationTab.initAttributeSection(tab:AddDynamicGroupbox("Attribute Farm"))
	AutomationTab.initEffectAutomation(tab:AddDynamicGroupbox("Effect Automation"))
	AutomationTab.initAutoLootSection(tab:AddLeftGroupbox("Auto Loot"))
	-- AutomationTab.initDebuggingSection(tab:AddRightGroupbox("Debugging"))
end

-- Return AutomationTab module.
return AutomationTab
