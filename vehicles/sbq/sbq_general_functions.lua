require("/scripts/poly.lua")
require("/scripts/rect.lua")
require("/interface/scripted/sbq/sbqSettings/autoSetSettings.lua")

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
	for setting, value in pairs(checkSettings or {}) do
		if (type(sbq.settings[setting]) == "table") and sbq.settings[setting].name ~= nil then
			if not value then return false
			elseif type(value) == "table" then
				if not sbq.checkTable(value, sbq.settings[setting]) then return false end
			end
		elseif type(value) == "table" then
			local match = false
			for i, value in ipairs(value) do if (sbq.settings[setting] or false) == value then
				match = true
				break
			end end
			if not match then return false end
		elseif (sbq.settings[setting] or false) ~= value then return false
		end
	end
	return true
end

function sbq.checkTable(check, checked)
	for k, v in pairs(check) do
		if type(v) == "table" then
			if not sbq.checkTable(v, (checked or {})[k]) then return false end
		elseif v == true and type((checked or {})[k]) ~= "boolean" and ((checked or {})[k]) ~= nil then
		elseif not (v == (checked or {})[k] or false) then return false
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
	if maybearray[1] == nil then -- not an array, check for eating
		if maybearray.location and maybearray.failOnFull ~= nil then
			if maybearray.failOnFull then
				if (maybearray.failOnFull ~= true) and (sbq.occupants[maybearray.location] >= maybearray.failOnFull) then return maybearray.failTransition
				elseif not sbq.getSidedLocationWithSpace(maybearray.location, 1) then return maybearray.failTransition end
			else
				if sbq.occupants[maybearray.location] <= 0 then return maybearray.failTransition end
			end
		end
		return maybearray
	else -- pick one depending on number of occupants
		return maybearray[math.floor(sbq.occupants[maybearray[1].location or "total"] or 0) + 1]
	end
end

function sbq.getSmolPreyData(settings, species, state, tags, layer)
	return {
		species = species,
		recieved = true,
		update = true,
		layer = layer,
		settings = settings or {},
		state = state,
		images = sbq.smolPreyAnimationPaths(settings or {}, species, state, tags)
	}
end

function sbq.smolPreyAnimationPaths(settings, species, state, newTags)
	local directory = "/vehicles/sbq/"..species.."/"
	local animatedParts = root.assetJson( "/vehicles/sbq/"..species.."/"..species..".animation" ).animatedParts
	local vehicle = root.assetJson( "/vehicles/sbq/"..species.."/"..species..".vehicle" )
	local edibleAnims = vehicle.states[state].edibleAnims or {}
	local tags = { global = root.assetJson("/vehicles/sbq/" .. species .. "/" .. species .. ".animation").globalTagDefaults or {} }
	for part, skin in pairs(settings.skinNames or {}) do
		tags.global[part .. "Skin"] = skin
	end
	for partname, data in pairs(animatedParts.parts or {}) do
		tags[partname] = {}
		for tagname, tag in pairs(data.properties or {}) do
			local tagType = type(tag)
			if (tagType == "string" or tagType == "number") and (tagname ~= "zLevel" and tagname ~= "image") then
				tags[partname][tagname] = tostring(tag)
			end
		end
	end
	tags = sb.jsonMerge(tags, newTags or {})

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
		returnValues.ballsBack = sbq.fixSmolPreyPathTags(directory, animatedParts, "ballsBack", "ballsBack", edibleAnims.balls, settings, tags)
		returnValues.ballsFront = sbq.fixSmolPreyPathTags(directory, animatedParts, "ballsFront", "ballsFront", edibleAnims.balls, settings, tags)
	end
	if edibleAnims.breasts ~= nil then
		returnValues.breastsBack = sbq.fixSmolPreyPathTags(directory, animatedParts, "breastsBack", "breastsBack", edibleAnims.breasts, settings, tags)
		returnValues.breastsFront = sbq.fixSmolPreyPathTags(directory, animatedParts, "breastsFront", "breastsFront", edibleAnims.breasts, settings, tags)
	end
	return returnValues
end

function sbq.fixSmolPreyPathTags(directory, animatedParts, partname, statename, animname, settings, tags)
	if not animatedParts.parts[partname] then return end
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
			colorReplaceString = colorReplaceString.."?replace"
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
					color = color.."fe"
				end
				colorReplaceString = colorReplaceString..";"..(basePalette[j] or "").."="..(color or "")
			end
		end
		return colorReplaceString
	end
end


function sbq.transformPrey(i)
	local smolPreyData = sbq.occupant[i].progressBarData or {}
	if smolPreyData.layer == true then
		smolPreyData.layer = sbq.occupant[i].smolPreyData
		sbq.occupant[i].smolPreyData = {}
	end
	if type(smolPreyData.species) == "string" then
		local entityType = world.entityType(sbq.occupant[i].id)
		if entityType == "player" or entityType == "npc" and not smolPreyData.forceSettings then
			sbq.addRPC(world.sendEntityMessage(sbq.occupant[i].id, "sbqLoadSettings", smolPreyData.species), function(settings)
				sbq.doTransformPrey(i, sb.jsonMerge(smolPreyData.settings, settings or {}), smolPreyData)
			end, function ()
				sbq.doTransformPrey(i, smolPreyData.settings or {}, smolPreyData)
			end)
		else
			sbq.doTransformPrey(i, smolPreyData.settings or {}, smolPreyData)
		end
	end
	if sbq.occupant[i].progressBarType == "eggifying" then
		sbq.occupant[i].egged = true
	else
		sbq.occupant[i].transformed = true
	end
	sbq.refreshList = true
end

function sbq.doTransformPrey(i, settings, smolPreyData)
	smolPreyData = sb.jsonMerge(smolPreyData, sbq.getSmolPreyData(settings, smolPreyData.species, smolPreyData.state or "smol"))
	if sbq.occupant[i].species == "sbqEgg" then
		sbq.occupant[i].smolPreyData.layer = smolPreyData
	else
		if type(sbq.occupant[i].smolPreyData.id) == "number" and world.entityExists(sbq.occupant[i].smolPreyData.id) then
			smolPreyData.id = world.spawnVehicle( smolPreyData.species, sbq.localToGlobal({ sbq.occupant[i].victimAnim.last.x or 0, sbq.occupant[i].victimAnim.last.y or 0}), { driver = sbq.occupant[i].id, settings = smolPreyData.settings, uneaten = true, startState = smolPreyData.state, layer = smolPreyData.layer, isNested = true, retrievePrey = sbq.occupant[i].smolPreyData.id })
		end
		sbq.occupant[i].smolPreyData = smolPreyData
		sbq.occupant[i].species = smolPreyData.species
	end
end

function sbq.transformPlayer(i)
	local id = sbq.occupant[i].id
	local data = sbq.occupant[i].progressBarData or {species = sbq.species, gender = sbq.settings.TFTG or "noChange"}
	sbq.occupant[i].transformed = true
	if sbq.settings.TGOnly then
		data.species = "originalSpecies"
		data.identity = nil
	end
	if type(id) == "number" and world.entityExists(id) then
		world.sendEntityMessage(id, "sbqMysteriousPotionTF", data )
	end
end

local map = {
	heal = "Heal",
	none = "None",
	digest = "Digest",
	softDigest = "SoftDigest"
}
local copyList = {
	"none",
	"heal",
	"digest",
	"softDigest",
	"TF",
	"eggify"
}

require("/scripts/SBQ_species_config.lua")

function sbq.initLocationEffects()
	for location, data in pairs(sbq.sbqData.locations or {}) do
		local data = sb.jsonMerge(sbq.config.defaultLocationData[location] or {}, data)
		local infusedLocation
		local item = (sbq.settings or {})[location .. "InfusedItem"]
		if item and data.infusion then
			local infuseSpecies
			if ((((item.parameters or {}).npcArgs or {}).npcParam or {}).scriptConfig or {}).uniqueId then
				infuseSpecies = item.parameters.npcArgs.npcSpecies
			else
				infuseSpecies = (item.parameters or {}).species
			end
			if infuseSpecies then
				local sbqData = sbq.getSbqData(infuseSpecies) or {}
				infusedLocation = (sbqData.locations or {})[location]
				if infusedLocation then
					infusedLocation = sb.jsonMerge(sbq.config.defaultLocationData[location] or {}, infusedLocation)
					if infusedLocation.TF then
						if (not infusedLocation.TF.data) or (not infusedLocation.TF.data.species) then
							infusedLocation.TF.data = { species = infuseSpecies, playerSpeciesTF = true }
						end
					end
					-- this is to make sure that if you have used an infusion slot to get this modified locationData you can still get these options for *your* species
					infusedLocation.combine = data.combine
					infusedLocation.combined = data.combined
					infusedLocation.infusedVisual = data.infusedVisual
					infusedLocation.infusion = data.infusion
					infusedLocation.infusionAccepts = data.infusionAccepts
					infusedLocation.checkSettings = data.checkSettings
				end
			end
		end
		sbq.sbqData.locations[location] = sb.jsonMerge(sbq.config.defaultLocationData[location] or {}, infusedLocation or data)
	end

	for location, data in pairs(sbq.sbqData.locations) do
		if data.sided then
			sbq.sbqData.locations[location.."L"] = sbq.sbqData.locations[location.."L"] or {}
			sbq.sbqData.locations[location.."R"] = sbq.sbqData.locations[location.."R"] or {}
			for name, copy in pairs(data) do
				if name ~= "combine" and name ~= "sided" then
					sbq.sbqData.locations[location.."L"][name] = sbq.sbqData.locations[location.."L"][name] or copy
					sbq.sbqData.locations[location.."R"][name] = sbq.sbqData.locations[location.."R"][name] or copy
				end
			end
			sbq.sbqData.locations[location .. "L"].side = sbq.sbqData.locations[location .. "L"].side or "L"
			sbq.sbqData.locations[location .. "R"].side = sbq.sbqData.locations[location .. "R"].side or "R"
		end
	end
	for location, data in pairs(sbq.sbqData.locations) do
		local value = sbq.settings[location.."EffectSlot"]
		if value then
			local effect = (data[value] or {}).effect or (sbq.sbqData.effectDefaults or {})[value] or (sbq.config.effectDefaults or {})[value] or "sbqRemoveBellyEffects"
			if( sbq.sbqData.overrideSettings or {})[location..map[value].."Enable"] == false then
				effect = (sbq.sbqData.defaultSettings or {})[location.."Effect"] or "sbqRemoveBellyEffects"
			end
			sbq.settings[location.."Effect"] = effect
		end
	end
end
