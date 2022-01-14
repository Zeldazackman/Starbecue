--[[
	Functions placed here are in key locations in the sbq scripts where I believe people would want to place predator specific actions
	these will typically be empty, but are called at points in the main loop

	they're meant to be replaced in the predator itself to have it have said specific actions happen
]]
---------------------------------------------------------------------------------------------------------------------------------

function p.init()
end

function p.uninit()
end

-- to have something in the main loop rather than a state loop
function p.update(dt)
end

-- the standard state called when a state's script is undefined
function p.standardState(dt)
end

-- the pathfinding function called if a state doesn't have its own pathfinding script
function p.pathfinding(dt)
end

-- for handling the grab action when clicked, some things may want to handle it differently
function p.handleGrab()
	local primary = (((p.seats[p.driverSeat].controls.primaryHandItemDescriptor or {}).parameters or {}).scriptStorage or {}).clickAction
	local alt = (((p.seats[p.driverSeat].controls.altHandItemDescriptor or {}).parameters or {}).scriptStorage or {}).clickAction
	local victim = p.grabbing

	if p.pressControl(p.driverSeat, "primaryFire") then
		p.uneat(p.grabbing)
		p.grabbing = nil
		if primary == "grab" then
			p.grabAngleTransitions(victim)
		else
			p.doTransition(primary, { id = victim })
		end
	elseif p.pressControl(p.driverSeat, "altFire") then
		p.uneat(p.grabbing)
		p.grabbing = nil
		if alt == "grab" then
			p.grabAngleTransitions(victim)
		else
			p.doTransition(alt, { id = victim })
		end
	end
end

function p.grabAngleTransitions(victim)
	local angle = p.armRotation.frontarmsAngle * 180/math.pi
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
	p.doTransition(transition, { id = victim })
end

-- for letting out prey, some predators might wand more specific logic regarding this
function p.letout(id)
	local id = id
	if id == nil then
		id = p.occupant[p.occupants.total].id
	end
	return p.doTransition( "escape", {id = id} )
end

-- warp in/out effect should be replaceable if needed
function p.warpInEffect()
	world.spawnProjectile( "sbqWarpInEffect", mcontroller.position(), entity.id(), {0,0}, true, { processing = p.getWarpInOutDirectives()})
end
function p.warpOutEffect()
	world.spawnProjectile( "sbqWarpOutEffect", mcontroller.position(), p.driver or entity.id(), {0,0}, true, { processing = p.getWarpInOutDirectives()})
end

function p.getWarpInOutDirectives()
	if p.driver ~= nil then
		species = world.entitySpecies(p.driver)
		if species ~= nil then
			return root.assetJson("/species/"..species..".species").effectDirectives
		end
	end
end

-- called whenever the settings manu is updated
function p.settingsMenuUpdated()
end

---------------------------------------------------------------------------------------------------------------------------------
--[[these are called when handling the effects applied to the occupants, called for each one and give the occupant index,
the entity id, health, and the status checked in the options]]

-- to have any extra effects applied to those in digest locations
function p.extraBellyEffects(i, eid, health, status)
end

-- to have effects applied to other locations, for example, womb if the predator does unbirth
function p.otherLocationEffects(i, eid, health, status, location)
end

---------------------------------------------------------------------------------------------------------------------------------

-- for doing the item actions
function p.setItemActionColorReplaceDirectives()
	local colorReplaceString = p.sbqData.itemActionDirectives or ""

	if p.sbqData.replaceColors ~= nil then
		local i = 1
		local basePalette = { "154247", "23646a", "39979e", "4cc1c9" }
		local replacePalette = p.sbqData.replaceColors[i][((p.settings.replaceColors or {})[i] or (p.sbqData.defaultSettings.replaceColors or {})[i] or 1) + 1]
		local fullbright = (p.settings.fullbright or {})[i]

		if p.settings.replaceColorTable ~= nil and p.settings.replaceColorTable[i] ~= nil then
			replacePalette = p.settings.replaceColorTable[i]
		end

		for j, color in ipairs(basePalette) do
			color = replacePalette[j]
			if fullbright and #color <= #"ffffff" then -- don't tack it on it if it already has a defined opacity or fullbright
				color = color.."fb"
			end
			colorReplaceString = colorReplaceString.."?replace;"..basePalette[j].."="..color
		end
	end

	p.itemActionDirectives = colorReplaceString
end
