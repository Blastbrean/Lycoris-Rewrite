---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local data = Mantra.data(self.entity, "Mantra:BeamIce{{Ice Beam}}")
	local range = data.stratus * 2 + data.cloud * 1

	local action = Action.new()
	action._when = math.min(570 + distance * 5, 1000)
	action._type = "Parry"
	action.hitbox = Vector3.new(15 + range, 15 + range, 85)
	action.name = "Dynamic Ice Beam Timing"

	timing.hitbox = action.hitbox

	self:action(timing, action)
end
