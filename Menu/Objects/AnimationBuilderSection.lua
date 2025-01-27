---@module Menu.Objects.BuilderSection
local BuilderSection = require("Menu/Objects/BuilderSection")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Game.Timings.AnimationTiming
local AnimationTiming = require("Game/Timings/AnimationTiming")

---@class AnimationBuilderSection: BuilderSection
---@field animationId table
---@field repeatStartDelay table
---@field repeatUntilParryEnd table
---@field repeatParryDelay table
---@field timing AnimationTiming
local AnimationBuilderSection = setmetatable({}, { __index = BuilderSection })
AnimationBuilderSection.__index = AnimationBuilderSection

---Create timing ID element. Override me.
---@param tab table
function AnimationBuilderSection:tide(tab)
	self.animationId = tab:AddInput(nil, {
		Text = "Animation ID",
	})
end

---Load the extra elements. Override me.
---@param timing Timing
function AnimationBuilderSection:exload(timing)
	self.animationId:SetRawValue(timing._id)
	self.repeatUntilParryEnd:SetRawValue(timing.rpue)
	self.repeatStartDelay:SetRawValue(timing._rsd)
	self.repeatParryDelay:SetRawValue(timing._rpd)
	self.hyperarmor:SetRawValue(timing.ha)
end

---Reset the elements. Extend me.
function AnimationBuilderSection:reset()
	BuilderSection.reset(self)
	self.animationId:SetRawValue("")
	self.repeatParryDelay:SetRawValue(0)
	self.repeatStartDelay:SetRawValue(0)
	self.repeatUntilParryEnd:SetRawValue(false)
	self.hyperarmor:SetRawValue(false)
end

---Check before creating new timing. Override me.
---@return boolean
function AnimationBuilderSection:check()
	if not BuilderSection.check(self) then
		return false
	end

	if not self.animationId.Value or #self.animationId.Value <= 0 then
		return Logger.longNotify("Please enter a valid animation ID.")
	end

	if self.pair:index(self.animationId.Value) then
		return Logger.longNotify("The timing ID '%s' is already in the list.", self.animationId.Value)
	end

	return true
end

---Create new timing. Override me.
---@return Timing
function AnimationBuilderSection:create()
	local timing = AnimationTiming.new()
	timing.name = self.timingName.Value
	timing._id = self.animationId.Value
	return timing
end

---Initialize extra tab.
---@param tab table
function AnimationBuilderSection:extra(tab)
	self.hyperarmor = tab:AddToggle(nil, {
		Text = "Hyperarmor Flag",
		Tooltip = "Is this timing not able to be interrupted by attacks during the animation?",
		Default = false,
		Callback = self:tnc(function(timing, value)
			timing.ha = value
		end),
	})
end

---Initialize action tab.
function AnimationBuilderSection:action()
	local tab = self.tabbox:AddTab("Action")

	self.repeatUntilParryEnd = tab:AddToggle(nil, {
		Text = "Repeat Parry Until End",
		Default = false,
		Callback = self:tnc(function(timing, value)
			timing.rpue = value
		end),
	})

	local depBoxOn = tab:AddDependencyBox()

	self.repeatStartDelay = depBoxOn:AddInput(nil, {
		Text = "Repeat Start Delay",
		Default = false,
		Callback = self:tnc(function(timing, value)
			timing._rsd = value
		end),
	})

	self.repeatParryDelay = depBoxOn:AddInput(nil, {
		Text = "Repeat Parry Delay",
		Numeric = true,
		Callback = self:tnc(function(timing, value)
			timing._rpd = value
		end),
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

---Create new AnimationBuilderSection object.
---@param name string
---@param tabbox table
---@param pair TimingContainerPair
---@param timing AnimationTiming
---@return AnimationBuilderSection
function AnimationBuilderSection.new(name, tabbox, pair, timing)
	return setmetatable(BuilderSection.new(name, tabbox, pair, timing), AnimationBuilderSection)
end

-- Return AnimationBuilderSection module.
return AnimationBuilderSection
