---@type PartTiming
local PartTiming = getfenv().PartTiming

---@type Action
local Action = getfenv().Action

---@type ProjectileTracker
---@diagnostic disable-next-line: unused-local
local ProjectileTracker = getfenv().ProjectileTracker

---Check if orbs have all been destroyed.
local function areOrbsStillParented(orbs)
	for _, orb in next, orbs do
		if not orb.Parent then
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
	local thrown = workspace:FindFirstChild("Thrown")
	if not thrown then
		return
	end

	local tracker = ProjectileTracker.new(function(candidate)
		return candidate.Name == "IntBangs"
	end)

	if self:distance(self.entity) <= 20 then
		local action = Action.new()
		action._when = 600
		action._type = "Start Block"
		action.name = "Close Ether Barrage Start"
		action.ihbc = true
		self:action(timing, action)

		local secondAction = Action.new()
		secondAction._when = 1000
		secondAction._type = "End Block"
		secondAction.name = "Close Ether Barrage End"
		secondAction.ihbc = true
		return self:action(timing, secondAction)
	end

	task.wait(0.7 - self.rtt())

	local model = tracker:wait()
	if not model then
		return
	end

	local orbs = {}

	for _, part in pairs(model:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		if not part.Name:match("etherorb") then
			continue
		end

		orbs[#orbs + 1] = part
	end

	local blockStarted = false

	while task.wait() do
		for _, orb in next, orbs do
			if not areOrbsStillParented(orbs) then
				local secondAction = Action.new()
				secondAction._when = 0
				secondAction._type = "End Block"
				secondAction.name = "Ether Barrage End"
				secondAction.ihbc = true
				return self:action(timing, secondAction)
			end

			if not orb or not orb.Parent then
				continue
			end

			if self:distance(orb) >= 30 then
				continue
			end

			if blockStarted then
				continue
			end

			local action = Action.new()
			action._when = 0
			action._type = "Start Block"
			action.name = "Ether Barrage Start"
			action.ihbc = true
			self:action(timing, action)

			blockStarted = true
		end
	end
end
