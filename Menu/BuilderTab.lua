---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Menu.Objects.AnimationBuilderSection
local AnimationBuilderSection = require("Menu/Objects/AnimationBuilderSection")

---@module Menu.Objects.SoundBuilderSection
local SoundBuilderSection = require("Menu/Objects/SoundBuilderSection")

---@module Menu.Objects.EffectBuilderSection
local EffectBuilderSection = require("Menu/Objects/EffectBuilderSection")

---@module Menu.Objects.PartBuilderSection
local PartBuilderSection = require("Menu/Objects/PartBuilderSection")

---@module Game.Timings.AnimationTiming
local AnimationTiming = require("Game/Timings/AnimationTiming")

---@module Game.Timings.EffectTiming
local EffectTiming = require("Game/Timings/EffectTiming")

---@module Game.Timings.PartTiming
local PartTiming = require("Game/Timings/PartTiming")

---@module Game.Timings.SoundTiming
local SoundTiming = require("Game/Timings/SoundTiming")

---@module Game.Timings.ModuleManager
local ModuleManager = require("Game/Timings/ModuleManager")

---@module Features.Game.AnimationVisualizer
local AnimationVisualizer = require("Features/Game/AnimationVisualizer")

---@module GUI.Library
local Library = require("GUI/Library")

-- BuilderTab module.
local BuilderTab = {
	abs = nil,
	ebs = nil,
	pbs = nil,
	sbs = nil,
}

---Refresh builder lists.
function BuilderTab.refresh()
	if BuilderTab.abs then
		BuilderTab.abs:reset()
		BuilderTab.abs:refresh()
	end

	if BuilderTab.ebs then
		BuilderTab.ebs:reset()
		BuilderTab.ebs:refresh()
	end

	if BuilderTab.pbs then
		BuilderTab.pbs:reset()
		BuilderTab.pbs:refresh()
	end

	if BuilderTab.sbs then
		BuilderTab.sbs:reset()
		BuilderTab.sbs:refresh()
	end
end

---Initialize save manager section.
---@param groupbox table
function BuilderTab.initSaveManagerSection(groupbox)
	local pasToggle = groupbox:AddToggle("PeriodicAutoSave", {
		Text = "Auto Save Periodically",
		Default = true,
	})

	local pasDepBox = groupbox:AddDependencyBox()

	pasDepBox:AddSlider("PeriodicAutoSaveInterval", {
		Text = "Auto Save Interval",
		Min = 1,
		Max = 240,
		Rounding = 0,
		Suffix = "s",
		Default = 60,
	})

	pasDepBox:SetupDependencies({
		{ pasToggle, true },
	})

	local configName = groupbox:AddInput("ConfigName", {
		Text = "Config Name",
	})

	local configList = groupbox:AddDropdown("ConfigList", {
		Text = "Config List",
		Values = SaveManager.list(),
		AllowNull = true,
	})

	groupbox
		:AddButton("Create Config", function()
			SaveManager.create(configName.Value)
			SaveManager.refresh(configList)
		end)
		:AddButton({
			Text = "Load Config",
			DoubleClick = true,
			Func = function()
				SaveManager.load(configList.Value)
				BuilderTab.refresh()
			end,
		})

	groupbox:AddButton({
		Text = "Overwrite Config",
		DoubleClick = true,
		Func = function()
			SaveManager.save(configList.Value)
		end,
	})

	groupbox:AddButton({
		Text = "Clear Config",
		DoubleClick = true,
		Func = function()
			SaveManager.clear(configList.Value)
		end,
	})

	groupbox:AddButton("Refresh List", function()
		SaveManager.refresh(configList)

		if Options.MergeConfigList then
			SaveManager.refresh(Options.MergeConfigList)
		end

		BuilderTab.refresh()
	end)

	groupbox:AddButton("Set To Auto Load", function()
		SaveManager.autoload(configList.Value)
	end)
end

---Initialize merge manager section.
---@param groupbox table
function BuilderTab.initMergeManagerSection(groupbox)
	local configList = groupbox:AddDropdown("MergeConfigList", {
		Text = "Config List",
		Values = SaveManager.list(),
		AllowNull = true,
	})

	local mergeConfigType = groupbox:AddDropdown("MergeConfigType", {
		Text = "Merge Type",
		Values = { "Add New Timings", "Overwrite and Add Everything" },
		Default = 1,
	})

	groupbox:AddButton({
		Text = "Merge With Current Config",
		DoubleClick = true,
		Func = function()
			SaveManager.merge(configList.Value, mergeConfigType.Value)
		end,
	})
end

---Initialize global changes section.
---@param groupbox table
function BuilderTab.initGlobalChangesSection(groupbox)
	local shfo = groupbox:AddToggle("SetHitboxFacingOffset", {
		Text = "Set Hitbox Facing Offset",
		Default = false,
	})

	groupbox:AddButton("Apply Changes", function()
		---@type AnimationTiming
		for _, timing in next, SaveManager.as:list() do
			timing.fhb = shfo.Value
		end
	end)
end

---Initialize logger section.
---@param groupbox table
function BuilderTab.initLoggerSection(groupbox)
	local animVisualizerToggle = groupbox:AddToggle("ShowAnimationVisualizer", {
		Text = "Show Animation Visualizer",
		Default = false,
		Callback = AnimationVisualizer.visible,
	})

	animVisualizerToggle:AddKeyPicker(
		"AnimationVisualizerKeyBind",
		{ Default = "N/A", SyncToggleState = true, Text = "Animation Visualizer" }
	)

	local showLoggerToggle = groupbox:AddToggle("ShowLoggerWindow", {
		Text = "Show Logger Window",
		Default = false,
		Callback = function(value)
			Library.InfoLoggerFrame.Visible = value
		end,
	})

	showLoggerToggle:AddKeyPicker(
		"ShowLoggerWindowKeyBind",
		{ Default = "N/A", SyncToggleState = true, Text = "Logger Window" }
	)

	groupbox:AddSlider("MinimumLoggerDistance", {
		Text = "Minimum Logger Distance",
		Min = 0,
		Max = 100,
		Rounding = 0,
		Suffix = "m",
		Default = 0,
	})

	groupbox:AddSlider("MaximumLoggerDistance", {
		Text = "Maximum Logger Distance",
		Min = 0,
		Max = 1000,
		Rounding = 0,
		Suffix = "m",
		Default = 0,
	})

	local blacklistedKeys = groupbox:AddDropdown("BlacklistedKeys", {
		Text = "Blacklisted Keys",
		Default = {},
		Values = Library:KeyBlacklists(),
		Multi = true,
	})

	groupbox:AddButton("Remove Selected Keys", function()
		for selected, _ in next, blacklistedKeys.Value do
			Library.InfoLoggerData.KeyBlacklistList[selected] = nil
		end

		blacklistedKeys:SetValues(Library:KeyBlacklists())
		blacklistedKeys:SetValue({})
		blacklistedKeys:Display()
	end)
end

---Initialize Module Manager section.
---@param groupbox table
function BuilderTab.initModuleManagerSection(groupbox)
	local moduleList = groupbox:AddDropdown("ModuleList", {
		Text = "Module List",
		Values = ModuleManager.loaded(),
		AllowNull = true,
		Multi = false,
	})

	groupbox:AddButton("Refresh List", function()
		-- Refresh manager.
		ModuleManager.refresh()

		-- Set loaded modules.
		moduleList:SetValues(ModuleManager.loaded())
		moduleList:SetValue(nil)
		moduleList:Display()
	end)
end

---Initialize tab.
---@param window table
function BuilderTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Builder")

	-- Initialize sections.
	BuilderTab.initSaveManagerSection(tab:AddDynamicGroupbox("Save Manager"))
	BuilderTab.initMergeManagerSection(tab:AddDynamicGroupbox("Merge Manager"))
	BuilderTab.initModuleManagerSection(tab:AddDynamicGroupbox("Module Manager"))
	BuilderTab.initLoggerSection(tab:AddDynamicGroupbox("Logger"))
	BuilderTab.initGlobalChangesSection(tab:AddDynamicGroupbox("Global Changes"))

	-- Create builder sections.
	BuilderTab.abs =
		AnimationBuilderSection.new("Animation", tab:AddDynamicTabbox(), SaveManager.as, AnimationTiming.new())
	BuilderTab.pbs = PartBuilderSection.new("Part", tab:AddDynamicTabbox(), SaveManager.ps, PartTiming.new())
	BuilderTab.ebs = EffectBuilderSection.new("Effect", tab:AddDynamicTabbox(), SaveManager.es, EffectTiming.new())
	BuilderTab.sbs = SoundBuilderSection.new("Sound", tab:AddDynamicTabbox(), SaveManager.ss, SoundTiming.new())

	-- Initialize builder sections.
	BuilderTab.abs:init()
	BuilderTab.ebs:init()
	BuilderTab.pbs:init()
	BuilderTab.sbs:init()
end

-- Return CombatTab module.
return BuilderTab
