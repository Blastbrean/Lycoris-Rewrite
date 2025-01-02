---@module Menu.Objects.BuilderSection
local BuilderSection = require("Menu/Objects/BuilderSection")

---@class EffectBuilderSection: BuilderSection
---@field effectName table
---@field repeatUntilParryEnd table
---@field repeatParryDelay table
---@field timing EffectTiming
local EffectBuilderSection = setmetatable({}, { __index = BuilderSection })
EffectBuilderSection.__index = EffectBuilderSection

---Add extra elements to the builder tab.
---@param tab table
function EffectBuilderSection:extra(tab)
	self.effectName = tab:AddInput(nil, {
		Text = "Effect Name",
	})
end

---Initialize action tab.
function EffectBuilderSection:action()
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
---@param timing EffectTiming
function EffectBuilderSection:load(timing)
	BuilderSection.load(self, timing)

	self.effectName:SetValue(timing.ename)
	self.repeatUntilParryEnd:SetValue(timing.rpue)
	self.repeatParryDelay:SetValue(timing.rpd)
end

---Write to the current timing.
function EffectBuilderSection:write()
	BuilderSection.write(self)

	self.timing.ename = self.effectName.Value
	self.timing.rpue = self.repeatUntilParryEnd.Value
	self.timing.rpd = self.repeatParryDelay.Value
end

---Create new EffectBuilderSection object.
---@param name string
---@param tabbox table
---@param pair TimingContainerPair
---@param timing EffectTiming
---@return EffectBuilderSection
function EffectBuilderSection.new(name, tabbox, pair, timing)
	return setmetatable(BuilderSection.new(name, tabbox, pair, timing), EffectBuilderSection)
end

-- Return EffectBuilderSection module.
return EffectBuilderSection
