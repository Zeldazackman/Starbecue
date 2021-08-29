--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/spov/playable_vso.lua")
state = {
	stand = {},
	crouch = {},
	fly = {},
	sit = {},
	hug = {}
}
-------------------------------------------------------------------------------
--[[

Commissioned by:
	-xeronious#8891			https://www.furaffinity.net/user/xeronious/

Sprites created by:
	-Wasabi_Raptor#1533		https://www.furaffinity.net/user/lokithevulpix/

Scripts created by:
	Zygan#0404 				<-did like 99% of the scripts
	Wasabi_Raptor#1533 		<-did debugs and copied scripts around for things

TODO:
	-roaming behavior
]]--
-------------------------------------------------------------------------------

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

end

function onBegin()	--This sets up the VSO ONCE.


end

function onEnd()

end

-------------------------------------------------------------------------------

function p.whenFalling()
	if p.state ~= ("stand" or "fly") and mcontroller.yVelocity() < -5 then
		p.setState( "stand" )
		p.doAnims( p.stateconfig[p.state].control.animations.fall )
		p.movement.falling = true
		for i = 1, p.occupants.total do
			if p.occupant[i].location == "hug" then
				p.uneat(i)
			end
		end
	end
end

function checkEscapes(args)
	local location = p.occupant[args.index].location
	local returnval = {}
	local direction = "escapeoral"
	local status = {"vsoindicatemaw"}
	local monstercoords = {6, 1} -- same as last coords of escape anim
	local move = args.direction or "up"

	if (p.occupant[args.index].species == "xeronious_egg"
	or vehicle.controlHeld(p.driverSeat, "down")) and location ~= "tail" then
		move = "down"
	end

	if location == "tail" then
		direction = "escapetail"
		monstercoords = {-6, 0}
	elseif location == "belly" and move == "down" then
		status = {"vsoindicateout"}
		direction = "escapeanalvore"
		monstercoords = {-0.75, -3}
	elseif location == "hug" then
		p.setState("sit")
		return p.doEscape(args.index, "hug", {2.5,0}, {}, {})
	end

	if not p.doTransition(direction, args) then return false end

	returnval[1], returnval[2] = p.doEscape(args, location, monstercoords, status, {"droolsoaked", 5})

	returnval[3] = p.occupantArray( p.stateconfig[p.state].transitions[direction] )

	return returnval[1], returnval[2], returnval[3]
end

function p.extraBellyEffects(i, eid, health)
	if p.occupant[i].location == "belly" and health[1] == 1 and ((p.settings.bellyEffect == "pvsoSoftDigest") or (p.settings.bellyEffect == "pvsoDisplaySoftDigest"))then
		p.occupant[i].species = "xeronious_egg"
		p.smolprey( i )
		if p.settings.autoegglay or not p.driving then p.doTransition("escape", {index=i, direction="down"}) end
		return
	end
end

function checkEggSitup()
	if not p.driving then
		for i = 1, p.occupants.total do
			if p.occupant[i].species == "xeronious_egg" then
				return p.doTransition("up")
			end
		end
	end
end

function succ(args)
	local pos1 = p.localToGlobal({-5,-8})
	local pos2 = p.localToGlobal({30,8})
	if pos1[1] > pos2[1] then
		pos1[1], pos2[1] = pos2[1], pos1[1]
	end

	-- local pos1 = p.localToGlobal({9,0})

	local entities = world.entityQuery(pos1, pos2, {
		withoutEntityId = vehicle.entityLoungingIn(p.driverSeat),
		includedTypes = {"creature"}
	})

	-- local entities = world.entityQuery(pos1, 10, {
	-- 	withoutEntityId = vehicle.entityLoungingIn(p.driverSeat),
	-- 	includedTypes = {"creature"}
	-- })

	local dest = p.localToGlobal({3, 2.5})

	for i = 1, #entities do
		local pos = world.distance(dest, world.entityPosition(entities[i]))
		local offset = math.floor(pos[2] + 0.5) * 1000 + math.floor(pos[1] + 500.5)
		world.sendEntityMessage( entities[i], "applyStatusEffect", "succ", 1, offset)
	end
	p.checkEatPosition( dest, "belly", "succeat", true)
end

function bellyToTail(args)
	return p.moveOccupantLocation(args, "body", "tail")
end

function tailToBelly(args)
	return p.moveOccupantLocation(args, "tail", "belly")
end

function oralEat(args)
	return p.doVore(args, "belly", {"vsoindicatemaw"}, "swallow")
end

function tailEat(args)
	return p.doVore(args, "tail", {"vsoindicatemaw"}, "swallow")
end

-------------------------------------------------------------------------------

function state.stand.update()
	local pos1 = p.localToGlobal({3.5, 4})
	local pos2 = p.localToGlobal({-3, 1})

	local pos3 = p.localToGlobal({3.5, -5})
	local pos4 = p.localToGlobal({-3, 0})

	if p.probablyOnGround()
	and world.rectCollision( {pos1[1], pos1[2], pos2[1], pos2[2]}, { "Null", "block", "slippery"} )
	and not world.rectCollision( {pos3[1], pos3[2], pos4[1], pos4[2] }, { "Null", "block", "slippery"} )
	then
		if (vehicle.controlHeld( p.driverSeat, "left") or vehicle.controlHeld( p.driverSeat, "right") )
		and vehicle.controlHeld( p.driverSeat, "down") then
			p.doTransition( "crouch" )
			return
		elseif p.settings.autocrouch or not p.driving then
			p.doTransition( "crouch" )
			return
		end
	end

	if p.driving then
		if vehicle.controlHeld( p.driverSeat, "down" ) then
			p.movement.downframes = p.movement.downframes + 1
		else
			if p.movement.downframes > 0 and p.movement.downframes < 10 and p.notMoving() and p.probablyOnGround() then
				p.doTransition( "down" )
			end
			p.movement.downframes = 0
		end
		if p.movement.wasspecial1 ~= true and p.movement.wasspecial1 ~= false and p.movement.wasspecial1 > 0 then
			-- a bit of a hack, prevents the special1 press from activating xeronious from also doing this by adding a 10 frame delay before checking if you're pressing it
			p.movement.wasspecial1 = p.movement.wasspecial1 - 1
		else
			p.movement.wasspecial1 = false
		end

		if vehicle.controlHeld( p.driverSeat, "jump" ) and p.movement.airframes > 10 and not p.movement.jumped then
			p.setState( "fly" )
			return
		end

		if p.standalone and vehicle.controlHeld( p.driverSeat, "Special2" ) then
			if p.occupants.total > 0 then
				p.doTransition( "escape", {index=p.occupants.total} ) -- last eaten
			end
		end
	end
end

function state.stand.bapeat()
	if p.checkEatPosition(p.localToGlobal( p.stateconfig.stand.control.primaryAction.projectile.position ), "belly", "eat") then return end
	if p.checkEatPosition(p.localToGlobal({-5, -2}), "tail", "taileat") then return end
end

function state.stand.interact( occupantId )
	if mcontroller.yVelocity() > -5 then
		p.onInteraction( occupantId )
	end
end

state.stand.checkletout = checkEscapes
state.stand.bellytotail = bellyToTail
state.stand.tailtobelly = tailToBelly
state.stand.eat = oralEat
state.stand.taileat = tailEat
state.stand.succ = succ

-------------------------------------------------------------------------------

function state.sit.update()
	checkEggSitup()

	if p.standalone and vehicle.controlHeld( p.driverSeat, "Special2" ) then
		if p.occupants.total > 0 then
			p.doTransition( "escape", {index=p.occupants.total} ) -- last eaten
		end
	end

	-- simulate npc interaction when nearby
	if p.occupants.total == 0 and p.standalone then
		if p.randomChance(1) then -- every frame, we don't want it too often
			local npcs = world.npcQuery(mcontroller.position(), 4)
			if npcs[1] ~= nil then
				p.doTransition( "hug", {id=npcs[1]} )
			end
		end
	end
end

function state.sit.hug( args )
	return p.doVore(args, "hug", {})
end

state.sit.checkletout = checkEscapes
state.sit.bellytotail = bellyToTail
state.sit.tailtobelly = tailToBelly
state.sit.eat = oralEat
state.sit.taileat = tailEat

-------------------------------------------------------------------------------

function state.hug.update()
	if p.occupants.hug < 1 then
		p.setState("sit")
	end
end

function state.hug.unhug( args )
	for i = 1, p.occupants.total do
		if p.occupant[i].location == "hug" then
			return p.doEscape({index = i}, "hug", {2.5,0}, {}, {})
		end
	end
end

state.hug.checkletout = checkEscapes
state.hug.bellytotail = bellyToTail
state.hug.tailtobelly = tailToBelly
state.hug.eat = oralEat
state.hug.taileat = tailEat

-------------------------------------------------------------------------------

function state.crouch.update()
	local pos1 = p.localToGlobal({3.5, 4})
	local pos2 = p.localToGlobal({-3, 1})

	if not world.rectCollision( {pos1[1], pos1[2], pos2[1], pos2[2]}, { "Null", "block", "slippery"} )
	and not vehicle.controlHeld( p.driverSeat, "down")
	then
		if not p.probablyOnGround() then
			p.setState( "stand" )
			return
		else
			p.doTransition( "uncrouch" )
			return
		end
	end
end

function state.crouch.begin()
	p.setMovementParams( "crouch" )
end

function state.crouch.ending()
	p.setMovementParams( "default" )
	p.movement.downframes = 11
end

state.crouch.checkletout = checkEscapes
state.crouch.bellytotail = bellyToTail
state.crouch.tailtobelly = tailToBelly
state.crouch.taileat = tailEat

-------------------------------------------------------------------------------

function state.fly.update()
	p.doAnims(p.stateconfig[p.state].control.animations.fly)

	local control = p.stateconfig[p.state].control

	if p.occupants.total >= control.fullThreshold and p.probablyOnGround() then
		p.setState( "stand" )
		return
	end

	local dx = 0
	local dy = 0
	local controlForce = 100

	if p.driving then
		if vehicle.controlHeld( p.driverSeat, "left" ) then
			dx = dx - 1
		end
		if vehicle.controlHeld( p.driverSeat, "right" ) then
			dx = dx + 1
		end
		if vehicle.controlHeld( p.driverSeat, "up" ) then
			dy = dy + 1
		end
		if vehicle.controlHeld( p.driverSeat, "down" ) then
			dy = dy - 1
		end

		if vehicle.controlHeld( p.driverSeat, "jump" ) then
			if not p.movement.jumped then
				p.setState( "stand" )
				return
			end
		else
			p.movement.jumped = false
		end

		if p.standalone and vehicle.controlHeld( p.driverSeat, "Special2" ) then
			if p.occupants.total > 0 then
				p.doTransition( "escape", {index=p.occupants.total} ) -- last eaten
			end
		end
	end

	local running = false
	if (p.occupants.total + p.settings.fatten) < control.fullThreshold then --add walk control here when we have more controls
		running = true
	end
	if dx ~= 0 then
		vsoFaceDirection( dx )
	end
	if running then
		mcontroller.approachXVelocity( dx * control.runSpeed, controlForce )
		mcontroller.approachYVelocity( dy * control.runSpeed -control.fullWeights[(p.occupants.total + p.settings.fatten) +1], controlForce )
	else
		mcontroller.approachXVelocity( dx * control.walkSpeed, controlForce )
		mcontroller.approachYVelocity( dy * control.walkSpeed -control.fullWeights[(p.occupants.total + p.settings.fatten) +1], controlForce )
	end
end

function state.fly.begin()
	p.setMovementParams( "fly" )
	p.movement.jumped = true
end

function state.fly.ending()
	p.movement.jumped = true
	p.setMovementParams( "default" )
end

function state.fly.analvore(args)
	return p.doVore(args, "belly", {"vsoindicateout"}, "swallow")
end

function state.fly.grabanalvore()
	if p.checkEatPosition(p.localToGlobal({0, -3}), "belly", "analvore") then return end
	if p.checkEatPosition(p.localToGlobal({-5, -2}), "tail", "taileat") then return end
end

state.fly.checkletout = checkEscapes
state.fly.bellytotail = bellyToTail
state.fly.tailtobelly = tailToBelly
state.fly.eat = oralEat
state.fly.taileat = tailEat
state.fly.succ = succ

-------------------------------------------------------------------------------
