
function p.pressControl(seat, control)
	return (( controls[seat][control.."Released"] > 0 ) and ( controls[seat][control.."Released"] < 0.15 ))
end

function p.heldControl(seat, control, min)
	return controls[seat][control] > (min or 0)
end

function p.heldControlMax(seat, control, max)
	return controls[seat][control] < (max or 1)
end

function p.heldControlMinMax(seat, control, min, max)
	return p.heldControl(seat, control, min) and p.heldControlMax(seat, control, max)
end

function p.heldControls(seat, controlList, time)
	for _, control in pairs(controlList) do
		if controls[seat][control] <= (time or 0) then
			return false
		end
	end
	return true
end

function p.updateControl(seatname, control, dt, forceHold)
	if vehicle.controlHeld(seatname, control) or forceHold then
		controls[seatname][control] = controls[seatname][control] + dt
		controls[seatname][control.."Released"] = 0
	else
		controls[seatname][control.."Released"] = controls[seatname][control]
		controls[seatname][control] = 0
	end
end

function p.updateDirectionControl(seatname, control, direction, val, dt, forceHold)
	if vehicle.controlHeld(seatname, control) or forceHold then
		controls[seatname][control] = controls[seatname][control] + dt
		controls[seatname][direction] = controls[seatname][direction] + val
		controls[seatname][control.."Released"] = 0
	else
		controls[seatname][control.."Released"] = controls[seatname][control]
		controls[seatname][control] = 0
	end
end

function p.updateControls(dt)
	for seatname, seat in pairs(controls) do
		local lounging = vehicle.entityLoungingIn(seatname)
		if lounging ~= nil and world.entityExists(lounging) and not (seatname == p.driverSeat and p.isPathfinding) then
			seat.dx = 0
			seat.dy = 0
			p.updateDirectionControl(seatname, "left", "dx", -1, dt)
			p.updateDirectionControl(seatname, "right", "dx", 1, dt)
			p.updateDirectionControl(seatname, "down", "dy", -1, dt)
			p.updateDirectionControl(seatname, "up", "dy", 1, dt)
			p.updateControl(seatname, "jump", dt)
			p.updateControl(seatname, "special1", dt)
			p.updateControl(seatname, "special2", dt)
			p.updateControl(seatname, "special3", dt)

			seat.species = world.entitySpecies(lounging) or world.monsterType(lounging)

			seat.primaryHandItem = world.entityHandItem(lounging, "primary")
			seat.altHandItem = world.entityHandItem(lounging, "alt")
			seat.primaryHandItemDescriptor = world.entityHandItemDescriptor(lounging, "primary")
			seat.altHandItemDescriptor = world.entityHandItemDescriptor(lounging, "alt")

			local type = "prey"
			if p.driving and (seatname == p.driverSeat) then
				type = "driver"
			end
			if seat.primaryHandItem == "pvsoController" or seat.primaryHandItem == "pvsoSecretTrick" then
				if seat.primaryHandItemDescriptor.parameters.scriptStorage.seatdata ~= nil then
					controls[seatname] = sb.jsonMerge(seat, seat.primaryHandItemDescriptor.parameters.scriptStorage.seatdata)
				end
			elseif seat.altHandItem == "pvsoController" or seat.primaryHandItem == "pvsoSecretTrick" then
				if seat.altHandItemDescriptor.parameters.scriptStorage.seatdata ~= nil then
					controls[seatname] = sb.jsonMerge(seat, seat.altHandItemDescriptor.parameters.scriptStorage.seatdata)
				end
			else
				seat.shiftReleased = seat.shift
				seat.shift = 0
				p.addRPC(world.sendEntityMessage(vehicle.entityLoungingIn(seatname), "getVSOseatInformation", type), function(seatdata)
					if seatdata ~= nil then
						controls[seatname] = sb.jsonMerge(seat, seatdata)
					end
				end)
				p.addRPC(world.sendEntityMessage(vehicle.entityLoungingIn(seatname), "getVSOseatEquips", type), function(seatdata)
					if seatdata ~= nil then
						controls[seatname] = sb.jsonMerge(seat, seatdata)
					end
				end)
			end
		else
			seat = p.clearSeat
		end
	end
end

function p.updateDriving(dt)
	if driver then
		local light = p.vso.lights.driver
		light.position = world.entityPosition( driver )
		world.sendEntityMessage( driver, "PVSOAddLocalLight", light )

		local aim = vehicle.aimPosition(p.driverSeat)
		local cursor = "/cursors/cursors.png:pointer"
		world.sendEntityMessage( driver, "PVSOCursor", aim, cursor)
	end

	if p.standalone then
		p.driving = true
		if p.pressControl(p.driverSeat, "special3") then
			world.sendEntityMessage(
				vehicle.entityLoungingIn( p.driverSeat ), "openPVSOInterface", p.vso.menuName.."settings",
				{ vso = entity.id(), occupants = p.getSettingsMenuInfo(), maxOccupants = p.vso.maxOccupants.total }, false, entity.id()
			)
		end
	end

	local dx = controls[p.driverSeat].dx
	local dy = controls[p.driverSeat].dy
	local state = p.stateconfig[p.state]
	if dx ~= 0 then
		p.faceDirection( dx )
	end
	if p.stateconfig[p.state].control ~= nil then
		p.groundMovement(dx, dy, state, dt)
		p.waterMovement(dx, dy, state, dt)
		p.jumpMovement(dx, dy, state, dt)
		p.airMovement(dx, dy, state, dt)
	end
end

function p.groundMovement(dx, dy, state, dt)
	p.movement.groundMovement = "walk"
	if not p.heldControl(p.driverSeat, "shift") and p.occupants.mass < state.control.fullThreshold then
		p.movement.groundMovement = "run"
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
	mcontroller.applyParameters{ ignorePlatformCollision = p.movementParams.ignorePlatformCollision }
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
					animator.burstParticleEmitter( state.control.pulseEffect )
					animator.playSound( "doublejump" )
					for i = 1, state.control.pulseSparkles do
						animator.burstParticleEmitter( "defaultblue" )
						animator.burstParticleEmitter( "defaultlightblue" )
					end
				end
			end
		end
		if dy == -1 then
			mcontroller.applyParameters{ ignorePlatformCollision = true }
		elseif p.movement.jumped and controls[p.driverSeat].jump < p.movementParams[p.movement.jumpProfile].jumpHoldTime and mcontroller.yVelocity() <= p.movementParams[p.movement.jumpProfile].jumpSpeed then
			mcontroller.force({0, p.movementParams[p.movement.jumpProfile].jumpControlForce * (1 + dt)})
		end
	else
		p.movement.jumped = false
	end
end

function p.airMovement( dx, dy, state, dt )
	if ((not p.underWater()) and (not mcontroller.onGround())) and not state.control.airMovementDiabled then
		p.movement.animating = true
		mcontroller.force({ dx * (p.movementParams.airForce * (dt + 1)), 0 })

		if (mcontroller.yVelocity() <= p.movementParams.fallStatusSpeedMin ) and (not p.movement.falling) then
			p.doAnims( state.control.animations.fall )
			p.movement.falling = true
		elseif (mcontroller.yVelocity() > 0) and (p.movement.falling) then
			p.doAnims( state.control.animations.jump )
			p.movement.falling = false
		end
	end
end

function sameSign(num1, num2)
	if num1 <= 0 and num2 <= 0 then
		return true
	elseif num1 >=0 and num2 >=0 then
		return true
	else
		return false
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

function p.primaryAction()
	local control = p.stateconfig[p.state].control
	if control.primaryAction ~= nil and vehicle.controlHeld( p.driverSeat, "PrimaryFire" ) then
		if p.movement.primaryCooldown < 1 then
			if control.primaryAction.projectile ~= nil then
				p.projectile(control.primaryAction.projectile)
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

function p.altAction()
	local control = p.stateconfig[p.state].control
	if control.altAction ~= nil and vehicle.controlHeld( p.driverSeat, "altFire" ) then
		if p.movement.altCooldown < 1 then
			if control.altAction.projectile ~= nil then
				p.projectile(control.altAction.projectile)
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

p.monsterstrugglecooldown = {}

function p.getSeatDirections(seatname)
	local occupantId = vehicle.entityLoungingIn(seatname)
	if not occupantId or not world.entityExists(occupantId) then return end

	if world.entityType( occupantId ) ~= "player" then
		if not p.monsterstrugglecooldown[seatname] or p.monsterstrugglecooldown[seatname] <= 0 then
			local randomDirections = { "back", "front", "up", "down", "jump", nil}
			p.monsterstrugglecooldown[seatname] = (math.random(100, 1000)/100)
			return randomDirections[math.random(1,6)]
		else
			p.monsterstrugglecooldown[seatname] = p.monsterstrugglecooldown[seatname] - p.dt
			return
		end
	else
		local direction = p.relativeDirectionName(controls[seatname].dx, controls[seatname].dy)
		if diretion then return direction end
		if controls[seatname].jump > 0 then
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
	p.addRPC( world.sendEntityMessage(eid, "getDriverStat", stat), callback, "getDriver"..stat)
end

function p.driverSeatStateChange()
	local transitions = p.stateconfig[p.state].transitions
	local dx = 0
	local dy = 0
	if p.pressControl(p.driverSeat, "left") then
		dx = dx -1
	end
	if p.pressControl(p.driverSeat, "right") then
		dx = dx +1
	end
	if p.pressControl(p.driverSeat, "up") then
		dy = dy +1
	end
	if p.pressControl(p.driverSeat, "down") then
		dy = dy -1
	end
	local movedir = p.relativeDirectionName(dx, dy)

	if (movedir == nil) and p.pressControl(p.driverSeat, "jump") then
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
	local driver = vehicle.entityLoungingIn(p.driverSeat)
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
		local aiming = vehicle.aimPosition( p.driverSeat )
		vsoFacePoint( aiming[1] )
		position = p.localToGlobal( projectiledata.position )
		aiming[2] = aiming[2] + 0.2 * p.direction * (aiming[1] - position[1])
		direction = world.distance( aiming, position )
	else
		direction = { p.direction, 0 }
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
