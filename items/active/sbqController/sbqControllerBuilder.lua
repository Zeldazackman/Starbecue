
function build(directory, config, parameters, level, seed)

	if parameters.scriptStorage ~= nil and parameters.scriptStorage.clickAction ~= nil then
		if not config.descriptions[parameters.scriptStorage.clickAction] then
			parameters.scriptStorage.clickAction = "unassigned"
		end
		local shortdescription = (config.descriptions[parameters.scriptStorage.clickAction] or {}).shortdescription
		local description = (config.descriptions[parameters.scriptStorage.clickAction] or {}).description
		if not shortdescription then
			shortdescription = parameters.scriptStorage.clickAction.." Controller"
		end
		if not description then
			description = "Triggers the "..parameters.scriptStorage.clickAction.." action of a predator."
		end

		config.shortdescription = shortdescription
		config.description = description..config.appendedDescription
		config.inventoryIcon = (parameters.scriptStorage.icon or ("/items/active/sbqController/"..(parameters.scriptStorage.clickAction or "unassigned")..".png"))..(parameters.scriptStorage.directives or "")
	end

	return config, parameters
end
