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
		repeat
			task.wait()
		until self.track.TimePosition >= 0.52

		local action = Action.new()
		action._when = 150
		action._type = "Parry"
		action.hitbox = Vector3.new(15, 25, 20)
		action.name = string.format("(%.2f) Dynamic Titus Punch Timing", self.track.Speed)
		return self:action(timing, action)
	end
end
