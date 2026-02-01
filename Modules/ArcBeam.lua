---@type PartTiming
local PartTiming = getfenv().PartTiming

---@type Action
local Action = getfenv().Action

---@type ProjectileTracker
local ProjectileTracker = getfenv().ProjectileTracker

---@module Features.Combat.Defense
local Defense = getfenv().Defense

---@module Game.Latency
local Latency = getfenv().Latency

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
        or candidate.Name == "Projectile"
        or candidate.Parent and candidate.Parent.Name == "Beam"
	end)

	task.wait(math.max(0, 0.5 - Latency.rtt()))

	if self:distance(self.entity) <= 20 then
		local action = Action.new()
		action._type = "Parry"
		action._when = 100
		action.name = "Arc Beam Close Timing"
		action.ihbc = true
		action.fhb = true
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
	pt.hitbox = Vector3.new(20, 25, 40)
	pt.actions:push(action)
	pt.cbm = true

	Defense.cdpo(tracker:wait(), pt)
end
