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
	local tracker = ProjectileTracker.new(function(candidate)
		return candidate.Name == "BloodCross_" .. self.entity.Name
	end)

	local action = Action.new()
	action._when = 0
	action._type = "Parry"
	action.name = "Blood Cross Part"

	local pt = PartTiming.new()
	pt.uhc = true
	pt.duih = true
	pt.fhb = true
	pt.name = "BloodCrossProjectile"
	pt.hitbox = Vector3.new(10, 20, 20)
	pt.actions:push(action)

	Defense.cdpo(tracker:wait(), pt)
end
