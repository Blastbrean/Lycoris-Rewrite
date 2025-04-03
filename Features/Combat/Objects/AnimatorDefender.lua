---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Features.Combat.Targeting
local Targeting = require("Features/Combat/Targeting")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Features.Combat.Objects.Task
local Task = require("Features/Combat/Objects/Task")

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

---@module Game.Timings.PlaybackData
local PlaybackData = require("Game/Timings/PlaybackData")

---@class AnimatorDefender: Defender
---@field animator Animator
---@field entity Model
---@field heffects Instance[]
---@field offset number? The ping in seconds when we received the animation track.
---@field lunisynctp number? The last time we unisynced the animation track.
---@field keyframes Action[]
---@field timing AnimationTiming?
---@field pbdata table<AnimationTrack, PlaybackData> Playback data to be recorded.
---@field rpbdata table<string, PlaybackData> Recorded playback data. Optimization so we don't have to constantly reiterate over recorded data.
---@field manimations table<number, Animation>
---@field track AnimationTrack? Don't be confused. This is the **valid && last** animation track played.
---@field maid Maid This maid is cleaned up after every new animation track. Safe to use for on-animation-track setup.
local AnimatorDefender = setmetatable({}, { __index = Defender })
AnimatorDefender.__index = AnimatorDefender
AnimatorDefender.__type = "Animation"

-- Services.
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

---Check if we're in a valid state to proceed with the action.
---@param timing AnimationTiming
---@param action Action
---@return boolean
AnimatorDefender.valid = LPH_NO_VIRTUALIZE(function(self, timing, action)
	if not self.track then
		return self:notify(timing, "No current track.")
	end

	if not self.entity then
		return self:notify(timing, "No entity found.")
	end

	local target = Targeting.find(self.entity)
	if not target then
		return self:notify(timing, "Not a viable target.")
	end

	while
		timing.duih
		and not self:hitbox(
			target.root.CFrame,
			timing.fhb and action.hitbox.Z / 2 or 0,
			timing.hitbox,
			{ players.LocalPlayer.Character }
		)
	do
		task.wait()
	end

	local character = players.LocalPlayer.Character
	if not character then
		return self:notify(timing, "No character found.")
	end

	if not self:hitbox(target.root.CFrame, timing.fhb and action.hitbox.Z / 2 or 0, action.hitbox, { character }) then
		return self:notify(timing, "Not inside of the hitbox.")
	end

	local targetInstance = self.entity:FindFirstChild("Target")

	if
		targetInstance
		and targetInstance.Value ~= character
		and Configuration.expectToggleValue("CheckTargetingValue")
	then
		return self:notify(timing, "Not being targeted.")
	end

	if not timing.iae and not self.track.IsPlaying then
		return self:notify(timing, "Animation stopped playing.")
	end

	if timing.iae and not self.track.IsPlaying and self.track.TimePosition < self.track.Length then
		return self:notify(timing, "Animation stopped playing early.")
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return self:notify(timing, "No effect replicator found.")
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return self:notify(timing, "No effect replicator module found.")
	end

	if
		not timing.ha
		and #self.heffects >= 1
		and (players:GetPlayerFromCharacter(self.entity) or self.entity:FindFirstChild("HumanController"))
	then
		return self:notify(timing, "Entity got attack cancelled.")
	end

	return true
end)

---Repeat until parry end.
---@param track AnimationTrack
---@param timing AnimationTiming
---@param index number
AnimatorDefender.rpue = LPH_NO_VIRTUALIZE(function(self, track, timing, index)
	if not self.track.IsPlaying then
		return
	end

	self:mark(
		Task.new(
			string.format("RPUE_%s_%i", timing.name, index),
			timing:rpd() - self:ping(),
			timing.punishable,
			timing.after,
			self.rpue,
			self,
			track,
			timing,
			index + 1
		)
	)

	if
		timing.duih
		and not self:hitbox(
			Targeting.find(self.entity).root.CFrame,
			0,
			timing.hitbox,
			{ players.LocalPlayer.Character }
		)
	then
		return
	end

	if not self:initial(self.entity, SaveManager.as, self.entity.Name, tostring(track.Animation.AnimationId)) then
		return
	end

	self:notify(timing, "(%i) Action 'RPUE Parry' is being executed.", index)

	InputClient.parry()
end)

---Get latest keyframe that we've exceeded.
---@return Action?
AnimatorDefender.latest = LPH_NO_VIRTUALIZE(function(self)
	local latestKeyframe = nil
	local latestTimePosition = nil

	for _, keyframe in next, self.keyframes do
		if (self:tp() or 0.0) <= keyframe.tp then
			continue
		end

		if latestTimePosition and keyframe.tp <= latestTimePosition then
			continue
		end

		latestTimePosition = keyframe.tp
		latestKeyframe = keyframe
	end

	return latestKeyframe
end)

 ---Get time position from history and track.
 ---@param track AnimationTrack
 ---@param pbdata PlaybackData
 ---@param offset number
 ---@return number?
 function AnimatorDefender:tpfh(track, pbdata, offset)
 	local last, delta = pbdata:last(offset)
 	if not last then
 		return nil
 	end
 
 	local lnext, _ = pbdata:last(offset + delta)
 	if not lnext then
 		return nil
 	end
 
 	---@note: This is the amount of seconds before the delta is reached.
 	local first = offset - delta
 
 	---@note: This is the amount of seconds after the delta is reached.
 	local second = delta
 
 	---@note: This means that the conversion to time position can use the last reached speed from the offset.
 	--- Then, the next conversion to time position can use the next reached speed from the offset after the delta.
 	--- After that, we just add them together and we have our proper answer.
 	return track.TimePosition + (first * last) + (second * lnext)
 end
 
 ---Get time position of current track.
 ---@note: This method is ping compensated, we attempt to calculate from the initial delay of receiving the animation how much forwards (e.g where we would be at) we would be.
 ---@todo: We should likely also subtract our round-trip time (e.g double the ping) since we have a receiving delay and a sending delay when we send the action to the server.
 ---@return number?
 function AnimatorDefender:tp()
 	if not self.track or self.offset == nil then
 		return nil
 	end
 
 	-- Check if we have valid speed history to go off of.
 	local pbdata = self.rpbdata[tostring(self.track.Animation.AnimationId)]
 	if pbdata then
 		return self:tpfh(self.track, pbdata, self.offset)
 	end
 
 	---@note: Compensate for ping. Shift the current position up by the offset to counteract the delay that we had receiving the animation.
 	--- We have no valid speed history to go off of. Let's use the current speed.
 	return self.track.TimePosition + (self.offset * self.track.Speed)
end

---Update playback data tracking. Attempt to record data for tracks that have not been recorded yet.
---@param self AnimatorDefender
AnimatorDefender.updt = LPH_NO_VIRTUALIZE(function(self)
	for track, data in next, self.pbdata do
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
end)

---Update keyframe handling.
---@param self AnimatorDefender
AnimatorDefender.update = LPH_NO_VIRTUALIZE(function(self)
	-- Update playback data tracking.
	self:updt()

	-- Run on validated track & timing.
	if not self.track or not self.timing then
		return
	end

	if not self.track.IsPlaying then
		return
	end

	-- Start blocking inputs if we have keyframes to process.
	if #self.keyframes >= 1 then
		self:smarker("KeyframeAction")
	end

	-- Find the latest keyframe that we have exceeded, if there is even any.
	local latest = self:latest()
	if not latest then
		return
	end

	-- Clear the keyframes that we have exceeded.
	local tp = self:tp() or 0.0

	for idx, keyframe in next, self.keyframes do
		if tp <= keyframe.tp then
			continue
		end

		self.keyframes[idx] = nil
	end

	-- Stop blocking inputs if there are no more keyframes to process.
	if #self.keyframes <= 0 then
		self:emarker("KeyframeAction")
	end

	-- Ok, run action of this keyframe.
	self.maid:mark(
		TaskSpawner.spawn(
			string.format("KeyframeAction_%s", latest._type),
			self.handle,
			self,
			self.timing,
			latest,
			"(%.2f) (compensating %.2f) Keyframe action type '%s' is being executed.",
			tp,
			tp - self.track.TimePosition,
			latest._type
		)
	)
end)

---Add animation delta actions.
---@param self AnimatorDefender
---@param timing AnimationTiming
AnimatorDefender.aeactions = LPH_NO_VIRTUALIZE(function(self, timing)
	for _, action in next, timing.actions:get() do
		-- Skip all actions that are non animation delta based.
		if not action.utp then
			continue
		end

		-- Add to keyframe list.
		self.keyframes[#self.keyframes + 1] = action

		-- Log.
		self:notify(
			timing,
			"Added action '%s' (position %.2f) with ping '%.2f' adjusted for.",
			action.name,
			action.tp,
			self.offset
		)
	end
end)

---Unisync animation track.
---@note: This doesn't work as I intended it to when I wrote it. But, it works and if I try to change it - it breaks. Fix me later.
---@param track AnimationTrack
function AnimatorDefender:unisync(track)
	if track.TimePosition == self.lunisynctp then
		return
	end

	if track.Looped then
		return
	end

	if not Configuration.expectToggleValue("AnimationUnisync") then
		return
	end

	-- Fetch frequency.
	local frequency = (Configuration.expectOptionValue("AnimationUnisyncFrequency") / 1000 or 0.05)

	-- Log.
	Logger.warn("Unisyncing animation '%s' in %.2fms.", track.Animation.AnimationId, frequency * 1000)

	-- Stop track immediately and save state.
	local lastWeightCurrent, lastSpeed, lastTimePosition, lastPriority =
		track.WeightCurrent, track.Speed, track.TimePosition, track.Priority

	track:Stop(0.0)

	-- Force priority to core instantly.
	track.Priority = Enum.AnimationPriority.Core

	-- Replay animation at faked priority state.
	track:Play(0.0, lastWeightCurrent, lastSpeed)
	track.TimePosition = lastTimePosition
	track.Priority = lastPriority

	-- Set last unisync time position.
	self.lunisynctp = track.TimePosition

	-- Unisync.
	self.maid:add(TaskSpawner.delay("AnimationDefender_UnisyncAnimation", frequency, function()
		-- Return if the animation is not playing.
		if not track.IsPlaying then
			return track:Stop(0.0)
		end

		-- Stop and save state.
		local stoppedWeightCurrent, stoppedSpeed, stoppedTimePosition =
			track.WeightCurrent, track.Speed, track.TimePosition

		track:Stop(0.0)

		-- Play animation at fake state.
		track:Play(
			0.0,
			Configuration.expectOptionValue("AnimationUnisyncWeight") or 0.0,
			Configuration.expectOptionValue("AnimationUnisyncSpeed") or -10.0
		)

		-- Set *real* animation speed, weight, and time position.
		track:AdjustSpeed(stoppedSpeed)
		track:AdjustWeight(stoppedWeightCurrent, 0.0)
		track.TimePosition = stoppedTimePosition

		-- Set last unisync time position.
		self.lunisynctp = track.TimePosition

		-- Repeat cycle.
		self:unisync(track)
	end))
end

---Virtualized processing checks.
---@param track AnimationTrack
---@return boolean
function AnimatorDefender:pvalidate(track)
	if track.Priority == Enum.AnimationPriority.Core then
		return false
	end

	if track.WeightTarget <= 0.05 then
		Logger.warn(
			"Animation %s is being skipped from entity %s with speed %.2f and weight-target %.2f. It is hidden.",
			track.Animation.AnimationId,
			self.entity.Name,
			track.WeightTarget,
			track.Speed
		)

		return false
	end

	if players:GetPlayerFromCharacter(self.entity) and self.manimations[track.Animation.AnimationId] ~= nil then
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

---Process animation track.
---@todo: Logger module.
---@param track AnimationTrack
AnimatorDefender.process = LPH_NO_VIRTUALIZE(function(self, track)
	local localCharacter = players.LocalPlayer.Character
	if localCharacter and self.entity == localCharacter then
		return self:unisync(track)
	end

	if not self:pvalidate(track) then
		return
	end

	-- Add to playback data list.
	self.pbdata[track] = PlaybackData.new(self.entity)

	-- Animation ID.
	local aid = tostring(track.Animation.AnimationId)

	---@type AnimationTiming?
	local timing = self:initial(self.entity, SaveManager.as, self.entity.Name, aid)
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

	local midAttackEffect = effectReplicatorModule:FindEffect("MidAttack")
	local midAttackData = midAttackEffect and midAttackEffect.index
	local midAttackExpiry = midAttackData and midAttackData.Expiration
	local midAttackCanFeint = midAttackExpiry and (os.clock() - midAttackExpiry) <= 0.45

	-- Stop! We need to feint if we're currently attacking. Input block will handle the rest.
	-- Assume, we cannot react in time. Example: we attacked just right before this process call.
	---@note: Replicate to other types. Improve me or move me.
	local shouldFeintAttack = midAttackCanFeint and Configuration.expectToggleValue("FeintM1WhileDefending")
	local shouldFeintMantra = effectReplicatorModule:FindEffect("CastingSpell")
		and Configuration.expectToggleValue("FeintMantrasWhileDefending")

	if not effectReplicatorModule:FindEffect("FeintCool") and (shouldFeintAttack or shouldFeintMantra) then
		-- Log.
		self:notify(timing, "Automatically feinting attack.")

		-- Feint.
		InputClient.feint()
	end

	---@note: Clean up previous tasks that are still waiting or suspended because they're in a different track.
	self:clean()

	-- Set current data.
	self.timing = timing
	self.offset = self:ping()
	self.track = track

	-- Use module over actions.
	if timing.umoa then
		return self:module(timing)
	end

	---@note: Start processing the timing. Add the actions if we're not RPUE.
	if not timing.rpue then
		-- Add animation actions.
		self:aeactions(timing)

		-- Add actions.
		self:actions(timing)

		-- Return.
		return
	end

	self:mark(
		Task.new(
			string.format("RPUE_%s", timing.name),
			timing:rsd() - self:ping(),
			timing.punishable,
			timing.after,
			self.rpue,
			self,
			track,
			timing,
			0
		)
	)

	self:notify(
		timing,
		"Added RPUE '%s' (%.2fs, then every %.2fs) with relevant ping subtracted.",
		timing.name,
		timing:rsd(),
		timing:rpd()
	)
end)

---Clean up the defender.
function AnimatorDefender:clean()
	-- Empty data.
	self.keyframes = {}
	self.heffects = {}

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
	local entityDescendantAdded = Signal.new(entity.DescendantAdded)

	self.animator = animator
	self.manimations = manimations
	self.entity = entity

	self.offset = nil
	self.track = nil
	self.timing = nil
	self.lunisynctp = nil

	self.heffects = {}
	self.keyframes = {}
	self.pbdata = {}
	self.rpbdata = {}

	self.maid:mark(
		entityDescendantAdded:connect(
			"AnimatorDefender_OnDescendantAdded",
			LPH_NO_VIRTUALIZE(function(descendant)
				if
					descendant.Name ~= "PunchBlood"
					and descendant.Name ~= "PunchEffect"
					and descendant.Name ~= "BloodSpray"
					and not (descendant:IsA("ParticleEmitter") and descendant.Texture == "rbxassetid://7216855595")
				then
					return
				end

				self.heffects[#self.heffects + 1] = descendant
			end)
		)
	)

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
