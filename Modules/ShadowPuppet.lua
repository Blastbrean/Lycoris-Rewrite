---@type Action
local Action = getfenv().Action

---@class Timing
local Timing = getfenv().Timing

---Module function.
---@param self PartDefender
---@param timing PartTiming
return function(self, timing)
	local parent = self.part.Parent
	if not parent then
		return
	end

	if not parent.Name:match("Puppet") then
		return
	end

	local newTiming = Timing.new()
	newTiming.cbm = true
	newTiming.duih = true
	newTiming.fhb = true
	newTiming.hitbox = Vector3.new(8, 8, 8)
	newTiming.name = "Shadow Puppet Timing"
	newTiming.imxd = 200
	newTiming.imdd = 0

	local action = Action.new()
	action._when = 1200
	action._type = "Parry"
	action.hitbox = Vector3.new(0, 0, 0)
	action.name = "Contact"
	self:action(timing, action)
end
