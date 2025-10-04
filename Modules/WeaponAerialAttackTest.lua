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

	local torsoEquipment = self.entity:FindFirstChild("TorsoEquipment")

	if torsoEquipment and torsoEquipment:GetAttribute("DisplayName") == "Mantle of Enmity" then
		timing.mat = 1200
		timing.iae = true
		timing.ieae = true
		timing.fhb = false

		local action = Action.new()
		action._when = 900
		action._type = "Parry"
		action.hitbox = Vector3.new(30, 30, 30)
		action.name = "Dynamic Mantle Of Enmity Swing"

		return self:action(timing, action)
	end

	timing.iae = false
	timing.fhb = true

	local windup = nil
	local ispeed = self.track.Speed

	-- Windup + 0-speed duration.

	if data.type == "Dagger" then
		windup = (0.169 / self.track.Speed) + 0.120
	elseif data.type == "Greataxe" then
		windup = (0.168 / self.track.Speed) + 0.125
	elseif data.type == "Twinblade" then
		windup = (0.151 / self.track.Speed) + 0.140
	elseif data.type == "Bow" then
		windup = (0.145 / self.track.Speed) + 0.170
	elseif data.type == "Club" then
		windup = (0.163 / self.track.Speed) + 0.140
	elseif data.type == "Pistol" then
		windup = 0.500 / data.ss
	elseif data.type == "Rifle" and not timing.name:match("Fist") then
		repeat
			task.wait()
		until self.track.Speed ~= ispeed

		windup = (0.300 / self.track.Speed)
	elseif data.type == "Rifle" then
		windup = (0.199 / self.track.Speed) + 0.100
	elseif data.type == "Greatsword" then
		windup = (0.166 / self.track.Speed) + 0.160
	elseif data.type == "Rapier" then
		windup = (0.255 / self.track.Speed) + 0.080
	elseif data.type == "Greatcannon" then
		windup = (0.163 / self.track.Speed) + 0.183
	elseif data.type == "Greathammer" then
		windup = (0.15 / self.track.Speed) + 0.170
	elseif data.type == "Fist" then
		windup = (0.160 / self.track.Speed) + 0.130
	elseif data.type == "Sword" then
		windup = (0.18 / self.track.Speed) + 0.120
	elseif data.type == "Spear" then
		windup = (0.150 / self.track.Speed) + 0.170
	end

	if not windup then
		return self:notify(timing, "(%s) No windup for this weapon type.", data.type)
	end

	-- Create action.
	local action = Action.new()
	action._when = windup * 1000
	action._type = "Parry"
	action.hitbox = Vector3.new(data.length * 2, data.length * 4, data.length * 2.5)
	action.name = string.format(
		"(%.2f, %.2f, %.2f) (%.2f) Dynamic Weapon Swing",
		data.oss,
		data.ss,
		self.track.Speed,
		data.length
	)

	return self:action(timing, action)
end
