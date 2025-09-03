---@module Modules.Globals.Waiter
local Waiter = getfenv().Waiter

---@module Game.Timings.Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local entity = self.entity
	if not entity then
		return
	end

	-- Maestro for the gap closer attack.
	if self.entity.Name:match(".evengarde") then
		local action = Action.new()
		action._when = 290
		action._type = "Parry"
		action.hitbox = Vector3.new(100, 100, 100)
		action.name = "Gap Closer Maestro Timing"
		return self:action(timing, action)
	end

	local speed = Waiter.wfsc(self.track)
	local action = Action.new()
	action._when = 400 / speed
	action._type = "Parry"
	action.hitbox = Vector3.new(50, 10, 50)
	action.name = string.format("(%.2f) Ground Slide Silentheart Timing", speed)
	self:action(timing, action)
end
