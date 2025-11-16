---@type Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Mantra.data(self.entity, "Mantra:GunWind{{Wind Gun}}")

	task.wait(0.45 - self.rtt())

	local action = Action.new()
	action._when = self.track.Speed > 1.00 and 0 or 350
	action._type = "Parry"
	action.name = string.format("(%.2f) Dynamic Wind Gun Timing", self.track.Speed)
	action.hitbox = Vector3.new(25, 20, 60)

	if data.blast then
		action.hitbox = Vector3.new(action.hitbox.X, action.hitbox.Y, action.hitbox.Z / 2.2)
	end

	return self:action(timing, action)
end
