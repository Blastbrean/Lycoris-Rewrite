---@note: Typed object that represents a target. It's not really a true class but just needs to store the correct data.
---@class Target
---@field character Model
---@field humanoid Humanoid
---@field root BasePart
---@field dc number Distance to crosshair.
---@field fov number Field of view to target.
---@field du number Distance to us.
local Target = {}

---Create new Target object.
---@param character Model
---@param humanoid Humanoid
---@param root BasePart
---@param dc number
---@param fov number
---@param du number
---@return Target
function Target.new(character, humanoid, root, dc, fov, du)
	local self = setmetatable({}, Target)
	self.character = character
	self.humanoid = humanoid
	self.root = root
	self.dc = dc
	self.fov = fov
	self.du = du
	return self
end

-- Return Target module.
return Target
