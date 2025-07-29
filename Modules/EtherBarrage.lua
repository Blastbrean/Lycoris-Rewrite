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
		return candidate.Name == "IntBangs"
	end)

	task.wait(0.7 - self.ping())

	local action = Action.new()
	action._when = 0
	action._type = "Parry"
	action.name = "Int Beam Part"

	local pt = PartTiming.new()
	pt.uhc = true
	pt.duih = true
	pt.fhb = true
	pt.name = "IntBeamProjectile"
	pt.hitbox = Vector3.new(10, 10, 10)
	pt.actions:push(action)

	local model = tracker:wait()
	if not model then
		return
	end

	local center = model:FindFirstChild("Center")
	if not center then
		return
	end

	Defense.cdpo(center, pt)
end
