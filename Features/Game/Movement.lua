---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Utility.OriginalStoreManager
local OriginalStoreManager = require("Utility/OriginalStoreManager")

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

---@module Utility.Maid
local Maid = require("Utility/Maid")

-- Maids.
local movementMaid = Maid.new()

-- Services.
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- AA gun map.
local aaGunMap = OriginalStoreManager.new()

---Update anti air bypass.
---@param rootPart BasePart
local function updateAABypass(rootPart)
	---@note: This method was patched on 3/25/2025.
	--[[
	local modOffice = workspace:FindFirstChild("ModOffice")
	if not modOffice then
		return
	end

	aaGunMap:add(modOffice, "ModelStreamingMode", Enum.ModelStreamingMode.Persistent)

	local officeCreature = modOffice:FindFirstChild("OfficeCreature")
	if not officeCreature then
		return movementMaid:add(
			TaskSpawner.spawn(
				"Movement_RequestStreamModOffice",
				players.LocalPlayer.RequestStreamAroundAsync,
				players.LocalPlayer,
				modOffice:GetPivot().Position,
				0.1
			)
		)
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	officeCreature.CollisionGroup = "Default"
	officeCreature.CanCollide = true

	firetouchinterest(officeCreature, rootPart, 0)
	firetouchinterest(officeCreature, rootPart, 1)
	]]
	--
end

return LPH_NO_VIRTUALIZE(function()
	-- Movement related stuff is handled here.
	---@todo: Make our own tween module.
	local Movement = {}

	---@module Utility.Signal
	local Signal = require("Utility/Signal")

	---@module Utility.InstanceWrapper
	local InstanceWrapper = require("Utility/InstanceWrapper")

	---@module Utility.OriginalStore
	local OriginalStore = require("Utility/OriginalStore")

	---@module Utility.ControlModule
	local ControlModule = require("Utility/ControlModule")

	---@module Utility.Entitites
	local Entitites = require("Utility/Entitites")

	---@module Utility.Logger
	local Logger = require("Utility/Logger")

	-- Services.
	local runService = game:GetService("RunService")
	local userInputService = game:GetService("UserInputService")

	-- Instances.
	local bloodJarTarget = nil

	-- Original stores.
	local agilitySpoofer = movementMaid:mark(OriginalStore.new())

	-- Original store managers.
	local noClipMap = movementMaid:mark(OriginalStoreManager.new())

	-- Signals.
	local preSimulation = Signal.new(runService.PreSimulation)

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

	---Update noclip.
	---@param character Model
	---@param rootPart BasePart
	local function updateNoClip(character, rootPart)
		local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
		if not effectReplicator then
			return
		end

		local effectReplicatorModule = require(effectReplicator)
		local knockedRestore = effectReplicatorModule:FindEffect("Knocked")
			and Configuration.expectToggleValue("NoClipCollisionsKnocked")

		for _, instance in pairs(character:GetChildren()) do
			if not instance:IsA("BasePart") then
				continue
			end

			noClipMap:add(instance, "CanCollide", knockedRestore and noClipMap:get(instance):get() or false)

			local bone = instance:FindFirstChild("Bone")
			if not bone then
				continue
			end

			noClipMap:add(bone, "CanCollide", knockedRestore and noClipMap:get(bone):get() or false)
		end
	end

	---Update speed hack.
	---@param rootPart BasePart
	---@param humanoid Humanoid
	local function updateSpeedHack(rootPart, humanoid)
		if Configuration.expectToggleValue("Fly") then
			return
		end

		rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity * Vector3.new(0, 1, 0)

		local moveDirection = humanoid.MoveDirection
		if moveDirection.Magnitude <= 0.001 then
			return
		end

		rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity
			+ moveDirection.Unit * Configuration.expectOptionValue("SpeedhackSpeed")
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

		rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
		rootPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity
			+ Vector3.new(0, Configuration.expectOptionValue("InfiniteJumpBoost"), 0)
	end

	---Update fly hack.
	---@param rootPart BasePart
	---@param humanoid Humanoid
	local function updateFlyHack(rootPart, humanoid)
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		local flyBodyVelocity = InstanceWrapper.create(movementMaid, "flyBodyVelocity", "BodyVelocity", rootPart)
		flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

		local flyVelocity = camera.CFrame:VectorToWorldSpace(
			ControlModule.getMoveVector() * Configuration.expectOptionValue("FlySpeed")
		)

		if userInputService:IsKeyDown(Enum.KeyCode.Space) then
			flyVelocity = flyVelocity + Vector3.new(0, Configuration.expectOptionValue("FlyUpSpeed"), 0)
		end

		flyBodyVelocity.Velocity = flyVelocity
	end

	---Update attach to back.
	---@param rootPart BasePart
	local function updateAttachToBack(rootPart)
		local attachTarget = Entitites.findNearestEntity(200)
		if not attachTarget then
			return
		end

		local attachTargetHrp = attachTarget:FindFirstChild("HumanoidRootPart")
		if not attachTargetHrp then
			return
		end

		local offsetCFrame = CFrame.new(
			0.0,
			Configuration.expectOptionValue("HeightOffset"),
			Configuration.expectOptionValue("BackOffset")
		)

		rootPart.CFrame = rootPart.CFrame:Lerp(attachTargetHrp.CFrame * offsetCFrame, 0.3)
	end

	---Update agility spoofer.
	---@param character Model
	local function updateAgilitySpoofer(character)
		local agility = character:FindFirstChild("Agility")
		if not agility then
			return
		end

		---@note: For every 10 investment points, there are two real agility points.
		-- With 40 investment points, we can have 16 real agility points.
		-- However, with 30 investment points, we can only have 14 real agility points.
		-- This means that the starting value must be 8 and we must increase by 2 for every point we have.
		local agilitySpoofValue = 8 + (Options.AgilitySpoof.Value / 10) * 2

		if Toggles.BoostAgilityDirectly.Value then
			agilitySpoofValue = Options.AgilitySpoof.Value
		end

		agilitySpoofer:set(agility, "Value", agilitySpoofValue)
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
		local chaserBloodJar = chaserHrp and chaserHrp:FindFirstChild("BloodJar") or nil

		if not chaserBloodJar or not chaserBloodJar.Value or bloodJarTarget ~= chaserBloodJar.Value then
			Logger.warn("Resetting tween lol.")
			print(chaserBloodJar, chaserBloodJar and chaserBloodJar.Value, bloodJarTarget)
			return resetBloodJarTween()
		end

		if movementMaid["bloodJarTween"] then
			return Logger.warn("Active tween.")
		end

		bloodJarTarget = chaserBloodJar.Value

		Logger.warn("(%s) Tweening towards BloodJar target.", bloodJarTarget.Name)

		local distance = (chaserBloodJar:GetPivot().Position - rootPart.HumanoidRootPart.Position).Magnitude
		local bloodJarTween =
			InstanceWrapper.tween(movementMaid, "bloodJarTween", rootPart, TweenInfo.new(distance / 80), {
				CFrame = CFrame.new(chaserBloodJar:GetPivot().Position),
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

		local live = workspace:FindFirstChild("Live")
		local chaserEntity = nil

		for _, instance in next, live:GetChildren() do
			if not instance.Name:match("chaser") then
				continue
			end

			chaserEntity = instance
			break
		end

		print(chaserEntity, bossRoomContainer)

		if bossRoomContainer then
			return tweenToAltars(rootPart, bossRoomContainer)
		end

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
		end

		if Configuration.expectToggleValue("Fly") then
			updateFlyHack(rootPart, humanoid)
		else
			movementMaid["flyBodyVelocity"] = nil
		end

		if Configuration.expectToggleValue("AAGunBypass") then
			updateAABypass(rootPart)
		else
			aaGunMap:restore()
		end

		if Configuration.expectToggleValue("Speedhack") then
			updateSpeedHack(rootPart, humanoid)
		end

		if Configuration.expectToggleValue("InfiniteJump") then
			updateInfiniteJump(rootPart)
		end

		if Configuration.expectToggleValue("NoClip") then
			updateNoClip(character, rootPart)
		else
			noClipMap:restore()
		end

		if Configuration.expectToggleValue("AgilitySpoof") then
			updateAgilitySpoofer(character)
		else
			agilitySpoofer:restore()
		end

		if Configuration.expectToggleValue("TweenToObjectives") then
			updateTweenToObjectives(rootPart)
		else
			movementMaid["altarTween"] = nil
			movementMaid["bloodJarTween"] = nil
		end
	end

	---Initialize movement.
	function Movement.init()
		-- Attach.
		movementMaid:add(preSimulation:connect("Movement_PreSimulation", updateMovement))

		-- Log.
		Logger.warn("Movement initialized.")
	end

	---Detach movement.
	function Movement.detach()
		-- Clean.
		movementMaid:clean()

		-- Log.
		Logger.warn("Movement detached.")
	end

	-- Return Movement module.
	return Movement
end)()
