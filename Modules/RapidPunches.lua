---@type Action
local Action = getfenv().Action

---@type Timing
local Timing = getfenv().Timing

---@module Modules.Globals.Waiter
local Waiter = getfenv().Waiter

---@module Features.Combat.Objects.RepeatInfo
local RepeatInfo = getfenv().RepeatInfo

---@module Game.Latency
local Latency = getfenv().Latency

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

	if humanoidRootPart:WaitForChild("REP_SOUND_6323221579", 0.1) then
		local radiantKickTiming = Timing.new()
		radiantKickTiming.fhb = false
		radiantKickTiming.duih = false
		radiantKickTiming.rpue = false
		radiantKickTiming.imxd = 200
		radiantKickTiming.name = "RadiantKick"
		radiantKickTiming.iae = true
		radiantKickTiming.cbm = true

		local action = Action.new()
		action._when = 500
		action._type = "Parry"
		action.hitbox = Vector3.new(100, 100, 100)
		action.name = "Radiant Kick Shared"
		return self:action(radiantKickTiming, action)
	end

	local firstPartTiming = Timing.new()
	firstPartTiming.fhb = true
	firstPartTiming.imxd = 150
	firstPartTiming.duih = false
	firstPartTiming.rpue = false
	firstPartTiming.name = "RapidPunches"
	firstPartTiming.cbm = true

	local action = Action.new()
	action._when = 300
	action._type = "Parry"
	action.hitbox = Vector3.new(16, 10, 20)
	action.name = "Rapid Punches First Part"
	self:action(firstPartTiming, action)

	timing.fhb = true
	timing._rsd = 0
	timing._rpd = 250
	timing.duih = true
	timing.rpue = true
	timing.hitbox = Vector3.new(16, 10, 12)

	local track = Waiter.fet("rbxassetid://8150846354", animator)
	if not track then
		return
	end

	local info = RepeatInfo.new(timing, Latency.rdelay(), self:uid(10))
	info.track = track
	self:srpue(self.entity, timing, info)
end
