---@class ValidationOptions
---@field sstun boolean Skip stun check.
---@field action Action The action being checked.
---@field timing Timing The timing of the action.
---@field notify boolean Whether to notify on failure.
local ValidationOptions = {}
ValidationOptions.__index = ValidationOptions

---Create a new ValidationOptions object.
---@param action Action
---@param timing Timing
function ValidationOptions.new(action, timing)
	local self = setmetatable({}, ValidationOptions)
	self.sstun = false
	self.action = action
	self.timing = timing
	self.notify = true
	return self
end

-- Return the module.
return ValidationOptions
