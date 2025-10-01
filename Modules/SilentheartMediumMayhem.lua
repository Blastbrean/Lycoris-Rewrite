---@class Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	timing.pfh = true

	local action = Action.new()
	action._when = (500 * 0.71) / self.track.Speed
	action._type = "Parry"
	action.hitbox = Vector3.new(10, 10, 50)
	action.name = string.format("(%.2f) Mayhem Silentheart Timing", self.track.Speed)
	self:action(timing, action)
end
