---@type PartTiming
local PartTiming = getfenv().PartTiming

---@type Action
local Action = getfenv().Action

---@type ProjectileTracker
---@diagnostic disable-next-line: unused-local
local ProjectileTracker = getfenv().ProjectileTracker

---@module Features.Combat.Defense
local Defense = getfenv().Defense

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local thrown = workspace:FindFirstChild("Thrown")
	if not thrown then
		return
	end

	local tracker = ProjectileTracker.new(function(candidate)
		return candidate.Name == "Spread"
	end)

	task.wait(0.5 - self.rtt())

	if self:distance(self.entity) <= 20 then
		local action = Action.new()
		action._type = "Parry"
		action._when = 100
		action.name = "Arc Beam Close Timing"
		action.ihbc = true
		return self:action(timing, action)
	end

	local action = Action.new()
	action._when = 0
	action._type = "Parry"
	action.name = "Arc Beam Part"

	local pt = PartTiming.new()
	pt.uhc = true
	pt.duih = true
	pt.fhb = true
	pt.name = "ArcBeamProjectile"
	pt.hitbox = Vector3.new(20, 20, 40)
	pt.actions:push(action)

	Defense.cdpo(tracker:wait(), pt)
end
