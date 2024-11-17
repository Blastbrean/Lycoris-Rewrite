---@class DrawingPool
---@field drawings Drawing[]
local DrawingPool = {}
DrawingPool.__index = DrawingPool

---@module Utility.DrawingWrapper
local DrawingWrapper = require("Utility/DrawingWrapper")

---Detach by removing drawing objects.
function DrawingPool:detach()
	for _, drawingObject in next, self.drawings do
		drawingObject:remove()
	end
end

---Set visibility of drawing objects.
---@param visible boolean
function DrawingPool:setVisible(visible)
	for _, drawingObject in next, self.drawings do
		drawingObject:set("Visible", visible)
	end
end

---Create drawing into pool.
---@param identifier string
---@param data table
---@return Drawing
function DrawingPool:createDrawing(identifier, data)
	local drawingObject = DrawingWrapper.new(data)

	self.drawings[identifier] = drawingObject

	return drawingObject
end

---get drawing from pool
---@param identifier string
---@return Drawing
function DrawingPool:getDrawing(identifier)
	return self.drawings[identifier]
end

---Create new DrawingPool object.
---@return DrawingPool
function DrawingPool.new()
	local self = setmetatable({}, DrawingPool)
	self.drawings = {}
	return self
end

-- Return DrawingPool module.
return DrawingPool
