function build(directory, config, parameters, level, seed)
	config = sb.jsonMerge(config, parameters)
	if (config or {}).npcArgs ~= nil then
		parameters.tooltipKind = "filledcapturepod"
		parameters.tooltipFields = parameters.tooltipFields or {}
		parameters.tooltipFields.subtitle = (config.npcArgs.wasPlayer and "Player") or config.npcArgs.npcType or "generictenant"
		parameters.tooltipFields.noCollarLabel = ""

		local success, speciesFile = pcall(root.assetJson, ("/species/"..(config.npcArgs.npcSpecies or "")..".species"))

		if success then
			parameters.inventoryIcon = root.npcPortrait("bust", config.npcArgs.npcSpecies, config.npcArgs.npcType or "generictenant",
				config.npcArgs.npcLevel or 1, config.npcArgs.npcSeed, config.npcArgs.npcParam)

			parameters.tooltipFields.collarNameLabel = ""

			parameters.description = ""

			parameters.tooltipFields.objectImage = config.fullPortrait or
			root.npcPortrait("full", config.npcArgs.npcSpecies, config.npcArgs.npcType or "generictenant",
					config.npcArgs.npcLevel or 1, config.npcArgs.npcSeed, config.npcArgs.npcParam)
		elseif config.speciesFile then
			local colorRemap = "?replace"
			config.baseColorMap = config.baseColorMap or {
				primary = { "A19579", "CBBD9D", "ECEACC" },
				secondary = { "726B5A" }
			}
			for colorName, from in pairs(config.baseColorMap) do
				local to = config.speciesFile.baseColorMap[colorName] or from
				for i, color in ipairs(from or {}) do
					colorRemap = colorRemap .. ";" .. color .. "=" .. (to[i] or to[#to])
				end
			end
			config.directives = colorRemap ..
				((((config.npcArgs.npcParam or {}).identity or {}).bodyDirectives or "") ..
					(((config.npcArgs.npcParam or {}).identity or {}).hairDirectives or ""))

			parameters.inventoryIcon = (config.useIcon or "/items/generic/other/secretnote.png")..config.directives

			parameters.tooltipFields.collarNameLabel = "Placeholder Card"

			parameters.description = "This card is a placeholder until the character is fully implemented"
		end
	end

	return config, parameters
end
