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

	local firstPartTiming = Timing.new()
	firstPartTiming.fhb = true
	firstPartTiming.duih = false
	firstPartTiming.rpue = false
	firstPartTiming.name = "IceCarve"

	local action = Action.new()
	action._when = 400
	action._type = "Parry"
	action.hitbox = Vector3.new(15, 15, 15)
	action.name = "Ice Carve First Part"
	self:action(firstPartTiming, action)

	timing.fhb = true
	timing._rsd = 0
	timing._rpd = 100
	timing.duih = true
	timing.rpue = true
	timing.hitbox = Vector3.new(15, 15, 15)

	local track = Waiter.fet("rbxassetid://15714151635", animator)
	if not track then
		return
	end

	local startTimestamp = os.clock()

	local info = RepeatInfo.new(timing, self.rdelay(), self:uid(10))
	info.track = track

	---@todo: Move to 'rc'
	self:hook("stopped", function(...)
		return os.clock() - startTimestamp >= 1.5
	end)

	self:rpue(self.entity, timing, info)
end
