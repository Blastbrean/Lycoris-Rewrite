---@module Modules.Globals.Weapon
local Weapon = getfenv().Weapon
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Weapon.action(self.entity, 325 * 1.11, true)
	if not action then
		return
	end

	action.name = "Dynamic Legion Mastery Swing"

	if self.entity.Name:match(".titus") then
		local speed = self.track.Speed
		local action = Action.new()

		action._type = "Parry"
		action.hitbox = Vector3.new(25, 20, 20)
		action.name = string.format("(%.2f) Dynamic Titus Punch Timing", self.track.Speed, speed)
		action._when = 530
		if self.track.Speed >= 0.4 and self.track.Speed <= 0.55 then
			action._type = "Dodge"
			action._when = 470
		end
		return self:action(timing, action)
	end
end
