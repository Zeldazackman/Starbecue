
function build( directory, config, parameters, level, seed )
	parameters.originalColonyTags = parameters.originalColonyTags or config.colonyTags
	parameters.colonyTags = parameters.originalColonyTags
	config = sb.jsonMerge(config, parameters)

	if not parameters.description or not parameters.shortdescription then
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

		local description
		local shortdescription
		if config.pred and config.prey then
			if type(config.replaceDescPredPrey) == "table" then
				local random = math.random(#config.replaceDescPredPrey)
				description = config.replaceDescPredPrey[random][1]
				shortdescription = config.replaceDescPredPrey[random][2] or config.replaceShortDescPredPrey
			else
				description = config.replaceDescPredPrey
				shortdescription = config.replaceShortDescPredPrey
			end
		elseif config.prey then
			if type(config.replaceDescPrey) == "table" then
				local random = math.random(#config.replaceDescPrey)
				description = config.replaceDescPrey[random][1]
				shortdescription = config.replaceDescPrey[random][2] or config.replaceShortDescPrey
			else
				description = config.replaceDescPrey
				shortdescription = config.replaceShortDescPrey
			end
		elseif config.pred then
			if type(config.replaceDescPred) == "table" then
				local random = math.random(#config.replaceDescPred)
				description = config.replaceDescPred[random][1]
				shortdescription = config.replaceDescPred[random][2] or config.replaceShortDescPred
			else
				description = config.replaceDescPred
				shortdescription = config.replaceShortDescPred
			end
		end

		if description then
			config.description = sb.replaceTags(description, replaceTagTable)
		end
		if shortdescription then
			config.shortdescription = sb.replaceTags(shortdescription, replaceTagTable)
		end
	end

	parameters.description = config.description
	parameters.shortdescription = config.shortdescription
	parameters.colonyTags = config.colonyTags

	return config, parameters
end
