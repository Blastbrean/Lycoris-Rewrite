---@type Action
local Action = getfenv().Action

---@type Timing
local Timing = getfenv().Timing

---@module Modules.Globals.Waiter
local Waiter = getfenv().Waiter

---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = getfenv().RepeatInfo

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local humanoid = self.entity:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local humanoidRootPart = self.entity:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		return
	end

	if humanoidRootPart:FindFirstChild("REP_SOUND_6323221579") then
		local radiantKickTiming = Timing.new()
		radiantKickTiming.fhb = false
		radiantKickTiming.duih = false
		radiantKickTiming.rpue = false
		radiantKickTiming.iae = true
		radiantKickTiming.name = "RadiantKick"

		local action = Action.new()
		action._when = 500
		action._type = "Parry"
		action.hitbox = Vector3.new(60, 60, 60)
		action.name = "Radiant Kick Shared"
		return self:action(radiantKickTiming, action)
	end

	local firstPartTiming = Timing.new()
	firstPartTiming.fhb = true
	firstPartTiming.duih = false
	firstPartTiming.rpue = false
	firstPartTiming.name = "RapidPunches"

	local action = Action.new()
	action._when = 300
	action._type = "Parry"
	action.hitbox = Vector3.new(10, 10, 8)
	action.name = "Rapid Punches First Part"
	self:action(firstPartTiming, action)

	timing.fhb = true
	timing._rsd = 0
	timing._rpd = 150
	timing.duih = true
	timing.rpue = true
	timing.hitbox = Vector3.new(10, 10, 8)

	local track = Waiter.fet("rbxassetid://8150846354", animator)
	if not track then
		return
	end

	local info = RepeatInfo.new(timing, self.rdelay(), self:uid(10))
	info.track = track
	self:rpue(self.entity, timing, info)
end
