---@module Modules.Globals.Weapon
local Weapon = getfenv().Weapon

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Weapon.action(self.entity, 325 * 1.11, true)
	if not action then
		return
	end

	action.name = "Dynamic Legion Swing"

	if self.entity.Name:match(".titus") then
		action.hitbox = action.hitbox * 1.15

		action._when = (530 * 0.49) / self.track.Speed

		action.name = string.format("(%.2f) Dynamic Titus Timing", self.track.Speed)
		if self.track.Speed >= 0.5 and self.track.Speed <= 0.6 then
			action._type = "Dodge"
			action._when = 470
		end
	end

	return self:action(timing, action)
end
