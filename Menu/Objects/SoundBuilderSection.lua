---@module Menu.Objects.BuilderSection
local BuilderSection = require("Menu/Objects/BuilderSection")

---@class SoundBuilderSection: BuilderSection
---@field soundId table
---@field repeatUntilParryEnd table
---@field repeatParryDelay table
---@field timing SoundTiming
local SoundBuilderSection = setmetatable({}, { __index = BuilderSection })
SoundBuilderSection.__index = SoundBuilderSection

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
	self.repeatParryDelay:SetValue(timing.rpd)
end

---Write to the current timing.
function SoundBuilderSection:write()
	BuilderSection.write(self)

	self.timing._id = self.animationId.Value
	self.timing.rpue = self.repeatUntilParryEnd.Value
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
