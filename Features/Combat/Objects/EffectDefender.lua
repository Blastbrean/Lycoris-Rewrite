---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Features.Combat.Targeting
local Targeting = require("Features/Combat/Targeting")

---@class EffectDefender: Defender
---@field owner Model The owner of the effect.
---@field name string The name of the effect.
local EffectDefender = setmetatable({}, { __index = Defender })
EffectDefender.__index = EffectDefender
EffectDefender.__type = "EffectDefender"

-- Services.
local players = game:GetService("Players")

---Override notify to include type.
---@param timing Timing
---@param str string
function EffectDefender:notify(timing, str, ...)
	Defender.notify(self, timing, string.format("[Effect] %s", str), ...)
end

---Check if we're in a valid state to proceed with the action.
---@param timing PartTiming
---@param action Action
---@return boolean
function EffectDefender:valid(timing, action)
	if not Targeting.find(self.owner) then
		return self:notify(timing, "Not a viable target.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return self:notify(timing, "No character found.")
	end

	if not self:hitbox(self.part.Position, action.hitbox, { character }) then
		return self:notify(timing, "Not inside of the hitbox.")
	end

	return true
end

---Check if the initial state is valid.
---@param timing SoundTiming
---@return boolean
function EffectDefender:initial(timing)
	local entRootPart = self.owner:FindFirstChild("HumanoidRootPart")
	if not entRootPart then
		return false
	end

	local localCharacter = players.LocalPlayer.Character
	if not localCharacter then
		return false
	end

	local localRootPart = localCharacter:FindFirstChild("HumanoidRootPart")
	if not localRootPart then
		return false
	end

	local distance = (entRootPart.Position - localRootPart.Position).Magnitude

	if distance < timing.imdd then
		return false
	end

	if distance > timing.imxd then
		return false
	end

	return true
end

---Process sound playing
function EffectDefender:process()
	local timing = SaveManager.es:index(self.name)
	if not timing then
		return
	end

	if not self:initial(timing) then
		return
	end

	---@note: Clean up previous tasks that are still waiting or suspended because they're in a different track.
	self:clean()

	-- Add actions.
	return self:actions(timing)
end

---Create new EffectDefender object.
---@param name string
---@param owner Model
---@return EffectDefender
function EffectDefender.new(name, owner)
	local self = setmetatable(Defender.new(), {})
	self.name = name
	self.owner = owner
	return self
end

-- Return EffectDefender module.
return EffectDefender
