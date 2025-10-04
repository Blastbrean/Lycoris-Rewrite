---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = math.min(450 + (distance * 10), 750)
	action._type = "Parry"
	action.hitbox = Vector3.new(15, 15, 50)
	action.name = string.format("(%.2f) Dynamic Metal Ball Timing", distance)
	return self:action(timing, action)
end
