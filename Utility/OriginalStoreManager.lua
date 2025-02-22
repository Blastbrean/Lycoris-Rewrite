return LPH_NO_VIRTUALIZE(function()
	---@module Utility.OriginalStore
	local OriginalStore = require("Utility/OriginalStore")

	---@class OriginalStoreManager
	---@param inner OriginalStore[]
	local OriginalStoreManager = {}
	OriginalStoreManager.__index = OriginalStoreManager

	---Forget data value.
	---@param data table|Instance
	function OriginalStoreManager:forget(data)
		self.inner[data] = nil
	end

	---Mark data value.
	---@param data table|Instance
	---@param index any
	function OriginalStoreManager:mark(data, index)
		local object = self.inner[data] or OriginalStore.new()

		object:mark(data, index)

		self.inner[data] = object
	end

	---Add data value.
	---@param data table|Instance
	---@param index any
	---@param value any
	function OriginalStoreManager:add(data, index, value)
		local object = self.inner[data] or OriginalStore.new()

		object:set(data, index, value)

		self.inner[data] = object
	end

	---Get data values.
	---@return OriginalStore[]
	function OriginalStoreManager:data()
		return self.inner
	end

	---Get data value.
	---@param data table|Instance
	---@return OriginalStore
	function OriginalStoreManager:get(data)
		return self.inner[data]
	end

	---Restore data values.
	function OriginalStoreManager:restore()
		for _, store in next, self.inner do
			store:restore()
		end
	end

	---Detach OriginalStoreManager object.
	function OriginalStoreManager:detach()
		for _, store in next, self.inner do
			store:detach()
		end

		self.inner = {}
	end

	---Create new OriginalStoreManager object.
	---@return OriginalStoreManager
	function OriginalStoreManager.new()
		local self = setmetatable({}, OriginalStoreManager)
		self.inner = {}
		return self
	end

	-- Return OriginalStoreManager module.
	return OriginalStoreManager
end)()
