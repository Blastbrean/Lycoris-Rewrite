-- Tweening module.
local Tweening = { active = false, queue = {} }

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

-- Services.
local players = game:GetService("Players")

---On update step. Queue gets processed from most recent to oldest.
---@param dt number
Tweening.update = LPH_NO_VIRTUALIZE(function(dt)
	Tweening.active = false

	local recent = Tweening.queue[#Tweening.queue]
	if not recent then
		return
	end

	local part = typeof(recent.goal) == "Instance" and recent.goal or nil
	if part and not part.Parent then
		return Tweening.stop(recent.identifier)
	end

	local localPlayer = players.LocalPlayer
	local character = localPlayer and localPlayer.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	Tweening.active = true

	local startPosition = humanoidRootPart.Position
	local targetCFrame = typeof(recent.goal) == "Instance" and recent.goal.CFrame or recent.goal
	local targetPosition = targetCFrame.Position

	local distanceToTarget = (targetPosition - startPosition).Magnitude

	if distanceToTarget <= 0.01 then
		return
	end

	local direction = (targetPosition - startPosition) / distanceToTarget
	local moveDistance = (Configuration.expectOptionValue("TweenStudsPerSecond") or 200) * dt

	if moveDistance > distanceToTarget then
		moveDistance = distanceToTarget
	end

	local newPosition = startPosition + (direction * moveDistance)
	local rotation = (targetCFrame - targetCFrame.Position)

	local _, _, _, m00, m01, m02, m10, m11, m12, m20, m21, m22 = rotation:GetComponents()

	-- We are never limited on the Y axis for tween studs.
	newPosition = Vector3.new(newPosition.X, targetPosition.Y, newPosition.Z)

	if
		m00 == m00
		or m01 == m01
		or m02 == m02
		or m10 == m10
		or m11 == m11
		or m12 == m12
		or m20 == m20
		or m21 == m21
		or m22 == m22
	then
		humanoidRootPart.CFrame = CFrame.new(newPosition) * rotation
	else
		humanoidRootPart.CFrame = CFrame.new(newPosition)
	end

	if not recent.swc then
		return
	end

	local newDistanceToTarget = (targetPosition - startPosition).Magnitude

	if newDistanceToTarget <= 1.0 then
		return Tweening.stop(recent.identifier)
	end
end)

---Get the tween data of an identifier.
---@param identifier string
---@return number, table?
function Tweening.get(identifier)
	for idx, data in next, Tweening.queue do
		if data.identifier ~= identifier then
			continue
		end

		return idx, data
	end

	return nil
end

---Set a goal to follow.
---@param identifier string
---@param goal BasePart|CFrame
---@param swc boolean? Whether or not to stop when we reach the goal.
function Tweening.goal(identifier, goal, swc)
	local _, data = Tweening.get(identifier)

	if data then
		data.goal = goal
		data.swc = swc
	else
		Tweening.queue[#Tweening.queue + 1] = { identifier = identifier, goal = goal, swc = swc }
	end
end

---Stop tweening.
---@param identifier string
function Tweening.stop(identifier)
	local idx, _ = Tweening.get(identifier)
	if not idx then
		return
	end

	table.remove(Tweening.queue, idx)
end

-- Return Tweening module.
return Tweening
