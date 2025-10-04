---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = 1200
	if self.track.Speed >= 1.05 then
		action._when = 900
	end
	action._type = "Parry"
	action.hitbox = Vector3.new(50, 50, 50)
	action.name = string.format("(%.2f) Dynamic Relentless SH Timing", self.track.Speed)
	self:action(timing, action)
end
