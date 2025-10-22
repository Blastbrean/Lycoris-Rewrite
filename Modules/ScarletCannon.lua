---@module Modules.Globals.ProjectileListener
local ProjectileListener = getfenv().ProjectileListener

---@class Action
local Action = getfenv().Action

---@module Game.Timings.PartTiming
local PartTiming = getfenv().PartTiming

---@module Features.Combat.Defense
local Defense = getfenv().Defense

-- Listener object.
local plistener = ProjectileListener.new("ScarletCannon")

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	plistener:connect(function(child)
		if child.Name ~= "sphereinner" then
			return
		end

		local action = Action.new()
		action._when = 0
		action._type = "Parry"
		action.name = "Scarlet Cannon Part"
		action.ihbc = true

		local pt = PartTiming.new()
		pt.uhc = true
		pt.duih = true
		pt.fhb = false
		pt.name = "ScarletCannonProjectile"
		pt.hitbox = Vector3.new(20, 20, 80)
		pt.imdd = 0
		pt.imxd = 100
		pt.actions:push(action)
		pt.cbm = true

		Defense.cdpo(child, pt)
	end)
end
