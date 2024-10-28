-- Movement related stuff is handled here.
local Movement = {}

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Maid
local Maid = require("Utility/Maid")

-- Services.
local runService = game:GetService("RunService")
local players = game:GetService("Players")

-- Maids.
local movementMaid = Maid.new()

-- Instances.
local attachTarget = nil

-- Signals.
local heartbeat = Signal.new(runService.Heartbeat)

---Find nearest entity within studs range.
---@param position Vector3
---@param studs number
---@return Model?
local function findNearestEntityWithinStuds(position, studs)
	local nearestEntity = nil
	local nearestDistance = studs

	local live = workspace:FindFirstChild("Live")
	if not live then
		return
	end

	for _, entity in pairs(live:GetChildren()) do
		if not entity:IsA("Model") then
			continue
		end

		local hrp = entity:FindFirstChild("HumanoidRootPart")
		if not hrp then
			continue
		end

		local distance = (hrp.Position - position).Magnitude
		if distance < nearestDistance then
			nearestEntity = entity
			nearestDistance = distance
		end
	end

	return nearestEntity
end

---Set attach target
---@param target Model?
local function setAttachTarget(target)
	attachTarget = target
end

---Update attach to back.
---@param rootPart BasePart
local function updateAttachToBack(rootPart)
	if not attachTarget then
		return setAttachTarget(findNearestEntityWithinStuds(rootPart.Position, 200))
	end

	local attachTargetHrp = attachTarget:FindFirstChild("HumanoidRootPart")
	if not attachTargetHrp then
		return setAttachTarget(nil)
	end

	rootPart.CFrame = rootPart.CFrame:Lerp(
		attachTargetHrp.CFrame * CFrame.new(0, Options.HeightOffset.Value, Options.BackOffset.Value),
		0.3
	)
end

---Update movement.
local function updateMovement()
	local localPlayer = players.LocalPlayer
	local character = localPlayer.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	if Toggles.AttachToBack.Value then
		updateAttachToBack(rootPart)
	else
		setAttachTarget(nil)
	end
end

---Initialize movement.
function Movement.init()
	movementMaid:add(heartbeat:connect("Movement_Heartbeat", updateMovement))
end

---Detach movement.
function Movement.detach()
	movementMaid:clean()
end

-- Return Movement module.
return Movement
