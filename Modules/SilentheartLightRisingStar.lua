---@class Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = 300
	action._type = "Parry"
	action.hitbox = Vector3.new(20, 20, 35)
	action.name = string.format("(%.2f) Rising Star Silentheart Timing", self.track.Speed)
	self:action(timing, action)
end
