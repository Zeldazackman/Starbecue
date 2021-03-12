--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/scripts/vore/vsosimple.lua")

function vsoNotnil( val, msg ) -- HACK: intercept self.cfgVSO to inject things from other files
	if val == nil then vsoError( msg ) end
	if msg == "missing vso in config file" and type(val.victimAnimations) == "string" then
		val.victimAnimations = root.assetJson( val.victimAnimations )
	end
	return val;
end

local _oldVictimAnimUpdate = vsoVictimAnimUpdate
function vsoVictimAnimUpdate( seatname, dt ) -- HACK: intercept animator methods to change transformation group name based on seatname
	-- check if patch is needed
	if seatname:sub(1, #"occupant") ~= "occupant" then
		return _oldVictimAnimUpdate( seatname, dt )
	end
	-- store real methods
	local a_reset = animator.resetTransformationGroup
	local a_scale = animator.scaleTransformationGroup
	local a_rotate = animator.rotateTransformationGroup
	local a_translate = animator.translateTransformationGroup
	-- apply patch
	animator.resetTransformationGroup = function(group, ...) a_reset(seatname.."position", ...) end
	animator.scaleTransformationGroup = function(group, ...) a_scale(seatname.."position", ...) end
	animator.rotateTransformationGroup = function(group, ...) a_rotate(seatname.."position", ...) end
	animator.translateTransformationGroup = function(group, ...) a_translate(seatname.."position", ...) end
	-- call original function
	local ret = _oldVictimAnimUpdate( seatname, dt )
	-- revert patch
	animator.resetTransformationGroup = a_reset
	animator.scaleTransformationGroup = a_scale
	animator.rotateTransformationGroup = a_rotate
	animator.translateTransformationGroup = a_translate
	return ret
end

p = {
	maxOccupants = { --basically everything I think we'd need
		total = 0,
		belly = 0,
		womb = 0,
		shaft = 0,
		knot = 0,
		ballL = 0,
		ballR = 0,
		breastL = 0,
		breastR = 0,
		hug = 0,
		tail = 0,
		other = 0

	},
	occupants = {
		total = 0,
		belly = 0,
		womb = 0,
		shaft = 0,
		knot = 0,
		ballL = 0,
		ballR = 0,
		breastL = 0,
		breastR = 0,
		hug = 0,
		tail = 0,
		other = 0
	},
	occupantLocation = {},
	occupantOffset = 1,
	fattenBelly = 0,
	justAte = false,
	justLetout = false,
	monstercoords = {0,0},
	nextIdle = 0,
	swapCooldown = 0
}

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

function locationFull(location)
	if p.occupants.total == p.maxOccupants.total then
		sb.logError("["..p.vsoMenuName.."] Can't have more than "..p.maxOccupants.total.." occupants total!")
		return true
	else
		if p.occupants[location] == p.maxOccupants[location] then
			sb.logError("["..p.vsoMenuName.."] Can't have more than "..p.maxOccupants[location].." occupants in their "..location.."!")
			return true
		else
			return false
		end
	end
end

function locationEmpty(location)
	if p.occupants.total == 0 then
		sb.logError( "["..p.vsoMenuName.."] No one to let out!" )
		return true
	else
		if p.occupants[location] == 0 then
			sb.logError( "["..p.vsoMenuName.."] No one in "..location.."to let out!" )
			return true
		else
			return false
		end
	end
end

function dovore(args, location, statuses, sound )
	if p.entityLounging( args.id ) then return false end
	if locationFull(location) then return false end

	local i = p.occupants.total + 1
	if p.eat( args.id, i, location ) then
		vsoMakeInteractive( false )
		p.showEmote("emotehappy")
		vsoVictimAnimSetStatus( "occupant"..i, statuses );
		return true, function()
			vsoMakeInteractive( true )
			vsoVictimAnimReplay( "occupant"..i, location.."center", "bodyState")
			vsoSound( sound )
		end
	else
		return false
	end
end

function doescape(args, location, monsteroffset, statuses, afterstatus )
	p.monstercoords = p.localToGlobal(monsteroffset)--same as last bit of escape anim

	if locationEmpty(location) then return false end
	local i = args.index
	local victim = vsoGetTargetId( "occupant"..i )

	if not victim then -- could be part of above but no need to log an error here
		return false
	end
	vsoMakeInteractive( false )
	vsoVictimAnimSetStatus( "occupant"..i, statuses );

	return true, function()
		vsoMakeInteractive( true )
		p.uneat( i )
		vsoApplyStatus( victim, afterstatus.status, afterstatus.duration );
	end
end

function checkEatPosition(position, location, transition)
	if not locationFull(location) then
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
				if prey[i] == entityaimed[aimednotlounging] and not p.entityLounging(prey[i]) then
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

function moveOccupantLocation(args, location1, location2)
	if locationEmpty(location1) then return false end
	if locationFull(location2) then return false end
	p.occupantLocation[args.index] = location2
end

function p.showEmote( emotename ) --helper function to express a emotion particle "emotesleepy","emoteconfused","emotesad","emotehappy","love"
	if vsoTimeDelta( "emoteblock" ) > 0.2 then
		animator.setParticleEmitterBurstCount( emotename, 1 );
		animator.burstParticleEmitter( emotename )
	end
end

function p.updateOccupants()
	p.occupants = {
		total = 0,
		belly = 0,
		womb = 0,
		shaft = 0,
		knot = 0,
		ballL = 0,
		ballR = 0,
		breastL = 0,
		breastR = 0,
		hug = 0,
		tail = 0,
		other = 0
	}

	local lastFilled = true
	for i = 1, p.maxOccupants.total do
		local targetid = vsoGetTargetId( "occupant"..i )
		if targetid and world.entityExists(targetid) then
			p.occupants.total = p.occupants.total + 1
			p.occupants[p.occupantLocation[i]] = p.occupants[p.occupantLocation[i]] + 1

			if not lastFilled and p.swapCooldown <= 0 then
				p.swapOccupants( i-1, i )
			end
			lastFilled = true
		else
			vsoClearTarget( "occupant"..i)
			lastFilled = false
		end
	end
	p.swapCooldown = math.max(0, p.swapCooldown - 1)
	p.occupants.belly = p.occupants.belly + p.fattenBelly + p.occupants.womb
	p.occupants.womb = p.occupants.belly --womb is going to be one of those weird cases, as I'm not sure it would ever require a sprite differentiation so they count to the same total but are different locations for differentiaon of escape and effects later
	animator.setGlobalTag( "totaloccupants", tostring(p.occupants.total) )
	animator.setGlobalTag( "bellyoccupants", tostring(p.occupants.belly) )-- womb counts to this total so no womb tag
	animator.setGlobalTag( "shaftoccupants", tostring(p.occupants.shaft) )
	animator.setGlobalTag( "knotoccupants", tostring(p.occupants.knot) )

	if self.vsoCurrentDirection >= 1 then -- to make sure those in the balls in CV and breasts in BV cases stay on the side they were on instead of flipping
		animator.setGlobalTag( "ball1occupants", tostring(p.occupants.ballL) )
		animator.setGlobalTag( "ball2occupants", tostring(p.occupants.ballR) )
		animator.setGlobalTag( "breast1occupants", tostring(p.occupants.breastL) )
		animator.setGlobalTag( "breast2occupants", tostring(p.occupants.breastR) )
	else
		animator.setGlobalTag( "ball1occupants", tostring(p.occupants.ballR) )
		animator.setGlobalTag( "ball2occupants", tostring(p.occupants.ballL) )
		animator.setGlobalTag( "breast1occupants", tostring(p.occupants.breastR) )
		animator.setGlobalTag( "breast2occupants", tostring(p.occupants.breastL) )

	end


	animator.setGlobalTag( "hugoccupants", tostring(p.occupants.hug) )
	animator.setGlobalTag( "tailoccupants", tostring(p.occupants.tail) )
	animator.setGlobalTag( "otheroccupants", tostring(p.occupants.other) )

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
			if maybearray.eating then
				if locationFull(maybearray.location) then return maybearray.failTransition end
			else
				if locationEmpty(maybearray.location) then return maybearray.failTransition end
			end
		end
		return maybearray
	else -- pick one depending on number of occupants
		return maybearray[(p.occupants[maybearray[1].location or "total"] or 0) + 1]
	end
end

function p.swapOccupants(a, b)
	local A = vsoGetTargetId("occupant"..a)
	local B = vsoGetTargetId("occupant"..b)
	vsoSetTarget( "occupant"..a, B )
	vsoSetTarget( "occupant"..b, A )

	local LocationA = p.occupantLocation[a]
	local LocationB = p.occupantLocation[b]
	p.occupantLocation[a] = LocationB
	p.occupantLocation[b] = LocationA

	if A then vsoUneat( "occupant"..a ) end
	if B then vsoUneat( "occupant"..b ) end
	if B then vsoEat( B, "occupant"..a ) end
	if A then vsoEat( A, "occupant"..b ) end

	local t = p.smolpreyspecies[a]
	p.smolpreyspecies[a] = p.smolpreyspecies[b]
	p.smolpreyspecies[b] = t

	t = self.sv.va["occupant"..a] -- victim animations
	self.sv.va["occupant"..a] = self.sv.va["occupant"..b]
	self.sv.va["occupant"..b] = t

	self.sv.va["occupant"..a].playing = true
	self.sv.va["occupant"..b].playing = true

	p.swapCooldown = 100 -- vsoUneat and vsoEat are asynchronous, without some cooldown it'll try to swap multiple times and bad things will happen
end

function p.entityLounging( entity )
	if entity == vehicle.entityLoungingIn( "driver" ) then return true end
	for i = 1, p.maxOccupants.total do
		if entity == vehicle.entityLoungingIn( "occupant"..i ) then return true end
	end
	return false
end

p.currentTags = {}
function p.doAnims( anims, force )
	for state,anim in pairs( anims or {} ) do
		if state == "offset" then
			p.headbob( anim )
		elseif state == "offset2" then
			p.otherbob( anim )
		elseif state == "rotate" then
			p.rotate( anim )
		elseif state == "tags" then
			for _,tag in ipairs(anim) do
				p.currentTags[tag.owner] = {
					part = tag.part,
					name = tag.name,
					reset = tag.reset or true
				}
				if tag.part == "global" then
					animator.setGlobalTag( tag.name, tag.value )
				else
					animator.setPartTag( tag.part, tag.name, tag.value )
				end
			end
		elseif force then
			vsoAnimReplay( state.."State", anim ) -- force that animation to restart
		else
			local oldPriority = (p.animStateData[state.."State"].states[vsoAnimCurr(state.."State") or "idle"] or {}).priority or 0
			local newPriority = (p.animStateData[state.."State"].states[anim] or {}).priority or 0
			local isSame = vsoAnimIs( state.."State", anim )
			local priorityHigher = (tonumber(newPriority) >= tonumber(oldPriority)) or (tonumber(newPriority) == -1)
			if (not isSame and priorityHigher) or vsoAnimEnded( state.."State" ) then
				vsoAnim( state.."State", anim )
			end
		end
	end
end

p.headbobbing = {enabled = false, time = 0, parts = {}}
function p.headbob( data )
	if data == p.headbobbing.data then
		if not p.headbobbing.enabled then p.headbobbing.time = 0 p.headbobbing.enabled = true end
		return
	end
	p.headbobbing = {
		enabled = data ~= nil,
		data = data,
		time = 0,
		parts = {},
		loop = data.loop or false,
		timing = data.timing or "body"
	}
	local continue = false
	for _,r in ipairs(data.parts or {}) do
		table.insert(p.headbobbing.parts, {
			x = r.x or {0},
			y = r.y or {0},
			head = r.head or false,
			body = r.body or false,
			legs = r.legs or false,
			tail = r.tail or false,
			})
		if (r.x and #r.x > 1) or (r.y and #r.y > 1) then
			continue = true
		end
	end

	vsoTransAnimUpdate( "headbob", 0 )
	if not continue then
		p.headbobbing.enabled = false
		p.headbobbing.head = false
		p.headbobbing.body = false
		p.headbobbing.legs = false
		p.headbobbing.tail = false
	end
end

p.rotating = {enabled = false, time = 0, parts = {}}
function p.rotate( data )
	if data == p.rotating.data then
		if not p.rotating.enabled then p.rotating.time = 0 p.rotating.enabled = true end
		return
	end
	p.rotating = {
		enabled = data ~= nil,
		data = data,
		time = 0,
		parts = {},
		timing = data.timing or "body"
	}
	local continue = false
	for _,r in ipairs(data.parts or {}) do
		table.insert(p.rotating.parts, {
			group = r.group or "frontarmrotation",
			center = r.center or {0,0},
			rotation = r.rotation or {0}
		})
		if r.rotation and #r.rotation > 1 then
			continue = true
		end
	end
	vsoTransAnimUpdate( "rotation", 0 )
	if not continue then
		p.rotating.enabled = false
	end
end

local _vsoTransAnimUpdate = vsoTransAnimUpdate
function vsoTransAnimUpdate( transformname, dt )
	if transformname == "headbob" then
		if p.headbobbing == nil or not p.headbobbing.enabled then return end
		local state = p.headbobbing.timing.."State"
		local animdata = self.vsoAnimStateData[state][vsoAnimCurr(state) or "idle"] or {}
		local cycle = animdata.cycle or 1
		local frames = animdata.frames or 1
		local speed = frames / cycle
		p.headbobbing.time = p.headbobbing.time + dt * speed;
		if p.headbobbing.time >= frames then
			if p.headbobbing.loop then
				p.headbobbing.time = p.headbobbing.time - frames
			else
				p.headbobbing.enabled = false
				p.headbobbing.head = false
				p.headbobbing.body = false
				p.headbobbing.legs = false
				p.headbobbing.tail = false
			end
		end
		for _,r in ipairs(p.headbobbing.parts) do
			local x = r.x[ math.floor( p.headbobbing.time ) + 1 ] or r.x[#r.x] or 0
			local y = r.y[ math.floor( p.headbobbing.time ) + 1 ] or r.y[#r.y] or 0
			if r.head then
				p.headbobbing.head = true
				vsoTransMoveTo( "headbob", x / 8, y / 8 )
			elseif not p.headbobbing.head then
				vsoTransMoveTo( "headbob", 0, 0 )
			end
			if r.body then
				p.headbobbing.body = true
				vsoTransMoveTo( "bodybob", x / 8, y / 8 )
			elseif not p.headbobbing.body then
				vsoTransMoveTo( "bodybob", 0, 0 )
			end
			if r.legs then
				p.headbobbing.legs = true
				vsoTransMoveTo( "legsbob", x / 8, y / 8 )
			elseif not p.headbobbing.legs then
				vsoTransMoveTo( "legsbob", 0, 0 )
			end
			if r.tail then
				p.headbobbing.tail = true
				vsoTransMoveTo( "tailbob", x / 8, y / 8 )
			elseif not p.headbobbing.tail then
				vsoTransMoveTo( "tailbob", 0, 0 )
			end
		end

	elseif transformname == "rotation" then
		if p.rotating == nil or not p.rotating.enabled then return end
		local state = p.rotating.timing.."State"
		local animdata = self.vsoAnimStateData[state][vsoAnimCurr(state) or "idle"] or {}
		local cycle = animdata.cycle or 1
		local frames = animdata.frames or 1
		local speed = frames / cycle
		p.rotating.time = p.rotating.time + dt * speed;
		if p.rotating.time >= frames then
			if p.rotating.loop then
				p.rotating.time = p.rotating.time - frames
			else
				p.rotating.enabled = false
			end
		end
		for _,r in ipairs(p.rotating.parts) do

			local previousRotation = r.rotation[math.floor(p.rotating.time) + 1] or 0
			local nextRotation = r.rotation[math.floor(p.rotating.time) + 2] or 0
			local rotation = previousRotation + (nextRotation - previousRotation) * (p.rotating.time % 1)

			animator.resetTransformationGroup( r.group )
			animator.rotateTransformationGroup(r.group, (rotation * math.pi/180), r.center)
		end
	else
		_vsoTransAnimUpdate( transformname, dt )
	end
end

function p.edible( targetid )
	if vehicle.entityLoungingIn( "driver" ) ~= targetid then return false end
	if p.occupants.total > 0 then return false end
	return p.stateconfig[p.state].edible
end

function p.isMonster( id )
	if id == nil then return false end
	if not world.entityExists(id) then return false end
	return world.entityType(id) == "monster"
end

p.smolpreyspecies = {}

function p.eat( targetid, seatindex, location )
	if targetid == nil or p.entityLounging(targetid) then return false end -- don't eat self
	local loungeables = world.entityQuery( world.entityPosition(targetid), 5, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" }
	} )
	local edibles = world.entityQuery( world.entityPosition(targetid), 2, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" },
		callScript = "p.edible", callScriptArgs = { targetid }
	} )
	p.occupantLocation[seatindex] = location

	if edibles[1] == nil then
		if loungeables[1] == nil then -- or not world.loungeableOccupied( loungeables[1] ) then
			-- won't work with multiple loungeables near each other
			vsoSetTarget( "occupant"..seatindex, targetid)
			p.smolprey( seatindex )
			vsoEat( targetid, "occupant"..seatindex )
			p.justAte = true
			return true -- not lounging
		else
			return false -- lounging in something inedible
		end
	end
	-- lounging in edible smol thing
	local species = world.entityName( edibles[1] ):sub( 5 ) -- "spov"..species
	vsoSetTarget( "occupant"..seatindex, targetid)
	p.smolpreyspecies[seatindex] = species
	p.smolprey( seatindex )
	world.sendEntityMessage( edibles[1], "despawn", true ) -- no warpout
	vsoEat( targetid, "occupant"..seatindex )
	local invis = { "vsoinvisible" }
	_ListAddStatus( invis, self.sv.va[ "occupant"..seatindex ].statuslist )
	vehicle.setLoungeStatusEffects( "occupant"..seatindex, invis );
	p.justAte = true
	return true
end

function p.uneat( seatindex )
	local targetid = vsoGetTargetId( "occupant"..seatindex )
	if p.smolpreyspecies[seatindex] ~= nil then
		world.sendEntityMessage( targetid, "spawnSmolPrey", p.smolpreyspecies[seatindex] )
		p.smolpreyspecies[seatindex] = nil
	end
	world.sendEntityMessage( targetid, "PVSOClear")
	vsoUneat( "occupant"..seatindex )
	p.smolprey( seatindex ) -- clear
	vsoClearTarget( "occupant"..seatindex)

	if p.isMonster(targetid) then
		-- do something to move it forward a few blocks
		world.sendEntityMessage( targetid, "applyStatusEffect", "pvsomonsterbindremove",  p.monstercoords[1], p.monstercoords[2]) --this is hacky as fuck I love it
	end
end

function p.smolprey( seatindex )
	if seatindex == nil then return end
	local id = vsoGetTargetId("occupant"..seatindex)
	if p.isMonster(id) then
		local portrait = world.entityPortrait(id, "fullneutral")
		if portrait and portrait[1] and portrait[1].image then
			animator.setPartTag( "occupant"..seatindex, "monster", portrait[1].image )
			vsoAnim( "occupant"..seatindex.."state", "monster" )
		end
	elseif p.smolpreyspecies[seatindex] ~= nil then
		animator.setPartTag( "occupant"..seatindex, "smolspecies", p.smolpreyspecies[seatindex] )
		animator.setPartTag( "occupant"..seatindex, "smoldirectives", "" ) -- todo eventually, unimportant since there are no directives to set yet
		vsoAnim( "occupant"..seatindex.."state", "smol" )
	else
		animator.setPartTag( "occupant"..seatindex, "smolspecies", "" )
		animator.setPartTag( "occupant"..seatindex, "smoldirectives", "" )
		vsoAnim( "occupant"..seatindex.."state", "empty" )
	end
end

-------------------------------------------------------------------------------

function p.loadStoredData()
	vsoStorageSaveAndLoad( function()	--Get defaults from the item spawner itself
		if storage.colorReplaceMap ~= nil then
			vsoSetDirectives( vsoMakeColorReplaceDirectiveString( storage.colorReplaceMap ) );
		end

		if vsoPill( "heal" ) then p.bellyeffect = "heal" end
		if vsoPill( "digest" ) then p.bellyeffect = "digest" end
		if vsoPill( "softdigest" ) then p.bellyeffect = "softdigest" end

		if vsoPill( "fatten" ) then
			p.fattenBelly = math.floor(vsoPillValue( "fatten" )) + 1
			if config.getParameter( "driver" ) == nil then
				p.control.driver = "occupant1"
			end
		end
	end )
end

function p.onForcedReset()
	vsoAnimSpeed( 1.0 );
	for i = 1, p.maxOccupants.total do
		vsoVictimAnimVisible( "occupant"..i, false )
		vsoUseLounge( false, "occupant"..i )
	end
	vsoUseSolid( false )

	vsoMakeInteractive( true )

	vsoTimeDelta( "emoteblock" ) -- without this, the first call to showEmote() does nothing
end

function p.onBegin()
	if not config.getParameter( "uneaten" ) then
		vsoEffectWarpIn();	--Play warp in effect
	end

	vsoUseLounge( false )

	if config.getParameter( "driver" ) ~= nil then
		p.control.standalone = true
		p.control.driver = "driver"
		p.control.driving = true
		local driver = config.getParameter( "driver" )
		storage._vsoSpawnOwner = driver
		storage._vsoSpawnOwnerName = world.entityName( driver )
		vsoEat( driver, "driver" )
		vsoVictimAnimVisible( "driver", false )

		local settings = config.getParameter( "settings" )
		p.bellyeffect = settings.bellyeffect
		p.displaydamage = settings.displaydamage
		p.autocrouch = settings.autocrouch
	else
		p.control.standalone = false
		p.control.driver = "occupant1"
		p.control.driving = false
		vsoUseLounge( false, "driver" )
	end

	onForcedReset();	--Do a forced reset once.

	vsoStorageLoad( p.loadStoredData );	--Load our data (asynchronous, so it takes a few frames)

	p.maxOccupants = config.getParameter( "maxOccupants", 0 )

	-- message.setHandler( "settingsMenuGet", function settingsMenuGet()
	-- 	return {
	-- 		bellyeffect = p.bellyeffect,
	-- 		clickmode = "attack", -- todo
	-- 		firstOccupant = vsoGetTargetId( "food" ),
	-- 		secondOccupant = vsoGetTargetId( "dessert" ),
	-- 	}
	-- end )
	message.setHandler( "settingsMenuSet", function(_,_, key, val )
		if key == "bellyeffect" then
			p.bellyeffect = val
		elseif key == "displaydamage" then
			p.displaydamage = val
		elseif key == "autocrouch" then
			p.autocrouch = val
		elseif key == "letout" then
			p.doTransition( "escape", {index = val} )
		end
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
		local location = p.occupantLocation[i]
		p.doTransition("digest"..location)
	end )

	message.setHandler( "uneat", function(_,_, eid)
		local i = getOccupantFromEid(eid)
		vsoClearTarget( "occupant"..i)
		vsoUneat( "occupant"..i)
	end )


	p.stateconfig = config.getParameter("states")
	p.animStateData = root.assetJson( self.directoryPath .. self.cfgAnimationFile ).animatedParts.stateTypes

	self.sv.ta.headbob = { visible = false } -- hack: intercept vsoTransAnimUpdate for our own headbob system
	self.sv.ta.otherbob = { visible = false } -- and another bob for other things to be seperate
	self.sv.ta.rotation = { visible = false } -- and rotation animation

	if not config.getParameter( "uneaten" ) then
		p.setState( "stand" )
		p.doAnims( p.stateconfig.stand.idle, true )
	else -- released from larger pred
		p.setState( "smol" )
		p.doAnims( p.stateconfig.smol.idle, true )
	end

	local v_status = vehicle.setLoungeStatusEffects -- has to be in here instead of root because vehicle is nil before init
	vehicle.setLoungeStatusEffects = function(seatname, effects)
		if p.smolpreyspecies[tonumber(seatname:sub(#"occupant" + 1))] or p.isMonster(vsoGetTargetId(seatname)) then -- fix invis on smolprey too
			local invis = false
			local effects2 = {} -- don't touch outer table
			for _,e in ipairs(effects) do
				if e == "vsoinvisible" then invis = true end
				table.insert(effects2, e)
			end
			if invis then
				animator.setAnimationState( seatname.."state", "empty" )
			elseif p.isMonster(vsoGetTargetId(seatname)) then
				animator.setAnimationState( seatname.."state", "monster" )
				table.insert(effects2, "vsoinvisible")
			else
				animator.setAnimationState( seatname.."state", "smol" )
				table.insert(effects2, "vsoinvisible")
			end
			v_status(seatname, effects2)
		else
			v_status(seatname, effects)
		end
	end
end

function getOccupantFromEid(eid)
	local i = 1 -1
	local targetid = nil
	while targetid ~= eid and i < p.maxOccupants.total do
		i = i + 1
		targetid = vsoGetTargetId( "occupant"..i )
	end
	return i
end

function p.onEnd()
	if not p.nowarpout then
		vsoEffectWarpOut();
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
	vsoCounterReset( "struggleCount" )
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
			end
		end
		vsoVictimAnimReplay( "occupant"..i, tconfig.victimAnimation, _ptransition.timing.."State" )
	end
	vsoNext( "state__ptransition" )
	return true
end

 -- somehow, even though I change the animation tag *after* vsoAnimEnded, it's too early
local _endedframes = 0
function state__ptransition()
	if vsoAnimEnded( _ptransition.timing.."State" ) then
		_endedframes = _endedframes + 1
		if _endedframes > 2 then
			_endedframes = 0
			_ptransition.after()
			p.setState( _ptransition.state )
			p.doAnims( p.stateconfig[p.state].idle )
		end
	end
	if not p.stateconfig[p.state].noPhysicsTransition then
		p.control.doPhysics()
	end
end

-------------------------------------------------------------------------------

p.control = {}

function p.control.updateDriving()
	local driver = vehicle.entityLoungingIn(p.control.driver)
	if driver then
		world.sendEntityMessage( driver, "PVSONightVision", self.cfgVSO.lights.driver)
		local aim = vehicle.aimPosition(p.control.driver)
		local cursor = "/cursors/cursors.png:pointer"

		world.sendEntityMessage( driver, "PVSOCursor", aim, cursor)
	end


	if p.control.standalone then
		vsoVictimAnimSetStatus( "driver", { "breathprotectionvehicle" } )
		p.control.driving = true
		if vehicle.controlHeld( p.control.driver, "Special3" ) then
			local occupants = {}
			for i = 1, p.maxOccupants.total do -- using p.occupants.total has potential for issues if slots become empty
				if vsoGetTargetId( "occupant"..i ) then
					occupants[i] = {
						id = vsoGetTargetId( "occupant"..i ),
						species = p.smolpreyspecies[ i ]
					}
				else
					occupants[i] = {}
				end
			end
			world.sendEntityMessage(
				vehicle.entityLoungingIn( p.control.driver ), "openInterface", p.vsoMenuName.."settings",
				{ vso = entity.id(), occupants = occupants, maxOccupants = p.maxOccupants.total }, false, entity.id()
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

function p.control.doPhysics()
	if not p.control.underWater() then
		mcontroller.setXVelocity( 0 )
		mcontroller.approachYVelocity( -200, 2 * world.gravity(mcontroller.position()) )
	else
		mcontroller.approachYVelocity( 0, 50 )
		mcontroller.approachYVelocity( -10, 50 )
	end
	if p.state ~= "stand" and mcontroller.yVelocity() < -5 then
		p.setState( "stand" )
		p.doAnims( p.stateconfig[p.state].control.animations.fall )
		p.movement.falling = true
		if p.state == "bed" or p.state == "hug" or p.state == "pinned" or p.state == "pinned_sleep" then
			vsoUneat( "occupant1" )
			vsoClearTarget( "occupant1" )
			vsoUseLounge( false, "occupant1" )
		end
	end
end

function p.control.pressE(_,_, seat_index )
	if seat_index == 0 and p.control.standalone then
		p.movement.E = true
	elseif seat_index == 1 and not p.control.standalone then
		p.movement.E = true
	end
end

function p.control.interact()
	if p.movement.E then -- intercepting vsoForcePlayerSit to get this
		if not p.movement.wasE then
			local aim = vehicle.aimPosition( p.control.driver )
			local mpos = mcontroller.position()
			local dpos = world.distance( mpos, aim )
			local interactables
			local queryParameters = {
				withoutEntityId = entity.id(), -- don't interact with self
				boundMode = "collisionarea", -- hopefully this makes you not have to point at the exact center of the object... doubtful though
				order = "nearest"
			}
			if world.magnitude( dpos ) < 9 then -- interact range -- and not world.lineTileCollision( mpos, aim )
				interactables = world.entityQuery( aim, 0.5, queryParameters )
			else
				interactables = world.entityQuery( mcontroller.position(), 3, queryParameters )
			end
			local obj = interactables[1]
			local driver = vehicle.entityLoungingIn( p.control.driver )
			if obj == driver then
				obj = interactables[2]
			end
			if obj ~= nil and driver ~= nil then
				local objpos = world.entityPosition( obj )
				vsoDebugRect( objpos[1]-0.5, objpos[2]-0.5, objpos[1]+0.5, objpos[2]+0.5, "red" )

				local name = world.getObjectParameter( obj, "objectName" )
				-- if name ~= nil then -- object
					local interactaction = world.getObjectParameter( obj, "interactAction" )
					local interactdata = world.getObjectParameter( obj, "interactData" )
					local localinteracted = false
					if interactaction == nil then -- some things return that from script? let's try to get that
						local s, e = pcall(function() -- this only works on local entities, pcall should stop it from crashing the game
							local action = world.callScriptedEntity( obj, "onInteraction", {
								source = world.distance( mpos, objpos ),
								sourceId = driver
							} )
							if action ~= nil then
								interactaction = action[1]
								interactdata = action[2]
							end
							localinteracted = true
						end)
						if not s then
							sb.logError(e)
						end
					end
					if interactaction ~= nil then
						if type( interactdata ) == "string" then
							interactdata = root.assetJson( interactdata )
						end
						world.sendEntityMessage( driver, "vsoForceInteract", interactaction, interactdata, obj )
					elseif world.getObjectParameter( obj, "uiConfig" ) ~= nil then
						uiconfig = world.getObjectParameter( obj, "uiConfig" )
						if world.getObjectParameter( obj, "slotCount" ) ~= nil then
							uiconfig = sb.replaceTags( uiconfig, { ["slots"] = world.getObjectParameter( obj, "slotCount" ) } )
						end
						local configdata = root.assetJson( uiconfig )
						world.sendEntityMessage( driver, "vsoForceInteract", "OpenContainer", configdata, obj )
					elseif world.getObjectParameter( obj, "upgradeStates" ) then -- upgradeablecraftingobjects
					elseif not localinteracted then -- call onInteraction for non-local entities, sadly we can't get the return value or this would be earlier
						world.objectQuery( objpos, 1, {
							name = name,
							callScript = "onInteraction",
							callScriptArgs = { {
								source = world.distance( mpos, objpos ),
								sourceId = driver
							} },
						} )
					end
				-- end
			end
		end
		p.movement.wasE = true
	else
		p.movement.wasE = false
	end
	p.movement.E = false
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
	p.control.interact()
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
				statescript() -- what arguments might this need?
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
				statescript() -- what arguments might this need?
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
				vsoSound( "doublejump" )
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
	p.control.doPhysics()
	p.control.updateDriving()

end

function p.idleStateChange()
	for owner,tag in pairs( p.currentTags ) do
		if vsoAnimEnded( owner.."State" ) then
			if tag.reset then
				if tag.part == "global" then
					animator.setGlobalTag( tag.name, "" )
				else
					animator.setPartTag( tag.part, tag.name, "" )
				end
				p.currentTags[owner] = nil
			end
		end
	end

	if not p.control.probablyOnGround() or not p.control.notMoving() or p.movement.animating then return end

	if vsoTimerEvery( "idleStateChange", 5.0, 5.0 ) then -- every 5 seconds? this is arbitrary, oh well
		local transitions = p.stateconfig[p.state].transitions
		if not p.control.driving then
			local percent = vsoRand(100)
			for name, t in pairs(transitions) do
				local transition = p.occupantArray( t )
				if transition and transition.chance and transition.chance > 0 then
					percent = percent - transition.chance
					if percent < 0 then
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
	local movetype, movedir = vso4DirectionInput( p.control.driver )
	if movetype > 0 then
		if movedir == "U" and transitions.up ~= nil then
			p.doTransition("up")
		end
		if (movedir == "F" or movedir == "B")  and transitions.side ~= nil then
			p.doTransition("side")
		end
		if movedir == "D" and transitions.down ~= nil then
			p.doTransition("down")
		end
	end
end

function p.handleBelly()
	p.updateOccupants()
	if p.occupants.belly > 0 and p.stateconfig[p.state].bellyEffect ~= false then
		p.bellyEffects()
	else
		for i = 1, p.maxOccupants.total do
			vsoVictimAnimSetStatus( "occupant"..i, {} )
		end
	end
	if p.control.probablyOnGround() and p.control.notMoving() then
		p.handleStruggles()
	end
end

function p.bellyEffects()
	if vsoTimerEvery( "gurgle", 1.0, 8.0 ) then
		vsoSound( "digest" )
	end
	local driver = vehicle.entityLoungingIn( "driver")

	if driver then
		getDriverStat(driver, "powerMultiplier", function(powerMultiplier)
			p.doBellyEffects(driver, powerMultiplier)
		end)
	else
		p.doBellyEffects(nil, p.standalonePowerLevel())
	end
end

function p.standalonePowerLevel()
	local powerMultiplier = world.threatLevel()
	if powerMultiplier < 1 then
		powerMultiplier = 1
	end
	return powerMultiplier
end

function p.doBellyEffects(driver, powerMultiplier)
	local status = nil
	local monsterstatus = nil
	local hungereffect = 0
	if p.bellyeffect == "digest" then
		hungereffect = 1
		if p.displaydamage then
			status = "displaydamagedigest"
		else
			status = "damagedigest"
		end
	elseif p.bellyeffect == "softdigest" then
		hungereffect = 1
		if p.displaydamage then
			status = "displaydamagesoftdigest"
		else
			status = "damagesoftdigest"
		end
	elseif p.bellyeffect == "heal" then
		status = "voreheal"
	end


	for i = 1, p.maxOccupants.total do
		local eid = vsoGetTargetId( "occupant"..i )

		if eid and world.entityExists(eid) and p.occupantLocation[i] == "belly" then
			vsoVictimAnimSetStatus( "occupant"..i, { "vsoindicatebelly", "breathprotectionvehicle" } )
			world.sendEntityMessage( eid, "PVSONightVision", self.cfgVSO.lights.prey)

			if status then
				world.sendEntityMessage( eid, "applyStatusEffect", status, powerMultiplier, entity.id() )
			end

			local hunger_change = hungereffect * powerMultiplier * vsoDelta()
			local health = world.entityHealth(eid)
			if p.bellyeffect == "softdigest" and health[1]/health[2] <= -hunger_change then
				hunger_change = (1 - health[1]) / health[2]
			end

			if driver then addHungerHealth( driver, hunger_change) end
		end
	end
end

function addHungerHealth(eid, amount, callback)
	_add_vso_rpc( world.sendEntityMessage(eid, "addHungerHealth", amount), callback)
end

function p.handleStruggles()
	local struggler = 0
	local movetype, movedir

	::NextStuggler::

	while (movetype == nil or movetype == 0) and struggler < p.maxOccupants.total do
		struggler = struggler + 1
		movetype, movedir = vso4DirectionInput( "occupant"..struggler )
	end
	if movetype == nil or movetype == 0 then return end

	if p.control.driving and struggler == 1 and not p.control.standalone then
		return -- control vappy instead of struggling
	end

	local struggledata = p.stateconfig[p.state].struggle[p.occupantLocation[struggler]]
	if struggledata == nil then return end

	if not vsoAnimEnded( struggledata.part.."State" ) and (
		vsoAnimIs( struggledata.part.."State", "s_up" ) or
		vsoAnimIs( struggledata.part.."State", "s_front" ) or
		vsoAnimIs( struggledata.part.."State", "s_back" ) or
		vsoAnimIs( struggledata.part.."State", "s_down" )
	) then
		movetype = nil
		goto NextStuggler -- already struggling
	end

	local dir = nil
	if movedir == "B" then dir = "back" end
	if movedir == "F" then dir = "front" end
	if movedir == "U" then dir = "up" end
	if movedir == "D" then dir = "down" end

	if dir == nil then return end -- invalid struggle
	if struggledata[dir] == nil then return end

	if struggledata.script ~= nil then
		local statescript = p.statestripts[p.state][struggledata.script]
		statescript( struggler, dir )
	end

	local chance = struggledata.chances
	if struggledata[dir].chances ~= nil then
		chance = struggledata[dir].chances
	end
	if vsoPill( "easyescape" ) then
		chance = chance.easyescape
	elseif vsoPill( "antiescape" ) then
		chance = chance.antiescape
	else
		chance = chance.normal
	end

	if chance ~= nil and ( chance.max == 0 or (
		(not p.control.driving or struggledata[dir].controlled)
		and vsoCounterValue( "struggleCount" ) >= chance.min
		and vsoCounterChance( "struggleCount", chance.min, chance.max )
	) ) then
		p.doTransition( struggledata[dir].transition, {index=struggler, direction=dir} )
	else
		sb.setLogMap("b", "struggle")
		local animation = {offset = struggledata[dir].offset}
		animation[struggledata.part] = "s_"..dir

		p.doAnims(animation)

		p.doAnims( struggledata[dir].animation or struggledata.animation, true )
		if struggledata[dir].victimAnimation then
			vsoVictimAnimReplay( "occupant"..struggler, struggledata[dir].victimAnimation, struggledata.part.."State" )
		end
		vsoSound( "struggle" )
		vsoCounterAdd( "struggleCount", 1 )
	end
end

function p.onInteraction( targetid )
	local state = p.stateconfig[p.state]

	local position = p.globalToLocal( world.entityPosition( targetid ) )
	local interact
	if position[1] > 3 then
		interact = p.occupantArray( state.interact.front )
	elseif position[1] < -3 then
		interact = p.occupantArray( state.interact.back )
	else
		interact = p.occupantArray( state.interact.side )
	end
	if not p.control.driving or interact.controlled then
		if interact.chance > 0 and vsoChance( interact.chance ) then
			p.doTransition( interact.transition, {id=targetid} )
			return
		end
	end

	if state.interact.animation then
		p.doAnims( state.interact.animation )
	end
	p.showEmote( "emotehappy" )
end