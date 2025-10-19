---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Mantra.data(self.entity, "Mantra:DashWeaponLight{{Rapid Slashes}}")
	local range = data.perfect * 2 + data.crystal * 1

	local action = Action.new()
	action._when = 400
	action._type = "Parry"
	action.hitbox = Vector3.new(40 + range, 15, 40 + range)
	action.name = "Dynamic Rapid Slashes Timing"

	timing.fhb = false
	timing.hitbox = action.hitbox

	self:action(timing, action)
end
