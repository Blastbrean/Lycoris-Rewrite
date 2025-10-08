---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Mantra.data(self.entity, "Mantra:RepulsionFire{{Flame Repulsion}}")
	local range = data.stratus * 14 + data.cloud * 10

	local action = Action.new()
	action._when = 100
	action._type = "Parry"
	action.hitbox = Vector3.new(32 + range, 32 + range, 32 + range)
	action.name = "Dynamic Flame Repulsion Timing"

	timing.hitbox = action.hitbox

	self:action(timing, action)
end
