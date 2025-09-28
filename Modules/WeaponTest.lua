---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Weapon
local Weapon = getfenv().Weapon

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Weapon.data(self.entity)
	if not data then
		return
	end

	local windup = nil

	-- Windup + 0-speed duration.

	if data.type == "Greataxe" and self.track.Speed ~= 1.0 then
		windup = (0.171 / self.track.Speed) + 0.120
	elseif data.type == "Greataxe" and self.track.Speed == 1.0 then
		windup = (0.171 / self.track.Speed) + 0.300
	elseif data.type == "Dagger" then
		windup = (0.195 / self.track.Speed) + 0.100
	elseif data.type == "Sword" then
		windup = (0.150 / self.track.Speed) + 0.150
	end

	if not windup then
		return self:notify(timing, "(%s) No windup for this weapon type.", data.type)
	end

	-- Create action.
	local action = Action.new()
	action._when = windup * 1000
	action._type = "Parry"
	action.hitbox = Vector3.new(data.length * 3, data.length * 3, data.length * 2)
	action.name = string.format(
		"(%.2f, %.2f, %.2f) (%.2f) Dynamic Weapon Swing",
		data.oss,
		data.ss,
		self.track.Speed,
		data.length
	)

	return self:action(timing, action)
end
