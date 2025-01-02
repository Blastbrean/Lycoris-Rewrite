---@module Menu.Objects.BuilderSection
local BuilderSection = require("Menu/Objects/BuilderSection")

---@class AnimationBuilderSection: BuilderSection
---@field animationId table
---@field repeatUntilParryEnd table
---@field repeatParryDelay table
---@field timing AnimationTiming
local AnimationBuilderSection = setmetatable({}, { __index = BuilderSection })
AnimationBuilderSection.__index = AnimationBuilderSection

---Add extra elements to the builder tab.
---@param tab table
function AnimationBuilderSection:extra(tab)
	self.animationId = tab:AddInput(nil, {
		Text = "Animation ID",
	})
end

---Initialize action tab.
function AnimationBuilderSection:action()
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
---@param timing AnimationTiming
function AnimationBuilderSection:load(timing)
	BuilderSection.load(self, timing)

	self.animationId:SetValue(timing._id)
	self.repeatUntilParryEnd:SetValue(timing.rpue)
	self.repeatParryDelay:SetValue(timing.rpd)
end

---Write to the current timing.
function AnimationBuilderSection:write()
	BuilderSection.write(self)

	self.timing._id = self.animationId.Value
	self.timing.rpue = self.repeatUntilParryEnd.Value
	self.timing.rpd = self.repeatParryDelay.Value
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
