---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Mantra.data(self.entity, "Mantra:RevengeAgility{{Revenge}}")
	local action = Action.new()
	action._when = 400
	action._type = "Parry"
	action.hitbox = Vector3.new(15, 15, 30 + (data.drift * 10) + (data.rush * 5))
	action.name = "Dynamic Revenge Timing"
	self:action(timing, action)
end
