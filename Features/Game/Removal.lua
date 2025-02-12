-- Removal related stuff is handled here.
local Removal = {}

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Utility.OriginalStoreManager
local OriginalStoreManager = require("Utility/OriginalStoreManager")

---@module Utility.OriginalStore
local OriginalStore = require("Utility/OriginalStore")

-- Services.
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")

-- Maids.
local removalMaid = Maid.new()

-- Original stores.
local noShadows = removalMaid:mark(OriginalStore.new())
local noBlur = removalMaid:mark(OriginalStore.new())

-- Original store managers.
local echoModifiersMap = removalMaid:mark(OriginalStoreManager.new())
local noFogMap = removalMaid:mark(OriginalStoreManager.new())
local noBlindMap = removalMaid:mark(OriginalStoreManager.new())
local killBricksMap = removalMaid:mark(OriginalStoreManager.new())
local lightBarrierMap = removalMaid:mark(OriginalStoreManager.new())
local yunShulBarrierMap = removalMaid:mark(OriginalStoreManager.new())
local yunShulResonanceDoorMap = removalMaid:mark(OriginalStoreManager.new())

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)
local workspaceDescendantAdded = Signal.new(workspace.DescendantAdded)
local workspaceDescendantRemoving = Signal.new(workspace.DescendantRemoving)

---Update no echo modifiers.
---@param localPlayer Player
local function updateNoEchoModifiers(localPlayer)
	local backpack = localPlayer:FindFirstChild("Backpack")
	if not backpack then
		return
	end

	for _, instance in pairs(backpack:GetChildren()) do
		if not instance.Name:match("EchoMod") then
			continue
		end

		echoModifiersMap:add(instance, "Parent", nil)
	end
end

---Update no kill bricks.
local function updateNoKillBricks()
	for _, store in next, killBricksMap:data() do
		local data = store.data
		if not data then
			continue
		end

		store:set(store.data, "CFrame", CFrame.new(math.huge, math.huge, math.huge))
	end
end

---Update no light barrier.
local function updateNoLightBarrier()
	for _, store in next, lightBarrierMap:data() do
		local data = store.data
		if not data then
			continue
		end

		store:set(store.data, "CFrame", CFrame.new(math.huge, math.huge, math.huge))
	end
end

---Update no fog.
local function updateNoFog()
	noFogMap:add(lighting, "FogStart", 9e9)
	noFogMap:add(lighting, "FogEnd", 9e9)

	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		return
	end

	noFogMap:add(atmosphere, "Density", 0)
end

---Update no blind.
---@param localPlayer Player
local function updateNoBlind(localPlayer)
	local sanityDof = lighting:FindFirstChild("SanityDoF")
	if not sanityDof then
		return
	end

	local sanityCorrect = lighting:FindFirstChild("SanityCorrect")
	if not sanityCorrect then
		return
	end

	noBlindMap:add(sanityDof, "Enabled", false)
	noBlindMap:add(sanityCorrect, "Enabled", false)

	local backpack = localPlayer:FindFirstChild("Backpack")
	if not backpack then
		return
	end

	local blindInstance = backpack:FindFirstChild("Talent:Blinded") or backpack:FindFirstChild("Flaw:Blind")
	if not blindInstance then
		return
	end

	noBlindMap:add(blindInstance, "Parent", nil)
end

---Update no blur.
local function updateNoBlur()
	local genericBlur = lighting:FindFirstChild("GenericBlur")
	if not genericBlur then
		return
	end

	noBlur:set(genericBlur, "Size", 0.0)
end

---Update no yun shul barrier.
local function updateNoYunShulBarrier()
	for _, store in next, yunShulBarrierMap:data() do
		local data = store.data
		if not data then
			continue
		end

		store:set(store.data, "CFrame", CFrame.new(math.huge, math.huge, math.huge))
	end

	for _, store in next, yunShulResonanceDoorMap:data() do
		local data = store.data
		if not data then
			continue
		end

		store:set(store.data, "Parent", nil)
	end
end

---Update removal.
local function updateRemoval()
	local localPlayer = players.LocalPlayer
	if not localPlayer then
		return
	end

	if Configuration.expectToggleValue("NoEchoModifiers") then
		updateNoEchoModifiers(localPlayer)
	else
		echoModifiersMap:restore()
	end

	if Configuration.expectToggleValue("NoKillBricks") then
		updateNoKillBricks()
	else
		killBricksMap:restore()
	end

	if Configuration.expectToggleValue("NoCastleLightBarrier") then
		updateNoLightBarrier()
	else
		lightBarrierMap:restore()
	end

	if Configuration.expectToggleValue("NoYunShulBarrier") then
		updateNoYunShulBarrier()
	else
		yunShulBarrierMap:restore()
		yunShulResonanceDoorMap:restore()
	end

	if Configuration.expectToggleValue("NoFog") then
		updateNoFog()
	else
		noFogMap:restore()
	end

	if Configuration.expectToggleValue("NoBlind") then
		updateNoBlind(localPlayer)
	else
		noBlindMap:restore()
	end

	if Configuration.expectToggleValue("NoBlur") then
		updateNoBlur()
	else
		noBlur:restore()
	end

	if Configuration.expectToggleValue("NoShadows") then
		noShadows:set(lighting, "GlobalShadows", false)
	else
		noShadows:restore()
	end
end

---Hide effect by unlinking it from being found.
---@param effect table
local function hideEffect(effect)
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	if not effect.Id then
		return
	end

	effectReplicatorModule.Effects[effect.Id] = nil
end

---Update removal effects.
---@param effect table
local function updateRemovalEffects(effect)
	local stunEffects = { "Stun", "LightAttack", "Action", "MobileAction", "OffhandAttack" }

	if Configuration.expectToggleValue("NoStun") and table.find(stunEffects, effect.Class) then
		return hideEffect(effect)
	end

	if effect.Class == "BeingWinded" and Configuration.expectToggleValue("NoWind") then
		return hideEffect(effect)
	end

	if
		(effect.Class == "NoJump" or effect.Class == "NoJumpAlt") and Configuration.expectToggleValue("NoJumpCooldown")
	then
		return hideEffect(effect)
	end

	if effect.Class == "SpeedOverride" and effect.Value < 14 and Configuration.expectToggleValue("NoSpeedDebuff") then
		return hideEffect(effect)
	end

	if effect.Class == "Speed" and effect.Value < 0 and Configuration.expectToggleValue("NoSpeedDebuff") then
		rawset(effect, "Value", 0)
	end

	if effect.Class == "Burning" and Configuration.expectToggleValue("AutoExtinguishFire") then
		local serverSlide = KeyHandling.getRemote("ServerSlide")
		local serverSlideStop = KeyHandling.getRemote("ServerSlideStop")

		if not serverSlide or not serverSlideStop then
			return
		end

		serverSlide:FireServer(true)

		serverSlideStop:FireServer()
	end
end

---On workspace descendant added.
---@param descendant Instance
local function onWorkspaceDescendantAdded(descendant)
	if descendant:IsA("Model") and descendant.Name == "ResonanceDoor" then
		yunShulResonanceDoorMap:mark(descendant, "Parent")
	end

	if not descendant:IsA("BasePart") then
		return
	end

	if descendant.Name == "LifeField" then
		lightBarrierMap:mark(descendant, "CFrame")
	end

	local killInstance = descendant.Name == "KillBrick" or descendant.Name == "KillPlane"
	local killChasm = descendant.Name:match("Chasm")
	local superWall = descendant.Name == "SuperWall"

	if killInstance or killChasm or superWall then
		killBricksMap:mark(descendant, "CFrame")
	end

	if descendant.Name == "DeepPassage_Yun" then
		yunShulBarrierMap:mark(descendant, "CFrame")
	end
end

---On workspace descendant removing.
---@param descendant Instance
local function onWorkspaceDescendantRemoving(descendant)
	killBricksMap:forget(descendant)
	lightBarrierMap:forget(descendant)
end

---Initalize removal.
function Removal.init()
	---@note: Not type of RBXScriptSignal - but it works.
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	local effectAddedSignal = Signal.new(effectReplicatorModule.EffectAdded)

	removalMaid:add(workspaceDescendantAdded:connect("Removal_WorkspaceDescendantAdded", onWorkspaceDescendantAdded))
	removalMaid:add(
		workspaceDescendantRemoving:connect("Removal_WorkspaceDescendantRemoving", onWorkspaceDescendantRemoving)
	)

	removalMaid:add(renderStepped:connect("Removal_RenderStepped", updateRemoval))
	removalMaid:add(effectAddedSignal:connect("Removal_EffectAdded", updateRemovalEffects))

	for _, descendant in pairs(workspace:GetDescendants()) do
		onWorkspaceDescendantAdded(descendant)
	end

	for _, effect in next, effectReplicatorModule.Effects do
		updateRemovalEffects(effect)
	end
end

---Detach removal.
function Removal.detach()
	removalMaid:clean()
end

-- Return Removal module.
return Removal
