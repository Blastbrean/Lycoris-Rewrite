---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local distance = self:distance(self.entity)
	local action = Action.new()
	action._when = 500
	action._type = "Parry"
	action.hitbox = Vector3.new(14, 15, 15)
	action.name = string.format("(%.2f) Strong Left Timing", distance)

	if self.entity.Name:match(".theduke") then
		action.ihbc = true
		action.name = string.format("(%.2f) Duke Strong Left Timing", self.track.Speed)
	end

	return self:action(timing, action)
end
