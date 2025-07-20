---@module Modules.Globals.ProjectileListener
local ProjectileListener = getfenv().ProjectileListener

---@class Action
local Action = getfenv().Action

---@module Features.Combat.Defense
local Defense = getfenv().Defense

---@module Game.Timings.PartTiming
local PartTiming = getfenv().PartTiming

-- Listener object.
local plistener = ProjectileListener.new("LightningImpact")

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	timing.iae = true

	local endAction = Action.new()
	endAction._type = "Parry"
	endAction._when = 600
	endAction.name = "Lightning Impact Stomp"
	endAction.ihbc = true
	self:action(timing, endAction)

	plistener:connect(function(child)
		if child.Name ~= "StaticBall" then
			return
		end

		local action = Action.new()
		action._when = 0
		action._type = "Parry"
		action.name = "Static Ball Part"

		local pt = PartTiming.new()
		pt.uhc = true
		pt.duih = true
		pt.fhb = true
		pt.name = "StaticBallProjectile"
		pt.hitbox = Vector3.new(7, 7, 7)
		pt.actions:push(action)

		Defense.cdpo(child, pt)
	end)
end
