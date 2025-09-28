---@class Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = 1100
	if self.track.Speed >= 1.15 and self.track.Speed <= 1.26 then
		action._when = 900
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(28, 28, 28)
	action.name = string.format("(%.2f) Relentless Silentheart Timing", self.track.Speed)
	self:action(timing, action)
end
