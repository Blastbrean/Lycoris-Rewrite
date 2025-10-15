---@class Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = self.track.Speed <= 1.0 and 350 or 300
	action._type = "Parry"
	action.hitbox = Vector3.new(15, 20, 27)
	action.name = string.format("(%.2f) Rising Star Silentheart Timing", self.track.Speed)
	self:action(timing, action)
end
