---@class Action
local Action = getfenv().Action

---@class Timing
local Timing = getfenv().Timing

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local humanoid = self.entity:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		return
	end

	task.wait(0.4 - self.rtt())

	if self:distance(self.entity) <= 10 then
		local firstPartTiming = Timing.new()
		firstPartTiming.fhb = true
		firstPartTiming.duih = false
		firstPartTiming.rpue = false
		firstPartTiming.name = "IceLunge"
		firstPartTiming.cbm = true

		local action = Action.new()
		action._when = 0
		action._type = "Parry"
		action.ihbc = true
		action.name = "Ice Lunge Close"
		return self:action(firstPartTiming, action)
	end

	local timestamp = os.clock()

	timing.fhb = true
	timing.duih = true
	timing.rpue = false
	timing.hitbox = Vector3.new(10, 10, 20)

	self:hook("stopped", function(...)
		return os.clock() - timestamp >= 2.0
	end)

	local action = Action.new()
	action._when = 0
	action._type = "Parry"
	action.hitbox = Vector3.new(10, 10, 20)
	action.name = "Ice Lunge Far"
	self:action(timing, action)
end
