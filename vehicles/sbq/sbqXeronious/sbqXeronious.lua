--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/sbq/sbq_main.lua")
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
	Zygan#0404
	Wasabi_Raptor#1533

TODO:
	-roaming behavior
]]--
-------------------------------------------------------------------------------

function onBegin()	--This sets up the VSO ONCE.
end

function onEnd()
end

function p.update(dt)
	p.whenFalling()
	p.setGrabTarget()
	if not p.heldControl(p.driverSeat, "primaryFire") and not p.heldControl(p.driverSeat, "altFire") then
		p.succTime = math.max(0, p.succTime - p.dt)
	end
end

-------------------------------------------------------------------------------

function p.whenFalling()
	if not (p.state == "stand" or p.state == "fly" or p.state == "crouch") and not mcontroller.onGround() then
		p.setState( "stand" )
		p.grabbing = p.findFirstOccupantIdForLocation("hug")
	end
end

function p.letout(id)
	local id = id
	if id == nil then
		id = p.occupant[p.occupants.total].id
	end
	if not id then return end
	local location = p.lounging[id].location

	if location == "belly" then
		if p.heldControl(p.driverSeat, "down") or p.lounging[id].species == "sbqEgg" then
			return p.doTransition("escapeAnal", {id = id})
		else
			return p.doTransition("escapeOral", {id = id})
		end
	elseif location == "tail" then
		return p.doTransition("escapeTail", {id = id})
	elseif location == "hug" then
		p.grabbing = nil
		return p.uneat(id)
	end
end

function checkEggSitup()
	if not p.driving then
		for i = 0, p.occupantSlots do
			if p.occupant[i].species == "sbqEgg" then
				return p.doTransition("up")
			end
		end
	end
end

p.succTime = 0
p.succing = false
function succ(args)
	if p.transitionLock or p.succTime > 5 then return end

	local globalSuccPosition = p.localToGlobal(p.stateconfig[p.state].actions.succ.position or {0,0})
	local aim = p.seats[p.driverSeat].controls.aim

	local magnitude = world.magnitude(globalSuccPosition, aim)
	local range = 30
	if magnitude > range then return end

	p.succTime = p.succTime + p.dt
	p.facePoint(p.seats[p.driverSeat].controls.aim[1])
	p.movement.aimingLock = 0.1

	local entities = world.entityLineQuery(globalSuccPosition, aim, {
		withoutEntityId = entity.id()
	})

	local data = {
		destination = globalSuccPosition,
		source = entity.id(),
		speed = 15,
		force = 500,
		direction = p.direction,
		range = range
	}

	for i, id in ipairs(entities) do
		if id and entity.entityInSight(id) then
			p.loopedMessage("succ"..i, id, "sbqSucc", {data})
		end
	end

	p.randomTimer("succ", 0, 0.3, function ()
		local effectPosition = { aim[1]+math.random(-3,3)*math.random(), aim[2]+math.random(-3,3)*math.random() }

		local aimLine = world.lineCollision(globalSuccPosition, effectPosition, { "Null", "block", "slippery" })
		if aimLine ~= nil then
			effectPosition = aimLine
		end
		world.spawnProjectile( "sbqSuccEffect", effectPosition, entity.id(), world.distance( globalSuccPosition, effectPosition ), false, {data = data} )
	end)

	p.checkEatPosition( globalSuccPosition, 3, "belly", "succEat", true)
	return true
end

function grab()
	p.grab("hug")
end

function hugGrab()
	return p.checkEatPosition(mcontroller.position(), 5, "hug", "hug")
end

function hugUnGrab()
	return p.uneat(p.findFirstOccupantIdForLocation("hug"))
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
	local args = { id = p.findFirstOccupantIdForLocation("pinned")}
	if not args.id then return false end
	if p.moveOccupantLocation(args, "belly") then
		p.lounging[args.id].visible = false
		return true
	end
end

function checkOral()
	return p.checkEatPosition(p.localToGlobal( {0, 0} ), 5, "belly", "eat")
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
	if checkTail() then return true end
	if checkOral() then return true end
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

-------------------------------------------------------------------------------

function state.stand.begin()
	p.grabbing = p.findFirstOccupantIdForLocation("hug")
	p.movement.flying = nil
	p.setMovementParams( "default" )
	p.resolvePosition(5)
end

function state.stand.update()
	if not p.transitionLock then
		if mcontroller.onGround() and p.heldControl(p.driverSeat, "shift") and p.heldControl(p.driverSeat, "down") then
			p.letGrabGo("hug")
			p.doTransition( "crouch" )
			return
		elseif not mcontroller.onGround() and p.pressControl(p.driverSeat, "jump") then
			p.letGrabGo("hug")
			p.setState( "fly" )
			return
		end
	end
end

function state.stand.sitpin(args)
	local pinnable = { args.id }
	local sat

	if p.grabbing ~= nil and p.occupants.hug <= p.sbqData.locations.pinned.maxNested then
		local angle = p.armRotation.frontarmsAngle * 180/math.pi
		if (angle >= 225 and angle <= 315) or (angle <= -45 and angle >= -135) then
			p.uneat(p.grabbing)
			pinnable = { p.grabbing }
			p.grabbing = nil
			sat = true
			p.timer("restoreClickActions", 0.5, function()
				p.movement.clickActionsDisabled = false
			end)
		end
	end
	-- if not interact target or target isn't too far away
	if not sat and (args.id == nil or math.abs(p.globalToLocal( world.entityPosition( args.id ) )[1]) > 3) then
		local pinbounds = {
			p.localToGlobal({-3, -4}),
			p.localToGlobal({-1, -5})
		}
		pinnable = world.playerQuery( pinbounds[1], pinbounds[2] )
		if #pinnable == 0 and p.driving then
			pinnable = world.npcQuery( pinbounds[1], pinbounds[2] )
		end
	end
	if #pinnable >= 1 then
		p.addRPC(world.sendEntityMessage(pinnable[1], "sbqIsPreyEnabled", "held"), function(enabled)
			if enabled then
				p.eat( pinnable[1], "pinned" )
			end
			p.doTransition("sit")
		end)
	else
		p.doTransition("sit")
	end
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
state.stand.grab = grab

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
	p.addRPC(world.sendEntityMessage(args.id, "sbqIsPreyEnabled", "held"), function(enabled)
		if enabled then
			return p.eat(args.id, "hug")
		end
	end)
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

state.sit.succ = succ
state.sit.grab = hugGrab

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

state.hug.succ = succ
state.hug.grab = hugUnGrab

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
	p.letGrabGo("hug")
	p.setMovementParams( "crouch" )
	p.resolvePosition(5)
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
	p.letGrabGo("hug")
	p.movement.flying = true
	p.setMovementParams( "fly" )
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
