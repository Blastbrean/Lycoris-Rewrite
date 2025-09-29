---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)

	local action = Action.new()
	action._when = math.min(840 + distance * 6.5, 3000)
	action._type = "Jump"
	action.hitbox = Vector3.new(35, 35, 120)
	action.name = string.format("(%.2f) Dynamic Bonekeeper Bone Floor Timing", distance)

	return self:action(timing, action)
end
