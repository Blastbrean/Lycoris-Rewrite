---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Game.Timings.SaveManager
local SaveManager = require("Game/Timings/SaveManager")

---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = require("Features/Combat/Objects/RepeatInfo")

---@module Features.Combat.Objects.HitboxOptions
local HitboxOptions = require("Features/Combat/Objects/HitboxOptions")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@class PartDefender: Defender
---@field part BasePart
---@field timing PartTiming
---@field touched boolean Determines whether if we touched the timing in the past.
---@field vuid string Visualizer UID.
local PartDefender = setmetatable({}, { __index = Defender })
PartDefender.__index = PartDefender
PartDefender.__type = "Part"

-- Services.
local players = game:GetService("Players")

---Get CFrame.
---@param self PartDefender
---@return CFrame
PartDefender.cframe = LPH_NO_VIRTUALIZE(function(self)
	return self.timing.uhc and self.part.CFrame or CFrame.new(self.part.Position)
end)

---Check if we're in a valid state to proceed with the action.
---@param self PartDefender
---@param options ValidationOptions
---@return boolean
PartDefender.valid = LPH_NO_VIRTUALIZE(function(self, options)
	if not Defender.valid(self, options) then
		return false
	end

	local function internalNotifyFunction(timing, message)
		if not options.notify then
			return
		end

		return self:notify(timing, message)
	end

	local timing = options.timing
	local action = options.action

	local character = players.LocalPlayer.Character
	if not character then
		return internalNotifyFunction(timing, "No character found.")
	end

	local hoptions = HitboxOptions.new(self.part, timing)
	hoptions.spredict = false
	hoptions.action = action
	hoptions:ucache()

	if not timing.duih or timing.umoa then
		if not self:hc(hoptions, timing.duih and RepeatInfo.new(timing, self.rdelay(), self.vuid) or nil) then
			return internalNotifyFunction(timing, "Not in hitbox.")
		end
	end

	return true
end)

---Update PartDefender object.
---@param self PartDefender
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

	local hb = self.timing.hitbox

	hb = Vector3.new(PP_SCRAMBLE_NUM(hb.X), PP_SCRAMBLE_NUM(hb.Y), PP_SCRAMBLE_NUM(hb.Z))

	-- Get current hitbox state.
	---@note: If we're using PartDefender, why perserve rotation? It's likely wrong or gonna mess us up.
	local touching, cframe = self:hitbox(self:cframe(), self.timing.fhb, self.timing.hso, hb, { character })

	if cframe then
		self:visualize(self.vuid, cframe, hb, touching and Color3.fromHex("#DDF527") or Color3.fromHex("#2765F5"))
	end

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
	if not Configuration.expectToggleValue("EnableAutoDefense") then
		return nil
	end

	local self = setmetatable(Defender.new(), PartDefender)
	self.part = part
	self.timing = timing or self:initial(part, SaveManager.ps, nil, part.Name)
	self.touched = false
	self.vuid = self:uid(10)

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
