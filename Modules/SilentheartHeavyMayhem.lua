---@class Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = (700 * 1.00) / self.track.Speed
	action._type = "Parry"
	action.hitbox = Vector3.new(20, 20, 50)
	action.name = string.format("(%.2f) Mayhem Silentheart Timing", self.track.Speed)
	self:action(timing, action)
end
