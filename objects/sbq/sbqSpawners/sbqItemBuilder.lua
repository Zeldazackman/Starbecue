
function build( directory, config, parameters, level, seed )

	if parameters.scriptStorage ~= nil then
		config.scriptStorage = sb.jsonMerge(config.scriptStorage, parameters.scriptStorage)

		if config.scriptStorage.vehicle ~= nil then
			local species = config.scriptStorage.vehicle.type
			local vehicleFile = root.assetJson("/vehicles/sbq/"..species.."/"..species..".vehicle")
			local settings = sb.jsonMerge( vehicleFile.sbqData.defaultSettings, parameters.scriptStorage.settings or {})
			local skins = settings.skinNames or {}
			local skin = skins.head or "default"
			local directives = settings.directives or ""

			config.rarity = "Rare"
			config.inventoryIcon = "/vehicles/sbq/"..species.."/skins/"..skin.."/icon.png"..directives
			config.tooltipFields.statusLabel = config.description.."\nInhabited by: "..(vehicleFile.sbqData.displayName or species:gsub("^sbq", ""))
		end
	end

	return config, parameters
end
