---@module Game.Timings.Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local humanoidRootPart = self.entity:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	task.wait(0.1 - self.rtt())

	timing.iae = true

	if
		humanoidRootPart:FindFirstChild("REP_SOUND_3755634435")
		and not humanoidRootPart:FindFirstChild("REP_SOUND_16022272502")
		and not humanoidRootPart:FindFirstChild("REP_SOUND_16528213414")
	then
		local action = Action.new()
		action._when = 0
		action._type = "Start Block"
		action.hitbox = Vector3.new(45, 25, 45)
		action.name = "Float Start Block"
		self:action(timing, action)

		local secondAction = Action.new()
		secondAction._when = 850
		secondAction._type = "End Block"
		secondAction.name = "Float End Block"
		secondAction.ihbc = true
		return self:action(timing, secondAction)
	end

	local action = Action.new()
	action._when = 400
	action._type = "Parry"
	action.hitbox = Vector3.new(20, 20, 20)
	action.name = "Decimate Normal"
	self:action(timing, action)
end
