
function build( directory, config, parameters, level, seed )

	if parameters.scriptStorage ~= nil then
		config.scriptStorage = sb.jsonMerge(config.scriptStorage, parameters.scriptStorage)

		if config.scriptStorage.spov ~= nil then
			local species = config.scriptStorage.spov.type:gsub("^spov","")
			local settings = sb.jsonMerge( root.assetJson("/vehicles/spov/"..species.."/"..species..".vehicle").vso.defaultSettings, parameters.scriptStorage.settings or {})
			local skins = settings.skinNames or {}
			local skin = skins.head or "default"
			local directives = settings.directives or ""

			config.rarity = "Rare"
			config.inventoryIcon = "/vehicles/spov/"..species.."/spov/"..skin.."/icon.png"..directives
		end

		--config.tooltipFields.statusLabel = sb.replaceTags(config.descriptionWithTags, {
		--	fattenAdjective = config.fattenAdjectives[settings.fatten + 1],
		--	hungryAdjective = config.hungryAdjectives[settings.bellyEffect]
		--})
	end

	return config, parameters
end
