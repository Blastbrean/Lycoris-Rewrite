-- Removal related stuff is handled here.
local Removal = {}

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module GUI.Configuration
local Configuration = require("GUI/Configuration")

-- Services.
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")

-- Instances.
local originalAtmosphereDensity = nil
local originalFogEnd = nil
local originalFogStart = nil
local originalBlindInstance = nil
local originalBlurSize = nil
local originalEchoModifiersMap = {}
local originalKillBricksMap = {}

-- Maids.
local removalMaid = Maid.new()

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

---@note: These setters are completely unnecessary - they're used to make the code look cleaner.
---It's really ugly when we want to return and set something at the same time.

---Reset original atmosphere density.
local function resetOriginalAtmospherDensity()
	originalAtmosphereDensity = nil
end

---Reset original blur size.
local function resetOriginalBlurSize()
	originalBlurSize = nil
end

---Update no echo modifiers.
---@param localPlayer Player
local function updateNoEchoModifiers(localPlayer)
	for _, instance in pairs(localPlayer.Backpack:GetChildren()) do
		if not instance.Name:match("EchoMod") then
			continue
		end

		originalEchoModifiersMap[#originalEchoModifiersMap + 1] = instance

		instance.Parent = nil
	end
end

---Reset no echo modifiers.
---@param localPlayer Player
local function resetNoEchoModifiers(localPlayer)
	for _, instance in pairs(originalEchoModifiersMap) do
		instance.Parent = localPlayer.Backpack
	end

	originalEchoModifiersMap = {}
end

---Update no kill bricks.
local function updateNoKillBricks()
	for _, instance in pairs(workspace:GetChildren()) do
		if originalKillBricksMap[instance] then
			continue
		end

		local killInstance = instance.Name == "KillBrick" or instance.Name == "KillPlane"
		local killChasm = instance.Name:match("Chasm") and instance:FindFirstChildOfClass("TouchTransmitter")

		if not killInstance and not killChasm then
			continue
		end

		originalKillBricksMap[instance] = instance.CFrame

		instance.CFrame = Vector3.new(math.huge, math.huge, math.huge)
	end

	local layer2Floor1 = workspace:FindFirstChild("Layer2Floor1")
	if not layer2Floor1 then
		return
	end

	for _, instance in pairs(layer2Floor1:GetChildren()) do
		if originalKillBricksMap[instance] then
			continue
		end

		if instance.Name ~= "SuperWall" then
			continue
		end

		originalKillBricksMap[instance] = instance.CFrame

		instance.CFrame = Vector3.new(math.huge, math.huge, math.huge)
	end
end

---Reset no kill bricks.
local function resetNoKillBricks()
	for instance, cframe in pairs(originalKillBricksMap) do
		instance.CFrame = cframe
	end

	originalKillBricksMap = {}
end

---Update no fog.
local function updateNoFog()
	if not originalFogStart then
		originalFogStart = lighting.FogStart
	end

	if not originalFogEnd then
		originalFogEnd = lighting.FogEnd
	end

	lighting.FogStart = math.huge
	lighting.FogEnd = math.huge

	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		return
	end

	if not originalAtmosphereDensity then
		originalAtmosphereDensity = atmosphere.Density
	end

	atmosphere.Density = 0
end

---Reset no fog.
local function resetNoFog()
	if not originalFogStart or not originalFogEnd then
		return
	end

	lighting.FogStart = originalFogStart
	lighting.FogEnd = originalFogEnd

	originalFogStart = nil
	originalFogEnd = nil

	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere or not originalAtmosphereDensity then
		return resetOriginalAtmospherDensity()
	end

	atmosphere.Density = originalAtmosphereDensity
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

	sanityDof.Enabled = false
	sanityCorrect.Enabled = false

	local backpack = localPlayer.Backpack
	local blindInstance = backpack:FindFirstChild("Talent:Blinded") or backpack:FindFirstChild("Flaw:Blind")
	if not blindInstance then
		return
	end

	originalBlindInstance = blindInstance

	blindInstance.Parent = nil
end

---Reset no blind.
---@param localPlayer Player
local function resetNoBlind(localPlayer)
	if not originalBlindInstance then
		return
	end

	originalBlindInstance.Parent = localPlayer.Backpack
	originalBlindInstance = nil

	local sanityDof = lighting:FindFirstChild("SanityDoF")
	if not sanityDof then
		return
	end

	local sanityCorrect = lighting:FindFirstChild("SanityCorrect")
	if not sanityCorrect then
		return
	end

	sanityDof.Enabled = true
	sanityCorrect.Enabled = true
end

---Update no blur.
local function updateNoBlur()
	local genericBlur = lighting:FindFirstChild("GenericBlur")
	if not genericBlur then
		return
	end

	if not originalBlurSize then
		originalBlurSize = genericBlur.Size
	end

	genericBlur.Size = 0.0
end

---Reset no blur.
local function resetNoBlur()
	local genericBlur = lighting:FindFirstChild("genericBlur")
	if not genericBlur or not originalBlurSize then
		return resetOriginalBlurSize()
	end

	genericBlur.Size = originalBlurSize

	originalBlurSize = nil
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
		resetNoEchoModifiers(localPlayer)
	end

	if Configuration.expectToggleValue("NoKillBricks") then
		updateNoKillBricks()
	else
		resetNoKillBricks()
	end

	if Configuration.expectToggleValue("NoFog") then
		updateNoFog()
	else
		resetNoFog()
	end

	if Configuration.expectToggleValue("NoBlind") then
		updateNoBlind(localPlayer)
	else
		resetNoBlind(localPlayer)
	end

	if Configuration.expectToggleValue("NoBlur") then
		updateNoBlur()
	else
		resetNoBlur()
	end

	if Configuration.expectToggleValue("NoShadows") then
		lighting.GlobalShadows = false
	else
		lighting.GlobalShadows = true
	end
end

---Update removal effects.
---@param effect table
local function updateRemovalEffects(effect)
	if not effect then
		return
	end

	local stunEffects = { "Stun", "LightAttack", "Action", "MobileAction", "OffhandAttack" }

	if Configuration.expectToggleValue("NoStun") and table.find(stunEffects, effect.Class) then
		effect:Remove()
	end

	if effect.Class == "BeingWinded" and Configuration.expectToggleValue("AntiWind") then
		effect:Remove()
	end

	if
		(effect.Class == "NoJump" or effect.Class == "NoJumpAlt") and Configuration.expectToggleValue("NoJumpCooldown")
	then
		effect:Remove()
	end

	if effect.Class == "SpeedOverride" and effect.Value < 14 and Configuration.expectToggleValue("NoSpeedDebuff") then
		effect:Remove()
	end

	if effect.Class == "Speed" and effect.Value < 0 and Configuration.expectToggleValue("NoSpeedDebuff") then
		rawset(effect, "Value", 0)
	end

	if effect.Class == "Burning" and Configuration.expectToggleValue("AntiFire") then
		local serverSlide = KeyHandling.getRemote("ServerSlide")
		local serverSlideStop = KeyHandling.getRemote("ServerSlideStop")

		if not serverSlide or not serverSlideStop then
			return
		end

		serverSlide:FireServer(true)

		task.delay(0.3, serverSlideStop.FireServer, serverSlideStop)
	end
end

---Initalize removal.
function Removal.init()
	---@note: Not type of RBXScriptSignal - but it works.
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	local effectAddedSignal = Signal.new(effectReplicatorModule.EffectAdded)

	removalMaid:add(renderStepped:connect("Removal_RenderStepped", updateRemoval))
	removalMaid:add(effectAddedSignal:connect("Removal_EffectAdded", updateRemovalEffects))

	for _, effect in next, effectReplicatorModule.Effects do
		updateRemovalEffects(effect)
	end
end

---Detach removal.
function Removal.detach()
	removalMaid:clean()

	resetNoKillBricks()
	resetNoEchoModifiers()
	resetNoFog()

	local localPlayer = players.LocalPlayer
	if not localPlayer then
		return
	end

	resetNoBlind(localPlayer)
end

-- Return Removal module.
return Removal
