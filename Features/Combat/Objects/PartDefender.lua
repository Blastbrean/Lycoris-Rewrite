---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@class PartDefender: Defender
---@field part BasePart
---@field timing PartTiming
---@field touched boolean Determines whether if we touched the timing in the past.
local PartDefender = setmetatable({}, { __index = Defender })
PartDefender.__index = PartDefender
PartDefender.__type = "Part"

-- Services.
local players = game:GetService("Players")

---Get CFrame.
---@note: Lag compensation of some kind? Maybe extrapolation.
---@todo: Have initial facing angle -> replace the direction of the part.
---@param self PartDefender
---@return CFrame
PartDefender.cframe = LPH_NO_VIRTUALIZE(function(self)
	return self.timing.uhc and self.part.CFrame or CFrame.new(self.part.Position)
end)

---Check if we're in a valid state to proceed with the action.
---@param timing PartTiming
---@param action Action
---@return boolean
PartDefender.valid = LPH_NO_VIRTUALIZE(function(self, timing, action)
	if not Defender.valid(self, timing, action) then
		return false
	end

	local character = players.LocalPlayer.Character
	if not character then
		return self:notify(timing, "No character found.")
	end

	if not self.timing.duih and not self:hc(self:cframe(), timing, action, { character }, nil) then
		return false
	end

	return true
end)

---Update PartDefender object.
PartDefender.update = LPH_NO_VIRTUALIZE(function(self)
	-- Skip if we're not handling delay until in hitbox.
	if not self.timing.duih then
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
	local touching = self:hitbox(self:cframe(), false, self.timing.hitbox, { character })

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

	-- Add actions.
	return self:actions(self.timing)
end)

---Create new PartDefender object.
---@param part BasePart
---@param timing PartTiming?
---@return PartDefender?
function PartDefender.new(part, timing)
	local self = setmetatable(Defender.new(), PartDefender)

	self.part = part
	self.timing = timing or self:initial(part, SaveManager.ps, nil, part.Name)
	self.touched = false

	-- Handle no timing.
	if not self.timing then
		return nil
	end

	-- Handle module.
	if self.timing.umoa then
		self:module(self.timing)
	end

	-- Handle no hitbox delay with no module.
	if not self.timing.umoa and not self.timing.duih then
		self:actions(self.timing)
	end

	-- Return self.
	return self
end

-- Return PartDefender module.
return PartDefender
