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
		return candidate.Name == "IceShuriken"
	end)

	task.wait(0.20 - self.rtt())
	if self:distance(self.entity) <= 20 then
		local action = Action.new()
		action._type = "Start Block"
		action._when = 0
		action.hitbox = Vector3.new(50, 50, 50)
		action.name = "Ice Forge Close Timing"
		self:action(timing, action)

		local actionTwo = Action.new()
		actionTwo._type = "End Block"
		actionTwo._when = 800
		actionTwo.hitbox = Vector3.new(80, 80, 80)
		self:action(timing, actionTwo)
	end

	local action = Action.new()
	action._when = 0
	action._type = "Parry"
	action.name = "Ice Forge Part"

	local pt = PartTiming.new()
	pt.uhc = true
	pt.duih = true
	pt.fhb = false
	pt.name = "IceForgeProjectile"
	pt.hitbox = Vector3.new(35, 35, 35)
	pt.actions:push(action)
	pt.cbm = true

	Defense.cdpo(tracker:wait(), pt)
end
