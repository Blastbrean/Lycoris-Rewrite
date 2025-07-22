---@class Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	if not self.entity.Name:match("mecha") then
		local action = Action.new()
		action._when = 500
		action._type = "Forced Full Dodge"
		action.hitbox = Vector3.new(20, 70, 20)
		action.name = "Normal Kick Timing"
		return self:action(timing, action)
	end

	local action = Action.new()
	action._when = 0
	action._type = "Dodge"
	action.hitbox = Vector3.new(20, 70, 20)
	action.name = "Normal Kick Timing"

	local lastTimestamp = os.clock()

	while task.wait() do
		if (os.clock() - lastTimestamp) > (0.6 - self:ping()) then
			break
		end

		if self.track.TimePosition < 0.2 or self.track.Speed ~= 0 then
			continue
		end

		action._when = 250
		action._type = "Parry"
	end

	return self:action(timing, action)
end
