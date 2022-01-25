--[[
	Functions placed here are in key locations in the sbq scripts where I believe people would want to place predator specific actions
	these will typically be empty, but are called at points in the main loop

	they're meant to be replaced in the predator itself to have it have said specific actions happen
]]
---------------------------------------------------------------------------------------------------------------------------------

function sbq.init()
end

function sbq.uninit()
end

-- to have something in the main loop rather than a state loop
function sbq.update(dt)
end

-- the standard state called when a state's script is undefined
function sbq.standardState(dt)
end

-- the pathfinding function called if a state doesn't have its own pathfinding script
function sbq.pathfinding(dt)
end

-- for handling the grab action when clicked, some things may want to handle it differently
function sbq.handleGrab()
	local primary = (((sbq.seats[sbq.driverSeat].controls.primaryHandItemDescriptor or {}).parameters or {}).scriptStorage or {}).clickAction
	local alt = (((sbq.seats[sbq.driverSeat].controls.altHandItemDescriptor or {}).parameters or {}).scriptStorage or {}).clickAction
	local victim = sbq.grabbing

	if sbq.pressControl(sbq.driverSeat, "primaryFire") then
		sbq.uneat(sbq.grabbing)
		sbq.grabbing = nil
		if primary == "grab" then
			sbq.grabAngleTransitions(victim)
		else
			sbq.doTransition(primary, { id = victim })
		end
	elseif sbq.pressControl(sbq.driverSeat, "altFire") then
		sbq.uneat(sbq.grabbing)
		sbq.grabbing = nil
		if alt == "grab" then
			sbq.grabAngleTransitions(victim)
		else
			sbq.doTransition(alt, { id = victim })
		end
	end
end

function sbq.grabAngleTransitions(victim)
	local angle = sbq.armRotation.frontarmsAngle * 180/math.pi
	local transition
	if (angle >= 45 and angle <= 135) then
		transition = "oralVore"
	elseif (angle >= 0 and angle <= 45) then
		transition = "breastVore"
	elseif (angle <= 0 and angle >= -30) then
		transition = "cockVore"
	elseif (angle <= -30 and angle >= -60) then
		transition = "unbirth"
	elseif (angle <= -60 and angle >= -135) then
		transition = "analVore"
	end
	sbq.doTransition(transition, { id = victim })
end

-- for letting out prey, some predators might wand more specific logic regarding this
function sbq.letout(id)
	local id = id
	if id == nil then
		id = sbq.occupant[sbq.occupants.total].id
	end
	return sbq.doTransition( "escape", {id = id} )
end

-- warp in/out effect should be replaceable if needed
function sbq.warpInEffect()
	world.spawnProjectile( "sbqWarpInEffect", mcontroller.position(), entity.id(), {0,0}, true, { processing = sbq.getWarpInOutDirectives()})
end
function sbq.warpOutEffect()
	world.spawnProjectile( "sbqWarpOutEffect", mcontroller.position(), sbq.driver or entity.id(), {0,0}, true, { processing = sbq.getWarpInOutDirectives()})
end

function sbq.getWarpInOutDirectives()
	if sbq.driver ~= nil then
		species = world.entitySpecies(sbq.driver)
		if species ~= nil then
			return root.assetJson("/species/"..species..".species").effectDirectives
		end
	end
end

-- called whenever the settings manu is updated
function sbq.settingsMenuUpdated()
end

---------------------------------------------------------------------------------------------------------------------------------
--[[these are called when handling the effects applied to the occupants, called for each one and give the occupant index,
the entity id, health, and the status checked in the options]]

-- to have any extra effects applied to those in digest locations
function sbq.extraBellyEffects(i, eid, health, status)
end

-- to have effects applied to other locations, for example, womb if the predator does unbirth
function sbq.otherLocationEffects(i, eid, health, status, location)
end

---------------------------------------------------------------------------------------------------------------------------------

-- for doing the item actions
function sbq.setItemActionColorReplaceDirectives()
	local colorReplaceString = sbq.sbqData.itemActionDirectives or ""

	if sbq.sbqData.replaceColors ~= nil then
		local i = 1
		local basePalette = { "154247", "23646a", "39979e", "4cc1c9" }
		local replacePalette = sbq.sbqData.replaceColors[i][((sbq.settings.replaceColors or {})[i] or (sbq.sbqData.defaultSettings.replaceColors or {})[i] or 1) + 1]
		local fullbright = (sbq.settings.fullbright or {})[i]

		if sbq.settings.replaceColorTable ~= nil and sbq.settings.replaceColorTable[i] ~= nil then
			replacePalette = sbq.settings.replaceColorTable[i]
		end

		for j, color in ipairs(basePalette) do
			color = replacePalette[j]
			if color then
				if fullbright and #color <= #"ffffff" then -- don't tack it on it if it already has a defined opacity or fullbright
					color = color.."fb"
				end
				colorReplaceString = colorReplaceString.."?replace;"..basePalette[j].."="..color
			end
		end
	end

	sbq.itemActionDirectives = colorReplaceString
end
