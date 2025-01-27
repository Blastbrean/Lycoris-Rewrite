---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Utility.Entitites
local Entities = require("Utility/Entitites")

---@module Utility.Table
local Table = require("Utility/Table")

---@module Features.Combat.Targeting
local Targeting = require("Features/Combat/Targeting")

---@class PartDefender: Defender
---@field owner Model? The owner of the part. There will be "no owner" if there is no animation to link to because we do not have enough data.
---@field part BasePart
---@field timing PartTiming
---@field touched boolean Determines whether if we touched the timing in the past.
local PartDefender = setmetatable({}, { __index = Defender })
PartDefender.__index = PartDefender
PartDefender.__type = "PartDefender"

-- Services.
local players = game:GetService("Players")

---Guess the nearest viable owner of a part by using a specific part timing.
---@param timing PartTiming
---@return Model?
local function guessOwnerFromPartTiming(timing)
	for _, entity in next, Entities.getEntitiesInRange(timing.imxd) do
		local humanoid = entity:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then
			continue
		end

		local animator = humanoid:FindFirstChildWhichIsA("Animator")
		if not animator then
			continue
		end

		local crossed = Table.elements(animator:GetPlayingAnimationTracks(), function(element)
			return table.find(timing.linked, tostring(element.Animation.AnimationId))
		end)

		if not crossed then
			continue
		end

		return entity
	end
end

---Check if we're in a valid state to proceed with the action.
---@param timing PartTiming
---@param action Action
---@return boolean
function PartDefender:valid(timing, action)
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

---Update PartDefender object.
function PartDefender:update()
	-- Deny updates if we already have actions in the queue.
	if #self.tasks > 0 then
		return
	end

	local localPlayer = players.LocalPlayer
	if not localPlayer then
		return
	end

	local character = localPlayer.Character
	if not character then
		return
	end

	-- Get current hitbox state.
	local touching = self:hitbox(self.part.Position, self.timing.hitbox, { character })

	-- Deny updates if the we were touching the part last and we are touching it now.
	if self.touched and touching then
		return
	end

	-- Ok, set the new state.
	self.touched = touching

	-- Clean all previous tasks. Just to be safe. We already check if it's empty... so.
	self:clean()

	-- Add actions.
	return self:actions(self.timing)
end

---Create new PartDefender object.
---@param part BasePart
---@param timing PartTiming
---@return PartDefender
function PartDefender.new(part, timing)
	local self = setmetatable(Defender.new(), PartDefender)
	self.part = part
	self.timing = timing
	self.owner = guessOwnerFromPartTiming(timing)
	self.touched = false
	return self
end

-- Return PartDefender module.
return PartDefender
