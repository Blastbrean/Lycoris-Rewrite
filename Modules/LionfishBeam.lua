---@type Action
local Action = getfenv().Action

---Module function.
---@param self AnimatorDefender
---@param timing AnimationTiming
return function(self, timing)
	local charging = false

	while task.wait() do
		local _, _, z = self.entity:GetPivot():ToOrientation()

		-- ok, so the first part of the beam is the charge. we must detect the peak in which he starts fully charging his beam.
		if not charging and z <= -1.7 then
			charging = true
		end

		-- if there is no charge, continue.
		if not charging then
			continue
		end

		-- after that, we must detect the release. his release is at around -0.9 so if we're below that, we can continue.
		if z <= -0.9 then
			continue
		end

		local action = Action.new()
		action._when = 200
		action._type = "Forced Full Dodge"
		action.hitbox = Vector3.new(100, 100, 100)
		action.name = "Lionfish Beam Dodge"
		return self:action(timing, action)
	end
end
