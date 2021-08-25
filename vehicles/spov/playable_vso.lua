--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

p = {
	maxOccupants = { --basically everything I think we'd need
		total = 0
	},
	occupants = {
		total = 0
	},
	occupant = {},
	occupantOffset = 1,
	fattenBelly = 0,
	justAte = false,
	justLetout = false,
	monstercoords = {0,0},
	nextIdle = 0,
	swapCooldown = 0
}
p.settings = {}

p.movement = {
	jumps = 0,
	jumped = false,
	waswater = false,
	bapped = 0,
	downframes = 0,
	spaceframes = 0,
	groundframes = 0,
	airframes = 0,
	run = false,
	wasspecial1 = 10, -- Give things time to finish initializing, so it realizes you're holding special1 from spawning vap instead of it being a new press
	E = false,
	wasE = false,
	primaryCooldown = 0,
	altCooldown = 0,
	lastYVelocity = 0
}

p.clearOccupant = {
	id = nil,
	loungeStatList = {},
	statList = {},
	statPower = {},
	visible = nil,
	location = nil,
	species = nil,
	filepath = nil
}

p.animationState = {}

require("/vehicles/spov/pvso_animation.lua")

function init()
	p.vso = config.getParameter("vso")
	p.directoryPath = config.getParameter("directoryPath")
	p.cfgAnimationFile = config.getParameter("animation")
	p.victimAnimations = root.assetJson(p.vso.victimAnimations)
	p.stateconfig = config.getParameter("states")
	p.animStateData = root.assetJson( p.directoryPath .. p.cfgAnimationFile ).animatedParts.stateTypes
	p.config = root.assetJson( "/vehicles/spov/pvso_general.config")
	p.animPartLists = root.assetJson(p.directoryPath .. p.cfgAnimationFile ).animationPartLists
	p.maxOccupants = config.getParameter( "maxOccupants")
	p.locations = config.getParameter( "locations")
	p.resetOccupantCount()

	for i = 1, p.maxOccupants.total do
		p.occupant[i] = p.clearOccupant
	end

	for i = 1, #p.animPartLists.stateTypes do
		local state = p.animPartLists.stateTypes[i]
		p.animationState[state] = {
			anim = p.animStateData[state].default,
			priority = p.animStateData[state].states[p.animStateData[state].default].priority,
			cycle = p.animStateData[state].states[p.animStateData[state].default].cycle,
			frames = p.animStateData[state].states[p.animStateData[state].default].frames,
			time = 0,
			queue = {}
		}
		p.victimAnims[state] = {
			done = true
		}
	end

	if not config.getParameter( "uneaten" ) then
		world.spawnProjectile( "spovwarpineffectprojectile", mcontroller.position(), entity.id(), {0,0}, true) --Play warp in effect
	end

	-- vsoUseLounge( false ) -- is this needed here?

	if config.getParameter( "driver" ) ~= nil then
		p.control.standalone = true
		p.control.driver = "driver"
		p.control.driving = true
		local driver = config.getParameter( "driver" )
		storage._vsoSpawnOwner = driver
		storage._vsoSpawnOwnerName = world.entityName( driver )
		p.forceSeat( driver, "driver" )
		-- vsoVictimAnimVisible( "driver", false )

		local settings = config.getParameter( "settings" )
		p.settings = settings
	else
		p.control.standalone = false
		p.control.driver = "occupant1"
		p.control.driving = false
		vehicle.setLoungeEnabled( "driver", false )
	end


	onForcedReset();	--Do a forced reset once.

	-- TODO: redo storage loading to use spawn config instead of entity messaging
	-- vsoStorageLoad( p.loadStoredData );	--Load our data (asynchronous, so it takes a few frames)

	message.setHandler( "settingsMenuSet", function(_,_, val )
		p.settings = val
	end )

	message.setHandler( "letout", function(_,_, val )
		p.doTransition( "escape", {index = val} )
	end )

	message.setHandler( "settingsMenuRefresh", function(_,_)
		return getSettingsMenuInfo()
	end )

	message.setHandler( "despawn", function(_,_, nowarpout)
		local driver = vehicle.entityLoungingIn(p.control.driver)
		world.sendEntityMessage(driver, "PVSOClear")
		p.nowarpout = nowarpout
		_vsoOnDeath()
	end )
	message.setHandler( "forcedsit", p.control.pressE )

	message.setHandler( "digest", function(_,_, eid)
		local i = getOccupantFromEid(eid)
		local location = p.occupant[i].location
		p.doTransition("digest"..location)
	end )

	message.setHandler( "uneat", function(_,_, eid)
		local i = getOccupantFromEid(eid)
		p.occupant[i] = p.clearOccupant
		p.unForceSeat( "occupant"..i)
	end )

	message.setHandler( "smolPreyPath", function(_,_, seatindex, path)
		p.occupant[seatindex].filepath = path
		p.smolprey()
	end )

	if not config.getParameter( "uneaten" ) then
		if not p.startState then
			p.startState = "stand"
		end
		p.setState( p.startState )
		p.doAnims( p.stateconfig[p.startState].idle, true )
	else -- released from larger pred
		p.setState( "smol" )
		p.doAnims( p.stateconfig.smol.idle, true )
	end

	local v_status = vehicle.setLoungeStatusEffects -- has to be in here instead of root because vehicle is nil before init
	vehicle.setLoungeStatusEffects = function(seatname, effects)
		local eid = vehicle.entityLoungingIn(seatname)
		local seatindex = getOccupantFromEid(eid)
		local smolprey
		if seatname ~= "driver" then
			smolprey = p.occupant[seatindex].species
		end
		if smolprey or p.isMonster(eid) then -- fix invis on smolprey too
			local invis = false
			local effects2 = {} -- don't touch outer table
			for _,e in ipairs(effects) do
				if e == "pvsoinvisible" then invis = true end
				table.insert(effects2, e)
			end
			if invis then
				animator.setAnimationState( seatname.."state", "empty" )
			elseif smolprey then
				animator.setAnimationState( seatname.."state", "smol" )
				table.insert(effects2, "vsoinvisible")
			elseif p.isMonster(eid) then
				animator.setAnimationState( seatname.."state", "monster" )
				table.insert(effects2, "vsoinvisible")
			end
			v_status(seatname, effects2)
		else
			v_status(seatname, effects)
		end
	end

	onBegin()
end

function update(dt)
	p.updateAnims(dt)

	p.idleStateChange()

	p.updateDriving()
	p.doPhysics()

	p.handleBelly()
	p.applyStatusLists()

	p.emoteCooldown = p.emoteCooldown - dt;
end

function uninit()
end

function p.applyStatusLists()
	for i = 1, p.occupants.total do
		for j = 1, #p.occupant[i].statList[j] do
			world.sendEntityMessage( p.occupant[i].id, "applyStatusEffect", p.occupant[i].statList[j], p.occupant[i].statPower[j], entity.id() )
		end
		vehicle.setLoungeStatusEffects( "occupant"..i, p.occupant[i].loungeStatList )
	end
end

function p.applyStatusEffects(eid, statuses)
	for i = 1, #statuses do
		world.sendEntityMessage(eid, "applyStatusEffect", statuses[i][1], statuses[i][2], entity.id())
	end
end

function p.addStatusToList(index, status, power)
	local power = power
	for i = 1, #p.occupant[index].statList do
		if p.occupant[index].statList[i] == status then
			if power then
				p.occupant[index].statPower[i] = power
			end
			return
		end
	end
	if not power then
		power = 1
	end
	table.insert(p.occupant[index].statList, status)
	table.insert(p.occupant[index].statPower, power)
end

function p.addLoungeStatusToList(index, status)
	for i = 1, #p.occupant[index].loungeStatList do
		if p.occupant[index].loungeStatList[i] == status then
			return
		end
	end
	table.insert(p.occupant[index].loungeStatList, status)
end

function p.removeLoungeStatusFromList(index, status)
	for i = 1, #p.occupant[index].loungeStatList do
		if p.occupant[index].loungeStatList[i] == status then
			table.remove(p.occupant[index].loungeStatList, i)
			return
		end
	end
end

function p.removeStatusFromList(index, status)
	for i = 1, #p.occupant[index].statList do
		if p.occupant[index].statList[i] == status then
			table.remove(p.occupant[index].statList, i)
			table.remove(p.occupant[index].statPower, i)
			return
		end
	end
end

function p.forceSeat( occupantId, seatname )
	if occupantId then
		world.sendEntityMessage( occupantId, "applyStatusEffect", "pvsoremoveforcesit", 1, entity.id())

		vehicle.setLoungeEnabled(seatname, true)
		local seat = 0
		if seatname ~= "driver" then
			seat = tonumber(seatname:sub(#"occupant"+1))
		end
		world.sendEntityMessage( occupantId, "applyStatusEffect", "pvsoforcesit", seat + 1, entity.id())
	end
end

function p.unForceSeat(seatname)
	local occupantId = vehicle.entityLoungingIn( seatname )
	vehicle.setLoungeEnabled(seatname, false)
	if occupantId then
		world.sendEntityMessage( occupantId, "applyStatusEffect", "pvsoremoveforcesit", 1, entity.id())
	end
end

function p.locationFull(location)
	if p.occupants.total == p.maxOccupants.total then
		--sb.logInfo("["..p.vsoMenuName.."] Can't have more than "..p.maxOccupants.total.." occupants total!")
		return true
	else
		return p.occupants[location] == p.maxOccupants[location]
		--[[if p.occupants[location] == p.maxOccupants[location] then
			--sb.logInfo("["..p.vsoMenuName.."] Can't have more than "..p.maxOccupants[location].." occupants in their "..location.."!")
			return true
		else
			return false
		end]]
	end
end

function p.locationEmpty(location)
	if p.occupants.total == 0 then
		--sb.logInfo( "["..p.vsoMenuName.."] No one to let out!" )
		return true
	else
		return p.occupants[location] == 0
		--[[if p.occupants[location] == 0 then
			sb.logInfo( "["..p.vsoMenuName.."] No one in "..location.." to let out!" )
			return true
		else
			return false
		end]]
	end
end

function p.doVore(args, location, statuses, sound )
	local i = p.occupants.total + 1
	if p.eat( args.id, i, location ) then
		vehicle.setInteractive( false )
		p.showEmote("emotehappy")
		--vsoVictimAnimSetStatus( "occupant"..i, statuses );
		return true, function()
			vehicle.setInteractive( true )
			if sound then animator.playSound( sound ) end
		end
	else
		return false
	end
end

function p.doEscape(args, location, monsteroffset, statuses, afterstatus )
	p.monstercoords = p.localToGlobal(monsteroffset)--same as last bit of escape anim

	if p.locationEmpty(location) then return false end
	local i = args.index
	local victim = p.occupant[i].id

	if not victim then -- could be part of above but no need to log an error here
		return false
	end
	vehicle.setInteractive( false )
	--vsoVictimAnimSetStatus( "occupant"..i, statuses );

	return true, function()
		vehicle.setInteractive( true )
		p.uneat( i )
		world.sendEntityMessage( victim, "applyStatusEffect", afterstatus.status, afterstatus.duration, entity.id() )
	end
end

function p.doEscapeNoDelay(args, location, monsteroffset, afterstatus )
	p.monstercoords = p.localToGlobal(monsteroffset)--same as last bit of escape anim

	if p.locationEmpty(location) then return false end
	local i = args.index
	local victim = p.occupant[i].id

	if not victim then -- could be part of above but no need to log an error here
		return false
	end

	vehicle.setInteractive( true )
	p.uneat( i )
	world.sendEntityMessage( victim, "applyStatusEffect", afterstatus.status, afterstatus.duration, entity.id() )
end


function p.checkEatPosition(position, location, transition, noaim)
	if not p.locationFull(location) then
		local prey = world.entityQuery(position, 2, {
			withoutEntityId = vehicle.entityLoungingIn(p.control.driver),
			includedTypes = {"creature"}
		})
		local entityaimed = world.entityQuery(vehicle.aimPosition(p.control.driver), 2, {
			withoutEntityId = vehicle.entityLoungingIn(p.control.driver),
			includedTypes = {"creature"}
		})
		local aimednotlounging = p.firstNotLounging(entityaimed)

		if #prey > 0 then
			for i = 1, #prey do
				if ((prey[i] == entityaimed[aimednotlounging]) or noaim) and not p.entityLounging(prey[i]) then
					animator.setGlobalTag( "bap", "" )
					p.doTransition( transition, {id=prey[i]} )
					return true
				end
			end
		end
		return false
	end
end

function p.firstNotLounging(entityaimed)
	for i = 1, #entityaimed do
		if not p.entityLounging(entityaimed[i]) then
			return i
		end
	end
end

function p.moveOccupantLocation(args, part, location)
	if p.locationFull(location) then return false end
	p.occupant[args.index].location = location
	return true
end

function p.findFirstIndexForLocation(location)
	for i = 1, p.occupants.total do
		if p.occupant[i].location == location then
			return i
		end
	end
	return
end

function p.showEmote( emotename ) --helper function to express a emotion particle "emotesleepy","emoteconfused","emotesad","emotehappy","love"
	if p.emoteCooldown < 0 then
		animator.setParticleEmitterBurstCount( emotename, 1 );
		animator.burstParticleEmitter( emotename )
		p.emoteCooldown = 0.2; -- seconds
	end
end
function p.resetOccupantCount()
	p.occupants.total = 0
	for i = 1, #p.locations.regular do
		p.occupants[p.locations.regular[i]] = 0
	end
	if p.locations.sided then
		for i = 1, #p.locations.sided do
			p.occupants[p.locations.sided[i].."R"] = 0
			p.occupants[p.locations.sided[i].."L"] = 0
		end
	end
end

function p.updateOccupants()
	p.resetOccupantCount()

	local lastFilled = true
	for i = 1, p.maxOccupants.total do
		local occupantId = p.occupant[i].id
		if occupantId and world.entityExists(occupantId) then
			p.occupants.total = p.occupants.total + 1
			p.occupants[p.occupant[i].location] = p.occupants[p.occupant[i].location] + 1

			if not lastFilled and p.swapCooldown <= 0 then
				p.swapOccupants( i-1, i )
			end
			lastFilled = true
		else
			p.occupant[i] = p.clearOccupant
			lastFilled = false
			animator.setAnimationState( "occupant"..i.."state", "empty" )
		end
		if not self.sv.va[ "occupant"..i ].visible then
			animator.setAnimationState( "occupant"..i.."state", "empty" )
		end
	end
	p.swapCooldown = math.max(0, p.swapCooldown - 1)

	p.occupants.fatten = p.fattenBelly

	for i = 1, #p.locations.combine do
		local a = 0
		for j = 1, #p.locations.combine[i] do
			a = a + p.occupants[p.locations.combine[i][j]]
			--sb.logInfo("added "..p.occupants[p.locations.combine[i][j]].." from "..p.locations.combine[i][j])
		end
		for j = 1, #p.locations.combine[i] do
			p.occupants[p.locations.combine[i][j]] = a
		end
	end

	animator.setGlobalTag( "totaloccupants", tostring(p.occupants.total) )
	for i = 1, #p.locations.regular do
		animator.setGlobalTag( p.locations.regular[i].."occupants", tostring(p.occupants[p.locations.regular[i]]) )
	end

	if p.locations.sided then
		for i = 1, #p.locations.sided do
			if self.vsoCurrentDirection >= 1 then -- to make sure those in the balls in CV and breasts in BV cases stay on the side they were on instead of flipping
				animator.setGlobalTag( p.locations.sided[i].."2occupants", tostring(p.occupants[p.locations.sided[i].."R"]) )
				animator.setGlobalTag( p.locations.sided[i].."1occupants", tostring(p.occupants[p.locations.sided[i].."L"]) )
			else
				animator.setGlobalTag( p.locations.sided[i].."1occupants", tostring(p.occupants[p.locations.sided[i].."R"]) )
				animator.setGlobalTag( p.locations.sided[i].."2occupants", tostring(p.occupants[p.locations.sided[i].."L"]) )
			end
		end
	end
end

function p.setState(state)
	if state == nil then
		sb.logError( "nil state from ".. p.state )
	end
	p.state = state
	animator.setGlobalTag( "state", state )
	vsoNext( "state_"..state )
	p.doAnims( p.stateconfig[state].idle )
end

function p.localToGlobal( position )
	local lpos = { position[1], position[2] }
	if self.vsoCurrentDirection == -1 then lpos[1] = -lpos[1] end
	local mpos = mcontroller.position()
	local gpos = { mpos[1] + lpos[1], mpos[2] + lpos[2] }
	return world.xwrap( gpos )
end
function p.globalToLocal( position )
	local pos = world.distance( position, mcontroller.position() )
	if self.vsoCurrentDirection == -1 then pos[1] = -pos[1] end
	return pos
end

function p.occupantArray( maybearray )
	if maybearray == nil or maybearray[1] == nil then -- not an array, check for eating
		if maybearray.location then
			if maybearray.failOnFull then
				if (maybearray.failOnFull ~= true) and (p.occupants[maybearray.location] >= maybearray.failOnFull) then return maybearray.failTransition
				elseif p.locationFull(maybearray.location) then return maybearray.failTransition end
			else
				if p.locationEmpty(maybearray.location) then return maybearray.failTransition end
			end
		end
		return maybearray
	else -- pick one depending on number of occupants
		return maybearray[(p.occupants[maybearray[1].location or "total"] or 0) + 1]
	end
end

function p.swapOccupants(a, b)
	local A = p.occupant[a]
	local B = p.occupant[b]
	p.occupant[a] = b
	p.occupant[b] = A

	if A then p.unForceSeat( "occupant"..a ) end
	if B then p.unForceSeat( "occupant"..b ) end
	if B then p.forceSeat( B, "occupant"..a ) end
	if A then p.forceSeat( A, "occupant"..b ) end

	p.swapCooldown = 100 -- p.unForceSeat and p.forceSeat are asynchronous, without some cooldown it'll try to swap multiple times and bad things will happen
end

function p.entityLounging( entity )
	if entity == vehicle.entityLoungingIn( "driver" ) then return true end
	for i = 1, p.maxOccupants.total do
		if entity == (vehicle.entityLoungingIn( "occupant"..i ) or p.occupant[i].id) then return true end
	end
	return false
end

function p.edible( occupantId, seatindex, source )
	if vehicle.entityLoungingIn( "driver" ) ~= occupantId then return false end
	if p.occupants.total > 0 then return false end
	if p.stateconfig[p.state].edible then
		if p.stateconfig[p.state].ediblePath then
			world.sendEntityMessage( source, "smolPreyPath", seatindex, p.stateconfig[p.state].ediblePath )
		end
		return true
	end
end

function p.isMonster( id )
	if id == nil then return false end
	if not world.entityExists(id) then return false end
	return world.entityType(id) == "monster"
end

function p.inedible(occupantId)
	for i = 1, #p.config.inedibleCreatures do
		if world.entityType(occupantId) == p.config.inedibleCreatures[i] then return true end
	end
	return false
end

function p.eat( occupantId, seatindex, location )
	if occupantId == nil or p.entityLounging(occupantId) or p.inedible(occupantId) or p.locationFull(location) then return false end -- don't eat self
	local loungeables = world.entityQuery( world.entityPosition(occupantId), 5, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" },
		callScript = "p.entityLounging", callScriptArgs = { occupantId }
	} )
	local edibles = world.entityQuery( world.entityPosition(occupantId), 2, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" },
		callScript = "p.edible", callScriptArgs = { occupantId, seatindex, entity.id() }
	} )
	p.occupant[seatindex].location = location

	if edibles[1] == nil then
		if loungeables[1] == nil then -- now just making sure the prey doesn't belong to another loungable now
			p.occupant[seatindex].id = occupantId
			p.smolprey( seatindex )
			p.forceSeat( occupantId, "occupant"..seatindex )
			p.justAte = true
			return true -- not lounging
		else
			return false -- lounging in something inedible
		end
	end
	-- lounging in edible smol thing
	local species = world.entityName( edibles[1] ):sub( 5 ) -- "spov"..species
	p.occupant[seatindex].id = occupantId
	p.occupant[seatindex].species = species
	p.smolprey( seatindex )
	world.sendEntityMessage( edibles[1], "despawn", true ) -- no warpout
	p.forceSeat( occupantId, "occupant"..seatindex )
	p.addStatusToList(seatindex, "vsoinvisible")
	vehicle.setLoungeStatusEffects( "occupant"..seatindex, invis );
	p.justAte = true
	return true
end

function p.uneat( seatindex )
	local occupantId = p.occupant[seatindex].id
	world.sendEntityMessage( occupantId, "PVSOClear")
	world.sendEntityMessage( occupantId, "applyStatusEffect", "pvsoremovebellyeffects")
	p.unForceSeat( "occupant"..seatindex )
	if p.occupant[seatindex].species then
		if world.entityType(occupantId) == "player" then
			world.sendEntityMessage( occupantId, "spawnSmolPrey", p.occupant[seatindex].species )
		else
			world.spawnVehicle( "spov"..p.occupant[seatindex].species, { p.monstercoords[1], p.monstercoords[2]}, { driver = occupantId, settings = {}, uneaten = true } )
		end
		p.occupant[seatindex].species = nil
		p.occupant[seatindex].filepath = nil
	elseif p.isMonster(occupantId) then
		-- do something to move it forward a few blocks
		world.sendEntityMessage( occupantId, "applyStatusEffect", "pvsomonsterbindremove", p.monstercoords[1], p.monstercoords[2]) --this is hacky as fuck I love it
	end
	p.smolprey( seatindex ) -- clear
	p.occupant[seatindex] = p.clearOccupant
end

function p.smolprey( seatindex )
	if seatindex == nil then return end
	local id = p.occupant[seatindex].id
	if p.occupant[seatindex].species ~= nil then
		if p.occupant[seatindex].filepath then
			animator.setPartTag( "occupant"..seatindex, "smolpath", p.occupant[seatindex].filepath)
		else
			animator.setPartTag( "occupant"..seatindex, "smolpath", "/vehicles/spov/"..p.occupant[seatindex].species.."/spov/default/smol/smol_body.png:smolprey")
		end
		animator.setPartTag( "occupant"..seatindex, "smoldirectives", "" ) -- todo eventually, unimportant since there are no directives to set yet
		p.doAnim( "occupant"..seatindex.."state", "smol" )
	elseif p.isMonster(id) then
		local portrait = world.entityPortrait(id, "fullneutral")
		if portrait and portrait[1] and portrait[1].image then
			animator.setPartTag( "occupant"..seatindex, "monster", portrait[1].image )
			p.doAnim( "occupant"..seatindex.."state", "monster" )
		end
	else
		animator.setPartTag( "occupant"..seatindex, "smolspecies", "" )
		animator.setPartTag( "occupant"..seatindex, "smoldirectives", "" )
		p.doAnim( "occupant"..seatindex.."state", "empty" )
	end
end

-------------------------------------------------------------------------------

function p.loadStoredData()
	vsoStorageSaveAndLoad( function()	--Get defaults from the item spawner itself
		if storage.colorReplaceMap ~= nil then
			vsoSetDirectives( vsoMakeColorReplaceDirectiveString( storage.colorReplaceMap ) );
		end

		sb.logInfo("Loaded VSO data")

		if vsoPill( "heal" ) then p.settings.bellyeffect = "heal" end
		if vsoPill( "digest" ) then p.settings.bellyeffect = "digest" end
		if vsoPill( "softdigest" ) then p.settings.bellyeffect = "softdigest" end

		if vsoPill( "fatten" ) then
			p.fattenBelly = math.floor(vsoPillValue( "fatten" ))
			if config.getParameter( "driver" ) == nil then
				p.control.driver = "occupant1"
			end
		end
	end )
end

function p.onForcedReset()
	animator.setAnimationRate( 1.0 );
	for i = 1, p.maxOccupants.total do
		-- vsoVictimAnimVisible( "occupant"..i, false )
		vehicle.setLoungeEnabled( "occupant"..i, false )
	end
	-- vsoUseSolid( false ) -- is this needed?

	vehicle.setInteractive( true )

	p.emoteCooldown = 0
end

function getOccupantFromEid(eid)
	for i = 1, p.maxOccupants.total do
		if eid == p.occupant[i].id then
			return i
		end
	end
end

function p.onEnd()
	if not p.nowarpout then
		world.spawnProjectile( "spovwarpouteffectprojectile", mcontroller.position(), entity.id(), {0,0}, true);
	end
end

-------------------------------------------------------------------------------

p.statescripts = {}

function p.registerStateScript( state, name, func )
	if p.statescripts[state] == nil then
		p.statescripts[state] = {}
	end
	p.statescripts[state][name] = func
end

local _ptransition = {}

function p.doTransition( direction, scriptargs )
	if not p.stateconfig[p.state].transitions[direction] then return end
	local tconfig = p.occupantArray( p.stateconfig[p.state].transitions[direction] )
	if tconfig == nil then return end
	local continue = true
	local after = function() end
	if tconfig.script then
		local statescript = p.statescripts[p.state][tconfig.script]
		local _continue, _after, _tconfig = statescript( scriptargs or {} )
		if _continue ~= nil then continue = _continue end
		if _after ~= nil then after = _after end
		if _tconfig ~= nil then tconfig = _tconfig end
	end
	if not continue then return end
	_ptransition.after = after
	_ptransition.state = tconfig.state or p.state
	_ptransition.timing = tconfig.timing or "body"
	if tconfig.animation ~= nil then
		p.doAnims( tconfig.animation )
	end
	if tconfig.victimAnimation ~= nil then
		local i = (scriptargs or {}).index
		if i == nil then
			i = p.occupants.total
			if p.justAte then
				i = i + 1
				p.justAte = false
			elseif tconfig.victimAnimLocation ~= nil then
				i = p.findFirstIndexForLocation(tconfig.victimAnimLocation)
			end
		end
		if i then p.doVictimAnim( "occupant"..i, tconfig.victimAnimation, _ptransition.timing.."State" ) end
	end
	vsoNext( "state__ptransition" )
	return true
end

 -- somehow, even though I change the animation tag *after* vsoAnimEnded, it's too early

 -- this itself as well as the _ptransition.after() thing should be changed to use p.queueAnimEndFunction
local _endedframes = 0
function state__ptransition()
	if p.hasAnimEnded( _ptransition.timing.."State" ) then
		_endedframes = _endedframes + 1
		if _endedframes > 2 then
			_endedframes = 0
			_ptransition.after()
			p.setState( _ptransition.state )
			p.doAnims( p.stateconfig[p.state].idle )
		end
	end
	if not p.stateconfig[p.state].noPhysicsTransition then
		p.doPhysics()
	end
end

-------------------------------------------------------------------------------

p.control = {}

function p.updateDriving()
	local driver = vehicle.entityLoungingIn(p.control.driver)
	if driver then
		local light = p.vso.lights.driver
		light.position = world.entityPosition( driver )
		world.sendEntityMessage( driver, "PVSOAddLocalLight", light )
		local aim = vehicle.aimPosition(p.control.driver)
		local cursor = "/cursors/cursors.png:pointer"

		world.sendEntityMessage( driver, "PVSOCursor", aim, cursor)
	end


	if p.control.standalone then
		--vsoVictimAnimSetStatus( "driver", { "breathprotectionvehicle" } )
		p.control.driving = true
		if vehicle.controlHeld( p.control.driver, "Special3" ) then
			world.sendEntityMessage(
				vehicle.entityLoungingIn( p.control.driver ), "openInterface", p.vsoMenuName.."settings",
				{ vso = entity.id(), occupants = getSettingsMenuInfo(), maxOccupants = p.maxOccupants.total }, false, entity.id()
			)
		end
	elseif p.occupants.total >= 1 then
		if vehicle.controlHeld( p.control.driver, "Special1" ) then
			p.control.driving = true
		end
		if vehicle.controlHeld( p.control.driver, "Special2" ) then
			p.control.driving = false
		end
	else
		p.control.driving = false
	end
end

function getSettingsMenuInfo()
	local occupants = {}
	for i = 1, p.occupants.total do
		if p.occupant[i].id then
			occupants[i] = {
				id = p.occupant[i].id,
				species = p.occupant[i].species
			}
		else
			occupants[i] = {}
		end
	end
	return occupants
end

function p.control.probablyOnGround() -- check number of frames -> ceiling isn't ground
	local yvel = mcontroller.yVelocity()
	if yvel < 0.1 and yvel > -0.1 then
		p.movement.groundframes = p.movement.groundframes + 1
	else
		p.movement.groundframes = 0
	end
	return p.movement.groundframes > 5
end

function p.control.notMoving()
	local xvel = mcontroller.xVelocity()
	return xvel < 0.1 and xvel > -0.1
end

function p.control.underWater()
	return mcontroller.liquidPercentage() >= 0.2
end

function p.doPhysics()
	if not p.control.underWater() then
		mcontroller.setXVelocity( 0 )
		mcontroller.approachYVelocity( -200, 2 * world.gravity(mcontroller.position()) )
	else
		mcontroller.approachXVelocity( 0, 50 )
		mcontroller.approachYVelocity( -10, 50 )
	end
end

function p.control.pressE(_,_, seat_index )
	if seat_index == 0 and p.control.standalone then
		p.movement.E = true
	elseif seat_index == 1 and not p.control.standalone then
		p.movement.E = true
	end
end

function p.control.drive()
	if not p.control.driving then return end
	local control = p.stateconfig[p.state].control
	if control.animations == nil then control.animations = {} end -- allow indexing

	local dx = 0
	if vehicle.controlHeld( p.control.driver, "left" ) then
		dx = dx - 1
	end
	if vehicle.controlHeld( p.control.driver, "right" ) then
		dx = dx + 1
	end
	mcontroller.approachXVelocity( dx * control.swimSpeed, 50 )
	if p.control.probablyOnGround() then
		p.control.groundMovement( dx )
	elseif p.control.underWater() then
		p.control.waterMovement( dx )
	else
		p.control.airMovement( dx )
	end

	p.control.primaryAction()
	p.control.altAction()
end

function p.control.primaryAction()
	local control = p.stateconfig[p.state].control
	if control.primaryAction ~= nil and vehicle.controlHeld( p.control.driver, "PrimaryFire" ) then
		if p.movement.primaryCooldown < 1 then
			if control.primaryAction.projectile ~= nil then
				p.control.projectile(control.primaryAction.projectile)
			end
			if control.primaryAction.animation ~= nil then
				p.doAnims( control.primaryAction.animation )
			end
			if control.primaryAction.script ~= nil then
				local statescript = p.statescripts[p.state][control.primaryAction.script]
				if statescript then
					statescript() -- what arguments might this need?
				else
					sb.logError("[PVSO "..world.entityName(entity.id()).."] Missing statescript "..control.altAction.script.." for state "..p.state.."!")
				end
			end
			if 	p.movement.primaryCooldown < 1 then
				p.movement.primaryCooldown = control.primaryAction.cooldown
			end
		end
	end
	p.movement.primaryCooldown = p.movement.primaryCooldown - 1
end
function p.control.altAction()
	local control = p.stateconfig[p.state].control
	if control.altAction ~= nil and vehicle.controlHeld( p.control.driver, "altFire" ) then
		if p.movement.altCooldown < 1 then
			if control.altAction.projectile ~= nil then
				p.control.projectile(control.altAction.projectile)
			end
			if control.altAction.animation ~= nil then
				p.doAnims( control.altAction.animation )
			end
			if control.altAction.script ~= nil then
				local statescript = p.statescripts[p.state][control.altAction.script]
				if statescript then
					statescript() -- what arguments might this need?
				else
					sb.logError("[PVSO "..world.entityName(entity.id()).."] Missing statescript "..control.altAction.script.." for state "..p.state.."!")
				end
			end
			if 	p.movement.altCooldown < 1 then
				p.movement.altCooldown = control.altAction.cooldown
			end
		end
	end
	p.movement.altCooldown = p.movement.altCooldown - 1
end

function p.control.groundMovement( dx )
	local state = p.stateconfig[p.state]
	local control = state.control

	local running = false
	if not vehicle.controlHeld( p.control.driver, "down" ) and (p.occupants.total + p.fattenBelly)< control.fullThreshold then
		running = true
	end
	if dx ~= 0 then
		vsoFaceDirection( dx )
	end
	if running then
		mcontroller.setXVelocity( dx * control.runSpeed )
	else
		mcontroller.setXVelocity( dx * control.walkSpeed )
	end

	if dx ~= 0 then
		if not running then
			p.doAnims( control.animations.walk )
			p.movement.animating = true
		elseif running then
			p.doAnims( control.animations.run )
			p.movement.animating = true
		end
	elseif p.movement.animating then
		p.doAnims( state.idle )
		p.movement.animating = false
	end

	mcontroller.setYVelocity( -0.15 ) -- to detect leaving ground
	if vehicle.controlHeld( p.control.driver, "jump" ) then
		if not vehicle.controlHeld( p.control.driver, "down" ) then
			if not p.movement.jumped then
				p.doAnims( control.animations.jump )
				p.movement.animating = true
				if p.occupants.total + p.fattenBelly < control.fullThreshold then
					mcontroller.setYVelocity( control.jumpStrength )
				else
					mcontroller.setYVelocity( control.fullJumpStrength )
				end
			end
		else
			mcontroller.applyParameters{ ignorePlatformCollision = true }
		end
		p.movement.jumped = true
	else
		p.movement.jumped = false
	end

	p.movement.waswater = false
	p.movement.jumps = 1
	p.movement.airframes = 0
	p.movement.falling = false
end

function p.control.waterMovement( dx )
	local control = p.stateconfig[p.state].control

	if dx ~= 0 then
		vsoFaceDirection( dx )
	end
	mcontroller.approachXVelocity( dx * control.swimSpeed, 50 )

	if vehicle.controlHeld( p.control.driver, "jump" ) then
		mcontroller.approachYVelocity( 10, 50 )
	else
		mcontroller.approachYVelocity( -10, 50 )
	end

	if vehicle.controlHeld( p.control.driver, "jump" )
	-- or vehicle.controlHeld( p.control.driver, "down" )
	or vehicle.controlHeld( p.control.driver, "left" )
	or vehicle.controlHeld( p.control.driver, "right" ) then
		p.doAnims( control.animations.swim )

		p.movement.animating = true
	else
		p.doAnims( control.animations.swimIdle )
		p.movement.animating = true
	end

	p.movement.waswater = true
	p.movement.jumped = false
	p.movement.jumps = 1
	p.movement.airframes = 0
	p.movement.falling = false
end

function p.control.airMovement( dx )
	local control = p.stateconfig[p.state].control

	local running = false
	if not vehicle.controlHeld( p.control.driver, "down" ) and (p.occupants.total + p.fattenBelly) < control.fullThreshold then
		running = true
	end
	if dx ~= 0 then
		if running then
			mcontroller.approachXVelocity( dx * control.runSpeed, 50 )
		else
			mcontroller.approachXVelocity( dx * control.walkSpeed, 50 )
		end
	else
		mcontroller.approachXVelocity( 0, 30 )
	end

	if vehicle.controlHeld( p.control.driver, "down" ) then
		mcontroller.applyParameters{ ignorePlatformCollision = true }
	else
		mcontroller.applyParameters{ ignorePlatformCollision = false }
	end
	if mcontroller.yVelocity() > 0 and vehicle.controlHeld( p.control.driver, "jump" ) then
		mcontroller.approachYVelocity( -100, world.gravity(mcontroller.position()) )
	else
		mcontroller.approachYVelocity( -200, 2 * world.gravity(mcontroller.position()) )
	end
	if vehicle.controlHeld( p.control.driver, "jump" ) then
		if not p.movement.jumped and p.movement.jumps < control.jumpCount then
			p.doAnims( control.animations.jump )
			p.movement.animating = true
			if (p.occupants.total + p.fattenBelly) < control.fullThreshold then
				mcontroller.setYVelocity( control.jumpStrength )
			else
				mcontroller.setYVelocity( control.fullJumpStrength )
			end
			if not p.movement.waswater and p.movement.airframes > 10 then
				p.movement.jumps = p.movement.jumps + 1
				-- particles from effects/multiJump.effectsource
				animator.burstParticleEmitter( control.pulseEffect )
				for i = 1, control.pulseSparkles do
					animator.burstParticleEmitter( "defaultblue" )
					animator.burstParticleEmitter( "defaultlightblue" )
				end
				animator.playSound( "doublejump" )
			end
		end
		p.movement.jumped = true
	else
		p.movement.jumped = false
	end

	if mcontroller.yVelocity() < -10 and p.movement.airframes > 15 then
		if not p.movement.falling then
			p.doAnims( control.animations.fall )
			p.movement.falling = true
			p.movement.animating = true
		end
	else
		p.movement.falling = false
	end
	p.movement.lastYVelocity = mcontroller.yVelocity()
	p.movement.airframes = p.movement.airframes + 1
end

function useEnergy(eid, cost, callback)
	_add_vso_rpc( world.sendEntityMessage(eid, "useEnergy", cost), callback)
end

function p.control.projectile( projectiledata )
	local driver = vehicle.entityLoungingIn(p.control.driver)
	if projectiledata.energy and driver then
		useEnergy(driver, projectiledata.cost, function(canUseEnergy)
			if canUseEnergy then
				p.control.fireProjectile( projectiledata, driver )
			end
		end)
	else
		p.control.fireProjectile( projectiledata, driver )
	end
end

function getDriverStat(eid, stat, callback)
	_add_vso_rpc( world.sendEntityMessage(eid, "getDriverStat", stat), callback)
end


function p.control.fireProjectile( projectiledata, driver )
	local position = p.localToGlobal( projectiledata.position )
	local direction
	if projectiledata.aimable then
		local aiming = vehicle.aimPosition( p.control.driver )
		vsoFacePoint( aiming[1] )
		position = p.localToGlobal( projectiledata.position )
		aiming[2] = aiming[2] + 0.2 * self.vsoCurrentDirection * (aiming[1] - position[1])
		direction = world.distance( aiming, position )
	else
		direction = { self.vsoCurrentDirection, 0 }
	end
	local params = {}

	if driver then
		getDriverStat(driver, "powerMultiplier", function(powerMultiplier)
			params.powerMultiplier = powerMultiplier
			world.spawnProjectile( projectiledata.name, position, driver, direction, true, params )
		end)
	else
		params.powerMultiplier = p.standalonePowerLevel()
		world.spawnProjectile( projectiledata.name, position, entity.Id(), direction, true, params )
	end
end

-------------------------------------------------------------------------------

function p.standardState()

	p.idleStateChange()
	if p.control.driving then
		p.driverStateChange()
	end
	p.handleBelly()
	p.doPhysics()
	p.updateDriving()
	p.whenFalling()
end

function p.whenFalling() -- an empty function here, meant to be overwritten in other things to return you to stand
end

function p.idleStateChange()
	if not p.control.probablyOnGround() or not p.control.notMoving() or p.movement.animating then return end

	if vsoTimerEvery( "idleStateChange", 5.0, 5.0 ) then -- every 5 seconds? this is arbitrary, oh well
		local transitions = p.stateconfig[p.state].transitions
		if not p.control.driving then
			local percent = math.random(100)
			for name, t in pairs(transitions) do
				local transition = p.occupantArray( t )
				if transition and transition.chance and transition.chance > 0 then
					percent = percent - transition.chance
					if percent <= 0 then
						p.doTransition( name )
						return
					end
				end
			end
		end
	end

	p.doAnims( p.stateconfig[p.state].idle )

	p.nextIdle = p.nextIdle - 1
	if p.nextIdle <= 0 then
		p.nextIdle = math.random(50, 300)
		local idles = p.stateconfig[p.state].idleAnimations
		if idles ~= nil and #idles >= 1 then
			local which = math.random(#idles)
			p.doAnims( idles[which] )
		end
	end
end

function p.driverStateChange()
	local transitions = p.stateconfig[p.state].transitions
	local movedir = p.getSeatDirections( p.control.driver )
	if movedir ~= nil then
		if transitions[movedir] ~= nil then
			p.doTransition(movedir)
		elseif (movedir == "front" or movedir == "back") and transitions.side ~= nil then
			p.doTransition("side")
		end
	end
end

function p.handleBelly()
	p.updateOccupants()
	if p.occupants.total > 0 and p.stateconfig[p.state].bellyEffect ~= false then
		p.bellyEffects()
	else
		for i = 1, p.maxOccupants.total do
			--vsoVictimAnimSetStatus( "occupant"..i, {} )
		end
	end
	p.handleStruggles()
end

function p.bellyEffects()
	local driver = vehicle.entityLoungingIn( "driver")
	if driver then
		getDriverStat(driver, "powerMultiplier", function(powerMultiplier)
			p.doBellyEffects(driver, math.log(powerMultiplier)+1)
		end)
	else
		p.doBellyEffects(false, p.standalonePowerLevel())
	end
end

function p.standalonePowerLevel()
	local power = world.threatLevel()
	if type(power) ~= "number" or power < 1 then return 1 end
	return power
end

function p.doBellyEffects(driver, powerMultiplier)
	local status = "pvsoremovebellyeffects"
	local hungereffect = 0
	if p.settings.bellyeffect == "digest" then
		hungereffect = 1
		if p.settings.displaydamage then
			status = "displaydamagedigest"
		else
			status = "damagedigest"
		end
	elseif p.settings.bellyeffect == "softdigest" then
		hungereffect = 1
		if p.settings.displaydamage then
			status = "displaydamagesoftdigest"
		else
			status = "damagesoftdigest"
		end
	elseif p.settings.bellyeffect == "heal" then
		status = "pvsovoreheal"
	end
	for i = 1, p.maxOccupants.total do
		local eid = p.occupant[i].id

		if eid and world.entityExists(eid) then
			local health = world.entityHealth(eid)
			local light = p.vso.lights.prey
			light.position = world.entityPosition( eid )
			world.sendEntityMessage( eid, "PVSOAddLocalLight", light )

			if p.isLocationDigest(p.occupant[i].location) then
				if vsoTimerEvery( "gurgle", 1.0, 8.0 ) then animator.playSound( "digest" ) end
				local hunger_change = (hungereffect * powerMultiplier * vsoDelta())/100
				if status then world.sendEntityMessage( eid, "applyStatusEffect", status, powerMultiplier, entity.id() ) end
				if p.settings.bellyeffect == "softdigest" and health[1] <= 1 then hunger_change = 0 end
				if driver then addHungerHealth( driver, hunger_change) end
				p.extraBellyEffects(i, eid, health, status)
			else
				p.otherLocationEffects()
			end
		end
	end
end

function p.isLocationDigest(location)
	for i = 1, #p.locations.digest do
		if #p.locations.digest[i] == location then
			return true
		end
	end
	return false
end

function p.extraBellyEffects(i, eid, health, status) -- something for the PVSOs to replace
end

function p.otherLocationEffects(i, eid, health, status)
end

randomDirections = { "back", "front", "up", "down", "jump", nil}
p.monsterstrugglecooldown = {}

function p.getSeatDirections(seatname)
	local occupantId = vehicle.entityLoungingIn(seatname)
	if not occupantId or not world.entityExists(occupantId) then return end

	if world.entityType( occupantId ) ~= "player" then
		if not p.monsterstrugglecooldown[seatname] or p.monsterstrugglecooldown[seatname] < 1 then
			local movedir = randomDirections[math.random(1,6)]
			p.monsterstrugglecooldown[seatname] = math.random(1, 30)
			return movedir
		else
			p.monsterstrugglecooldown[seatname] = p.monsterstrugglecooldown[seatname] - 1
			return
		end
	else
		local dx = 0
		local dy = 0
		if vehicle.controlHeld( seatname, "left" ) then
			dx = dx - 1
		end
		if vehicle.controlHeld( seatname, "right" ) then
			dx = dx + 1
		end
		if vehicle.controlHeld( seatname, "down" ) then
			dy = dy - 1
		end
		if vehicle.controlHeld( seatname, "up" ) then
			dy = dy + 1
		end

		dx = dx * self.vsoCurrentDirection

		if dx ~= 0 then
			if dx >= 1 then
				return "front"
			else
				return "back"
			end
		end

		if dy ~= 0 then
			if dy >= 1 then
				return "up"
			else
				return "down"
			end
		end

		if vehicle.controlHeld( seatname, "jump" ) then
			return "jump"
		end
	end
end

function addHungerHealth(eid, amount, callback)
	_add_vso_rpc( world.sendEntityMessage(eid, "addHungerHealth", amount), callback)
end

p.struggleCount = 0
p.bellySettleDownTimer = 3

function p.handleStruggles()
	p.bellySettleDownTimer = p.bellySettleDownTimer - vsoDelta()
	if p.bellySettleDownTimer <= 0 then
		if p.struggleCount > 0 then
			p.struggleCount = p.struggleCount - 1
			p.bellySettleDownTimer = 3
		end
	end

	local struggler = 0
	local struggledata
	if p.control.driving and not p.control.standalone then
		struggler = 1
	end

	local movedir = nil

	while (movedir == nil) and struggler < p.maxOccupants.total do
		struggler = struggler + 1
		movedir = p.getSeatDirections( "occupant"..struggler )
		struggledata = p.stateconfig[p.state].struggle[p.occupant[struggler].location]
		if movedir then
			if (struggledata == nil) or (struggledata[movedir] == nil) then
				movedir = nil
			elseif not p.hasAnimEnded( struggledata.part.."State" )
			and (
				p.animationIs( struggledata.part.."State", "s_up" ) or
				p.animationIs( struggledata.part.."State", "s_front" ) or
				p.animationIs( struggledata.part.."State", "s_back" ) or
				p.animationIs( struggledata.part.."State", "s_down" )
			)then
				movedir = nil
			else
				for i = 1, #p.config.speciesStrugglesDisabled do
					if p.occupant[struggler].species == p.config.speciesStrugglesDisabled[i] then
						movedir = nil
					end
				end
			end
		end
	end
	if movedir == nil then return end -- invalid struggle

	if struggledata.script ~= nil then
		local statescript = p.statestripts[p.state][struggledata.script]
		statescript( struggler, movedir )
	end

	local chance = struggledata.chances
	if struggledata[movedir].chances ~= nil then
		chance = struggledata[movedir].chances
	end
	if vsoPill( "easyescape" ) then
		chance = chance.easyescape
	elseif vsoPill( "antiescape" ) then
		chance = chance.antiescape
	else
		chance = chance.normal
	end

	if chance ~= nil and ( chance.max == 0 or (
		(not p.control.driving or struggledata[movedir].controlled)
		and (math.random(chance.min, chance.max) <= p.struggleCount))
	) then
		p.struggleCount = 0
		p.doTransition( struggledata[movedir].transition, {index=struggler, direction=movedir} )
	else
		p.struggleCount = p.struggleCount + 1
		p.bellySettleDownTimer = 5

		sb.setLogMap("b", "struggle")
		local animation = {offset = struggledata[movedir].offset}
		animation[struggledata.part] = "s_"..movedir


		p.doAnims(animation)

		if p.control.notMoving() then
			p.doAnims( struggledata[movedir].animation or struggledata.animation, true )
		else
			p.doAnims( struggledata[movedir].animationWhenMoving or struggledata.animationWhenMoving, true )
		end

		if struggledata[movedir].victimAnimation then
			p.doVictimAnim( "occupant"..struggler, struggledata[movedir].victimAnimation, struggledata.part.."State" )
		end
		animator.playSound( "struggle" )
	end
end

function p.onInteraction( occupantId )
	local state = p.stateconfig[p.state]

	local position = p.globalToLocal( world.entityPosition( occupantId ) )
	local interact
	if position[1] > 3 then
		interact = p.occupantArray( state.interact.front )
	elseif position[1] < -3 then
		interact = p.occupantArray( state.interact.back )
	else
		interact = p.occupantArray( state.interact.side )
	end
	if not p.control.driving or interact.controlled then
		if interact.chance > 0 and p.randomChance( interact.chance ) then
			p.doTransition( interact.transition, {id=occupantId} )
			return
		end
	end

	if state.interact.animation then
		p.doAnims( state.interact.animation )
	end
	p.showEmote( "emotehappy" )
end

function p.randomChance(percent)
	return math.random() <= (percent/100)
end
