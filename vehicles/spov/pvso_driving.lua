
function p.pressControl(seat, control)
	return p.seats[seat].controls[control.."Pressed"]
end

function p.tapControl(seat, control)
	return (( p.seats[seat].controls[control.."Released"] > 0 ) and ( p.seats[seat].controls[control.."Released"] < 0.15 ))
end

function p.heldControl(seat, control, min)
	return p.seats[seat].controls[control] > (min or 0)
end

function p.heldControlMax(seat, control, max)
	return p.seats[seat].controls[control] < (max or 1)
end

function p.heldControlMinMax(seat, control, min, max)
	return p.heldControl(seat, control, min) and p.heldControlMax(seat, control, max)
end

function p.heldControls(seat, controlList, time)
	for _, control in pairs(controlList) do
		if p.seats[seat].controls[control] <= (time or 0) then
			return false
		end
	end
	return true
end

function p.updateControl(seatname, control, dt, forceHold)
	if vehicle.controlHeld(seatname, control) or forceHold then
		if p.seats[seatname].controls[control] == 0 then
			p.seats[seatname].controls[control.."Pressed"] = true
		else
			p.seats[seatname].controls[control.."Pressed"] = false
		end
		p.seats[seatname].controls[control] = p.seats[seatname].controls[control] + dt
		p.seats[seatname].controls[control.."Released"] = 0
	else
		p.seats[seatname].controls[control.."Released"] = p.seats[seatname].controls[control]
		p.seats[seatname].controls[control] = 0
	end
end

function p.updateDirectionControl(seatname, control, direction, val, dt, forceHold)
	if vehicle.controlHeld(seatname, control) or forceHold then
		p.seats[seatname].controls[control] = p.seats[seatname].controls[control] + dt
		p.seats[seatname].controls[direction] = p.seats[seatname].controls[direction] + val
		p.seats[seatname].controls[control.."Released"] = 0
	else
		p.seats[seatname].controls[control.."Released"] = p.seats[seatname].controls[control]
		p.seats[seatname].controls[control] = 0
	end
end

function p.updateControls(dt)
	for i = 0, #p.occupant do
		local seatname = p.occupant[i].seatname
		local eid = p.getEidFromSeatname(seatname)
		if eid ~= nil and world.entityExists(eid) and not (seatname == p.driverSeat and p.isPathfinding) then
			p.occupant[i].controls.dx = 0
			p.occupant[i].controls.dy = 0
			p.updateDirectionControl(seatname, "left", "dx", -1, dt)
			p.updateDirectionControl(seatname, "right", "dx", 1, dt)
			p.updateDirectionControl(seatname, "down", "dy", -1, dt)
			p.updateDirectionControl(seatname, "up", "dy", 1, dt)
			p.updateControl(seatname, "jump", dt)
			p.updateControl(seatname, "special1", dt)
			p.updateControl(seatname, "special2", dt)
			p.updateControl(seatname, "special3", dt)
			p.updateControl(seatname, "primaryFire", dt)
			p.updateControl(seatname, "altFire", dt)

			p.occupant[i].controls.aim = vehicle.aimPosition( p.driverSeat ) or {0,0}
			p.occupant[i].controls.species = world.entitySpecies(eid) or world.monsterType(eid)
			p.occupant[i].controls.primaryHandItem = world.entityHandItem(eid, "primary")
			p.occupant[i].controls.altHandItem = world.entityHandItem(eid, "alt")
			p.occupant[i].controls.primaryHandItemDescriptor = world.entityHandItemDescriptor(eid, "primary")
			p.occupant[i].controls.altHandItemDescriptor = world.entityHandItemDescriptor(eid, "alt")

			local type = "prey"
			if (seatname == p.driverSeat) then
				type = "driver"
			end
			if p.occupant[i].controls.primaryHandItem == "pvsoController" or p.occupant[i].controls.primaryHandItem == "pvsoSecretTrick" then
				p.mergeSeatData(seatname, p.occupant[i].controls.primaryHandItemDescriptor.parameters.scriptStorage.seatdata)
			elseif p.occupant[i].controls.altHandItem == "pvsoController" or p.occupant[i].controls.primaryHandItem == "pvsoSecretTrick" then
				p.mergeSeatData(seatname, p.occupant[i].controls.altHandItemDescriptor.parameters.scriptStorage.seatdata)
			else
				p.occupant[i].controls.shiftReleased = p.occupant[i].controls.shift
				p.occupant[i].controls.shift = 0
				p.loopedMessage(seatname.."Info", eid, "getVSOseatInformation", type, function(seatdata)
					p.mergeSeatData(seatname, seatdata)
				end)
				p.loopedMessage(seatname.."Equips", eid, "getVSOseatEquips", type, function(seatdata)
					p.mergeSeatData(seatname, seatdata)
				end)
			end
		end
	end
end

function p.mergeSeatData(seatname, seatdata)
	if seatdata ~= nil then
		for name, data in pairs(seatdata) do
			if data ~= nil then
				p.seats[seatname].controls[name] = data
			end
		end
	end
end

function p.updateDriving(dt)
	if p.driver then
		local light = p.vso.lights.driver
		light.position = world.entityPosition( p.driver )
		world.sendEntityMessage( p.driver, "PVSOAddLocalLight", light )

		local aim = vehicle.aimPosition(p.driverSeat)
		local cursor = "/cursors/cursors.png:pointer"
		world.sendEntityMessage( p.driver, "PVSOCursor", aim, cursor)
	end
	if p.standalone then
		if p.tapControl(p.driverSeat, "special3") then
			world.sendEntityMessage(
				p.driver, "openPVSOInterface", p.vso.menuName.."settings",
				{ vso = entity.id(), occupants = p.occupant, maxOccupants = p.vso.maxOccupants.total, powerMultiplier = p.seats[p.driverSeat].controls.powerMultiplier }, false, entity.id()
			)
		end
	end
	if p.tapControl(p.driverSeat, "special2") then
		p.doTransition("escape", {index = p.occupants.total})
	end

	if (p.stateconfig[p.state].control ~= nil) and not p.movementLock then
		local dx = p.seats[p.driverSeat].controls.dx
		local dy = p.seats[p.driverSeat].controls.dy
		local state = p.stateconfig[p.state]
		if (dx ~= 0) and (p.movement.aimingLock <= 0) and (p.underWater() or mcontroller.onGround()) then
			p.faceDirection( dx )
		end

		p.doClickActions(state, dt)
		p.groundMovement(dx, dy, state, dt)
		p.waterMovement(dx, dy, state, dt)
		p.jumpMovement(dx, dy, state, dt)
		p.airMovement(dx, dy, state, dt)
	end
	p.driverSeatStateChange()
end

function p.groundMovement(dx, dy, state, dt)
	p.movement.groundMovement = "run"
	if p.heldControl(p.driverSeat, "shift") or (p.occupants.mass > state.control.fullThreshold) then
		p.movement.groundMovement = "walk"
	end
	if mcontroller.onGround() then
		if dx ~= 0 and not state.control.groundMovementDisabled then
			p.doAnims( state.control.animations[p.movement.groundMovement] )
			p.movement.animating = true
			mcontroller.applyParameters{ groundFriction = p.movementParams.ambulatingGroundFriction }
			if (math.abs(mcontroller.xVelocity()) <= p.movementParams[p.movement.groundMovement.."Speed"]) or (not sameSign(mcontroller.xVelocity(), dx)) then
				mcontroller.force({ dx * p.movementParams.groundForce * (1 + dt), 0})
			end
		elseif p.movement.animating then
			p.doAnims( state.idle )
			p.movement.animating = false
			mcontroller.applyParameters{ groundFriction = p.movementParams.normalGroundFriction }
		end
		p.movement.jumps = 0
		p.movement.falling = false
		p.movement.airtime = 0
	end
end

function p.jumpMovement(dx, dy, state, dt)
	mcontroller.applyParameters{ ignorePlatformCollision = false }
	p.movement.sinceLastJump = p.movement.sinceLastJump + dt

	p.movement.jumpProfile = "airJumpProfile"
	if mcontroller.liquidPercentage() ~= 0 then
		p.movement.jumpProfile = "liquidJumpProfile"
	end

	if p.heldControl( p.driverSeat, "jump" ) then
		if (p.movement.jumps < p.movementParams.jumpCount) and (p.movement.sinceLastJump >= p.movementParams[p.movement.jumpProfile].reJumpDelay)
		and ((not p.movement.jumped) or p.movementParams[p.movement.jumpProfile].autoJump) and ((not p.underWater()) or mcontroller.onGround())
		then
			if state.control.jumpMovementDisabled then return end
			p.movement.sinceLastJump = 0
			p.movement.jumps = p.movement.jumps + 1
			p.movement.jumped = true
			if (dy ~= -1) then
				p.doAnims( state.control.animations.jump )
				p.movement.animating = true
				p.movement.falling = false
				mcontroller.setYVelocity(p.movementParams[p.movement.jumpProfile].jumpSpeed)
				if (p.movement.jumps > 1) and mcontroller.liquidPercentage() == 0 then
					-- particles from effects/multiJump.effectsource
					if state.control.pulseEffect then
						animator.burstParticleEmitter( state.control.pulseEffect )
						animator.playSound( "doublejump" )
						for i = 1, state.control.pulseSparkles do
							animator.burstParticleEmitter( "defaultblue" )
							animator.burstParticleEmitter( "defaultlightblue" )
						end
					end
				end
			end
		end
		if dy == -1 then
			mcontroller.applyParameters{ ignorePlatformCollision = true }
		elseif p.movement.jumped and p.seats[p.driverSeat].controls.jump < p.movementParams[p.movement.jumpProfile].jumpHoldTime and mcontroller.yVelocity() <= p.movementParams[p.movement.jumpProfile].jumpSpeed then
			mcontroller.force({0, p.movementParams[p.movement.jumpProfile].jumpControlForce * (1 + dt)})
		end
	else
		p.movement.jumped = false
	end
end

function p.airMovement( dx, dy, state, dt )
	if ((not p.underWater()) and (not mcontroller.onGround())) and not state.control.airMovementDisabled then
		p.movement.animating = true
		if math.abs(mcontroller.xVelocity()) <= p.movementParams[p.movement.groundMovement.."Speed"] then
			mcontroller.force({ dx * (p.movementParams.airForce * (dt + 1)), 0 })
		end

		if (mcontroller.yVelocity() <= p.movementParams.fallStatusSpeedMin ) and (not p.movement.falling) then
			p.doAnims( state.control.animations.fall )
			p.movement.falling = true
		elseif (mcontroller.yVelocity() > 0) and (p.movement.falling) then
			p.doAnims( state.control.animations.jump )
			p.movement.falling = false
		end
	end
end

function p.waterMovement( dx, dy, state, dt )
	if (p.underWater() and (not mcontroller.onGround())) and not state.control.waterMovementDisabled then
		local swimSpeed = p.movementParams.swimSpeed or p.movementParams[p.movement.groundMovement.."Speed"]
		local dy = dy
		if p.heldControl(p.driverSeat, "jump") and (dy ~= 1) then
			dy = dy + 1
		end
		if (dx ~= 0) or (dy ~= 0)then
			p.doAnims( state.control.animations.swim )
			if (dx ~= 0) and ((math.abs(mcontroller.xVelocity()) <= swimSpeed) or (not sameSign(mcontroller.xVelocity(), dx))) then
				mcontroller.force({ dx * p.movementParams.liquidForce * (1 + dt), 0})
			end
			if (dy ~= 0) and ((math.abs(mcontroller.yVelocity()) <= swimSpeed) or (not sameSign(mcontroller.yVelocity(), dy))) then
				mcontroller.force({ 0, dy * (p.movementParams.liquidJumpProfile.jumpControlForce or p.movementParams.airJumpProfile.jumpControlForce) * (1 + dt)})
			end
		else
			p.doAnims( state.control.animations.swimIdle )
		end
		p.movement.animating = true
		p.movement.jumps = 0
		p.movement.falling = false
		p.movement.airtime = 0
	end
end

p.clickActionCooldowns = {
	vore = 0
}

function p.doClickActions(state, dt)
	for name, cooldown in pairs(p.clickActionCooldowns) do
		p.clickActionCooldowns[name] = math.max( 0, cooldown - dt)
	end

	p.movement.aimingLock = p.movement.aimingLock - dt

	if (p.seats[p.driverSeat].controls.primaryHandItem == "pvsoController") and (p.seats[p.driverSeat].controls.primaryHandItemDescriptor.parameters.scriptStorage.clickActions ~= nil) then
		p.clickAction(state, p.seats[p.driverSeat].controls.primaryHandItemDescriptor.parameters.scriptStorage.clickActions.primaryFire, "primaryFire")
		p.clickAction(state, p.seats[p.driverSeat].controls.primaryHandItemDescriptor.parameters.scriptStorage.clickActions.altFire, "altFire")
	else
		p.clickAction(state, state.control.defaultActions[1], "primaryFire")
		p.clickAction(state, state.control.defaultActions[2], "altFire")
	end
end

function p.clickAction(stateData, name, control)
	if stateData.control.clickActions[name] == nil then return end
	if not p.clickActionCooldowns[name] then
		p.clickActionCooldowns[name] = 0
	end

	if p.clickActionCooldowns[name] > 0 then return end

	if (p.pressControl(p.driverSeat, control))
	or (p.heldControl(p.driverSeat, control) and stateData.control.clickActions[name].hold)
	then
		local continue = true
		if stateData.control.clickActions[name].script ~= nil and state[p.state][stateData.control.clickActions[name].script] ~= nil then
			continue = state[p.state][stateData.control.clickActions[name].script]()
		end
		if continue then
			p.clickActionCooldowns[name] = stateData.control.clickActions[name].cooldown or 0
		end
		if continue and stateData.control.clickActions[name].animation ~= nil then
			p.doAnims(stateData.control.clickActions[name].animation)
		end
		if continue and stateData.control.clickActions[name].projectile ~= nil then
			p.projectile(stateData.control.clickActions[name].projectile)
		end
	end
end

p.monsterstrugglecooldown = {}

function p.getSeatDirections(seatname)
	local occupantId = p.getEidFromSeatname(seatname)
	if not occupantId or not world.entityExists(occupantId) then return end

	if world.entityType( occupantId ) ~= "player" then
		if not p.monsterstrugglecooldown[seatname] or p.monsterstrugglecooldown[seatname] <= 0 then
			local randomDirections = { "back", "front", "up", "down", "jump", nil}
			p.monsterstrugglecooldown[seatname] = (math.random(10, 300)/100)
			return randomDirections[math.random(1,6)]
		else
			p.monsterstrugglecooldown[seatname] = p.monsterstrugglecooldown[seatname] - p.dt
			return
		end
	else
		local direction = p.relativeDirectionName(p.seats[seatname].controls.dx, p.seats[seatname].controls.dy)
		if direction then return direction end
		if p.seats[seatname].controls.jump > 0 then
			return "jump"
		end
	end
end

function p.relativeDirectionName(dx, dy)
	local dx = dx * p.direction
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
end

function getDriverStat(eid, stat, callback)
	p.addRPC( world.sendEntityMessage(eid, "getDriverStat", stat), callback)
end

function p.driverSeatStateChange()
	if p.movement.animating then return end
	local transitions = p.stateconfig[p.state].transitions
	local dx = 0
	local dy = 0
	if p.tapControl(p.driverSeat, "left") then
		dx = dx -1
	end
	if p.tapControl(p.driverSeat, "right") then
		dx = dx +1
	end
	if p.tapControl(p.driverSeat, "up") then
		dy = dy +1
	end
	if p.tapControl(p.driverSeat, "down") then
		dy = dy -1
	end
	local movedir = p.relativeDirectionName(dx, dy)

	if (movedir == nil) and p.tapControl(p.driverSeat, "jump") then
		movedir = "jump"
	end

	if movedir ~= nil then
		if transitions[movedir] ~= nil then
			p.doTransition(movedir)
		elseif (movedir == "front" or movedir == "back") and transitions.side ~= nil then
			p.doTransition("side")
		end
	end
end

function p.projectile( projectiledata )
	local driver = p.driver
	if projectiledata.energy and driver then
		p.useEnergy(driver, projectiledata.cost, function(energyUsed)
			if energyUsed then
				p.fireProjectile( projectiledata, driver )
			end
		end)
	else
		p.fireProjectile( projectiledata, driver )
	end
end

function p.fireProjectile( projectiledata, driver )
	local position = p.localToGlobal( projectiledata.position )
	local direction
	if projectiledata.aimable then
		p.movement.aimingLock = 0.1

		local aiming = p.seats[p.driverSeat].controls.aim
		p.facePoint( aiming[1] )
		position = p.localToGlobal( projectiledata.position )
		aiming[2] = aiming[2] + 0.2 * p.direction * (aiming[1] - position[1])
		direction = world.distance( aiming, position )
	else
		direction = { p.direction, 0 }
	end
	local params = {}

	if driver then
		params.powerMultiplier = p.seats[p.driverSeat].controls.powerMultiplier
		world.spawnProjectile( projectiledata.name, position, driver, direction, true, params )
	else
		params.powerMultiplier = p.standalonePowerLevel()
		world.spawnProjectile( projectiledata.name, position, entity.Id(), direction, true, params )
	end
end
