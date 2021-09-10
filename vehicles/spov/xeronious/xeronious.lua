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

function p.update(dt)
	p.whenFalling()
end

-------------------------------------------------------------------------------

function p.whenFalling()
	if not (p.state == "stand" or p.state == "fly" or p.state == "crouch") and not mcontroller.onGround() then
		p.setState( "stand" )
		p.uneat(p.findFirstOccupantIdForLocation("hug"))
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
		p.loopedMessage("succ"..i, entities[i], "pvsoSucc", {data})
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
	if checkTail() then return true end
end

-------------------------------------------------------------------------------

function state.stand.update()
	if not p.transitionLock then
		if mcontroller.onGround() and p.heldControl(p.driverSeat, "shift") and p.heldControl(p.driverSeat, "down") then
			p.doTransition( "crouch" )
			return
		elseif not mcontroller.onGround() and p.pressControl(p.driverSeat, "jump") then
			p.setState( "fly" )
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
	return p.eat(args.id, "hug", {})
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
	p.uneat(p.findFirstOccupantIdForLocation("hug"))
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
	local pos1 = p.localToGlobal({3, 4})
	local pos2 = p.localToGlobal({-3, 1})

	if not world.rectCollision( {pos1[1], pos1[2], pos2[1], pos2[2]}, { "Null", "block", "slippery"} )
	and not (p.heldControl( p.driverSeat, "down") and p.heldControl( p.driverSeat, "shift"))
	then
		p.doTransition( "uncrouch" )
		return
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

	if not p.transitionLock then
		if p.pressControl( p.driverSeat, "jump" )
		or ((p.occupants.mass >= p.movementParams.fullThreshold) and mcontroller.onGround())
		or p.underWater()
		then
			p.setState( "stand" )
			return
		end
	end
end

function state.fly.begin()
	p.setMovementParams( "fly" )
end

function state.fly.ending()
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
