---@class Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	timing.pfh = true

	local action = Action.new()
	action._when = 500

	if self.track.speed >= 0.8 then
		action._when = 400
	end

	action._type = "Parry"
	action.hitbox = Vector3.new(20, 15, 45)
	action.name = string.format("(%.2f) Mayhem Silentheart Timing", self.track.Speed)
	self:action(timing, action)
end
