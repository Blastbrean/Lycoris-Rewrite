---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Mantra.data(self.entity, "Mantra:BlastWind{{Air Force}}")
	local range = data.perfect * 8 + data.crystal * 6
	local size = data.stratus * 1.5 + data.cloud * 1

	local action = Action.new()
	action._when = 0
	action._type = "Parry"
	action.hitbox = Vector3.new(20 + size, 20 + size, 50 + range)
	action.name = "Dynamic Air Force Timing"

	timing.ffh = true

	self:action(timing, action)
end
