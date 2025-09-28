---@type PartTiming
local PartTiming = getfenv().PartTiming

---@type Action
local Action = getfenv().Action

---@module Modules.Globals.Weapon
local Weapon = getfenv().Weapon

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
		return candidate.Name == "Bullet" or candidate.Name:match("ScrapsingerBullet")
	end)

	if self:distance(self.entity) <= 20 then
		local action = Weapon.action(self.entity, 400 * 1.17, true)
		if not action then
			return
		end

		action.name = "Dynamic Gun Close Timing"

		return self:action(timing, action)
	end

	local action = Action.new()
	action._when = 0
	action._type = "Parry"
	action.name = "Bullet Part"

	local pt = PartTiming.new()
	pt.uhc = true
	pt.duih = true
	pt.fhb = true
	pt.name = "BulletProjectile"
	pt.hitbox = Vector3.new(20, 20, 20)
	pt.actions:push(action)

	Defense.cdpo(tracker:wait(), pt)
end
