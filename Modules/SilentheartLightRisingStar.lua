---@class Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = math.min(250 + distance * 4)
	action._type = "Parry"
	action.hitbox = Vector3.new(16, 20, 20)
	action.name = string.format("(%.2f) Rising Star Silentheart Timing", self.track.Speed)
	self:action(timing, action)
end
