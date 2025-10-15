---@class Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	timing.pfh = true

	local action = Action.new()
	action._when = math.min(400 + distance * 9.5)

	if self.track.Speed >= 0.7 then
		action._when = math.min(250 + distance * 9.5)
	end

	action._type = "Parry"
	action.hitbox = Vector3.new(20, 40, 32)
	action.name = string.format("(%.2f) Mayhem Silentheart Timing", self.track.Speed)
	self:action(timing, action)
end
