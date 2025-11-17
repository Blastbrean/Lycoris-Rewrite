---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Mantra
local Mantra = getfenv().Mantra

---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = getfenv().RepeatInfo

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Mantra.data(self.entity, "Mantra:CarveWind{{Wind Carve}}")
	local range = data.stratus * 1.4 + data.cloud * 0.9

	timing.ffh = true
	timing.fhb = true
	timing.rpue = false

	local action = Action.new()
	action._when = 400
	action._type = "Start Block"
	action.hitbox = Vector3.new(18 + range, 15 + range, 15 + range)
	action.name = "Wind Carve Start"
	self:action(timing, action)

	local actionEnd = Action.new()
	actionEnd._when = 1500
	actionEnd._type = "End Block"
	actionEnd.name = "Wind Carve End"
	return self:action(timing, actionEnd)
end
