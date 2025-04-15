return LPH_NO_VIRTUALIZE(function()
	---@class OriginalStore
	---@param data any
	---@param index any
	---@param value any
	---@field stored boolean
	local OriginalStore = {}
	OriginalStore.__index = OriginalStore

	---Get stored data value.
	---@return any
	function OriginalStore:get()
		if not self.stored then
			return nil
		end

		return self.value
	end

	---Mark data value.
	---@param data table|Instance
	---@param index any
	function OriginalStore:mark(data, index)
		if self.stored and self.data ~= data then
			self:restore()
		end

		if not self.stored then
			self.data = data
			self.index = index
			self.value = data[index]
			self.stored = true
		end
	end

	---Set data value.
	---@param data table|Instance
	---@param index any
	---@param value any
	function OriginalStore:set(data, index, value)
		self:mark(data, index)

		data[index] = value
	end

	---Restore data value.
	function OriginalStore:restore()
		if not self.stored then
			return
		end

		pcall(function()
			self.data[self.index] = self.value
		end)

		self.stored = false
	end

	---Detach OriginalStore object.
	function OriginalStore:detach()
		self:restore()
		self.data = nil
		self.index = nil
		self.value = nil
		self.stored = false
	end

	---Create new OriginalStore object.
	---@return OriginalStore
	function OriginalStore.new()
		local self = setmetatable({}, OriginalStore)
		self.data = nil
		self.index = nil
		self.value = nil
		self.stored = false
		return self
	end

	-- Return OriginalStore module.
	return OriginalStore
end)()
