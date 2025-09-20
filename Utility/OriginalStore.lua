---@class OriginalStore
---@param data any
---@param index any
---@param value any
---@field stored boolean
local OriginalStore = {}
OriginalStore.__index = OriginalStore

---Get stored data value.
---@return any
OriginalStore.get = LPH_NO_VIRTUALIZE(function(self)
	if not self.stored then
		return nil
	end

	return self.value
end)

---Set something, run a callback, and then restore.
---@param data table|Instance
---@param index any
---@param value any
---@param callback fun(): any
OriginalStore.run = LPH_NO_VIRTUALIZE(function(self, data, index, value, callback)
	self:set(data, index, value)

	callback()

	self:restore()
end)

---Mark data value.
---@param data table|Instance
---@param index any
OriginalStore.mark = LPH_NO_VIRTUALIZE(function(self, data, index)
	if self.stored and self.data ~= data then
		self:restore()
	end

	if not self.stored then
		self.data = data
		self.index = index
		self.value = data[index]
		self.stored = true
	end
end)

---Set data value.
---@param data table|Instance
---@param index any
---@param value any
OriginalStore.set = LPH_NO_VIRTUALIZE(function(self, data, index, value)
	self:mark(data, index)

	data[index] = value
end)

---Restore data value.
OriginalStore.restore = LPH_NO_VIRTUALIZE(function(self)
	if not self.stored then
		return
	end

	pcall(function()
		self.data[self.index] = self.value
	end)

	self.stored = false
end)

---Detach OriginalStore object.
OriginalStore.detach = LPH_NO_VIRTUALIZE(function(self)
	self:restore()
	self.data = nil
	self.index = nil
	self.value = nil
	self.stored = false
end)

---Create new OriginalStore object.
---@return OriginalStore
OriginalStore.new = LPH_NO_VIRTUALIZE(function()
	local self = setmetatable({}, OriginalStore)
	self.data = nil
	self.index = nil
	self.value = nil
	self.stored = false
	return self
end)

-- Return OriginalStore module.
return OriginalStore
