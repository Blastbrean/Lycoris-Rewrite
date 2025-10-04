---@type Action
local Action = getfenv().Action

---Module function.
---@param self PartDefender
---@param timing PartTiming
return function(self, timing)
	-- Glacial Arc starts creating new parts that are ordered least to smallest
	local model = self.part.Parent
	if not model then
		return
	end

	if #model:GetChildren() <= 3 then
		return
	end

	if self:distance(self.part) >= 15 then
		return
	end

	local action = Action.new()
	action._when = 0
	action._type = "Parry"
	action.ihbc = true
	action.name = "Dynamic Glacial Arc Timing"
	return self:action(timing, action)
end
