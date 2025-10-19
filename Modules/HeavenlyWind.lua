---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local hrp = self.entity:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	-- vertical position
	local startVertical = hrp.Position.Y

	-- wait for normal move
	task.wait(0.35 - self.rtt())

	-- slam delay
	local slamDelta = math.abs(startVertical - hrp.Position.Y)
	local slamDelay = slamDelta >= 4 and 600 or 0

	-- slam
	local action = Action.new()
	action._when = slamDelay
	action._type = "Parry"
	action.hitbox = Vector3.new(30, 75, 55)
	action.name = string.format("(%.2f) Heavenly Wind Timing", slamDelta)

	if self.entity.Name:match(".evengarde") then
		action.hitbox = Vector3.new(55, 55, 55)
		action.name = string.format("(%.2f) Maestro Heavenly Wind Timing", slamDelta)
	end

	return self:action(timing, action)
end
