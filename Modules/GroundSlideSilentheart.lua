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

	local ispeed = self.track.Speed

	repeat
		task.wait()
	until self.track.Speed ~= ispeed

	local action = Action.new()
	action._when = 300 / self.track.Speed
	action._type = "Parry"
	action.hitbox = Vector3.new(40, 10, 40)
	action.name = string.format("(%.2f) Ground Slide Silentheart Timing", self.track.Speed)
	self:action(timing, action)
end
