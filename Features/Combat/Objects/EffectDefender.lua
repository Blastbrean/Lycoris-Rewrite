---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Features.Combat.Targeting
local Targeting = require("Features/Combat/Targeting")

---@class EffectDefender: Defender
---@field owner Model The owner of the effect.
---@field name string The name of the effect.
---@field data table The data of the effect.
local EffectDefender = setmetatable({}, { __index = Defender })
EffectDefender.__index = EffectDefender
EffectDefender.__type = "Effect"

-- Services.
local players = game:GetService("Players")

---Check if we're in a valid state to proceed with the action.
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

	if not Targeting.find(self.owner) then
		return self:notify(timing, "Not a viable target.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return self:notify(timing, "No character found.")
	end

	if not self:hc(humanoidRootPart.CFrame, timing, action, { players.LocalPlayer.Character }, nil) then
		return false
	end

	return true
end)

---Process effect.
EffectDefender.process = LPH_NO_VIRTUALIZE(function(self)
	---@type EffectTiming?
	local timing = self:initial(self.owner, SaveManager.es, self.owner.Name, self.name)
	if not timing then
		return
	end

	if players.LocalPlayer.Character and self.owner == players.LocalPlayer.Character then
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
---@param owner Model
---@param data table
---@param dao table
---@return EffectDefender
function EffectDefender.new(name, owner, data, dao)
	local self = setmetatable(Defender.new(), EffectDefender)
	self.name = name
	self.owner = owner
	self.data = data or {}
	self:process()
	return self
end

-- Return EffectDefender module.
return EffectDefender
