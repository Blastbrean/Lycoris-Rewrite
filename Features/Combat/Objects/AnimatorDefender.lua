---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Game.Timings.PlaybackData
local PlaybackData = require("Game/Timings/PlaybackData")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = require("Features/Combat/Objects/RepeatInfo")

---@module Game.QueuedBlocking
local QueuedBlocking = require("Game/QueuedBlocking")

---@module Features.Combat.Objects.HitboxOptions
local HitboxOptions = require("Features/Combat/Objects/HitboxOptions")

---@module Utility.OriginalStore
local OriginalStore = require("Utility/OriginalStore")

---@module Features.Combat.EntityHistory
local EntityHistory = require("Features/Combat/EntityHistory")

---@module Features.Combat.StateListener
local StateListener = require("Features/Combat/StateListener")

---@module Game.Latency
local Latency = require("Game/Latency")

---@module GUI.Library
local Library = require("GUI/Library")

---@class AnimatorDefender: Defender
---@field animator Animator
---@field offset number?
---@field entity Model
---@field keyframes Action[]
---@field timing AnimationTiming?
---@field pbdata table<AnimationTrack, PlaybackData> Playback data to be recorded.
---@field rpbdata table<string, PlaybackData> Recorded playback data. Optimization so we don't have to constantly reiterate over recorded data.
---@field manimations table<number, Animation>
---@field track AnimationTrack? Don't be confused. This is the **valid && last** animation track played.
---@field maid Maid This maid is cleaned up after every new animation track. Safe to use for on-animation-track setup.
---@field sct table<AnimationTrack, boolean> Tracks that need to have their speed changed.
---@field tsc table<AnimationTrack, number> Tracks that are saving their last speed.
local AnimatorDefender = setmetatable({}, { __index = Defender })
AnimatorDefender.__index = AnimatorDefender
AnimatorDefender.__type = "Animation"

-- Services.
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Constants.
local MAX_REPEAT_TIME = 5.0
local HISTORY_STEPS = 5.0
local PREDICT_FACING_DELTA = 3

---Is animation stopped? Made into a function for de-duplication.
---@param self AnimatorDefender
---@param track AnimationTrack
---@param timing AnimationTiming
---@param notify boolean? Whether to notify or not.
---@return boolean
AnimatorDefender.stopped = LPH_NO_VIRTUALIZE(function(self, track, timing, notify)
	local function internalNotifyFunction(...)
		if not notify then
			return
		end

		return self:notify(...)
	end

	local overrideData = Library:GetOverrideData(PP_SCRAMBLE_STR(timing.name))
	local rate = (Configuration.expectOptionValue("IgnoreAnimationEndRate") or 0.0)

	if overrideData then
		rate = overrideData.iaer
	end

	if
		(Configuration.expectToggleValue("AllowFailure") or overrideData)
		and not timing.rpue
		and Random.new():NextNumber(1.0, 100.0) <= rate
		and StateListener.cdodge()
	then
		return false, internalNotifyFunction(timing, "Intentionally ignoring animation end to simulate human error.")
	end

	if not timing.iae and not track.IsPlaying then
		return true, internalNotifyFunction(timing, "Animation stopped playing.")
	end

	if timing.iae and not timing.ieae and not track.IsPlaying and track.TimePosition < track.Length then
		return true, internalNotifyFunction(timing, "Animation stopped playing early.")
	end
end)

---Repeat conditional. Extra parameter 'track' added on.
---@param self AnimatorDefender
---@param info RepeatInfo
---@return boolean
AnimatorDefender.rc = LPH_NO_VIRTUALIZE(function(self, info)
	---@note: There are cases where we might not have a track. If it's not handled properly, it will throw an error.
	-- Perhaps, the animation can end and we're handling a different repeat conditional.
	if not info.track then
		return Logger.warn(
			"(%s) Did you forget to pass the track? Or perhaps you forgot to place a hook before using this function.",
			PP_SCRAMBLE_STR(info.timing.name)
		)
	end

	if self:stopped(info.track, info.timing) then
		return false
	end

	if info.timing.iae and os.clock() - info.start >= ((info.timing.mat / 1000) or MAX_REPEAT_TIME) then
		return self:notify(info.timing, "Max animation timeout exceeded.")
	end

	return true
end)

---Run predict facing hitbox check.
---@param self AnimatorDefender
---@param options HitboxOptions
---@return boolean
AnimatorDefender.pfh = LPH_NO_VIRTUALIZE(function(self, options)
	local root = self.entity:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	local localRoot = players.LocalPlayer.Character and players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not localRoot then
		return false
	end

	if not options.timing.ffh then
		local yrate = EntityHistory.yrate(self.entity)
		if not yrate then
			return false
		end

		if math.abs(yrate) < PREDICT_FACING_DELTA then
			return
		end
	end

	local clone = options:clone()
	clone.hcolor = Color3.new(0, 1, 1)
	clone.mcolor = Color3.new(1, 1, 0)
	clone:ucache()

	local result = false
	local store = OriginalStore.new()

	store:run(root, "CFrame", CFrame.lookAt(root.Position, localRoot.Position), function()
		result = self:hc(clone, nil)
	end)

	return result
end)

---Run past hitbox check.
---@param timing Timing
---@param options HitboxOptions
---@return boolean
AnimatorDefender.phd = LPH_NO_VIRTUALIZE(function(self, timing, options)
	for _, cframe in next, EntityHistory.pstepped(self.entity, HISTORY_STEPS, timing.phds) or {} do
		local clone = options:clone()
		clone.cframe = cframe
		clone.hcolor = Color3.new(0.839215, 0.976470, 0.537254)
		clone.mcolor = Color3.new(0.564705, 0, 1)
		clone:ucache()

		if not self:hc(clone, nil) then
			continue
		end

		return true
	end
end)

---Run our facing extrapolation / interpolation.
AnimatorDefender.fpc = LPH_NO_VIRTUALIZE(function(self, timing, options)
	if timing.duih then
		return false
	end

	if (timing.ffh or timing.pfh) and self:pfh(options) then
		return true
	end

	if timing.phd and self:phd(timing, options) then
		return true
	end
end)

---Check if we're in a valid state to proceed with the action.
---@param self AnimatorDefender
---@param options ValidationOptions
---@return boolean
AnimatorDefender.valid = LPH_NO_VIRTUALIZE(function(self, options)
	if not Defender.valid(self, options) then
		return false
	end

	local timing = options.timing
	local action = options.action

	local function internalNotifyFunction(...)
		if not options.notify then
			return
		end

		return self:notify(...)
	end

	if not self.track then
		return internalNotifyFunction(timing, "No current track.")
	end

	if not self.entity then
		return internalNotifyFunction(timing, "No entity found.")
	end

	local target = self:target(self.entity)
	if not target then
		return internalNotifyFunction(timing, "Not a viable target.")
	end

	local root = self.entity:FindFirstChild("HumanoidRootPart")
	if not root then
		return internalNotifyFunction(timing, "No humanoid root part found.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return internalNotifyFunction(timing, "No character found.")
	end

	local targetInstance = self.entity:FindFirstChild("Target")

	if
		targetInstance
		and targetInstance.Value ~= character
		and Configuration.expectToggleValue("CheckTargetingValue")
	then
		return internalNotifyFunction(timing, "Not being targeted.")
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return internalNotifyFunction(timing, "No effect replicator found.")
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return internalNotifyFunction(timing, "No effect replicator module found.")
	end

	if
		not timing.imb
		and root:FindFirstChild("MegalodauntBroken")
		and not players:GetPlayerFromCharacter(self.entity)
	then
		return internalNotifyFunction(timing, "Entity is block broken.")
	end

	if self:stopped(self.track, timing, options.notify) then
		return false
	end

	local hoptions = HitboxOptions.new(root, timing)
	hoptions.spredict = not timing.duih and not timing.dp
	hoptions.ptime = self:fsecs(timing)
	hoptions.action = action
	hoptions.entity = self.entity
	hoptions.visualize = options.visualize
	hoptions:ucache()

	local info = RepeatInfo.new(timing, Latency.rdelay(), self:uid(10))
	info.track = self.track

	local hc = self:hc(hoptions, timing.duih and info or nil)
	if hc then
		return true
	end

	local pc = self:fpc(timing, hoptions)
	if pc then
		return true
	end

	return self:notify(timing, "Not in hitbox.")
end)

---Update keyframe handling.
---@param self AnimatorDefender
AnimatorDefender.update = LPH_NO_VIRTUALIZE(function(self)
	for track, data in next, self.pbdata do
		-- Don't process tracks.
		if not Configuration.expectToggleValue("ShowAnimationVisualizer") then
			self.pbdata[track] = nil
			continue
		end

		-- Check if the track is playing.
		if not track.IsPlaying then
			-- Remove out of 'pbdata' and put it in to the recorded table.
			self.pbdata[track] = nil
			self.rpbdata[tostring(track.Animation.AnimationId)] = data

			-- Continue to next playback data.
			continue
		end

		-- Start tracking the animation's speed.
		data:astrack(track.Speed)
	end

	if not Configuration.expectToggleValue("AnimationSpeedChanger") then
		return
	end

	-- Animation speed changer.
	local min = Configuration.expectOptionValue("AnimationSpeedMinimum") or 1.0
	local max = Configuration.expectOptionValue("AnimationSpeedMaximum") or 1.3
	local rng = Random.new()

	for track, _ in next, self.sct do
		if not track.IsPlaying then
			self.sct[track] = nil
			self.tsc[track] = nil
			self.multiplier[track] = nil
			continue
		end

		if self.tsc[track] == tostring(track.Speed) then
			continue
		end

		local mode = rng:NextInteger(1, 2)
		local generated = nil

		if not self.multiplier[track] and not Configuration.expectToggleValue("SwitchBetweenSpeeds") then
			generated = rng:NextNumber(min, max)
		end

		if not self.multiplier[track] and Configuration.expectToggleValue("SwitchBetweenSpeeds") then
			generated = mode == 1 and min or max
		end

		if not self.multiplier[track] and generated then
			self.multiplier[track] = generated
		end

		local multiplier = self.multiplier[track]
		if not multiplier then
			continue
		end

		if multiplier == 1.0 then
			continue
		end

		local adjusted = track.Speed * multiplier

		track:AdjustSpeed(adjusted)

		self.tsc[track] = tostring(track.Speed)
	end
end)

---Virtualized processing checks.
---@param track AnimationTrack
---@return boolean
function AnimatorDefender:pvalidate(track)
	if track.Priority == Enum.AnimationPriority.Core or track.Priority == Enum.AnimationPriority.Idle then
		return false
	end

	local isComingFromPlayer = players:GetPlayerFromCharacter(self.entity)

	if isComingFromPlayer and track.WeightTarget <= 0.05 then
		return false
	end

	if isComingFromPlayer and self.manimations[track.Animation.AnimationId] ~= nil then
		Logger.warn(
			"(%s) Animation %s is being skipped from player %s because they're likely AP breaking.",
			self.manimations[track.Animation.AnimationId].Name,
			track.Animation.AnimationId,
			self.entity.Name
		)

		return false
	end

	return true
end

---Animation speed changer.
---@param self AnimatorDefender
---@param track AnimationTrack
AnimatorDefender.asc = LPH_NO_VIRTUALIZE(function(self, track)
	if not Configuration.expectToggleValue("AnimationSpeedChanger") then
		return
	end

	if
		Configuration.expectToggleValue("LimitToAPAnimations")
		and not SaveManager.as:index(tostring(track.Animation.AnimationId))
	then
		return
	end

	self.sct[track] = true
end)

---Process animation track.
---@todo: AP telemetry - aswell as tracking effects that are added with timestamps and current ping to that list.
---@param self AnimatorDefender
---@param track AnimationTrack
AnimatorDefender.process = LPH_NO_VIRTUALIZE(function(self, track)
	if players.LocalPlayer.Character and self.entity == players.LocalPlayer.Character then
		return self:asc(track)
	end

	if not self:pvalidate(track) then
		return
	end

	-- Animation ID.
	local aid = tostring(track.Animation.AnimationId)

	-- Block abnormal animation speeds to prevent AP breaker spam.
	if track.Speed >= 1000 then
		Logger.warn("(%s) Blocked potential AP breaker from %s (speed: %.0fx)", aid, self.entity.Name, track.Speed)
		return
	end

	---@type AnimationTiming?
	local timing = self:initial(self.entity, SaveManager.as, self.entity.Name, aid)

	-- A bit of a hack, but it works.
	if timing ~= nil and Configuration.expectToggleValue("ShowAnimationVisualizer") then
		self.pbdata[track] = PlaybackData.new(self.entity)
	end

	if not timing then
		return
	end

	if not Configuration.expectToggleValue("EnableAutoDefense") then
		return
	end

	local humanoidRootPart = self.entity:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	if timing.tag == "Critical" then
		timing.nbfb = true
		timing.ha = true
	end

	---@note: Clean up previous tasks that are still waiting or suspended because they're in a different track.
	self:clean()

	-- Set current data.
	self.timing = timing
	self.track = track
	self.offset = Latency.rdelay()

	-- Use module over actions.
	if timing.umoa then
		return self:module(timing)
	end

	---@note: Start processing the timing. Add the actions if we're not RPUE.
	if not timing.rpue then
		return self:actions(timing)
	end

	-- Start RPUE.
	local info = RepeatInfo.new(timing, Latency.rdelay(), self:uid(10))
	info.track = track
	self:srpue(self.entity, timing, info)
end)

---Clean up the defender.
function AnimatorDefender:clean()
	-- Empty data.
	self.keyframes = {}

	-- Clean through base method.
	Defender.clean(self)
end

---Create new AnimatorDefender object.
---@param animator Animator
---@param manimations table<number, Animation>
---@return AnimatorDefender
function AnimatorDefender.new(animator, manimations)
	local entity = animator:FindFirstAncestorWhichIsA("Model")
	if not entity then
		return error(string.format("AnimatorDefender.new(%s) - no entity.", animator:GetFullName()))
	end

	local self = setmetatable(Defender.new(), AnimatorDefender)
	local animationPlayed = Signal.new(animator.AnimationPlayed)

	self.animator = animator
	self.manimations = manimations
	self.entity = entity

	self.track = nil
	self.timing = nil
	self.offset = nil

	self.keyframes = {}
	self.pbdata = {}
	self.rpbdata = {}
	self.sct = {}
	self.tsc = {}
	self.multiplier = {}

	self.maid:mark(animationPlayed:connect(
		"AnimatorDefender_OnAnimationPlayed",
		LPH_NO_VIRTUALIZE(function(track)
			self:process(track)
		end)
	))

	return self
end

-- Return AnimatorDefender module.
return AnimatorDefender
