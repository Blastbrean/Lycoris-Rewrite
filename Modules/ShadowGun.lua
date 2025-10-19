---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Mantra.data(self.entity, "Mantra:GunShadow{{Shadow Gun}}")
	local range = data.perfect * 5 + data.crystal * 2
	local size = data.stratus * 3 + data.cloud * 2

	local action = Action.new()
	action._when = 650
	action._type = "Parry"
	action.hitbox = Vector3.new(10 + size, 10 + size, 25 + range)
	action.name = "Dynamic Shadow Gun Timing"

	if data.blast then
		action.hitbox = Vector3.new(action.hitbox.X * 2.0, action.hitbox.Y * 2.0, action.hitbox.Z)
	end

	timing.iae = true
	timing.ieae = true
	timing.duih = false
	timing.mat = 1000
	timing.ffh = true

	self:action(timing, action)
end
