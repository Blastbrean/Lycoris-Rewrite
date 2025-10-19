---@class Action
local Action = getfenv().Action

---@module Modules.Globals.Weapon
local Weapon = getfenv().Weapon

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local data = Weapon.data(self.entity)
	if not data then
		return
	end

	timing.pfh = true
	timing.duih = false
	timing.fhb = true
	timing.dp = false
	timing.pfht = 0.3

	local windup = nil

	-- Windup + 0-speed duration.

	if data.type == "Dagger" then
		windup = (0.147 / self.track.Speed) + 0.140
	elseif data.type == "Greatsword" then
		windup = (0.160 / self.track.Speed) + 0.180
		windup += 0.100 / data.ss
	elseif data.type == "Spear" then
		windup = (0.150 / self.track.Speed) + 0.170
		windup += 0.100 / data.ss
	elseif data.type == "Pistol" then
		repeat
			task.wait()
		until self.track.Speed >= 0.1

		windup = (0.300 / self.track.Speed)
	elseif data.type == "Rifle" then
		windup = (0.169 / self.track.Speed) + 0.180
		windup += 0.100 / data.ss
	elseif data.type == "Sword" then
		windup = (0.135 / self.track.Speed) + 0.150
		windup += 0.150 / data.ss
	elseif data.type == "Rapier" then
		windup = (0.238 / self.track.Speed) + 0.060
	elseif data.type == "Club" then
		windup = (0.173 / self.track.Speed) + 0.140
		windup += 0.150 / data.ss
	elseif data.type == "Bow" then
		windup = (0.160 / self.track.Speed) + 0.130
	elseif data.type == "Twinblade" then
		windup = (0.164 / self.track.Speed) + 0.140
		windup += 0.150 / data.ss
	elseif data.type == "Fist" then
		windup = (0.153 / self.track.Speed) + 0.150
	end

	if not windup then
		return self:notify(timing, "(%s) No windup for this weapon type.", data.type)
	end

	-- Create action.
	local action = Action.new()
	action._when = windup * 1000
	action._type = "Parry"
	action.hitbox = Vector3.new(data.length * 2, data.length * 2, data.length * 2.5)
	action.name = string.format(
		"(%.2f, %.2f, %.2f) (%.2f) Dynamic Weapon Swing",
		data.oss,
		data.ss,
		self.track.Speed,
		data.length
	)

	if data.type == "Twinblade" then
		-- Twinblade adjustment.
		action.hitbox = Vector3.new(data.length * 2, data.length * 2, data.length * 3.5)

		-- Create second action.
		local secondAction = Action.new()
		secondAction._when = action._when + (300 / data.ss)
		secondAction._type = "Parry"
		secondAction.hitbox = action.hitbox
		secondAction.name = "(2)" .. " " .. action.name
		self:action(timing, secondAction)
	end

	return self:action(timing, action)
end
