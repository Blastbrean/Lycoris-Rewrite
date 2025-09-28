---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Mantra.data(self.entity, "Mantra:GunShadow{{Shadow Gun}}")
	local range = data.perfect * 2 + data.crystal * 1
	local size = data.stratus * 2 + data.cloud * 1

	local action = Action.new()
	action._when = 300
	action._type = "Parry"
	action.hitbox = Vector3.new(5 + size, 5 + size, 20 + range)
	action.name = "Dynamic Shadow Gun Timing"

	if data.blast then
		action.hitbox = Vector3.new(action.hitbox.X * 2.0, action.hitbox.Y * 2.0, action.hitbox.Z)
	end

	timing.duih = true
	timing.hitbox = action.hitbox

	self:action(timing, action)
end
