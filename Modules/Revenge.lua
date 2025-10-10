---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Mantra.data(self.entity, "Mantra:RevengeAgility{{Revenge}}")
	local range = data.rush * 12 + data.drift * 6
	timing.pfh = true

	local action = Action.new()
	action._when = 400
	action._type = "Parry"
	action.hitbox = Vector3.new(20, 20, 30 + range)
	action.name = "Dynamic Revenge Timing"
	self:action(timing, action)
end
