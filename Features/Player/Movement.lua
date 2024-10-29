-- Movement related stuff is handled here.
local Movement = {}

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.InstanceWrapper
local InstanceWrapper = require("Utility/InstanceWrapper")

---@module Utility.ControlModule
local ControlModule = require("Utility/ControlModule")

-- Services.
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Maids.
local movementMaid = Maid.new()

-- Instances.
local attachTarget = nil
local originalCanCollideMap = {}

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

---Reset noclip.
local function resetNoClip()
	for instance, canCollide in pairs(originalCanCollideMap) do
		if not instance:IsA("BasePart") then
			continue
		end

		instance.CanCollide = canCollide
	end

	originalCanCollideMap = {}
end

---Update noclip.
---@param character Model
---@param rootPart BasePart
local function updateNoClip(character, rootPart)
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	local shouldCollide = false

	if effectReplicatorModule:FindEffect("Knocked") and Toggles.NoClipCollisionsKnocked.Value then
		shouldCollide = true
	end

	for _, instance in pairs(character:GetDescendants()) do
		if not instance:IsA("BasePart") then
			continue
		end

		if originalCanCollideMap[instance] then
			continue
		end

		originalCanCollideMap[instance] = instance.CanCollide

		instance.CanCollide = shouldCollide
	end
end

---Update speed hack.
---@param rootPart BasePart
---@param humanoid Humanoid
local function updateSpeedHack(rootPart, humanoid)
	if not humanoid then
		return
	end

	if Toggles.Fly.Value then
		return
	end

	rootPart.AssemblyAngularVelocity = rootPart.AssemblyAngularVelocity * Vector3.new(0, 1, 0)

	local moveDirection = humanoid.MoveDirection
	if moveDirection.Magnitude <= 0.001 then
		return
	end

	rootPart.AssemblyAngularVelocity = rootPart.AssemblyAngularVelocity + moveDirection.Unit * Options.Speedhack.Value
end

---Update infinite jump.
---@param rootPart BasePart
local function updateInfiniteJump(rootPart)
	if Toggles.Fly.Value then
		return
	end

	if not userInputService:IsKeyDown(Enum.KeyCode.Space) then
		return
	end

	local manipulationInst = rootPart:FindFirstChildOfClass("BodyVelocity")
		or rootPart:FindFirstChildOfClass("BodyPosition")

	if manipulationInst and manipulationInst ~= movementMaid["FlyBodyVelocity"] then
		manipulationInst.Parent = nil
	end

	rootPart.AssemblyAngularVelocity = rootPart.AssemblyAngularVelocity * Vector3.new(0, 1, 0)
	rootPart.AssemblyAngularVelocity = rootPart.AssemblyAngularVelocity
		+ Vector3.new(0, Options.InfiniteJumpBoost.Value, 0)
end

---Update fly hack.
---@param rootPart BasePart
local function updateFlyHack(rootPart)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local flyBodyVelocity = InstanceWrapper.create(movementMaid, "FlyBodyVelocity", "BodyVelocity", rootPart)
	local flyVelocity = camera.CFrame:VectorToWorldSpace(ControlModule.getMoveVector() * Options.FlySpeed.Value)

	if userInputService:IsKeyDown(Enum.KeyCode.Space) then
		flyVelocity = flyVelocity + Vector3.new(0, Options.FlyUpSpeed.Value, 0)
	end

	flyBodyVelocity.Velocity = flyVelocity
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

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	if Toggles.AttachToBack.Value then
		updateAttachToBack(rootPart)
	else
		setAttachTarget(nil)
	end

	if Toggles.Fly.Value then
		updateFlyHack(rootPart)
	end

	if Toggles.Speedhack.Value then
		updateSpeedHack(rootPart, humanoid)
	end

	if Toggles.InfiniteJump.Value then
		updateInfiniteJump(humanoid)
	end

	if Toggles.NoClip.Value then
		updateNoClip(character, rootPart)
	elseif #originalCanCollideMap > 0 then
		resetNoClip()
	end
end

---Initialize movement.
function Movement.init()
	movementMaid:add(heartbeat:connect("Movement_Heartbeat", updateMovement))
end

---Detach movement.
function Movement.detach()
	movementMaid:clean()

	resetNoClip()
end

-- Return Movement module.
return Movement
