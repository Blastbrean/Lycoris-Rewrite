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

-- BuilderTab module.
local BuilderTab = {}

---Initialize save manager section.
---@param groupbox table
function BuilderTab.initSaveManagerSection(groupbox)
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
		Text = "Delete Config",
		DoubleClick = true,
		Func = function()
			SaveManager.delete(configList.Value)
			SaveManager.refresh(configList)
		end,
	})

	groupbox:AddButton("Refresh List", function()
		SaveManager.refresh(configList)
	end)

	groupbox:AddButton("Set To Auto Load", function()
		SaveManager.autoload(configList.Value)
	end)
end

---Initialize merge manager section.
---@param groupbox table
function BuilderTab.initMergeManagerSection(groupbox)
	local configList = groupbox:AddDropdown("ConfigList", {
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

---Initialize logger section.
---@param groupbox table
function BuilderTab.initLoggerSection(groupbox)
	groupbox:AddToggle("Show Logger Window", {
		Text = "Show Logger Window",
		Default = false,
	})
end

---Initialize tab.
---@param window table
function BuilderTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Builder")

	-- Initialize sections.
	BuilderTab.initSaveManagerSection(tab:AddDynamicGroupbox("Save Manager"))
	BuilderTab.initMergeManagerSection(tab:AddDynamicGroupbox("Merge Manager"))
	BuilderTab.initLoggerSection(tab:AddDynamicGroupbox("Logger"))

	-- Initialize builder tabboxes.
	local atb = tab:AddDynamicTabbox()
	local etb = tab:AddDynamicTabbox()
	local ptb = tab:AddDynamicTabbox()
	local stb = tab:AddDynamicTabbox()

	-- Initalize builder sections.
	AnimationBuilderSection.new("Animation", atb, SaveManager.as, AnimationTiming.new()):init()
	EffectBuilderSection.new("Effect", etb, SaveManager.es, EffectTiming.new()):init()
	PartBuilderSection.new("Part", ptb, SaveManager.ps, PartTiming.new()):init()
	SoundBuilderSection.new("Sound", stb, SaveManager.ss, SoundTiming.new()):init()
end

-- Return CombatTab module.
return BuilderTab
