---@class Action
local Action = getfenv().Action

---@class RepeatInfo
local RepeatInfo = getfenv().RepeatInfo

---@module Game.Latency
local Latency = getfenv().Latency

---@class Signal
local Signal = getfenv().Signal

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	timing.ffh = true
	timing.fhb = true
	timing.rpue = false
	timing.duih = true
	timing._rpd = 100
	timing._rsd = 300
	timing.hitbox = Vector3.new(14, 14, 14)

	local stopped = false

	self:hook("rc", function()
		return stopped
	end)

	local info = RepeatInfo.new(timing, Latency.rdelay(), self:uid(10))
	info.track = self.track
	self:srpue(self.entity, timing, info)

	local hrp = self.entity:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local humanoid = self.entity:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	stopped = true

	repeat
		task.wait()
	until not self.track.IsPlaying

	task.wait(0.8)

	stopped = false
end
