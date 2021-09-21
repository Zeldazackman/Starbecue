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
	p.setGrabTarget()
end

-------------------------------------------------------------------------------

function p.whenFalling()
	if not (p.state == "stand" or p.state == "fly" or p.state == "crouch") and not mcontroller.onGround() then
		p.setState( "stand" )
		p.uneat(p.findFirstOccupantIdForLocation("hug"))
	end
end

function p.letout(id)
	if not id then return end
	local location = p.lounging[id].location
	if location == "belly" then
		if p.heldControl(p.driverSeat, "down") or p.lounging[id].species == "egg" then
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
	if p.transitionLock then return end
	p.facePoint(p.seats[p.driverSeat].controls.aim[1])
	p.movement.aimingLock = 0.1

	local globalSuccPosition = p.localToGlobal(p.stateconfig[p.state].control.clickActions.succ.position or {0,0})
	local aim = p.seats[p.driverSeat].controls.aim

	local entities = world.entityLineQuery(globalSuccPosition, aim, {
		withoutEntityId = entity.id()
	})

	local data = {
		destination = globalSuccPosition,
		source = entity.id(),
		speed = 20,
		force = 200
	}

	for i, id in ipairs(entities) do
		if id and entity.entityInSight(id) then
			p.loopedMessage("succ"..i, id, "pvsoSucc", {data})
		end
	end
	p.checkEatPosition( globalSuccPosition, 2, "belly", "succEat", true)
	return true
end

function letGrabGo()
	local victim = p.findFirstOccupantIdForLocation("hug")
	p.grabbing = nil
	p.armRotation.enabledL = false
	p.armRotation.enabledR = false
	p.armRotation.groupsR = {}
	p.armRotation.groupsL = {}
	p.uneat(victim)
end

function bellyToTail(args)
	return p.moveOccupantLocation(args, "tail")
end

function tailToBelly(args)
	return p.moveOccupantLocation(args, "belly")
end

function grabOralEat(args)
	p.grabbing = args.id
	return p.doVore(args, "belly", {"vsoindicatemaw"}, "swallow")
end

function oralEat(args)
	return p.doVore(args, "belly", {"vsoindicatemaw"}, "swallow")
end

function tailEat(args)
	return p.doVore(args, "tail", {"vsoindicatemaw"}, "swallow")
end

function analEat(args)
	return p.doVore(args, "belly", {"vsoindicateout"}, "swallow")
end

function sitAnalEat(args)
	args.id = p.findFirstOccupantIdForLocation("pinned")
	if not args.id then return false end
	local continue, func = p.moveOccupantLocation(args, "belly")
	if continue then
		p.lounging[args.id].visible = false
		func()
	end
	return continue
end

function checkOral()
	return p.checkEatPosition(p.localToGlobal( {3, -1.5} ), 5, "belly", "eat")
end

function checkTail()
	return p.checkEatPosition(p.localToGlobal({-5, -2}), 2, "tail", "tailEat")
end

function checkAnal()
	return p.checkEatPosition(p.localToGlobal({-1, -3}), 2, "belly", "analEat")
end

function sitCheckAnal()
	local victim = p.findFirstOccupantIdForLocation("pinned")
	local entityaimed = world.entityQuery(p.seats[p.driverSeat].controls.aim, 2, {
		withoutEntityId = p.driver,
		includedTypes = {"creature"}
	})
	if entityaimed[1] == victim then
		p.doTransition("analEat")
		return true
	end
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

function sitCheckVore()
	if checkOral() then return true end
	if checkTail() then return true end
	if sitCheckAnal() then return true end
end


function unpin(args)
	args.id = p.findFirstOccupantIdForLocation("pinned")
	local returnval = {}
	returnval[1], returnval[2], returnval[3] = p.doEscape(args, {}, {})
	return true, returnval[2], returnval[3]
end

function p.setGrabTarget()
	local controls = p.seats[p.driverSeat].controls
	if not (((controls.primaryHandItem == "pvsoController") or (controls.altHandItem == "pvsoController"))
	or ((controls.primaryHandItem == nil) and (controls.altHandItem == nil)))
	then
		p.grabbing = nil
	end
	if p.justAte ~= nil and p.justAte == p.grabbing then
		p.wasEating = true
		p.armRotation.enabledL = true
		p.armRotation.enabledR = true
		p.armRotation.target = p.globalToLocal(world.entityPosition(p.justAte))
		p.armRotation.groupsR = {}
		p.armRotation.groupsL = {}
	elseif p.wasEating then
		p.wasEating = false
		p.grabbing = nil
	elseif p.grabbing ~= nil and p.entityLounging(p.grabbing) then
		p.movement.clickActionsDisabled = true
		p.armRotation.enabledL = true
		p.armRotation.enabledR = true
		p.armRotation.target = p.globalToLocal(p.seats[p.driverSeat].controls.aim)
		p.armRotation.groupsR = {p.lounging[p.grabbing].seatname.."Position"}
		p.armRotation.groupsL = {p.lounging[p.grabbing].seatname.."Position"}
		p.armRotation.occupantR = p.grabbing
		p.armRotation.occupantL = p.grabbing
	else
		p.armRotation.enabledL = false
		p.armRotation.enabledR = false
		p.armRotation.groupsR = {}
		p.armRotation.groupsL = {}
		p.armRotation.occupantR = nil
		p.armRotation.occupantL = nil
	end
end

function p.grab()
	local target = p.checkValidAim(p.driverSeat, 2)
	if target then
		p.addRPC(world.sendEntityMessage(target, "pvsoIsPreyEnabled", "held"), function(enabled)
			if enabled then
				local prey = world.entityQuery(mcontroller.position(), 5, {
					withoutEntityId = p.driver,
					includedTypes = {"creature"}
				})
				for _, entity in ipairs(prey) do
					if entity == target then
						if p.eat(target, "hug") then
							p.grabbing = target
							p.movement.clickActionsDisabled = true
						end
					end
				end
			end
		end)
		return true
	end
end

-------------------------------------------------------------------------------

function state.stand.begin()
	local hugged = p.findFirstOccupantIdForLocation("hug")
	if hugged ~= nil then
		p.grabbing = hugged
	end
end

function state.stand.update()
	if p.movement.clickActionsDisabled then
		if p.pressControl(p.driverSeat, "primaryFire") then
			p.uneat(p.grabbing)
			local transition = "eat"
			local victim = p.grabbing
			if p.armRotation.target[1] < 2 and p.armRotation.target[2] < 0 then
				p.grabbing = nil
				transition = "analEat"
			end
			p.doTransition(transition, {id = victim})
			p.timer("restoreClickActions", 0.5, function()
				p.movement.clickActionsDisabled = false
			end)
		elseif p.pressControl(p.driverSeat, "altFire") then
			p.uneat(p.grabbing)
			p.grabbing = nil
			p.timer("restoreClickActions", 0.5, function()
				p.movement.clickActionsDisabled = false
			end)
		end
	end
	if not p.transitionLock then
		if mcontroller.onGround() and p.heldControl(p.driverSeat, "shift") and p.heldControl(p.driverSeat, "down") then
			letGrabGo()
			p.doTransition( "crouch" )
			return
		elseif not mcontroller.onGround() and p.pressControl(p.driverSeat, "jump") then
			letGrabGo()
			p.setState( "fly" )
			return
		end
	end
end

state.stand.grab = p.grab

function state.stand.sitpin(args)
	local pinnable = { args.id }
	-- if not interact target or target isn't in front
	if args.id == nil or p.globalToLocal( world.entityPosition( args.id ) )[1] < 3 then
		local pinbounds = {
			p.localToGlobal({-3, -4}),
			p.localToGlobal({-1, -5})
		}
		pinnable = world.playerQuery( pinbounds[1], pinbounds[2] )
		if #pinnable == 0 and p.driving then
			pinnable = world.npcQuery( pinbounds[1], pinbounds[2] )
		end
	end
	if #pinnable >= 1 and p.eat( pinnable[1], "pinned" ) then
		--vsoVictimAnimSetStatus( "occupant"..index , {} )
	end
	return true
end

function state.stand.vore()
	if checkOral() then return true end
	if checkTail() then return true end
	if checkAnal() then return true end
end


state.stand.bellyToTail = bellyToTail
state.stand.tailToBelly = tailToBelly
state.stand.eat = grabOralEat
state.stand.succEat = oralEat
state.stand.tailEat = tailEat
state.stand.analEat = analEat

state.stand.oralVore = checkOral
state.stand.tailVore = checkTail
state.stand.analVore = checkAnal

state.stand.escapeOral = escapeOral
state.stand.escapeAnal = escapeAnal
state.stand.escapeTail = escapeTail

state.stand.succ = succ

-------------------------------------------------------------------------------

function state.sit.update()
	checkEggSitup()

	if p.pressControl(p.driverSeat, "jump") then
		p.doTransition("analEat")
	end

	if p.occupants.hug > 0 then
		p.setState("hug")
	end

	-- simulate npc interaction when nearby
	if p.occupants.hug == 0 and not p.isObject and not p.transitionLock then
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
state.sit.eat = grabOralEat
state.sit.succEat = oralEat
state.sit.tailEat = tailEat
state.sit.analEat = sitAnalEat

state.sit.vore = sitCheckVore
state.sit.oralVore = checkOral
state.sit.tailVore = checkTail
state.sit.analVore = sitCheckAnal

state.sit.escapeOral = escapeOral
state.sit.escapeTail = escapeTail
state.sit.unpin = unpin


-------------------------------------------------------------------------------

function state.hug.begin()
	local victim = p.findFirstOccupantIdForLocation("hug")
	if victim then
		p.grabbing = nil
		p.doVictimAnim( victim, "hugcenter", "bodyState")
	end
end

function state.hug.update()
	if p.pressControl(p.driverSeat, "jump") then
		p.doTransition("analEat")
	end

	if p.occupants.hug < 1 then
		p.setState("sit")
	end
end

function state.hug.unhug( args )
	p.uneat(p.findFirstOccupantIdForLocation("hug"))
end

state.hug.bellyToTail = bellyToTail
state.hug.tailToBelly = tailToBelly
state.hug.eat = grabOralEat
state.hug.succEat = oralEat
state.hug.tailEat = tailEat
state.hug.analEat = sitAnalEat

state.hug.vore = sitCheckVore
state.hug.oralVore = checkOral
state.hug.tailVore = checkTail
state.hug.analVore = sitCheckAnal

state.hug.escapeOral = escapeOral
state.hug.escapeTail = escapeTail
state.hug.unpin = unpin

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
	letGrabGo()
	p.setMovementParams( "crouch" )
end

function state.crouch.ending()
	p.setMovementParams( "default" )
end

state.crouch.bellyToTail = bellyToTail
state.crouch.tailToBelly = tailToBelly

state.crouch.succEat = oralEat
state.crouch.tailEat = tailEat
state.crouch.tailVore = checkTail
state.crouch.vore = checkTail

state.crouch.escapeTail = escapeTail

-------------------------------------------------------------------------------

function state.fly.update()
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
	letGrabGo()
	p.movement.flying = true
	p.setMovementParams( "fly" )
end

function state.fly.ending()
	p.movement.flying = false
	p.setMovementParams( "default" )
end

function state.fly.vore()
	if checkAnal() then return true end
	if checkTail() then return true end
end

state.fly.bellyToTail = bellyToTail
state.fly.tailToBelly = tailToBelly
state.fly.eat = oralEat
state.fly.succEat = oralEat
state.fly.tailEat = tailEat
state.fly.analEat = analEat

state.fly.tailVore = checkTail
state.fly.analVore = checkAnal

state.fly.escapeOral = escapeOral
state.fly.escapeAnal = escapeAnal
state.fly.escapeTail = escapeTail

state.fly.succ = succ

-------------------------------------------------------------------------------
