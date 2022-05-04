
function build(directory, config, parameters, level, seed)

	if parameters ~= nil then
		if parameters.species then
			local success, speciesFile = pcall(root.assetJson, ("/species/"..parameters.species..".species") )
			if success then
				config.shortdescription = speciesFile.charCreationTooltip.title.." Potion"
			end
		end
		if parameters.name then
			config.shortdescription = parameters.name.." Potion"
		end
	end

	return config, parameters
end
