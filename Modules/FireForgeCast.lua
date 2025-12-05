---@class Action
local Action = getfenv().Action

---@class Signal
local Signal = getfenv().Signal

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local player = game:GetService("Players"):GetPlayerFromCharacter(self.entity)
	local backpack = player and player:FindFirstChild("Backpack")

	if backpack and backpack:FindFirstChild("Mantra:TrapWind{{Galetrap}}") then
		timing.ffh = true

		local action = Action.new()
		action._when = 300
		action._type = "Parry"
		action.hitbox = Vector3.new(10, 25, 25)
		action.name = "Galetrap Timing"
		return self:action(timing, action)
	end
end
