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
				p.uneat(p.occupant[i].id)
			end
		end
	end
end

function checkEscapes(args)
	local location = p.occupant[args.index].location
	local returnval = {}
	local direction = "escapeoral"
	local status = {"vsoindicatemaw"}
	local move = args.direction or "up"

	if (p.occupant[args.index].species == "xeronious_egg"
	or vehicle.controlHeld(p.driverSeat, "down")) and location ~= "tail" then
		move = "down"
	end

	if location == "tail" then
		direction = "escapetail"
	elseif location == "belly" and move == "down" then
		status = {"vsoindicateout"}
		direction = "escapeanalvore"
	elseif location == "hug" then
		p.setState("sit")
		return p.doEscape(args.index, "hug", {}, {})
	end

	if not (p.doTransition(direction, args) == "success") then return false end

	returnval[1], returnval[2] = p.doEscape(args, location, status, {"droolsoaked", 5})

	returnval[3] = p.occupantArray( p.stateconfig[p.state].transitions[direction] )

	return returnval[1], returnval[2], returnval[3]
end

function p.extraBellyEffects(i, eid, health)
	if p.occupant[i].location == "belly" and health[1] == 1 and ((p.settings.bellyEffect == "pvsoSoftDigest") or (p.settings.bellyEffect == "pvsoDisplaySoftDigest"))then
		p.occupant[i].species = "xeronious_egg"
		--p.smolprey( i )
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
		withoutEntityId = p.driver,
		includedTypes = {"creature"}
	})

	-- local entities = world.entityQuery(pos1, 10, {
	-- 	withoutEntityId = p.driver,
	-- 	includedTypes = {"creature"}
	-- })

	local data = {
		destination = p.localToGlobal({3, 2.5}),
		source = entity.id(),
		force = 400
	}

	for i = 1, #entities do
		p.loopedMessage("succ"..i, entities[i], "pvsoSucc", data)
	end
	p.checkEatPosition( data.destination, "belly", "succeat", true)
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

function checkOral()
	return p.checkEatPosition(p.localToGlobal( {3, -1.5} ), "belly", "eat")
end

function checkTail()
	return p.checkEatPosition(p.localToGlobal({-5, -2}), "tail", "taileat")
end

function checkAnal()
	return p.checkEatPosition(p.localToGlobal({0, -3}), "belly", "analvore")
end


function checkVore()
	if checkOral() then return true end
	if checkTail then return true end
end

-------------------------------------------------------------------------------

function state.stand.update()
	local pos1 = p.localToGlobal({3.5, 4})
	local pos2 = p.localToGlobal({-3, 1})

	local pos3 = p.localToGlobal({3.5, -5})
	local pos4 = p.localToGlobal({-3, 0})

	if mcontroller.onGround()
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
		if p.tapControl( p.driverSeat, "jump" ) and p.movement.airtime > 10 and not p.movement.jumped then
			p.setState( "fly" )
			return
		end

		if p.tapControl( p.driverSeat, "special2" ) then
			if p.occupants.total > 0 then
				p.doTransition( "escape", {index=p.occupants.total} ) -- last eaten
			end
		end
	end
end

state.stand.checkletout = checkEscapes
state.stand.bellytotail = bellyToTail
state.stand.tailtobelly = tailToBelly
state.stand.eat = oralEat
state.stand.taileat = tailEat

state.stand.vore = checkVore
state.stand.oralVore = checkOral
state.stand.tailVore = checkTail

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

state.sit.vore = checkVore
state.sit.oralVore = checkOral
state.sit.tailVore = checkTail


-------------------------------------------------------------------------------

function state.hug.update()
	if p.occupants.hug < 1 then
		p.setState("sit")
	end
end

function state.hug.unhug( args )
	for i = 1, p.occupants.total do
		if p.occupant[i].location == "hug" then
			return p.doEscape({index = i}, "hug", {}, {})
		end
	end
end

state.hug.checkletout = checkEscapes
state.hug.bellytotail = bellyToTail
state.hug.tailtobelly = tailToBelly
state.hug.eat = oralEat
state.hug.taileat = tailEat

state.hug.vore = checkVore
state.hug.oralVore = checkOral
state.hug.tailVore = checkTail


-------------------------------------------------------------------------------

function state.crouch.update()
	local pos1 = p.localToGlobal({3.5, 4})
	local pos2 = p.localToGlobal({-3, 1})

	if not world.rectCollision( {pos1[1], pos1[2], pos2[1], pos2[2]}, { "Null", "block", "slippery"} )
	and not vehicle.controlHeld( p.driverSeat, "down")
	then
		if not mcontroller.onGround() then
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
end

state.crouch.checkletout = checkEscapes
state.crouch.bellytotail = bellyToTail
state.crouch.tailtobelly = tailToBelly

state.crouch.taileat = tailEat
state.crouch.tailVore = checkTail
state.crouch.vore = checkTail



-------------------------------------------------------------------------------

function state.fly.update()
	p.doAnims(p.stateconfig[p.state].control.animations.fly)

	local control = p.stateconfig[p.state].control

	if p.occupants.total >= control.fullThreshold and mcontroller.onGround() then
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
	if p.occupants.mass < control.fullThreshold then --add walk control here when we have more controls
		running = true
	end
	if dx ~= 0 then
		p.faceDirection( dx )
	end
	if running then
		mcontroller.approachXVelocity( dx * control.runSpeed, controlForce )
		mcontroller.approachYVelocity( dy * control.runSpeed -control.fullWeights[math.floor(p.occupants.mass) +1], controlForce )
	else
		mcontroller.approachXVelocity( dx * control.walkSpeed, controlForce )
		mcontroller.approachYVelocity( dy * control.walkSpeed -control.fullWeights[math.floor(p.occupants.mass) +1], controlForce )
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

function state.fly.vore()
	if checkAnal() then return true end
	if checkTail() then return true end
end

state.fly.checkletout = checkEscapes
state.fly.bellytotail = bellyToTail
state.fly.tailtobelly = tailToBelly
state.fly.eat = oralEat
state.fly.taileat = tailEat

state.fly.tailVore = checkTail
state.fly.analVore = checkAnal

state.fly.succ = succ

-------------------------------------------------------------------------------
