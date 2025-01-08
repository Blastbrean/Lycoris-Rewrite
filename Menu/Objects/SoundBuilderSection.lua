---@module Menu.Objects.BuilderSection
local BuilderSection = require("Menu/Objects/BuilderSection")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@class SoundBuilderSection: BuilderSection
---@field soundId table
---@field repeatStartDelay table
---@field repeatUntilParryEnd table
---@field repeatParryDelay table
---@field timing SoundTiming
local SoundBuilderSection = setmetatable({}, { __index = BuilderSection })
SoundBuilderSection.__index = SoundBuilderSection

---Check before writing.
---@return boolean
function SoundBuilderSection:check()
	if not self.soundId.Value or #self.soundId.Value <= 0 then
		return Logger.longNotify("Please enter a valid sound ID.")
	end

	local found = self.pair:config().timings[self.soundId.Value]

	if found then
		return Logger.longNotify("The timing '%s' already has the same sound ID.", found.name)
	end

	return true
end

---Add extra elements to the builder tab.
---@param tab table
function SoundBuilderSection:extra(tab)
	self.soundId = tab:AddInput(nil, {
		Text = "Sound ID",
	})
end

---Initialize action tab.
function SoundBuilderSection:action()
	local tab = self.tabbox:AddTab("Action")

	self.repeatUntilParryEnd = tab:AddToggle(nil, {
		Text = "Repeat Parry Until End",
		Default = false,
	})

	local depBoxOn = tab:AddDependencyBox()

	self.repeatStartDelay = depBoxOn:AddInput(nil, {
		Text = "Repeat Start Delay",
		Default = false,
	})

	self.repeatParryDelay = depBoxOn:AddInput(nil, {
		Text = "Repeat Parry Delay",
		Numeric = true,
	})

	local depBoxOff = tab:AddDependencyBox()

	self:baction(depBoxOff)

	depBoxOn:SetupDependencies({
		{ self.repeatUntilParryEnd, true },
	})

	depBoxOff:SetupDependencies({
		{ self.repeatUntilParryEnd, false },
	})
end

---Load the timing.
---@param timing SoundTiming
function SoundBuilderSection:load(timing)
	BuilderSection.load(self, timing)

	self.soundId:SetValue(timing._id)
	self.repeatUntilParryEnd:SetValue(timing.rpue)
	self.repeatStartDelay:SetValue(timing.rsd)
	self.repeatParryDelay:SetValue(timing.rpd)
end

---Write to the current timing.
function SoundBuilderSection:write()
	BuilderSection.write(self)

	self.timing._id = self.soundId.Value
	self.timing.rpue = self.repeatUntilParryEnd.Value
	self.timing.rsd = self.repeatStartDelay.Value
	self.timing.rpd = self.repeatParryDelay.Value
end

---Create new SoundBuilderSection object.
---@param name string
---@param tabbox table
---@param pair TimingContainerPair
---@param timing SoundTiming
---@return SoundBuilderSection
function SoundBuilderSection.new(name, tabbox, pair, timing)
	return setmetatable(BuilderSection.new(name, tabbox, pair, timing), SoundBuilderSection)
end

-- Return SoundBuilderSection module.
return SoundBuilderSection
