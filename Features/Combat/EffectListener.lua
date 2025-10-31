-- EffectListener module.
local EffectListener = { lastMantraActivated = nil }

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

-- Maids.
local effectMaid = Maid.new()

-- Services.
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

---Is an effect within a specific time?
---@param effect table
---@param time number? If the number is unspecified, it will use the Debris time.
---@return boolean
local function withinTime(effect, time)
	if not effect.index then
		return false
	end

	local timestamp = effect.index.Timestamp
	if not timestamp then
		return false
	end

	local dtime = time or effect.index.DebrisTime
	if not dtime then
		return false
	end

	return os.clock() - timestamp <= dtime
end

---Are we currently casting Sightless Beam?
---@return boolean
function EffectListener.csb()
	if not EffectListener.lastMantraActivated then
		return false
	end

	local name = tostring(EffectListener.lastMantraActivated)
	if not name or not name:match("Sightless Beam") then
		return false
	end

	local character = players.LocalPlayer and players.LocalPlayer.Character
	if not character then
		return false
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	if hrp:FindFirstChild("REP_SOUND_376107250") then
		return true
	end

	for _, child in next, hrp:GetChildren() do
		if not child:IsA("Sound") then
			continue
		end

		if child.Name ~= "Telekin" then
			continue
		end

		if not child.IsPlaying then
			continue
		end

		return true
	end

	return false
end

---Are we in action stun? That small window after doing an action where you can't do anything.
---@return boolean
function EffectListener.astun()
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	local lightAttackEffect = effectReplicatorModule:FindEffect("LightAttack")
	local usingCriticalEffect = effectReplicatorModule:FindEffect("UsingCritical")
	local usingSpellEffect = effectReplicatorModule:FindEffect("UsingSpell")

	if lightAttackEffect and withinTime(lightAttackEffect, 0.5) then
		return true
	end

	if usingCriticalEffect then
		return true
	end

	if usingSpellEffect then
		return true
	end

	return false
end

---Can we block?
---@return boolean
function EffectListener.cblock()
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	return effectReplicatorModule:HasAny("ShakyBlock", "CancelBlock")
end

---Can we parry?
---@return boolean
function EffectListener.cparry()
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	local parryCooldownEffect = effectReplicatorModule:FindEffect("ParryCool")

	if not effectReplicatorModule:FindEffect("Equipped") then
		return false
	end

	if parryCooldownEffect then
		return false
	end

	return true
end

---Can we feint?
---@return boolean
function EffectListener.cfeint()
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	local feintCooldownEffect = effectReplicatorModule:FindEffect("FeintCool")

	if feintCooldownEffect then
		return false
	end

	return true
end

---Can we dodge?
---@return boolean
function EffectListener.cdodge()
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	local dodgeCooldownEffect = effectReplicatorModule:FindEffect("NoRoll")
	local stunCooldownEffect = effectReplicatorModule:FindEffect("Stun")

	if dodgeCooldownEffect then
		return false
	end

	if stunCooldownEffect and withinTime(stunCooldownEffect, nil) then
		return false
	end

	return true
end

---On effect replicated.
---@param effect table
local onEffectReplicated = LPH_NO_VIRTUALIZE(function(effect)
	if Configuration.expectToggleValue("EffectLogging") then
		print(string.format("%s", tostring(effect)))
	end

	if effect.Class == "Knocked" or effect.Class == "Ragdoll" then
		if Configuration.expectToggleValue("AutoRagdollRecover") then
			InputClient.feint()
		end
	end

	if effect.Class == "LightAttack" then
		effect.index.Timestamp = os.clock()
	end

	if effect.Class == "Stun" then
		effect.index.Timestamp = os.clock()
	end

	if effect.Class == "DodgeCool" then
		effect.index.Timestamp = os.clock()
	end

	if effect.Class == "ParryCool" then
		effect.index.Timestamp = os.clock()
	end
end)

--On effect removing.
---@param effect table
local onEffectRemoving = LPH_NO_VIRTUALIZE(function(effect)
	if not Configuration.expectToggleValue("EffectLogging") then
		return
	end

	warn(string.format("%s", tostring(effect)))
end)

---Initialize EffectListener.
function EffectListener.init()
	---@note: Not type of RBXScriptSignal - but it works.
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	local effectAddedSignal = Signal.new(effectReplicatorModule.EffectAdded)
	local effectRemovingSignal = Signal.new(effectReplicatorModule.EffectRemoving)

	effectMaid:mark(effectAddedSignal:connect("Defense_EffectReplicated", onEffectReplicated))
	effectMaid:mark(effectRemovingSignal:connect("Defense_EffectRemoving", onEffectRemoving))

	for _, effect in next, effectReplicatorModule.Effects do
		onEffectReplicated(effect)
	end

	Logger.warn("EffectListener initialized.")
end

---Detach EffectListener.
function EffectListener.detach()
	effectMaid:clean()
end

-- Return EffectListener module.
return EffectListener
