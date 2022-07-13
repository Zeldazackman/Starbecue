
function build( directory, config, parameters, level, seed )
	parameters.originalColonyTags = parameters.originalColonyTags or config.colonyTags
	parameters.colonyTags = parameters.originalColonyTags
	config = sb.jsonMerge(config, parameters)
	local preyPossessive = "'s"
	if config.prey then
		if config.prey:sub(-1,-1) == "s" then
			preyPossessive = "'"
		end
		if config.preyUUID then
			table.insert(config.colonyTags, config.objectName.."Prey"..config.preyUUID)
		end
	end
	local predPossessive = "'s"
	if config.pred then
		if config.pred:sub(-1,-1) == "s" then
			predPossessive = "'"
		end
		if config.predUUID then
			table.insert(config.colonyTags, config.objectName.."Pred"..config.predUUID)
		end
	end
	local replaceTagTable = { predName = config.pred, preyName = config.prey, predPossessive = predPossessive, preyPossessive = preyPossessive}

	if config.pred and config.prey then
		config.description = sb.replaceTags(config.replaceDescPredPrey, replaceTagTable)
		config.shortdescription = sb.replaceTags(config.replaceShortDescPredPrey, replaceTagTable)
	elseif config.prey then
		config.description = sb.replaceTags(config.replaceDescPrey, replaceTagTable)
		config.shortdescription = sb.replaceTags(config.replaceShortDescPrey, replaceTagTable)
	elseif config.pred then
		config.description = sb.replaceTags(config.replaceDescPred, replaceTagTable)
		config.shortdescription = sb.replaceTags(config.replaceShortDescPred, replaceTagTable)
	end

	parameters.description = config.description
	parameters.shortdescription = config.shortdescription
	parameters.colonyTags = config.colonyTags

	return config, parameters
end
