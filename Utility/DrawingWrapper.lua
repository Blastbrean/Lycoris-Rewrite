---@class DrawingWrapper
---@field object table Underlying drawing object
-- Wrapper of multiple drawing object types & allows for the use of default properties.
local DrawingWrapper = {}
DrawingWrapper.__index = DrawingWrapper

---Remove drawing from being rendered and delete itself.
function DrawingWrapper:remove()
	self.object:Remove()
	self = nil
end

---Get drawing object.
---@param key string
---@return any
function DrawingWrapper:get(key)
	return self.object[key]
end

---Set key in drawing object.
---@param key string
---@param value any
function DrawingWrapper:set(key, value)
	self.object[key] = value
end

---Create new drawing object.
---@param data table
---@return Drawing
function DrawingWrapper.new(data)
	local self = setmetatable({}, DrawingWrapper)
	self.object = Drawing.new(data.type)

	self:set("Visible", data.visible ~= nil and data.visible or true)
	self:set("Transparency", data.transparency ~= nil and data.transparency or 1.0)
	self:set("Color", data.color ~= nil and data.color or Color3.new(0.0, 0.0, 0.0))

	return self
end

-- Return DrawingWrapper module.
return DrawingWrapper
