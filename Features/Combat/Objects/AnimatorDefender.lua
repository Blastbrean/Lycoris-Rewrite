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

---@module Features.Combat.Objects.HitboxOptions
local HitboxOptions = require("Features/Combat/Objects/HitboxOptions")

---@module Features.Combat.Objects.Task
local Task = require("Features/Combat/Objects/Task")

---@class AnimatorDefender: Defender
---@field animator Animator
---@field entity Model
---@field heffects Instance[]
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

-- Constants.
local MAX_REPEAT_TIME = 5.0

---Is animation stopped? Made into a function for de-duplication.
---@param self AnimatorDefender
---@param track AnimationTrack
---@param timing AnimationTiming
---@return boolean
AnimatorDefender.stopped = LPH_NO_VIRTUALIZE(function(self, track, timing)
	if not timing.iae and not track.IsPlaying then
		return true, self:notify(timing, "Animation stopped playing.")
	end

	if timing.iae and not timing.ieae and not track.IsPlaying and track.TimePosition < track.Length then
		return true, self:notify(timing, "Animation stopped playing early.")
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
			info.timing.name
		)
	end

	if self:stopped(info.track, info.timing) then
		return false
	end

	if info.timing.iae and info.timing.ieae and os.clock() - info.start >= MAX_REPEAT_TIME then
		return self:notify(info.timing, "Max repeat time exceeded.")
	end

	return true
end)

---Check if we're in a valid state to proceed with the action.
---@param self AnimatorDefender
---@param timing AnimationTiming
---@param action Action
---@return boolean
AnimatorDefender.valid = LPH_NO_VIRTUALIZE(function(self, timing, action)
	if not Defender.valid(self, timing, action) then
		return false
	end

	if not self.track then
		return self:notify(timing, "No current track.")
	end

	if not self.entity then
		return self:notify(timing, "No entity found.")
	end

	local target = self:target(self.entity)
	if not target then
		return self:notify(timing, "Not a viable target.")
	end

	local root = self.entity:FindFirstChild("HumanoidRootPart")
	if not root then
		return self:notify(timing, "No humanoid root part found.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return self:notify(timing, "No character found.")
	end

	local targetInstance = self.entity:FindFirstChild("Target")

	if
		targetInstance
		and targetInstance.Value ~= character
		and Configuration.expectToggleValue("CheckTargetingValue")
	then
		return self:notify(timing, "Not being targeted.")
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

	if root:FindFirstChild("MegalodauntBroken") and not players:GetPlayerFromCharacter(self.entity) then
		return self:notify(timing, "Entity is block broken.")
	end

	if self:stopped(self.track, timing) then
		return false
	end

	local options = HitboxOptions.new(root, timing)
	options.spredict = true
	options.action = action
	options.entity = self.entity

	local info = RepeatInfo.new(timing)
	info.track = self.track

	if not self:hc(options, timing.duih and info or nil) then
		return self:notify(timing, "Not in hitbox.")
	end

	return true
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
end)

---Virtualized processing checks.
---@param track AnimationTrack
---@return boolean
function AnimatorDefender:pvalidate(track)
	if track.Priority == Enum.AnimationPriority.Core then
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

---Process animation track.
---@todo: AP telemetry - aswell as tracking effects that are added with timestamps and current ping to that list.
---@param self AnimatorDefender
---@param track AnimationTrack
AnimatorDefender.process = LPH_NO_VIRTUALIZE(function(self, track)
	if players.LocalPlayer.Character and self.entity == players.LocalPlayer.Character then
		return
	end

	if not self:pvalidate(track) then
		return
	end

	-- Add to playback data list.
	if Configuration.expectToggleValue("ShowAnimationVisualizer") then
		self.pbdata[track] = PlaybackData.new(self.entity)
	end

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
	local shouldFeintAttack = midAttackCanFeint and Configuration.expectToggleValue("FeintM1WhileDefending")
	local shouldFeintMantra = effectReplicatorModule:FindEffect("CastingSpell")
		and Configuration.expectToggleValue("FeintMantrasWhileDefending")

	---@todo: Auto-feint should work on all types and should try to be feinting during every waiting period.
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
	self.track = track

	-- Use module over actions.
	if timing.umoa then
		return self:module(timing)
	end

	---@note: Start processing the timing. Add the actions if we're not RPUE.
	if not timing.rpue then
		return self:actions(timing)
	end

	-- Start RPUE.
	local info = RepeatInfo.new(timing)
	info.track = track
	info.irdelay = self.rdelay()

	self:mark(Task.new(string.format("RPUE_%s_%i", timing.name, 0), function()
		return timing:rsd() - info.irdelay - self.sdelay()
	end, timing.punishable, timing.after, self.rpue, self, self.entity, timing, info))

	-- Notify.
	self:notify(
		timing,
		"Added RPUE '%s' (%.2fs, then every %.2fs) with ping '%.2f' (changing) subtracted.",
		timing.name,
		timing:rsd(),
		timing:rpd(),
		self.rtt()
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

	self.track = nil
	self.timing = nil

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
