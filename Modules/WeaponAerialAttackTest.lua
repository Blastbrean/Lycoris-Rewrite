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

	if data.type == "Dagger" then
		windup = (0.169 / self.track.Speed) + 0.120
	elseif data.type == "Greataxe" then
		windup = (0.168 / self.track.Speed) + 0.110
		windup += 0.100 * data.ss
	elseif data.type == "Sword" then
		windup = (0.18 / self.track.Speed) + 0.120
	end

	if not windup then
		return self:notify(timing, "(%s) No windup for this weapon type.", data.type)
	end

	-- Create action.
	local action = Action.new()
	action._when = windup * 1000
	action._type = "Parry"
	action.hitbox = Vector3.new(data.length * 2, data.length * 4, data.length * 2.5)
	action.name = string.format(
		"(%.2f, %.2f, %.2f) (%.2f) Dynamic Weapon Swing",
		data.oss,
		data.ss,
		self.track.Speed,
		data.length
	)

	return self:action(timing, action)
end
