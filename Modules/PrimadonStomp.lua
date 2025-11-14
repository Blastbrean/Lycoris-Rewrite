---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local action = Action.new()
	action._when = (750 * 1.21) / self.track.Speed
	action._type = "Parry"

	local hitbox = Vector3.new(50, 250, 50)

	if self.entity.Name:match(".monkyking") then
		hitbox = Vector3.new(80, 250, 80)
	end

	action.hitbox = hitbox
	action.name = string.format("(%.2f) Dynamic Primadon Timing", self.track.Speed)

	return self:action(timing, action)
end
