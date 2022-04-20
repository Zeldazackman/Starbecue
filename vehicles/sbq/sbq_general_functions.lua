
function sbq.logJson(arg)
	sb.logInfo(sb.printJson(arg, 1))
end

function sbq.sameSign(num1, num2)
	if num1 < 0 and num2 < 0 then
		return true
	elseif num1 > 0 and num2 > 0 then
		return true
	else
		return false
	end
end

sbq.dtSinceList = {}
function sbq.dtSince(name, overwrite) -- used for when something isn't in the main update loop but knowing the dt since it was last called is good
	local last = sbq.dtSinceList[name] or 0
	if overwrite then
		sbq.dtSinceList[name] = sbq.totalTimeAlive
	end
	return sbq.totalTimeAlive - last
end


function sbq.notMoving()
	return (math.abs(mcontroller.xVelocity()) < 0.1) and mcontroller.onGround()
end

function sbq.underWater()
	return mcontroller.liquidPercentage() >= sbq.movementParams.minimumLiquidPercentage
end

function sbq.useEnergy(eid, cost, callback)
	sbq.addRPC( world.sendEntityMessage(eid, "sbqUseEnergy", cost), callback)
end

-------------------------------------------------------------------------------

function sbq.objectPowerLevel()
	local power = world.threatLevel()
	if type(power) ~= "number" or power < 1 then return 1 end
	return power
end

function sbq.randomChance(percent)
	return math.random() <= (percent/100)
end

function sbq.checkSettings(checkSettings)
	for setting, value in pairs(checkSettings) do
		if sbq.settings[setting] ~= value then
			return false
		end
	end
	return true
end

function sbq.localToGlobal( position )
	local lpos = { position[1], position[2] }
	if sbq.direction == -1 then lpos[1] = -lpos[1] end
	local mpos = mcontroller.position()
	local gpos = { mpos[1] + lpos[1], mpos[2] + lpos[2] }
	return world.xwrap( gpos )
end
function sbq.globalToLocal( position )
	local pos = world.distance( position, mcontroller.position() )
	if sbq.direction == -1 then pos[1] = -pos[1] end
	return pos
end

function sbq.occupantArray( maybearray )
	if maybearray == nil or maybearray[1] == nil then -- not an array, check for eating
		if maybearray.location then
			if maybearray.failOnFull then
				if (maybearray.failOnFull ~= true) and (sbq.occupants[maybearray.location] >= maybearray.failOnFull) then return maybearray.failTransition
				elseif sbq.locationFull(maybearray.location) then return maybearray.failTransition end
			else
				if sbq.locationEmpty(maybearray.location) then return maybearray.failTransition end
			end
		end
		return maybearray
	else -- pick one depending on number of occupants
		return maybearray[(sbq.occupants[maybearray[1].location or "total"] or 0) + 1]
	end
end

function sbq.getSmolPreyData(settings, species, state, tags, layer)
	return {
		species = species,
		recieved = true,
		update = true,
		layer = layer,
		settings = settings,
		state = state,
		images = sbq.smolPreyAnimationPaths(settings, species, state, tags)
	}
end

function sbq.smolPreyAnimationPaths(settings, species, state, tags)
	local directory = "/vehicles/sbq/"..species.."/"
	local animatedParts = root.assetJson( "/vehicles/sbq/"..species.."/"..species..".animation" ).animatedParts
	local vehicle = root.assetJson( "/vehicles/sbq/"..species.."/"..species..".vehicle" )
	local edibleAnims = vehicle.states[state].edibleAnims or {}
	local tags = tags
	if tags == nil then
		tags = { global = root.assetJson( "/vehicles/sbq/"..species.."/"..species..".animation" ).globalTagDefaults }
	end

	settings.directives = sbq.getColorReplaceDirectives(vehicle.sbqData, settings)

	local returnValues  = {}

	if edibleAnims.head ~= nil then
		returnValues.head = sbq.fixSmolPreyPathTags(directory, animatedParts, "head", "head", edibleAnims.head, settings, tags)
	end
	if edibleAnims.head1 ~= nil then
		returnValues.head1 = sbq.fixSmolPreyPathTags(directory, animatedParts, "head1", "head", edibleAnims.head1, settings, tags)
	end
	if edibleAnims.head2 ~= nil then
		returnValues.head2 = sbq.fixSmolPreyPathTags(directory, animatedParts, "head2", "head", edibleAnims.head2, settings, tags)
	end
	if edibleAnims.head3 ~= nil then
		returnValues.head3 = sbq.fixSmolPreyPathTags(directory, animatedParts, "head3", "head", edibleAnims.head3, settings, tags)
	end
	if edibleAnims.body ~= nil then
		returnValues.body = sbq.fixSmolPreyPathTags(directory, animatedParts, "body", "body", edibleAnims.body, settings, tags)
	end
	if edibleAnims.belly ~= nil then
		returnValues.belly = sbq.fixSmolPreyPathTags(directory, animatedParts, "belly", "belly", edibleAnims.belly, settings, tags)
	end
	if edibleAnims.tail ~= nil then
		returnValues.tail = sbq.fixSmolPreyPathTags(directory, animatedParts, "tail", "tail", edibleAnims.tail, settings, tags)
	end
	if edibleAnims.cock ~= nil then
		returnValues.cock = sbq.fixSmolPreyPathTags(directory, animatedParts, "cock", "cock", edibleAnims.cock, settings, tags)
	end
	if edibleAnims.legs ~= nil then
		returnValues.backlegs = sbq.fixSmolPreyPathTags(directory, animatedParts, "backlegs", "legs", edibleAnims.legs, settings, tags)
		returnValues.frontlegs = sbq.fixSmolPreyPathTags(directory, animatedParts, "frontlegs", "legs", edibleAnims.legs, settings, tags)
	end
	if edibleAnims.arms ~= nil then
		returnValues.backarms = sbq.fixSmolPreyPathTags(directory, animatedParts, "backarms", "arms", edibleAnims.arms, settings, tags)
		returnValues.frontarms = sbq.fixSmolPreyPathTags(directory, animatedParts, "frontarms", "arms", edibleAnims.arms, settings, tags)
	end
	if edibleAnims.balls ~= nil then
		returnValues.backBalls = sbq.fixSmolPreyPathTags(directory, animatedParts, "backBalls", "backBalls", edibleAnims.balls, settings, tags)
		returnValues.frontBalls = sbq.fixSmolPreyPathTags(directory, animatedParts, "frontBalls", "frontBalls", edibleAnims.balls, settings, tags)
	end
	if edibleAnims.breasts ~= nil then
		returnValues.backBreasts = sbq.fixSmolPreyPathTags(directory, animatedParts, "backBreasts", "backBreasts", edibleAnims.breasts, settings, tags)
		returnValues.frontBreasts = sbq.fixSmolPreyPathTags(directory, animatedParts, "frontBreasts", "frontBreasts", edibleAnims.breasts, settings, tags)
	end
	return returnValues
end

function sbq.fixSmolPreyPathTags(directory, animatedParts, partname, statename, animname, settings, tags)
	local path = (
		((((animatedParts.parts[partname].partStates[statename.."State"] or {})[animname] or {}).properties or {}).image)
		or ((((animatedParts.parts[partname].partStates[statename.."State"] or {})[((animatedParts.stateTypes[statename.."State"] or {}).states[animname] or {}).baseAnim or ""] or {}).properties or {}).image)
	)
	local framesName = animname
	if ((animatedParts.stateTypes[statename.."State"] or {}).states[animname] or {}).animFrames ~= nil then
		framesName = ((animatedParts.stateTypes[statename.."State"] or {}).states[animname] or {}).animFrames
	end

	if not path or path == "" then return end
	local partTags = sb.jsonMerge( tags.global, sb.jsonMerge( tags[partname], {
		directives = settings.directives,
		skin = (settings.skinNames or {})[partname] or "default",
		[statename.."StateFrame"] = "1",
		[statename.."StateAnim"] = framesName
	}))
	return directory..sb.replaceTags(path, partTags)
end

function sbq.getColorReplaceDirectives(predatorConfig, predatorSettings)
	if predatorConfig.replaceColors ~= nil then
		local colorReplaceString = ""
		for i, colorGroup in ipairs(predatorConfig.replaceColors) do
			local basePalette = colorGroup[1]
			local replacePalette = colorGroup[((predatorSettings.replaceColors or {})[i] or (predatorConfig.defaultSettings.replaceColors or {})[i] or 1) + 1]
			local fullbright = (predatorSettings.fullbright or {})[i]

			if predatorSettings.replaceColorTable and predatorSettings.replaceColorTable[i] then
				replacePalette = predatorSettings.replaceColorTable[i]
				if type(replacePalette) == "string" then
					return replacePalette
				end
			end

			for j, color in ipairs(replacePalette) do
				if fullbright and #color <= #"ffffff" then -- don't tack it on it if it already has a defined opacity or fullbright
					color = color.."fb"
				end
				colorReplaceString = colorReplaceString.."?replace;"..(basePalette[j] or "").."="..(color or "")
			end
		end
		return colorReplaceString
	end
end


function sbq.transformPrey(i)
	local smolPreyData
	if sbq.occupant[i].progressBarData ~= nil then
		smolPreyData = sbq.occupant[i].progressBarData
	end
	if smolPreyData ~= nil then
		if smolPreyData.layer == true then
			smolPreyData.layer = sbq.occupant[i].smolPreyData
			for j = 0, sbq.occupantSlots do
				if sbq.occupant[j].location == "nested" and sbq.occupant[j].nestedPreyData.owner == sbq.occupant[i].id then
					local nestedPreyData = sb.jsonMerge(sbq.occupant[j].nestedPreyData, {})
					sbq.occupant[j].nestedPreyData = {
						nestedPreyData = nestedPreyData,
						location = smolPreyData.layerLocation,
						owner = sbq.occupant[i].id
					}
				end
			end
		end
		if world.entityType(sbq.occupant[i].id) == "player" and not smolPreyData.forceSettings then
			sbq.addRPC(world.sendEntityMessage(sbq.occupant[i].id, "sbqLoadSettings", smolPreyData.species), function(settings)
				smolPreyData.settings = settings
				sbq.occupant[i].smolPreyData = smolPreyData
				sbq.occupant[i].species = smolPreyData.species
			end)
		else
			sbq.occupant[i].smolPreyData = smolPreyData
			sbq.occupant[i].species = smolPreyData.species
		end
	else
		local species = world.entityName( entity.id() )
		local tags = {}
		local animationFile = root.assetJson("/vehicles/sbq/"..species.."/"..species..".vehicle").animation
		tags.global = root.assetJson( animationFile ).globalTagDefaults
		for part, _ in pairs(root.assetJson( animationFile ).animatedParts.parts ) do
			tags[part] = {}
		end

		if world.entityType(sbq.occupant[i].id) == "player" then
			sbq.addRPC(world.sendEntityMessage(sbq.occupant[i].id, "sbqLoadSettings", species), function(settings)
				sbq.occupant[i].smolPreyData = sbq.getSmolPreyData(settings, species, "smol", tags)
				sbq.occupant[i].species = species
			end)
		else
			sbq.occupant[i].smolPreyData = sbq.getSmolPreyData(sbq.settings, species, "smol", tags)
			sbq.occupant[i].species = species
		end
	end
	sbq.refreshList = true
end
