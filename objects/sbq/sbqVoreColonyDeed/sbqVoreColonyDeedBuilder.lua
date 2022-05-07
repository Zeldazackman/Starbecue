
function build( directory, config, parameters, level, seed )

	if parameters.saveTenants ~= nil then
		local name = (((((parameters.saveTenants.occupier or {}).tenants or {})[1] or {}).overrides or {}).identity or {}).name
		if name then
			config.shortdescription = name.."'s Deed"
			parameters.shortdescription = name.."'s Deed"
		else
			config.shortdescription = "SBQ Colony Deed"
			parameters.shortdescription = "SBQ Colony Deed"
		end
	end

	return config, parameters
end
