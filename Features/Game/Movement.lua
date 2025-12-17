---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Utility.OriginalStoreManager
local OriginalStoreManager = require("Utility/OriginalStoreManager")

---@module Utility.Maid
local Maid = require("Utility/Maid")

-- Maids.
local movementMaid = Maid.new()

-- Services.
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

return LPH_NO_VIRTUALIZE(function()
	-- Movement related stuff is handled here.
	local Movement = {}

	---@module Utility.Signal
	local Signal = require("Utility/Signal")

	---@module Utility.InstanceWrapper
	local InstanceWrapper = require("Utility/InstanceWrapper")

	---@module Utility.OriginalStore
	local OriginalStore = require("Utility/OriginalStore")

	---@module Utility.ControlModule
	local ControlModule = require("Utility/ControlModule")

	---@module Utility.Finder
	local Finder = require("Utility/Finder")

	---@module Features.Game.Tweening
	local Tweening = require("Features/Game/Tweening")

	---@module Utility.Logger
	local Logger = require("Utility/Logger")

	-- Services.
	local runService = game:GetService("RunService")
	local userInputService = game:GetService("UserInputService")

	-- Original stores.
	local agilitySpoofer = movementMaid:mark(OriginalStore.new())

	-- Original store managers.
	local noClipMap = movementMaid:mark(OriginalStoreManager.new())

	-- Signals.
	local preSimulation = Signal.new(runService.PreSimulation)
	local heartbeat = Signal.new(runService.Heartbeat)

	-- Instances.
	local cachedTarget = nil

	---Update noclip.
	---@param character Model
	---@param rootPart BasePart
	local function updateNoClip(character, rootPart)
		local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
		if not effectReplicator then
			return
		end

		local controllerManager = character:FindFirstChild("ControllerManager")
		if not controllerManager then
			return
		end

		local airController = controllerManager:FindFirstChild("AirController")
		if not airController then
			return
		end

		local groundController = controllerManager:FindFirstChild("GroundController")
		if not groundController then
			return
		end

		if Configuration.expectToggleValue("Fly") then
			controllerManager.ActiveController = airController
		else
			controllerManager.ActiveController = groundController
		end

		local effectReplicatorModule = require(effectReplicator)
		local knockedRestore = effectReplicatorModule:FindEffect("Knocked")
			and Configuration.expectToggleValue("NoClipCollisionsKnocked")

		if Tweening.active then
			knockedRestore = false
		end

		for _, instance in pairs(character:GetChildren()) do
			if not instance:IsA("BasePart") then
				continue
			end

			noClipMap:add(instance, "CanCollide", knockedRestore and noClipMap:get(instance):get() or false)

			local bone = instance:FindFirstChild("Bone")
			if not bone then
				continue
			end

			local success, result = pcall(function()
				return bone.CanCollide ~= nil
			end)

			if not success or not result then
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

	---Update max momentum spoofer.
	local function updateMaxMomentumSpoofer()
		local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
		local effectReplicatorModule = effectReplicator and require(effectReplicator)
		if not effectReplicatorModule then
			return
		end

		local forcedMomentumEffect = effectReplicatorModule:FindEffect("ForceMomentum")
		if not forcedMomentumEffect then
			return effectReplicatorModule:CreateEffect("ForceMomentum")
		end

		if forcedMomentumEffect.Value ~= 10 then
			forcedMomentumEffect.Value = 10
		end

		forcedMomentumEffect.Disabled = not Configuration.expectToggleValue("MaxMomentumSpoof")
	end

	---Update agility spoofer.
	---@param character Model
	local function updateAgilitySpoofer(character)
		local agility = character:FindFirstChild("PassiveAgility")
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

	---Update tween to back.
	local function updateTweenToBack()
		local validTargets = Finder.geir(300, Configuration.expectToggleValue("AttachIgnorePlayers"))
		if not validTargets then
			return true
		end

		local attachTarget = Configuration.expectToggleValue("StickyAttach") and cachedTarget or validTargets[1]
		if not attachTarget then
			return true
		end

		if not attachTarget.Parent then
			return false
		end

		local attachTargetHrp = attachTarget:FindFirstChild("HumanoidRootPart")
		if not attachTargetHrp then
			return false
		end

		local attachTargetHumanoid = attachTarget:FindFirstChild("Humanoid")
		if not attachTargetHumanoid then
			return false
		end

		if attachTargetHumanoid.Health <= 0 then
			return false
		end

		cachedTarget = cachedTarget or attachTarget

		local offsetCFrame = CFrame.new(
			0.0,
			Configuration.expectOptionValue("HeightOffset"),
			Configuration.expectOptionValue("BackOffset")
		)

		local targetPosition = (attachTargetHrp.CFrame * offsetCFrame).Position
		local goalCFrame = CFrame.lookAt(targetPosition, attachTargetHrp.Position)

		Tweening.goal("TweenToBack", goalCFrame, false)

		return true
	end

	---Update movement.
	---@param dt number
	local function updateMovement(dt)
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

		if not Configuration.expectToggleValue("TweenToBack") or not updateTweenToBack() then
			cachedTarget = nil
		end

		if Configuration.expectToggleValue("AgilitySpoof") then
			updateAgilitySpoofer(character)
		else
			agilitySpoofer:restore()
		end

		if Configuration.expectToggleValue("MaxMomentumSpoof") then
			updateMaxMomentumSpoofer()
		end

		if Tweening.active or Configuration.expectToggleValue("NoClip") then
			updateNoClip(character, rootPart)
		else
			noClipMap:restore()
		end

		if Tweening.active then
			return
		end

		if Configuration.expectToggleValue("Fly") then
			updateFlyHack(rootPart, humanoid)
		else
			movementMaid["flyBodyVelocity"] = nil
		end

		if Configuration.expectToggleValue("Speedhack") then
			updateSpeedHack(rootPart, humanoid)
		end

		if Configuration.expectToggleValue("InfiniteJump") then
			updateInfiniteJump(rootPart)
		end
	end

	---Initialize movement.
	function Movement.init()
		-- Attach.
		movementMaid:add(preSimulation:connect("Movement_PreSimulation", updateMovement))
		movementMaid:add(heartbeat:connect("Movement_Heartbeat", Tweening.update))

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
