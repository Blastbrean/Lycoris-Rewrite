---@class Action
local Action = getfenv().Action

---Module function.
---@param self EffectDefender
---@param timing EffectTiming
return function(self, timing)
	if self:distance(self.owner) >= 20 then
		return
	end

	local humanoidRootPart = self.owner:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local terrain = workspace:FindFirstChild("Terrain")
	if not terrain then
		return
	end

	---@type Attachment
	local attachment = terrain:WaitForChild("REP_EMIT", 0.5)
	if not attachment then
		return
	end

	if not attachment:IsA("Attachment") then
		return
	end

	if (attachment.Position - humanoidRootPart.Position).Magnitude >= 5 then
		return
	end

	local action = Action.new()
	action._when = 0
	action._type = "Dodge"
	action.hitbox = Vector3.new(30, 30, 30)
	action.name = "Dynamic Shadow Sludge Timing"
	self:action(timing, action)
end
