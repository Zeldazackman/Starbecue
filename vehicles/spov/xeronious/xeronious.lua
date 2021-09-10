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

function p.letout(id)
	local location = p.entity[id].location
	if location == "belly" then
		if p.heldControl(p.driverSeat, "down") or p.entity[id].species == "egg" then
			return p.doTransition("escapeAnal", {id = id})
		else
			return p.doTransition("escapeOral", {id = id})
		end
	elseif location == "tail" then
		return p.doTransition("escapeTail", {id = id})
	elseif location == "hug" then
		return p.uneat(id)
	end
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

function escapeOral(args)
	return p.doEscape(args, {"vsoindicatemaw"}, {"droolsoaked", 5} )
end

function escapeAnal(args)
	return p.doEscape(args, {"vsoindicateout"}, {"droolsoaked", 5} )
end

function escapeTail(args)
	return p.doEscape(args, {"vsoindicateout"}, {"droolsoaked", 5} )
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

state.stand.bellyToTail = bellyToTail
state.stand.tailToBelly = tailToBelly
state.stand.eat = oralEat
state.stand.tailEat = tailEat

state.stand.vore = checkVore
state.stand.oralVore = checkOral
state.stand.tailVore = checkTail

state.stand.escapeOral = escapeOral
state.stand.escapeAnal = escapeAnal
state.stand.escapeTail = escapeTail

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

state.sit.bellyToTail = bellyToTail
state.sit.tailToBelly = tailToBelly
state.sit.eat = oralEat
state.sit.tailEat = tailEat

state.sit.vore = checkVore
state.sit.oralVore = checkOral
state.sit.tailVore = checkTail

state.sit.escapeOral = escapeOral
state.sit.escapeTail = escapeTail

-------------------------------------------------------------------------------

function state.hug.update()
	if p.occupants.hug < 1 then
		p.setState("sit")
	end
end

function state.hug.unhug( args )
	p.uneat(p.findFirstOccupantIdForLocation("hug"))
end

state.hug.bellyToTail = bellyToTail
state.hug.tailToBelly = tailToBelly
state.hug.eat = oralEat
state.hug.tailEat = tailEat

state.hug.vore = checkVore
state.hug.oralVore = checkOral
state.hug.tailVore = checkTail

state.hug.escapeOral = escapeOral
state.hug.escapeTail = escapeTail

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

state.crouch.bellyToTail = bellyToTail
state.crouch.tailToBelly = tailToBelly

state.crouch.tailEat = tailEat
state.crouch.tailVore = checkTail
state.crouch.vore = checkTail

state.crouch.escapeTail = escapeTail

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

state.fly.bellyToTail = bellyToTail
state.fly.tailToBelly = tailToBelly
state.fly.eat = oralEat
state.fly.tailEat = tailEat

state.fly.tailVore = checkTail
state.fly.analVore = checkAnal

state.fly.escapeOral = escapeOral
state.fly.escapeAnal = escapeAnal
state.fly.escapeTail = escapeTail

state.fly.succ = succ

-------------------------------------------------------------------------------
