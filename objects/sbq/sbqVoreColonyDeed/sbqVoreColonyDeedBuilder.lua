
function build( directory, config, parameters, level, seed )

	if parameters.saveTenants ~= nil then
		local name = (parameters.saveTenants.occupier or {}).partyName or (((((parameters.saveTenants.occupier or {}).tenants or {})[1] or {}).overrides or {}).identity or {}).name
		if name then
			local ownership = "'s"
			if name:sub(-1,-1) == "s" then
				ownership = "'"
			end
			config.shortdescription = name..ownership.." Deed"
			parameters.shortdescription = name..ownership.." Deed"
		else
			config.shortdescription = "SBQ Colony Deed"
			parameters.shortdescription = "SBQ Colony Deed"
		end
	end

	return config, parameters
end
