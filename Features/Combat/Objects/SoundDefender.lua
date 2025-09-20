---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = require("Features/Combat/Objects/RepeatInfo")

---@module Features.Combat.Objects.HitboxOptions
local HitboxOptions = require("Features/Combat/Objects/HitboxOptions")

---@class SoundDefender: Defender
---@field owner Model? The owner of the part.
---@field sound Sound The sound that we're defending.
---@field part BasePart A part that we can base the position off of.
local SoundDefender = setmetatable({}, { __index = Defender })
SoundDefender.__index = SoundDefender
SoundDefender.__type = "Sound"

-- Services.
local players = game:GetService("Players")

---Check if we're in a valid state to proceed with the action.
---@param self SoundDefender
---@param timing PartTiming
---@param action Action
---@return boolean
SoundDefender.valid = LPH_NO_VIRTUALIZE(function(self, timing, action)
	if not Defender.valid(self, timing, action) then
		return false
	end

	if self.owner and not self:target(self.owner) then
		return self:notify(timing, "Not a viable target.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return self:notify(timing, "No character found.")
	end

	local options = HitboxOptions.new(self.part, timing)
	options.spredict = false
	options.action = action

	if not self:hc(options, timing.duih and RepeatInfo.new(timing, self.rdelay(), self:uid(10)) or nil) then
		return self:notify(timing, "Not in hitbox.")
	end

	return true
end)

---Repeat conditional.
---@param self SoundDefender
---@param _ RepeatInfo
---@return boolean
SoundDefender.rc = LPH_NO_VIRTUALIZE(function(self, _)
	if not self.sound.IsPlaying then
		return false
	end

	return true
end)

---Process sound playing.
---@param self SoundDefender
SoundDefender.process = LPH_NO_VIRTUALIZE(function(self)
	---@type SoundTiming?
	local timing = self:initial(
		self.owner or self.part,
		SaveManager.ss,
		self.owner and self.owner.Name or self.part.Name,
		tostring(self.sound.SoundId)
	)

	if not timing then
		return
	end

	if not Configuration.expectToggleValue("EnableAutoDefense") then
		return
	end

	if players.LocalPlayer.Character and self.owner == players.LocalPlayer.Character then
		return
	end

	---@note: Clean up previous tasks that are still waiting or suspended because they're in a different track.
	self:clean()

	-- Use module if we need to.
	if timing.umoa then
		return self:module(timing)
	end

	-- Add actions.
	return self:actions(timing)
end)

---Create new SoundDefender object.
---@param sound Sound
---@param part BasePart
---@return SoundDefender
function SoundDefender.new(sound, part)
	local self = setmetatable(Defender.new(), SoundDefender)
	local soundPlayed = Signal.new(sound.Played)

	self.sound = sound
	self.part = part
	self.owner = sound:FindFirstAncestorWhichIsA("Model")
	self.maid:mark(soundPlayed:connect(
		"SoundDefender_OnSoundPlayed",
		LPH_NO_VIRTUALIZE(function()
			self:process()
		end)
	))

	if sound.Playing then
		self:process()
	end

	return self
end

-- Return SoundDefender module.
return SoundDefender
