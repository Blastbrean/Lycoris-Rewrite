-- EffectListener module.
local EffectListener = {}

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Utility.Logger
local Logger = require("Utility/Logger")

-- Maids.
local effectMaid = Maid.new()

-- Services.
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

---Are we in swinging stun? That small window after swinging where you can't do anything.
---@return boolean
function EffectListener.sstun()
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	local lightAttackEffect = effectReplicatorModule:FindEffect("LightAttack")

	if lightAttackEffect and withinTime(lightAttackEffect, 0.5) then
		return true
	end

	return false
end

---Can we parry?
---@return boolean
function EffectListener.cparry()
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	local parryCooldownEffect = effectReplicatorModule:FindEffect("ParryCool")

	if parryCooldownEffect and withinTime(parryCooldownEffect, nil) then
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
