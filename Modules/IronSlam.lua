---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Mantra.data(self.entity, "Mantra:SmashMetal{{Iron Slam}}")
	local range = data.stratus * 4 + data.cloud * 2

	local action = Action.new()
	action._when = 530
	action._type = "Parry"
	action.hitbox = Vector3.new(24 + range, 24, 24 + range)
	action.name = "Dynamic Rapid Slashes Timing"
	self:action(timing, action)
end
