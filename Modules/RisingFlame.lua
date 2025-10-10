---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Mantra.data(self.entity, "Mantra:RisingSlashFire{{Rising Flame}}")
	local range = data.stratus * 3 + data.cloud * 2

	local action = Action.new()
	action._when = 400
	action._type = "Parry"
	action.hitbox = Vector3.new(25 + range, 25, 25 + range)
	action.name = "Dynamic Rising Flame Timing"

	timing.hitbox = action.hitbox

	self:action(timing, action)
end
