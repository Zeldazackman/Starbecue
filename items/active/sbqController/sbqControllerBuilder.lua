
function build(directory, config, parameters, level, seed)

	if parameters.scriptStorage ~= nil and parameters.scriptStorage.clickAction ~= nil then
		if not config.descriptions[parameters.scriptStorage.clickAction] then
			parameters.scriptStorage.clickAction = "unassigned"
		end

		config.shortdescription = config.descriptions[parameters.scriptStorage.clickAction].shortdescription
		config.description = config.descriptions[parameters.scriptStorage.clickAction].description..config.appendedDescription
		config.inventoryIcon = "/items/active/sbqController/"..(parameters.scriptStorage.clickAction or "unassigned")..".png"
	end

	return config, parameters
end
