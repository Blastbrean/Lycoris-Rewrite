---@type Action
local Action = getfenv().Action

---@module Modules.Globals.Waiter
local Waiter = getfenv().Waiter

-- Services.
local players = game:GetService("Players")

---Module function.
---@param self SoundDefender
---@param timing SoundTiming
return function(self, timing)
	if not self.owner then
		return
	end

	if players:GetPlayerFromCharacter(self.owner) then
		local humanoid = self.owner:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			return
		end

		if not Waiter.ftrack("rbxassetid://8172871094", animator) then
			return
		end

		local action = Action.new()
		action._when = 350
		action._type = "Dodge"
		action.hitbox = Vector3.new(20, 20, 100)
		action.name = "Krysiger Timing"
		return self:action(timing, action)
	end

	if self.owner.Name:match("gigamed") then
		local action = Action.new()
		action._when = 0
		action._type = "Dodge"
		action.hitbox = self.owner.Name:match("king") and Vector3.new(75, 75, 75) or Vector3.new(30, 30, 30)
		action.name = "Gigamed Shock Timing"
		return self:action(timing, action)
	end
end
