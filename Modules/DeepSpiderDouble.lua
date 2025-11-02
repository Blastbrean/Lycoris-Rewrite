---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = 400
	action._type = "Parry"
	action.hitbox = Vector3.new(40, 40, 40)
	action.name = string.format("(%.2f) Dynamic Spider Double Stab Timing", self.track.Speed)

	if self.entity.Name:match(".miniwidow") then
		action.hitbox /= 4
	end
	self:action(timing, action)
end
