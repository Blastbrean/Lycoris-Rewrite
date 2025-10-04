---@module Modules.Globals.ProjectileListener
local ProjectileListener = getfenv().ProjectileListener

---@class Action
local Action = getfenv().Action

---@module Game.Timings.PartTiming
local PartTiming = getfenv().PartTiming

---@module Features.Combat.Defense
local Defense = getfenv().Defense

-- Listener object.
local plistener = ProjectileListener.new("MetalRain")

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	plistener:connect(function(child)
		if child.Name ~= "RodMetalRain2" then
			return
		end

		local action = Action.new()
		action._when = 200
		action._type = "Parry"
		action.name = "Metal Rod Part"
		action.ihbc = true

		local pt = PartTiming.new()
		pt.uhc = false
		pt.duih = false
		pt.fhb = false
		pt.name = "MetalRodProjectile"
		pt.hitbox = Vector3.new(100, 100, 100)
		pt.imdd = 0
		pt.imxd = 100
		pt.actions:push(action)

		Defense.cdpo(child, pt)
	end)
end
