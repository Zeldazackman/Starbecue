require "/scripts/augments/item.lua"

function apply(input)
	local augmentConfig = config.getParameter("augment")
	local output = Item.new(input)
	if augmentConfig and output:instanceValue("acceptsAugmentType", "") == augmentConfig.type then
		local storage = sb.jsonMerge(config.getParameter("scriptStorage") or {}, storage)
		local currentStorage = output:instanceValue("scriptStorage") or {}
		if currentStorage.spov ~= nil then return nil end
		storage.spov = config.getParameter("spov")

		output:setInstanceValue("scriptStorage", sb.jsonMerge(currentStorage, storage))

		return output:descriptor(), 1
	end
end
