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

---@class AnimatorDefender: Defender
---@field animator Animator
---@field entity Model
---@field heffects Instance[]
---@field manimations table<number, Animation>
---@field track AnimationTrack? Don't be confused. This is the **valid && last** animation track played.
---@field maid Maid This maid is cleaned up after every new animation track. Safe to use for on-animation-track setup.
local AnimatorDefender = setmetatable({}, { __index = Defender })
AnimatorDefender.__index = AnimatorDefender
AnimatorDefender.__type = "Animation"

-- Services.
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

---Find the Heavy Hands Ring instance in a character.
---@param character Model
---@return Instance
local function hasHeavyHandsRing(character)
	for _, instance in pairs(character:GetChildren()) do
		if instance:GetAttribute("EquipmentRef") ~= "Heavy Hands Ring" then
			continue
		end

		return instance
	end
end

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

	local character = players.LocalPlayer.Character
	if not character then
		return self:notify(timing, "No character found.")
	end

	if not self:hitbox((target.root.CFrame).Position, action.hitbox.Z / 2, action.hitbox, { character }) then
		return self:notify(timing, "Not inside of the hitbox.")
	end

	local targetInstance = self.entity:FindFirstChild("Target")
	if targetInstance and targetInstance.Value ~= character and Configuration.toggleValue("CheckTargetingValue") then
		return self:notify(timing, "Not being targeted.")
	end

	if not self.track.IsPlaying then
		return self:notify(timing, "Animation stopped playing.")
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

	if not self:initial(self.entity, SaveManager.as, self.entity.Name, tostring(track.Animation.AnimationId)) then
		return
	end

	self:notify(timing, "(%i) Action 'RPUE Parry' is being executed.", index)

	InputClient.parry()
end)

---Process animation track.
---@todo: Logger module.
---@param track AnimationTrack
AnimatorDefender.process = LPH_NO_VIRTUALIZE(function(self, track)
	if not Configuration.expectToggleValue("EnableAutoDefense") then
		return
	end

	if track.Priority == Enum.AnimationPriority.Core then
		return
	end

	if track.WeightTarget <= 0.05 then
		return Logger.warn(
			"Animation %s is being skipped from entity %s with speed %.2f and weight-target %.2f. It is hidden.",
			track.Animation.AnimationId,
			self.entity.Name,
			track.WeightTarget,
			track.Speed
		)
	end

	if players:GetPlayerFromCharacter(self.entity) and self.manimations[track.Animation.AnimationId] ~= nil then
		return Logger.warn(
			"Animation %s is being skipped from player %s because they're likely AP breaking.",
			track.Animation.AnimationId,
			self.entity.Name
		)
	end

	local localCharacter = players.LocalPlayer.Character
	if localCharacter and self.entity == localCharacter then
		return
	end

	---@type AnimationTiming?
	local timing = self:initial(self.entity, SaveManager.as, self.entity.Name, tostring(track.Animation.AnimationId))
	if not timing then
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

	if not effectReplicatorModule:FindEffect("FeintCool") and (shouldFeintAttack or shouldFeintMantra) then
		-- Log.
		self:notify(timing, "Automatically feinting attack.")

		-- Feint.
		InputClient.feint()
	end

	---@note: Clean up previous tasks that are still waiting or suspended because they're in a different track.
	self:clean()

	-- Set current data.
	self.track = track
	self.heffects = {}

	---@note: Start processing the timing. Add the actions if we're not RPUE.
	if not timing.rpue then
		return self:actions(timing, timing.tag == "M1" and hasHeavyHandsRing(self.entity) and 0.85 or 1)
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
	self.heffects = {}

	self.maid:mark(entityDescendantAdded:connect("AnimatorDefender_OnDescendantAdded", function(descendant)
		if
			descendant.Name ~= "PunchBlood"
			and descendant.Name ~= "PunchEffect"
			and descendant.Name ~= "BloodSpray"
			and not (descendant:IsA("ParticleEmitter") and descendant.Texture == "rbxassetid://7216855595")
		then
			return
		end

		self.heffects[#self.heffects + 1] = descendant
	end))

	self.maid:mark(animationPlayed:connect("AnimatorDefender_OnAnimationPlayed", function(track)
		self:process(track)
	end))

	return self
end

-- Return AnimatorDefender module.
return AnimatorDefender
