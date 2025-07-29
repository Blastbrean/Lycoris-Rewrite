---@module Modules.Globals.ProjectileListener
local ProjectileListener = getfenv().ProjectileListener

---@class Action
local Action = getfenv().Action

---@module Features.Combat.Defense
local Defense = getfenv().Defense

---@module Game.Timings.PartTiming
local PartTiming = getfenv().PartTiming

-- Listener object.
local plistener = ProjectileListener.new("DaggerThrow")

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	task.wait(0.45 - self.ping())

	if self:distance(self.entity) <= 10 then
		local action = Action.new()
		action._when = 0
		action._type = "Parry"
		action.ihbc = true
		action.name = "Ice Daggers Close"
		return self:action(timing, action)
	end

	plistener:connect(function(child)
		if child.Name ~= "IceDagger" then
			return
		end

		local action = Action.new()
		action._when = 0
		action._type = "Parry"
		action.name = "Ice Dagger Part"

		local pt = PartTiming.new()
		pt.uhc = true
		pt.duih = true
		pt.fhb = true
		pt.name = "IceDaggerProjectile"
		pt.hitbox = Vector3.new(10, 10, 20)
		pt.actions:push(action)

		Defense.cdpo(child, pt)
	end)
end
