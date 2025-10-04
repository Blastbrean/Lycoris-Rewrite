---@type Action
local Action = getfenv().Action

---Module function.
---@param self PartDefender
---@param timing PartTiming
return function(self, timing)
	local shooty = self.part:FindFirstChild("Shooty")
	if not shooty then
		return
	end

	repeat
		task.wait()
	until shooty.IsPlaying

	timing.duih = true
	timing.hitbox = Vector3.new(5, 5, 5)
	timing.fhb = false

	local action = Action.new()
	action._when = 350
	action._type = "Parry"
	action.hitbox = Vector3.new(0, 0, 0)
	action.name = "Contact"
	return self:action(timing, action)
end
