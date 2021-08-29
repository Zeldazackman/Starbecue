
function p.updateDriving()
	local driver = vehicle.entityLoungingIn(p.driverSeat)
	if driver then
		local light = p.vso.lights.driver
		light.position = world.entityPosition( driver )
		world.sendEntityMessage( driver, "PVSOAddLocalLight", light )
		local aim = vehicle.aimPosition(p.driverSeat)
		local cursor = "/cursors/cursors.png:pointer"

		world.sendEntityMessage( driver, "PVSOCursor", aim, cursor)
	end

	if p.standalone then
		--vsoVictimAnimSetStatus( "driver", { "breathprotectionvehicle" } )
		p.driving = true
		if controls[p.driverSeat].special3 > 0 then
			world.sendEntityMessage(
				vehicle.entityLoungingIn( p.driverSeat ), "openPVSOInterface", p.vso.menuName.."settings",
				{ vso = entity.id(), occupants = p.getSettingsMenuInfo(), maxOccupants = p.vso.maxOccupants.total }, false, entity.id()
			)
		end
	elseif p.occupants.total >= 1 then
		if controls[p.driverSeat].special1 > 0 then
			p.driving = true
		end
		if controls[p.driverSeat].special2 > 0 then
			p.driving = false
		end
	else
		p.driving = false
	end
end

function p.drive()
	if (not p.driving) or (not p.stateconfig[p.state].control) then return end


end

function p.updateControls(dt)
	for seatname, seat in pairs(controls) do
		local lounging = vehicle.entityLoungingIn(seatname)

		if lounging ~= nil and world.entityExists(lounging) then
			local dx = 0
			local dy = 0
			if vehicle.controlHeld(seatname, "left") then
				seat.left = seat.left + dt
				dx = dx -1
			else
				seat.left = 0
			end
			if vehicle.controlHeld(seatname, "right") then
				seat.right = seat.right + dt
				dx = dx +1
			else
				seat.right = 0
			end
			if vehicle.controlHeld(seatname, "up") then
				seat.up = seat.up + dt
				dy = dy +1
			else
				seat.up = 0
			end
			if vehicle.controlHeld(seatname, "down") then
				seat.down = seat.down + dt
				dy = dy -1
			else
				seat.down = 0
			end
			if vehicle.controlHeld(seatname, "jump") then
				seat.jump = seat.jump + dt
			else
				seat.jump = 0
			end
			if vehicle.controlHeld(seatname, "special1") then
				seat.special1 = seat.special1 + dt
			else
				seat.special1 = 0
			end
			if vehicle.controlHeld(seatname, "special2") then
				seat.special2 = seat.special2 + dt
			else
				seat.special2 = 0
			end
			if vehicle.controlHeld(seatname, "special3") then
				seat.special3 = seat.special3 + dt
			else
				seat.special3 = 0
			end
			seat.dx = dx
			seat.dy = dy
			p.addRPC(world.sendEntityMessage(vehicle.entityLoungingIn(seatname), "getVSOseatInformation"), function(seatdata)
				for index, data in pairs(seatdata) do
					seat[index] = data
				end
			end, seatname.."Info")
		else
			seat = p.clearSeat
		end
	end
end

function p.groundMovement( dx )
	local state = p.stateconfig[p.state]
	local control = state.control

	local running = false
	if not (controls[p.driverSeat].down > 0) and (p.occupants.total)< control.fullThreshold then
		running = true
	end
	if dx ~= 0 then
		p.faceDirection( dx )
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
	if vehicle.controlHeld( p.driverSeat, "jump" ) then
		if not vehicle.controlHeld( p.driverSeat, "down" ) then
			if not p.movement.jumped then
				p.doAnims( control.animations.jump )
				p.movement.animating = true
				if p.occupants.mass < control.fullThreshold then
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

function p.waterMovement( dx )
	local control = p.stateconfig[p.state].control

	if dx ~= 0 then
		p.faceDirection( dx )
	end
	mcontroller.approachXVelocity( dx * control.swimSpeed, 50 )

	if vehicle.controlHeld( p.driverSeat, "jump" ) then
		mcontroller.approachYVelocity( 10, 50 )
	else
		mcontroller.approachYVelocity( -10, 50 )
	end

	if vehicle.controlHeld( p.driverSeat, "jump" )
	-- or vehicle.controlHeld( p.driverSeat, "down" )
	or vehicle.controlHeld( p.driverSeat, "left" )
	or vehicle.controlHeld( p.driverSeat, "right" ) then
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

function p.airMovement( dx )
	local control = p.stateconfig[p.state].control

	local running = false
	if not vehicle.controlHeld( p.driverSeat, "down" ) and (p.occupants.mass < control.fullThreshold) then
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

	if vehicle.controlHeld( p.driverSeat, "down" ) then
		mcontroller.applyParameters{ ignorePlatformCollision = true }
	else
		mcontroller.applyParameters{ ignorePlatformCollision = false }
	end
	if mcontroller.yVelocity() > 0 and vehicle.controlHeld( p.driverSeat, "jump" ) then
		mcontroller.approachYVelocity( -100, world.gravity(mcontroller.position()) )
	else
		mcontroller.approachYVelocity( -200, 2 * world.gravity(mcontroller.position()) )
	end
	if vehicle.controlHeld( p.driverSeat, "jump" ) then
		if not p.movement.jumped and p.movement.jumps < control.jumpCount then
			p.doAnims( control.animations.jump )
			p.movement.animating = true
			if p.occupants.mass < control.fullThreshold then
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
		local dx = controls[seatname].dx
		local dy = controls[seatname].dy
		dx = dx * p.direction

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

		if controls[seatname].jump > 0 then
			return "jump"
		end
	end
end

function getDriverStat(eid, stat, callback)
	p.addRPC( world.sendEntityMessage(eid, "getDriverStat", stat), callback)
end

function p.driverSeatStateChange()
	local transitions = p.stateconfig[p.state].transitions
	local movedir = p.getSeatDirections( p.driverSeat )
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
