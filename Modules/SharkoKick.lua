---@class Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	if not self.entity.Name:match("mecha") then
		local action = Action.new()
		action._when = 530
		action._type = "Dodge"
		action.hitbox = Vector3.new(25, 70, 25)
		action.name = "Normal Kick Timing"
		return self:action(timing, action)
	end

	local action = Action.new()
	action._when = 0
	action._type = "Dodge"
	action.hitbox = Vector3.new(25, 70, 25)
	action.name = "Normal Kick Timing"

	local lastTimestamp = os.clock()

	while task.wait() do
		if (os.clock() - lastTimestamp) > (0.6 - self.rtt()) then
			break
		end

		if self.track.TimePosition < 0.2 or self.track.Speed ~= 0 then
			continue
		end

		action._when = 280
		action._type = "Dodge"
	end

	return self:action(timing, action)
end
