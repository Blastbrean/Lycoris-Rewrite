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

---@module GUI.Configuration
local Configuration = require("GUI/Configuration")

-- Services.
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Maids.
local movementMaid = Maid.new()

-- Instances.
local attachTarget = nil
local bloodJarTarget = nil
local originalAgilityValue = nil
local originalCanCollideMap = {}

-- Signals.
local heartbeat = Signal.new(runService.Heartbeat)

---@note: These setters are completely unnecessary - they're used to make the code look cleaner.
---It's really ugly when we want to return and set something at the same time.

---Set original agility value.
local function resetOriginalAgilityValue()
	originalAgilityValue = nil
end

---Set attach target
---@param target Model?
local function setAttachTarget(target)
	attachTarget = target
end

---Reset blood jar tween.
---@param tween Tween?
local function resetBloodJarTween(tween)
	movementMaid["bloodJarTween"] = nil
end

-- Find an empty altar.
---@param bossRoomContainer Folder
local function findEmptyAltar(bossRoomContainer)
	for _, instance in next, bossRoomContainer:GetChildren() do
		if instance.Name ~= "Altar" or not instance:IsA("Model") then
			continue
		end

		if instance:FindFirstChild("BoneSpear") then
			continue
		end

		return instance
	end
end

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

	if effectReplicatorModule:FindEffect("Knocked") and Configuration.expectToggleValue("NoClipCollisionsKnocked") then
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

	if Configuration.expectToggleValue("Fly") then
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
	if Configuration.expectToggleValue("Fly") then
		return
	end

	if not userInputService:IsKeyDown(Enum.KeyCode.Space) then
		return
	end

	local manipulationInst = rootPart:FindFirstChildOfClass("BodyVelocity")
		or rootPart:FindFirstChildOfClass("BodyPosition")

	if manipulationInst and manipulationInst ~= movementMaid["FlyBodyVelocity"] then
		manipulationInst:Destroy()
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

---Update agility spoofer.
---@param character Model
local function updateAgilitySpoofer(character)
	local agility = character:FindFirstChild("Agility")
	if not agility then
		return
	end

	if not originalAgilityValue then
		originalAgilityValue = agility.Value
	end

	---@note: For every 10 investment points, there are two real agility points.
	-- With 40 investment points, we can have 16 real agility points.
	-- However, with 30 investment points, we can only have 14 real agility points.
	-- This means that the starting value must be 8 and we must increase by 2 for every 10 investment points.

	agility.Value = 8 + (Options.AgilitySpoof.Value / 10) * 2
end

---Reset agility spoofer.
---@param character Model
local function resetAgilitySpoofer(character)
	local agility = character:FindFirstChild("Agility")
	if not agility or not originalAgilityValue then
		return resetOriginalAgilityValue()
	end

	agility.Value = originalAgilityValue

	originalAgilityValue = nil
end

---Tween to altars.
---@param rootPart BasePart
---@param bossRoomContainer Folder
local function tweenToAltars(rootPart, bossRoomContainer)
	if movementMaid["altarTween"] then
		return
	end

	local emptyAltar = findEmptyAltar(bossRoomContainer)

	if not emptyAltar then
		return
	end

	local distance = (emptyAltar:GetPivot().Position - rootPart.Position).Magnitude
	local altarTween = InstanceWrapper.tween(movementMaid, "altarTween", rootPart, TweenInfo.new(distance / 80), {
		CFrame = CFrame.new(emptyAltar:GetPivot().Position),
	})

	altarTween:Play()
	altarTween.Completed:Connect(function()
		movementMaid["altarTween"] = nil
	end)
end

---Tween to blood jars.
---@param rootPart BasePart
---@param chaserEntity Model
local function tweenToBloodJars(rootPart, chaserEntity)
	local chaserHrp = chaserEntity:FindFirstChild("HumanoidRootPart")
	local bloodJar = chaserHrp and chaserHrp:FindFirstChild("BloodJar") or nil

	if not bloodJar or not bloodJar.Value or bloodJarTarget ~= bloodJar.Value then
		return resetBloodJarTween()
	end

	if movementMaid["bloodJarTween"] then
		return
	end

	bloodJarTarget = bloodJar.Value

	local distance = (bloodJar:GetPivot().Position - rootPart.HumanoidRootPart.Position).Magnitude
	local bloodJarTween = InstanceWrapper.tween(movementMaid, "bloodJarTween", rootPart, TweenInfo.new(distance / 80), {
		CFrame = CFrame.new(bloodJar:GetPivot().Position),
	})

	bloodJarTween:Play()
	bloodJarTween.Completed:Connect(function()
		movementMaid["bloodJarTween"] = nil
	end)
end

---Update tween to objectives.
---@param rootPart BasePart
local function updateTweenToObjectives(rootPart)
	local bossRoom = workspace:FindFirstChild("TrueAvatarBossRoom")
	local bossRoomContainer = bossRoom and bossRoom:FindFirstChild("Floor1Stuff") or nil

	if bossRoomContainer then
		return tweenToAltars(rootPart, bossRoomContainer)
	end

	local chaserEntity = workspace.Live:FindFirstChild(".chaser")
	if chaserEntity then
		return tweenToBloodJars(rootPart, chaserEntity)
	end
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

	if Configuration.expectToggleValue("AttachToBack") then
		updateAttachToBack(rootPart)
	else
		attachTarget = nil
	end

	if Configuration.expectToggleValue("Fly") then
		updateFlyHack(rootPart)
	end

	if Configuration.expectToggleValue("Speedhack") then
		updateSpeedHack(rootPart, humanoid)
	end

	if Configuration.expectToggleValue("InfiniteJump") then
		updateInfiniteJump(humanoid)
	end

	if Configuration.expectToggleValue("NoClip") then
		updateNoClip(character, rootPart)
	elseif #originalCanCollideMap > 0 then
		resetNoClip()
	end

	if Configuration.expectToggleValue("AgilitySpoof") then
		updateAgilitySpoofer(character)
	else
		resetAgilitySpoofer(character)
	end

	if Configuration.expectToggleValue("TweenToObjective") then
		updateTweenToObjectives(rootPart)
	else
		movementMaid["altarTween"] = nil
		movementMaid["bloodJarTween"] = nil
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

	local localPlayer = players.LocalPlayer
	local character = localPlayer.Character

	if not character then
		return
	end

	resetAgilitySpoofer(character)
end

-- Return Movement module.
return Movement
