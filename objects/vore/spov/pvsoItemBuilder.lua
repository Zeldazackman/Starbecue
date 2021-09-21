
function build( directory, config, parameters, level, seed )

	if parameters.scriptStorage ~= nil and parameters.scriptStorage.settings ~= nil then
		config.scriptStorage = parameters.scriptStorage

		local settings = parameters.scriptStorage.settings

		local skin = settings.skinNames.head or "default"

		config.inventoryIcon = "/vehicles/spov/"..config.spov.types[1]:sub( 5 ).."/spov/"..skin.."/icon.png"..settings.directives

		config.tooltipFields.statusLabel = sb.replaceTags(config.descriptionWithTags, {
			fattenAdjective = config.fattenAdjectives[settings.fatten + 1],
			hungryAdjective = config.hungryAdjectives[settings.bellyEffect]
		})
	end

	return config, parameters
end
