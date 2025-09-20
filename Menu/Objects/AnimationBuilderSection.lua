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
---@param timing AnimationTiming
function AnimationBuilderSection:exload(timing)
	self.animationId:SetRawValue(timing._id)
	self.repeatUntilParryEnd:SetRawValue(timing.rpue)
	self.repeatStartDelay:SetRawValue(timing._rsd)
	self.repeatParryDelay:SetRawValue(timing._rpd)
	self.hyperarmor:SetRawValue(timing.ha)
	self.ignoreAnimationEnd:SetRawValue(timing.iae)
	self.ignoreEarlyAnimationEnd:SetRawValue(timing.ieae)
	self.maxAnimationTimeout:SetRawValue(timing.mat)
	self.pastHitboxDetection:SetRawValue(timing.phd)
	self.predictFacingHitboxes:SetRawValue(timing.pfh)
	self.historySeconds:SetRawValue(timing.phds)
	self.extrapolationTime:SetRawValue(timing.pfht)
end

---Reset the elements. Extend me.
function AnimationBuilderSection:reset()
	BuilderSection.reset(self)
	self.animationId:SetRawValue("")
	self.repeatParryDelay:SetRawValue(0)
	self.repeatStartDelay:SetRawValue(0)
	self.repeatUntilParryEnd:SetRawValue(false)
	self.hyperarmor:SetRawValue(false)
	self.hitboxFacingOffset:SetRawValue(true)
	self.ignoreAnimationEnd:SetRawValue(false)
	self.ignoreEarlyAnimationEnd:SetRawValue(false)
	self.maxAnimationTimeout:SetRawValue(2000)
	self.pastHitboxDetection:SetRawValue(false)
	self.historySeconds:SetRawValue(0.5)
	self.predictFacingHitboxes:SetRawValue(false)
	self.extrapolationTime:SetRawValue(0.15)
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

	local timing = self.pair:index(self.animationId.Value)
	if timing then
		return Logger.longNotify("The timing ID '%s' (%s) is already in the list.", self.animationId.Value, timing.name)
	end

	return true
end

---Set creation timing properties. Override me.
---@param timing AnimationTiming
function AnimationBuilderSection:cset(timing)
	timing.name = self.timingName.Value
	timing._id = self.animationId.Value
end

---Create new timing. Override me.
---@return Timing
function AnimationBuilderSection:create()
	local timing = AnimationTiming.new()
	self:cset(timing)
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

	self.ignoreAnimationEnd = tab:AddToggle(nil, {
		Text = "Ignore Animation End",
		Tooltip = "Should the timing ignore the end of the animation?",
		Default = false,
		Callback = self:tnc(function(timing, value)
			timing.iae = value
		end),
	})

	local depBoxEnd = tab:AddDependencyBox()

	self.maxAnimationTimeout = depBoxEnd:AddInput(nil, {
		Text = "Max Animation Timeout",
		Tooltip = "The maximum time (in milliseconds) that the animation is allowed to run with no end check.",
		Default = 2000,
		Numeric = true,
		Callback = self:tnc(function(timing, value)
			timing.mat = tonumber(value)
		end),
	})

	depBoxEnd:SetupDependencies({
		{ self.ignoreAnimationEnd, true },
	})

	self.ignoreEarlyAnimationEnd = tab:AddToggle(nil, {
		Text = "Ignore Early Animation End",
		Tooltip = "Should the timing ignore the early end of the animation?",
		Default = false,
		Callback = self:tnc(function(timing, value)
			timing.ieae = value
		end),
	})

	self.pastHitboxDetection = tab:AddToggle(nil, {
		Text = "Past Hitbox Detection",
		Default = false,
		Tooltip = "Should the hitbox detection track the past hitboxes too?",
		Callback = self:tnc(function(timing, value)
			timing.phd = value
		end),
	})

	local pfdOffDepBox = tab:AddDependencyBox()

	self.historySeconds = pfdOffDepBox:AddSlider(nil, {
		Text = "History Seconds",
		Tooltip = "How far back in seconds should we fetch history?",
		Default = 0.5,
		Min = 0,
		Max = 3.0,
		Rounding = 2,
		Numeric = true,
		Callback = self:tnc(function(timing, value)
			timing.phds = tonumber(value) or 0
		end),
	})

	pfdOffDepBox:SetupDependencies({
		{ self.pastHitboxDetection, true },
	})

	self.predictFacingHitboxes = tab:AddToggle(nil, {
		Text = "Predict Facing Hitboxes",
		Default = false,
		Tooltip = "Should we make a prediction on the facing direction and make a hitbox on that?",
		Callback = self:tnc(function(timing, value)
			timing.pfh = value
		end),
	})

	self.disablePrediction = tab:AddToggle(nil, {
		Text = "Disable Prediction",
		Default = false,
		Tooltip = "Should we disable prediction?",
		Callback = self:tnc(function(timing, value)
			timing.dp = value
		end),
	})

	self.extrapolationTime = tab:AddSlider(nil, {
		Text = "Extrapolation Time",
		Tooltip = "The time (in seconds) to extrapolate by.",
		Default = 0.15,
		Min = 0,
		Max = 2.0,
		Rounding = 3,
		Numeric = true,
		Callback = self:tnc(function(timing, value)
			timing.pfht = tonumber(value)
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
		Numeric = true,
		Finished = true,
		Callback = self:tnc(function(timing, value)
			timing._rsd = tonumber(value) or 0
		end),
	})

	self.repeatParryDelay = depBoxOn:AddInput(nil, {
		Text = "Repeat Parry Delay",
		Numeric = true,
		Finished = true,
		Callback = self:tnc(function(timing, value)
			timing._rpd = tonumber(value) or 0
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
