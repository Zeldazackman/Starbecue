
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
		if vehicle.controlHeld( p.driverSeat, "Special3" ) then
			world.sendEntityMessage(
				vehicle.entityLoungingIn( p.driverSeat ), "openInterface", p.vso.menuName.."settings",
				{ vso = entity.id(), occupants = getSettingsMenuInfo(), maxOccupants = p.vso.maxOccupants.total }, false, entity.id()
			)
		end
	elseif p.occupants.total >= 1 then
		if vehicle.controlHeld( p.driverSeat, "Special1" ) then
			p.driving = true
		end
		if vehicle.controlHeld( p.driverSeat, "Special2" ) then
			p.driving = false
		end
	else
		p.driving = false
	end
end

function p.drive()
	if (not p.driving) or (not p.stateconfig[p.state].control) then return end
	local control = p.stateconfig[p.state].control
	if control.animations == nil then control.animations = {} end -- allow indexing

	local dx = 0
	if vehicle.controlHeld( p.driverSeat, "left" ) then
		dx = dx - 1
	end
	if vehicle.controlHeld( p.driverSeat, "right" ) then
		dx = dx + 1
	end
	mcontroller.approachXVelocity( dx * control.swimSpeed, 50 )
	if p.probablyOnGround() then
		p.groundMovement( dx )
	elseif p.underWater() then
		p.waterMovement( dx )
	else
		p.airMovement( dx )
	end

	p.primaryAction()
	p.altAction()
end

function p.groundMovement( dx )
	local state = p.stateconfig[p.state]
	local control = state.control

	local running = false
	if not vehicle.controlHeld( p.driverSeat, "down" ) and (p.occupants.total)< control.fullThreshold then
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
				if p.occupants.weight < control.fullThreshold then
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
	if not vehicle.controlHeld( p.driverSeat, "down" ) and (p.occupants.weight < control.fullThreshold) then
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
			if p.occupants.weight < control.fullThreshold then
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


function p.getSeatDirections(seatname)
	local occupantId = vehicle.entityLoungingIn(seatname)
	if not occupantId or not world.entityExists(occupantId) then return end

	if world.entityType( occupantId ) ~= "player" then
		if not p.monsterstrugglecooldown[seatname] or p.monsterstrugglecooldown[seatname] < 1 then
			local movedir = randomDirections[math.random(1,6)]
			p.monsterstrugglecooldown[seatname] = math.random(1, 30)
			return movedir
		else
			p.monsterstrugglecooldown[seatname] = p.monsterstrugglecooldown[seatname] - 1
			return
		end
	else
		local dx = 0
		local dy = 0
		if vehicle.controlHeld( seatname, "left" ) then
			dx = dx - 1
		end
		if vehicle.controlHeld( seatname, "right" ) then
			dx = dx + 1
		end
		if vehicle.controlHeld( seatname, "down" ) then
			dy = dy - 1
		end
		if vehicle.controlHeld( seatname, "up" ) then
			dy = dy + 1
		end

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

		if vehicle.controlHeld( seatname, "jump" ) then
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
