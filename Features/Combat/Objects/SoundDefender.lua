---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Features.Combat.Targeting
local Targeting = require("Features/Combat/Targeting")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@class SoundDefender: Defender
---@field owner Model? The owner of the part.
---@field sound Sound The sound that we're defending.
---@field part BasePart A part that we can base the position off of.
local SoundDefender = setmetatable({}, { __index = Defender })
SoundDefender.__index = SoundDefender
SoundDefender.__type = "SoundDefender"

-- Services.
local players = game:GetService("Players")

---Override notify to include type.
---@param timing Timing
---@param str string
function SoundDefender:notify(timing, str, ...)
	Defender.notify(self, timing, string.format("[Sound] %s", str), ...)
end

---Check if we're in a valid state to proceed with the action.
---@param timing PartTiming
---@param action Action
---@return boolean
function SoundDefender:valid(timing, action)
	if self.owner and not Targeting.find(self.owner) then
		return self:notify(timing, "Not a viable target.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return self:notify(timing, "No character found.")
	end

	if not self:hitbox(self.part.Position, action.hitbox, { character }) then
		return self:notify(timing, "Not inside of the hitbox.")
	end

	return true
end

---Check if the initial state is valid.
---@param timing SoundTiming
---@return boolean
function SoundDefender:initial(timing)
	local localCharacter = players.LocalPlayer.Character
	if not localCharacter then
		return false
	end

	local localRootPart = localCharacter:FindFirstChild("HumanoidRootPart")
	if not localRootPart then
		return false
	end

	local distance = (self.part.Position - localRootPart.Position).Magnitude

	if distance < timing.imdd then
		return false
	end

	if distance > timing.imxd then
		return false
	end

	return true
end

---Process sound playing
function SoundDefender:process()
	local timing = SaveManager.ss:index(self.sound.SoundId)
	if not timing then
		return
	end

	if not self:initial(timing) then
		return
	end

	---@note: Clean up previous tasks that are still waiting or suspended because they're in a different track.
	self:clean()

	-- Add actions.
	return self:actions(timing)
end

---Create new SoundDefender object.
---@param sound Sound
---@param timing SoundTiming
---@param part BasePart
---@return SoundDefender
function SoundDefender.new(sound, timing, part)
	local self = setmetatable(Defender.new(), SoundDefender)
	local soundPlayed = Signal.new(sound.Played)

	self.sound = sound
	self.timing = timing
	self.part = part
	self.owner = sound:FindFirstAncestorWhichIsA("Model")
	self.maid:mark(soundPlayed:connect("SoundDefender_OnSoundPlayed", function()
		self:process()
	end))

	return self
end

-- Return SoundDefender module.
return SoundDefender
