-- StateListener module. Practically, it is a module to store data / information about what is happening with the character.
local StateListener =
	{ lMantraActivated = nil, lAnimTiming = nil, lAnimFaction = nil, lAnimTimestamp = nil, chainStacks = nil }

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

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Game.Timings.ModuleManager
local ModuleManager = require("Game/Timings/ModuleManager")

-- Maids.
local stateMaid = Maid.new()

-- Services.
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Constants.
local CHIME_ARENA_PLACE_ID = 6832944305

---Handle module data.
---@param track AnimationTrack
---@param timing AnimationTiming
local function handleModuleData(track, timing)
	-- Since we don't know what it could fail on, limit it to weapons for now.
	if timing.tag ~= "M1" then
		return
	end

	-- Get loaded function.
	local lf = ModuleManager.modules[PP_SCRAMBLE_STR(timing.smod)]
	if not lf then
		return
	end

	-- Run module with a fake 'AnimationDefender' object.
	local extracted = {}
	local fake = {
		tmaid = Maid.new(),
		track = track,
		entity = players.LocalPlayer.Character,
		action = function(_, _, action)
			table.insert(extracted, action)
		end,
	}

	lf(fake, timing)

	-- Clean up.
	fake.tmaid:clean()

	-- Set first extracted action as last animation faction.
	StateListener.lAnimFaction = extracted[1]
end

---On local animation played.
---@param track AnimationTrack
local function onLocalAnimationPlayed(track)
	local aid = tostring(track.Animation.AnimationId)
	local data = SaveManager.as:index(aid)
	if not data then
		return
	end

	StateListener.lAnimTimestamp = os.clock()
	StateListener.lAnimationValidTrack = track
	StateListener.lAnimTiming = data

	-- If this is a module, we need to extract the actions differently. It expects to be ran normally.
	-- Run it in a emulated environment.
	if data.umoa then
		return handleModuleData(track, data)
	end

	StateListener.lAnimFaction = data.actions:stack()[1]
end

---On descendant added.
---@param descendant Instance
local function onDescendantAdded(descendant)
	if not descendant:IsA("Animator") then
		return
	end

	local character = players.LocalPlayer.Character
	if not character then
		return
	end

	if not descendant:IsDescendantOf(character) then
		return
	end

	local animationPlayed = Signal.new(descendant.AnimationPlayed)

	stateMaid["LocalPlayerAnimListener"] =
		animationPlayed:connect("StateListener_AnimationPlayed", onLocalAnimationPlayed)
end

---Is an effect within a specific time?
---@param effect table
---@param time number? If the number is unspecified, it will use the Debris time.
---@param offset boolean If the number is specified, should we use it as an offset from the Debris time?
---@return boolean
local function withinTime(effect, time, offset)
	if not effect.index then
		return false
	end

	local timestamp = effect.index.Timestamp
	if not timestamp then
		return false
	end

	local dtime = effect.index.DebrisTime
	if not dtime then
		return false
	end

	if offset and time then
		return os.clock() - timestamp <= (dtime + time)
	end

	return os.clock() - timestamp <= (time or dtime)
end

---Are we currently casting Sightless Beam?
---@return boolean
function StateListener.csb()
	if not StateListener.lMantraActivated then
		return false
	end

	local name = tostring(StateListener.lMantraActivated)
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
function StateListener.astun()
	local lAnimFaction = StateListener.lAnimFaction
	local lAnimationValidTrack = StateListener.lAnimationValidTrack
	local lAnimTimestamp = StateListener.lAnimTimestamp

	if not lAnimFaction and not lAnimationValidTrack and not lAnimTimestamp then
		return false
	end

	if lAnimationValidTrack.IsPlaying and os.clock() - lAnimTimestamp <= (lAnimFaction:when() + 0.1) then
		return true
	end

	return false
end

---Can we vent?
---@return boolean
function StateListener.cvent()
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	local ventCooldownEffect = effectReplicatorModule:FindEffect("NoBurst")

	local character = players.LocalPlayer and players.LocalPlayer.Character
	if not character then
		return false
	end

	local tempo = character:FindFirstChild("Tempo")
	if not tempo then
		return false
	end

	if tempo.Value < 40 then
		return false
	end

	if not effectReplicatorModule:FindEffect("Equipped") then
		return false
	end

	if ventCooldownEffect then
		return false
	end

	return true
end

---Can we block?
---@return boolean
function StateListener.cblock()
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	return effectReplicatorModule:HasAny("ShakyBlock", "CancelBlock")
end

---Can we parry?
---@return boolean
function StateListener.cparry()
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
function StateListener.cfeint()
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
function StateListener.cdodge()
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	local dodgeCooldownEffect = effectReplicatorModule:FindEffect("NoRoll")
	local stunCooldownEffect = effectReplicatorModule:FindEffect("Stun")

	if dodgeCooldownEffect then
		return false
	end

	if stunCooldownEffect and withinTime(stunCooldownEffect, nil, false) then
		return false
	end

	return true
end

---Are we in chime countdown?
---@return boolean
function StateListener.ccd()
	return game.PlaceId == CHIME_ARENA_PLACE_ID and workspace.DistributedGameTime < 15
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

	if effect.Class == "PerfectStack" then
		StateListener.chainStacks = 0
	end

	if effect.Class == "PerfectionCool" and StateListener.chainStacks then
		StateListener.chainStacks = math.min(StateListener.chainStacks + 1, 20)
	end
end)

---On effect removing.
---@param effect table
local onEffectRemoving = LPH_NO_VIRTUALIZE(function(effect)
	if effect.Class == "PerfectStack" then
		StateListener.chainStacks = nil
	end

	if not Configuration.expectToggleValue("EffectLogging") then
		return
	end

	warn(string.format("%s", tostring(effect)))
end)

---Initialize StateListener.
function StateListener.init()
	local live = workspace:WaitForChild("Live")
	local liveDescendantAdded = Signal.new(live.DescendantAdded)

	---@note: Not type of RBXScriptSignal - but it works.
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	local effectAddedSignal = Signal.new(effectReplicatorModule.EffectAdded)
	local effectRemovingSignal = Signal.new(effectReplicatorModule.EffectRemoving)

	stateMaid:mark(effectAddedSignal:connect("StateListener_EffectReplicated", onEffectReplicated))
	stateMaid:mark(effectRemovingSignal:connect("StateListener_EffectRemoving", onEffectRemoving))
	stateMaid:mark(liveDescendantAdded:connect("StateListener_DescendantAdded", onDescendantAdded))

	for _, effect in next, effectReplicatorModule.Effects do
		onEffectReplicated(effect)
	end

	for _, descendant in next, live:GetDescendants() do
		onDescendantAdded(descendant)
	end

	Logger.warn("StateListener initialized.")
end

---Detach StateListener.
function StateListener.detach()
	stateMaid:clean()
end

-- Return StateListener module.
return StateListener
