
function build(directory, config, parameters, level, seed)

	if parameters.scriptStorage ~= nil and parameters.scriptStorage.settings ~= nil then

		config.inventoryIcon = "/vehicles/sbq/sbqEgg/skins/plastic/icon.png"..(parameters.scriptStorage.settings.directives or "?replace;47623a=777777;678857=999999;779e64=cccccc;9ccd83=ffffff;70695a=777777;a99f87=999999;eae0c8=cccccc;fff6de=ffffff")
	end

	return config, parameters
end
