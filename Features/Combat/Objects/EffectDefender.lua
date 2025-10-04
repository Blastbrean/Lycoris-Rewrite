---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = require("Features/Combat/Objects/RepeatInfo")

---@module Features.Combat.Objects.HitboxOptions
local HitboxOptions = require("Features/Combat/Objects/HitboxOptions")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@class EffectDefender: Defender
---@field name string The name of the effect.
---@field data table The data of the effect.
local EffectDefender = setmetatable({}, { __index = Defender })
EffectDefender.__index = EffectDefender
EffectDefender.__type = "Effect"

-- Services.
local players = game:GetService("Players")

---Iteratively find effect owner from effect data.
---@param data table
---@return Model?
local findEffectOwner = LPH_NO_VIRTUALIZE(function(data)
	local live = workspace:FindFirstChild("Live")
	if not live then
		return
	end

	for _, value in next, data do
		if typeof(value) ~= "Instance" or value.Parent ~= live then
			continue
		end

		return value
	end
end)

---Check if we're in a valid state to proceed with the action.
---@param self EffectDefender
---@param timing PartTiming
---@param action Action
---@return boolean
EffectDefender.valid = LPH_NO_VIRTUALIZE(function(self, timing, action)
	if not Defender.valid(self, timing, action) then
		return false
	end

	local humanoidRootPart = self.owner:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return self:notify(timing, "No humanoid root part found.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return self:notify(timing, "No character found.")
	end

	if not self:target(self.owner) then
		return self:notify(timing, "Not a viable target.")
	end

	local options = HitboxOptions.new(humanoidRootPart, timing)
	options.spredict = false
	options.action = action

	if not self:hc(options, timing.duih and RepeatInfo.new(timing) or nil) then
		return self:notify(timing, "Not in hitbox.")
	end

	return true
end)

---Process effect.
---@param self EffectDefender
EffectDefender.process = LPH_NO_VIRTUALIZE(function(self)
	if not self.owner then
		return
	end

	if not Configuration.expectToggleValue("EnableAutoDefense") then
		return
	end

	---@type EffectTiming?
	local timing = self:initial(self.owner, SaveManager.es, self.owner.Name, self.name)
	if not timing then
		return
	end

	if timing.ilp and self.owner == players.LocalPlayer.Character then
		return
	end

	---@note: Clean up previous tasks that are still waiting or suspended because they're in a different track.
	self:clean()

	-- Handle module.
	if timing.umoa then
		return self:module(timing)
	end

	-- Add actions.
	return self:actions(timing)
end)

---Create new EffectDefender object.
---@param name string
---@param data table
---@param dao table
---@return EffectDefender
function EffectDefender.new(name, data, dao)
	local self = setmetatable(Defender.new(), EffectDefender)
	self.name = name
	self.data = data or {}
	self.owner = findEffectOwner(data)
	self:process()
	return self
end

-- Return EffectDefender module.
return EffectDefender
