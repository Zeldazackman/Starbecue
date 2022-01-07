
function p.updateDriving(dt)
	if p.driver and p.driving then
		local light = p.sbqData.lights.driver
		if light ~= nil then
			light.position = world.entityPosition( p.driver )
			world.sendEntityMessage( p.driver, "sbqLight", light )
		end

		p.predHudOpen = math.max( 0, p.predHudOpen - dt )
		if p.predHudOpen <= 0 then
			p.predHudOpen = 2
			world.sendEntityMessage( p.driver, "sbqOpenMetagui", "starbecue:predHud", entity.id())
		end

		local aim = vehicle.aimPosition(p.driverSeat)
		local cursor = "/cursors/cursors.png:pointer"
		world.sendEntityMessage( p.driver, "sbqDrawCursor", aim, cursor)
	end
	if p.pressControl(p.driverSeat, "special2") then
		p.letout(p.occupant[p.occupants.total].id)
	end

	if not mcontroller.onGround() and not p.underWater() then
		p.movement.airtime = p.movement.airtime + dt
	end

	local state = p.stateconfig[p.state]
	p.doClickActions(state, dt)

	p.movement.aimingLock = math.max(0, p.movement.aimingLock - dt)
	if (p.stateconfig[p.state].control ~= nil) and not p.movementLock then
		local dx = p.seats[p.driverSeat].controls.dx
		if p.activeControls.moveDirection then
			dx = p.activeControls.moveDirection
		end
		local dy = p.seats[p.driverSeat].controls.dy
		if (dx ~= 0) then
			if (p.movement.aimingLock <= 0) then
				p.faceDirection( dx )
			end
			p.setPartTag( "global","direction", p.direction * dx)
		end

		if p.stateconfig[p.state].defaultActions ~= nil and p.driver ~= nil then
			p.loopedMessage("primaryItemData", p.driver, "primaryItemData", {{
				defaultClickAction = p.stateconfig[p.state].defaultActions[1]
			}})
			p.loopedMessage("altItemData", p.driver, "altItemData", {{
				defaultClickAction = p.stateconfig[p.state].defaultActions[2]
			}})
		end

		p.groundMovement(dx, dy, state, dt)
		p.waterMovement(dx, dy, state, dt)
		p.jumpMovement(dx, dy, state, dt)
		p.airMovement(dx, dy, state, dt)
		p.flyMovement(dx, dy, state, dt)
		p.doControls() -- set by mcontroller.control*(), used by pathfinding
	end
	p.driverSeatStateChange()
end

function p.groundMovement(dx, dy, state, dt)
	p.movement.groundMovement = "run"
	if p.heldControl(p.driverSeat, "shift") or (p.occupants.mass >= (p.movementParams.fullThreshold or 1)) or (p.activeControls.run == false) then
		p.movement.groundMovement = "walk"
	end
	if mcontroller.onGround() and not p.movement.flying then
		if dx ~= 0 and not state.control.groundMovementDisabled then
			p.movingDX = dx
			p.doAnims( state.control.animations[p.movement.groundMovement] )
			p.movement.animating = true
			mcontroller.applyParameters{ groundFriction = p.movementParams.ambulatingGroundFriction }
			mcontroller.approachXVelocity( dx * p.movementParams[p.movement.groundMovement.."Speed"], p.movementParams.groundForce * p.movementParams.mass)
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
	p.movement.sinceLastJump = p.movement.sinceLastJump + dt

	if not mcontroller.onGround() and (dy == -1 or p.activeControls.drop) then
		mcontroller.applyParameters{ ignorePlatformCollision = true }
	elseif p.isPathfinding and p.pathMover.downHoldTimer2 and p.pathMover.downHoldTimer2 > 0 then
		p.pathMover.downHoldTimer2 = p.pathMover.downHoldTimer2 - dt
	else
		mcontroller.applyParameters{ ignorePlatformCollision = false }
	end

	p.movement.jumpProfile = "airJumpProfile"
	if mcontroller.liquidPercentage() ~= 0 then
		p.movement.jumpProfile = "liquidJumpProfile"
	end

	if state.control.jumpMovementDisabled or p.movement.flying then return end

	if p.heldControl( p.driverSeat, "jump" ) or p.activeControls.drop then
		if (p.movement.jumps < p.movementParams.jumpCount) and (p.movement.sinceLastJump >= p.movementParams[p.movement.jumpProfile].reJumpDelay)
		and ((not p.movement.jumped) or p.movementParams[p.movement.jumpProfile].autoJump) and ((not p.underWater()) or mcontroller.onGround()) and not p.activeControls.drop
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
					if p.movementParams.pulseEffect then
						animator.burstParticleEmitter( p.movementParams.pulseEffect )
						animator.playSound( "doublejump" )
						for i = 1, p.movementParams.pulseSparkles do
							animator.burstParticleEmitter( "defaultblue" )
							animator.burstParticleEmitter( "defaultlightblue" )
						end
					end
				end
			end
		end
		if dy == -1 or p.activeControls.drop then
			mcontroller.applyParameters{ ignorePlatformCollision = true }
		elseif p.movement.jumped and p.seats[p.driverSeat].controls.jump <= (p.movementParams[p.movement.jumpProfile].jumpHoldTime) and mcontroller.yVelocity() <= p.movementParams[p.movement.jumpProfile].jumpSpeed then
			mcontroller.force({ 0, p.movementParams[p.movement.jumpProfile].jumpControlForce * p.movementParams.mass})
		end
	else
		p.movement.jumped = false
	end
end

function p.airMovement( dx, dy, state, dt )
	if p.underWater() or mcontroller.onGround() or state.control.airMovementDisabled or p.movement.flying then return end

	p.movement.animating = true

	if dx ~= 0 then
		mcontroller.approachXVelocity( dx * p.movementParams[p.movement.groundMovement.."Speed"], p.movementParams.airForce * p.movementParams.mass)
	end

	if (mcontroller.yVelocity() < p.movementParams.fallStatusSpeedMin ) and (not p.movement.falling) and p.movement.airtime >= 0.25 then
		p.doAnims( state.control.animations.fall )
		p.movement.falling = true
	elseif (mcontroller.yVelocity() > 0) and (p.movement.falling) then
		p.doAnims( state.control.animations.jump )
		p.movement.falling = false
	end
end

function p.waterMovement( dx, dy, state, dt )
	if not p.underWater() or mcontroller.onGround() or state.control.waterMovementDisabled then return end

	local swimSpeed = p.movementParams.swimSpeed or p.movementParams[p.movement.groundMovement.."Speed"]
	local dy = dy
	if p.heldControl(p.driverSeat, "jump") and (dy ~= 1) then
		dy = dy + 1
	end
	if (dx ~= 0) or (dy ~= 0)then
		p.doAnims( state.control.animations.swim )
		if (dx ~= 0) then
			mcontroller.approachXVelocity( dx * p.movementParams[p.movement.groundMovement.."Speed"], p.movementParams.liquidForce * p.movementParams.mass)
		end
		if (dy ~= 0) then
			mcontroller.approachYVelocity( dy * p.movementParams.liquidJumpProfile.jumpSpeed or p.movementParams.airJumpProfile.jumpSpeed, (p.movementParams.liquidJumpProfile.jumpControlForce or p.movementParams.airJumpProfile.jumpControlForce) * p.movementParams.mass)
		end
	else
		p.doAnims( state.control.animations.swimIdle )
	end
	p.movement.animating = true
	p.movement.jumps = 0
	p.movement.falling = false
	p.movement.airtime = 0
end

function p.flyMovement( dx, dy, state, dt )
	if p.movementParams.flySpeed == 0 or state.control.flyMovementDisabled or mcontroller.onGround() or p.underWater() or not p.movement.flying then return end

	p.doAnims( state.control.animations.fly )
	mcontroller.approachXVelocity( dx * p.movementParams.flySpeed, p.movementParams.airForce * p.movementParams.mass)
	mcontroller.approachYVelocity( dy * p.movementParams.flySpeed, p.movementParams.airForce * p.movementParams.mass)
	p.movement.animating = true

end

p.clickActionCooldowns = {
	vore = 0
}

function p.doClickActions(state, dt)
	for name, cooldown in pairs(p.clickActionCooldowns) do
		p.clickActionCooldowns[name] = math.max( 0, cooldown - dt)
	end

	if p.heldControl(p.driverSeat, "special1", 0.2) and p.totalTimeAlive > 1 then
		if not p.movement.assignClickActionRadial then
			p.movement.assignClickActionRadial = true
			p.assignClickActionMenu(state)
		else
			p.loopedMessage("radialSelection", p.driver, "sbqGetRadialSelection", {}, function(data)

				if data.selection ~= nil and data.type == "actionSelect" then
					p.lastRadialSelection = data.selection
					if data.selection == "cancel" or data.selection == "despawn" then return end
					if data.button == 0 and data.pressed and not p.click then
						p.click = true
						if p.grabbing ~= nil then
							p.uneat(p.grabbing)
							local victim = p.grabbing
							p.grabbing = nil
							p.doTransition(data.selection, { id = victim })
							return
						elseif p.seats[p.driverSeat].controls.primaryHandItem == "sbqController" then
							world.sendEntityMessage(p.driver, "primaryItemData", {assignClickAction = data.selection})
						elseif p.seats[p.driverSeat].controls.primaryHandItem == nil then
							world.sendEntityMessage(p.driver, "sbqGiveItem", {
								name = "sbqController",
								parameters = { scriptStorage = { clickAction = data.selection } }
							})
						end
					elseif data.button == 2 and data.pressed and not p.click then
						p.click = true
						if p.grabbing ~= nil then
							p.uneat(p.grabbing)
							local victim = p.grabbing
							p.grabbing = nil
							p.doTransition(data.selection, { id = victim })
							return
						elseif p.seats[p.driverSeat].controls.altHandItem == "sbqController" then
							world.sendEntityMessage(p.driver, "altItemData", {assignClickAction = data.selection})
						elseif p.seats[p.driverSeat].controls.altHandItem == nil then
							world.sendEntityMessage(p.driver, "sbqGiveItem", {
								name = "sbqController",
								parameters = { scriptStorage = { clickAction = data.selection } }
							})
						end
					elseif not data.pressed then
						p.click = false
					end
				end
			end)
		end
	elseif p.movement.assignClickActionRadial then
		world.sendEntityMessage( p.driver, "sbqOpenInterface", "sbqClose" )
		if p.lastRadialSelection == "despawn" then
			p.onDeath()
		elseif p.lastRadialSelection ~= "cancel" and p.lastRadialSelection ~= nil then
			if p.grabbing ~= nil then
				p.uneat(p.grabbing)
				local victim = p.grabbing
				p.grabbing = nil
				p.doTransition(p.lastRadialSelection, { id = victim })
				return
			else
				p.action(state, p.lastRadialSelection, "force")
			end
		end
		p.movement.assignClickActionRadial = nil
	end

	if p.grabbing ~= nil then p.handleGrab() return end

	if (p.seats[p.driverSeat].controls.primaryHandItem ~= nil) and (not p.seats[p.driverSeat].controls.primaryHandItem == "sbqController") and (p.seats[p.driverSeat].controls.primaryHandItemDescriptor.parameters.itemHasOverrideLockScript) then
		p.action(state, (state.defaultActions or {})[1], "primaryFire")
		p.action(state, (state.defaultActions or {})[2], "altFire")
	else
		if (p.seats[p.driverSeat].controls.primaryHandItem == "sbqController") then
			local action = p.seats[p.driverSeat].controls.primaryHandItemDescriptor.parameters.scriptStorage.clickAction
			if not action or action == "unassigned" then
				action = (state.defaultActions or {})[1]
			end
			p.action(state, action, "primaryFire")
		elseif (p.seats[p.driverSeat].controls.primaryHandItem == nil) then
			p.action(state, (state.defaultActions or {})[1], "primaryFire")
		end

		if (p.seats[p.driverSeat].controls.altHandItem == "sbqController") then
			local action = p.seats[p.driverSeat].controls.altHandItemDescriptor.parameters.scriptStorage.clickAction
			if not action or action == "unassigned" then
				action = (state.defaultActions or {})[2]
			end
			p.action(state, action, "altFire")
		elseif (p.seats[p.driverSeat].controls.altHandItem == nil) then
			p.action(state, (state.defaultActions or {})[2], "altFire")
		end
	end
end

function p.action(stateData, name, control)
	if name == nil or (stateData.actions or {})[name] == nil then return end
	if not p.clickActionCooldowns[name] then
		p.clickActionCooldowns[name] = 0
	end

	if p.clickActionCooldowns[name] > 0 then return end

	if control == "force" or (p.pressControl(p.driverSeat, control))
	or (p.heldControl(p.driverSeat, control) and stateData.actions[name].hold)
	then
		p.clickActionCooldowns[name] = stateData.actions[name].cooldown or 0
		if stateData.actions[name].script ~= nil then
			if state[p.state][stateData.actions[name].script] ~= nil then
				if not state[p.state][stateData.actions[name].script]() then return end
			else
				sb.logError("no script named: ["..stateData.actions[name].script.."] in state: ["..p.state.."]")
			end
		end
		p.doTransition(stateData.actions[name].transition)
		if stateData.actions[name].animation ~= nil then
			p.doAnims(stateData.actions[name].animation)
		end
		if stateData.actions[name].projectile ~= nil then
			p.projectile(stateData.actions[name].projectile)
		end
	end
end

function p.assignClickActionMenu(state)
	local options = {}
	table.insert(options, {
			name = "despawn",
			icon = "/interface/xhover.png"
		})
	table.insert(options, {
			name = "unassigned",
			icon = "/items/active/sbqController/unassigned.png"
		})
	for action, data in pairs((state.actions or {})) do
		table.insert(options, {
			name = action,
			icon = data.icon or ("/items/active/sbqController/"..action..".png")
		})
	end

	world.sendEntityMessage( p.driver, "sbqOpenInterface", "sbqRadialMenu", {options = options, type = "actionSelect" }, true )
end

function p.checkValidAim(seat, range)
	local entityaimed = world.entityQuery(p.seats[seat].controls.aim, range or 2, {
		withoutEntityId = p.driver,
		includedTypes = {"creature"}
	})
	local target = p.firstNotLounging(entityaimed)

	if target and target ~= entity.id() and entity.entityInSight(target) then
		return target
	end
end

function p.checkEatPosition(position, range, location, transition, noaim, aimrange)
	if not p.locationFull(location) then
		local target = p.checkValidAim(p.driverSeat, aimrange)

		local prey = world.entityQuery(position, range, {
			withoutEntityId = p.driver,
			includedTypes = {"creature"}
		})

		for _, entity in ipairs(prey) do
			if (noaim or (entity == target)) and not p.entityLounging(entity) then
				p.doTransition( transition, {id=entity} )
				return true
			end
		end
		return false
	end
end

function getDriverStat(eid, stat, callback)
	p.addRPC( world.sendEntityMessage(eid, "sbqGetDriverStat", stat), callback)
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
		world.spawnProjectile( projectiledata.name, position, driver, direction, projectiledata.relative, params )
	else
		params.powerMultiplier = p.objectPowerLevel()
		world.spawnProjectile( projectiledata.name, position, entity.id(), direction, projectiledata.relative, params )
	end
end

function p.grab(location, aimrange, grabrange)
	local target = p.checkValidAim(p.driverSeat, aimrange or 2)
	if target then
		p.addRPC(world.sendEntityMessage(target, "sbqIsPreyEnabled", "held"), function(enabled)
			if enabled then
				local prey = world.entityQuery(mcontroller.position(), grabrange or 5, {
					withoutEntityId = p.driver,
					includedTypes = {"creature"}
				})
				for _, entity in ipairs(prey) do
					if entity == target then
						if p.eat(target, location) then
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

function p.letGrabGo(location)
	local victim = p.findFirstOccupantIdForLocation(location)
	p.grabbing = nil
	p.armRotation.enabledL = false
	p.armRotation.enabledR = false
	p.armRotation.groupsR = {}
	p.armRotation.groupsL = {}
	p.armRotation.occupantL = nil
	p.armRotation.occupantR = nil
	p.uneat(victim)
end
