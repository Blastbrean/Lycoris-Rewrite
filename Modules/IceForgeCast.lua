---@type Action
local Action = getfenv().Action

---@type ProjectileTracker
---@diagnostic disable-next-line: unused-local
local ProjectileTracker = getfenv().ProjectileTracker

---Check if cubes have all been destroyed.
local function areCubesStillAlive(cubes)
	for _, cube in next, cubes do
		if not cube.Parent then
			continue
		end

		return true
	end

	return false
end

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local entity = self.entity
	if not entity then
		return
	end

	local hrp = entity:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	timing.iae = false

	if hrp:FindFirstChild("REP_SOUND_15214335898") then
		local action = Action.new()
		action._when = 0
		action._type = "Parry"
		action.hitbox = Vector3.new(30, 30, 30)
		action.name = "Storm Blades Timing"
		return self:action(timing, action)
	end

	task.wait(1.0 - self.rtt())

	if not hrp:FindFirstChild("REP_SOUND_13692212248") then
		return
	end

	local thrown = workspace:FindFirstChild("Thrown")
	if not thrown then
		return
	end

	local cubes = {}

	for _, part in pairs(thrown:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		if not part.Name:match("Cube") then
			continue
		end

		cubes[#cubes + 1] = part
	end

	local blockStarted = false

	timing.mat = 2000
	timing.iae = true

	while task.wait() do
		for _, cube in next, cubes do
			if not areCubesStillAlive(cubes) then
				local secondAction = Action.new()
				secondAction._when = 0
				secondAction._type = "End Block"
				secondAction.name = "Ice Cubes End"
				secondAction.ihbc = true
				return self:action(timing, secondAction)
			end

			if not cube or not cube.Parent then
				continue
			end

			if self:distance(cube) >= 20 then
				continue
			end

			if blockStarted then
				continue
			end

			local action = Action.new()
			action._when = 0
			action._type = "Start Block"
			action.name = "Ice Cubes Start"
			action.ihbc = true
			self:action(timing, action)

			blockStarted = true
		end
	end
end
