---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Utility.Entitites
local Entities = require("Utility/Entitites")

---@module Utility.Table
local Table = require("Utility/Table")

---@module Features.Combat.Targeting
local Targeting = require("Features/Combat/Targeting")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@class PartDefender: Defender
---@field owner Model? The owner of the part. There will be "no owner" if there is no animation to link to because we do not have enough data.
---@field part BasePart
---@field timing PartTiming
---@field touched boolean Determines whether if we touched the timing in the past.
---@field finished boolean Determines whether if we finished the timing. This is used when we're doing timing delay instead of delay until in hitbox.
local PartDefender = setmetatable({}, { __index = Defender })
PartDefender.__index = PartDefender
PartDefender.__type = "Part"

-- Services.
local players = game:GetService("Players")

---Guess the nearest viable owner of a part by using a specific part timing.
---@param timing PartTiming
---@return Model?
local guessOwnerFromPartTiming = LPH_NO_VIRTUALIZE(function(timing)
	for _, entity in next, Entities.getEntitiesInRange(timing.imxd) do
		local humanoid = entity:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then
			continue
		end

		local animator = humanoid:FindFirstChildWhichIsA("Animator")
		if not animator then
			continue
		end

		---@note: Might have to fix. What if the player's track ended?
		local crossed = Table.elements(animator:GetPlayingAnimationTracks(), function(element)
			return table.find(timing.linked, tostring(element.Animation.AnimationId))
		end)

		if not crossed then
			continue
		end

		return entity
	end
end)

---Check if we're in a valid state to proceed with the action.
---@param timing PartTiming
---@param action Action
---@param origin CFrame?
---@param foreign boolean?
---@return boolean
PartDefender.valid = LPH_NO_VIRTUALIZE(function(self, timing, action, origin, foreign)
	if not Defender.valid(self, timing, action) then
		return false
	end

	if not foreign and self.owner and not Targeting.find(self.owner) then
		return self:notify(timing, "Not a viable target.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return self:notify(timing, "No character found.")
	end

	---@note: If we're using PartDefender, why perserve rotation? It's likely wrong or gonna mess us up.
	--- Also, ignore this if we're using delay until in hitbox since there'd be no use-case for it being seperated.
	if
		not self.timing.duih
		and not self:hitbox(origin or CFrame.new(self.part.Position), 0, action.hitbox, { character })
	then
		return self:notify(timing, "Not inside of the hitbox.")
	end

	return true
end)

---Update PartDefender object.
PartDefender.update = LPH_NO_VIRTUALIZE(function(self)
	-- Check if we're finished.
	if self.finished then
		return
	end

	-- Handle no hitbox delay.
	if not self.timing.duih then
		-- Use module if we need to, else add actions.
		if self.timing.umoa then
			self:module(self.timing)
		else
			self:actions(self.timing)
		end

		-- Set that we're finished so we don't have to do this again.
		self.finished = true

		-- Return.
		return
	end

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
	---@note: If we're using PartDefender, why perserve rotation? It's likely wrong or gonna mess us up.
	local touching = self:hitbox(CFrame.new(self.part.Position), 0, self.timing.hitbox, { character })

	-- Deny updates if we're not touching the part.
	if not touching then
		return
	end

	-- Deny updates if the we were touching the part last and we are touching it now.
	if self.touched and touching then
		return
	end

	-- Ok, set the new state.
	self.touched = touching

	-- Clean all previous tasks. Just to be safe. We already check if it's empty... so.
	self:clean()

	-- Use module if we need to.
	if self.timing.umoa then
		return self:module(self.timing)
	end

	-- Add actions.
	return self:actions(self.timing)
end)

---Create new PartDefender object.
---@param part BasePart
---@return PartDefender?
function PartDefender.new(part)
	local self = setmetatable(Defender.new(), PartDefender)

	self.part = part
	self.timing = self:initial(part, SaveManager.ps, nil, part.Name)
	self.owner = self.timing and guessOwnerFromPartTiming(self.timing)
	self.touched = false
	self.finished = false

	return self.timing and self or nil
end

-- Return PartDefender module.
return PartDefender
