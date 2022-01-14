
function p.updateAnims(dt)
	for statename, state in pairs(p.animStateData) do
		state.animationState.time = state.animationState.time + dt
	end

	for i = 0, p.occupantSlots do
		p.victimAnimUpdate(p.occupant[i].id)
		p.updateVisibilityAndSmolprey(i)
	end
	p.offsetAnimUpdate()
	p.rotationAnimUpdate()

	p.emoteCooldown =  math.max( 0, p.emoteCooldown - dt )

	for statename, state in pairs(p.animStateData) do
		if state.animationState.time >= state.animationState.cycle then
			p.endAnim(state, statename)
		end
	end
end

function p.endAnim(state, statename)
	for _, func in pairs(p.animFunctionQueue[statename]) do
		func()
	end
	p.animFunctionQueue[statename] = {}

	if (state.tag ~= nil) and state.tag.reset then
		if state.tag.part == "global" then
			p.setPartTag( "global", state.tag.name, "" )
		else
			p.setPartTag( state.tag.part, state.tag.name, "" )
		end
		state.tag = nil
	end
end

p.armRotation = {
	target = {0,0},
	enabledR = false,
	enabledL = false,
	groupsR = {},
	groupsL = {},
	occupantR = nil,
	occupantL = nil,
	backarmsAngle = 0,
	frontarmsAngle = 0
}
function p.armRotationUpdate()
	p.setGrabTarget()

	if p.armRotation.enabledR or p.armRotation.enabledL then
		p.movement.aimingLock = 0.1
		local LR = "L"
		if p.direction > 0 then
			LR = "R"
		end

		p.faceDirection(p.armRotation["target"..LR][1]*p.direction)
	end
	if p.direction > 0 then
		p.rotateArm( p.armRotation.enabledL, "backarms", "L")
		p.rotateArm( p.armRotation.enabledR, "frontarms", "R")
	else
		p.rotateArm( p.armRotation.enabledR, "backarms", "R")
		p.rotateArm( p.armRotation.enabledL, "frontarms", "L")
	end
end

function p.rotateArm(enabled, arm, LR)
	if enabled then
		animator.setAnimationState(arm.."_rotationState", p.stateconfig[p.state].rotationArmState or "rotation", true )


		local occupantId = p.armRotation["occupant"..LR]
		local groups = p.armRotation["groups"..LR]

		local center = {(p.stateconfig[p.state].rotationCenters[arm][1] or 0) / 8, (p.stateconfig[p.state].rotationCenters[arm][2] or 0) / 8}
		local handOffset = {(p.stateconfig[p.state].handOffsets[arm][1] or 0) / 8, (p.stateconfig[p.state].handOffsets[arm][2] or 0) / 8}

		local target = p.armRotation["target"..LR]
		if target ~= nil then
			local angle = math.atan((target[2] - center[2]), (target[1] - center[1]))

			p.armRotation[arm.."Angle"] = angle
			p.armRotation["armAngle"..LR] = angle
		end

		p.resetTransformationGroup(arm.."rotation")
		p.rotateTransformationGroup(arm.."rotation", p.armRotation[arm.."Angle"], center)

		for i, group in ipairs(groups) do
			p.resetTransformationGroup(group)
			p.translateTransformationGroup(group, handOffset, true)
			p.rotateTransformationGroup(group, p.armRotation[arm.."Angle"], center)
		end

		if occupantId ~= nil and p.lounging[occupantId] ~= nil then
			local victimAnim = p.lounging[occupantId].victimAnim
			victimAnim.last.x = math.cos(p.armRotation[arm.."Angle"]) * handOffset[1]
			victimAnim.last.y = math.sin(p.armRotation[arm.."Angle"]) * handOffset[2]
		end

		p.setPartTag( arm, "armVisible", "?multiply=FFFFFF00" )
		p.setPartTag( arm.."_rotation", "armVisible", "" )
	else
		p.setPartTag( arm, "armVisible", "" )
		p.setPartTag( arm.."_rotation", "armVisible", "?multiply=FFFFFF00" )
	end
end

function p.setGrabTarget()
	local controls = p.seats[p.driverSeat].controls
	if p.driver and (not (((controls.primaryHandItem == "sbqController") or (controls.altHandItem == "sbqController"))
	or ((controls.primaryHandItem == nil) and (controls.altHandItem == nil))))
	then
		if p.armRotation.occupantL ~= nil or p.armRotation.occupantR ~= nil then
			p.grabbing = nil
			p.uneat(p.armRotation.occupantL)
			p.uneat(p.armRotation.occupantR)
		end
	end
	if p.justAte ~= nil and p.justAte == p.grabbing then
		p.wasEating = true
		p.armRotation.enabledL = true
		p.armRotation.enabledR = true
		p.armRotation.targetL = p.globalToLocal(world.entityPosition(p.justAte))
		p.armRotation.targetR = p.armRotation.targetL
		p.armRotation.groupsR = {}
		p.armRotation.groupsL = {}
		p.armRotation.occupantR = nil
		p.armRotation.occupantL = nil
	elseif p.wasEating then
		p.wasEating = nil
		p.grabbing = nil
	elseif p.grabbing ~= nil and p.entityLounging(p.grabbing) then
		p.armRotation.enabledL = true
		p.armRotation.enabledR = true
		p.armRotation.targetL = p.globalToLocal(p.seats[p.driverSeat].controls.aim)
		p.armRotation.targetR = p.armRotation.targetL
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


function p.updateVisibilityAndSmolprey(i)
	if p.occupant[i].id == nil then
		animator.setAnimationState( p.occupant[i].seatname.."State", "empty", true )
		return
	end
	if p.occupant[i].visible then
		if (p.occupant[i].species ~= nil) and (p.occupant[i].species ~= "sbqOccupantHolder") then
			world.sendEntityMessage(p.occupant[i].id, "applyStatusEffect", "sbqInvisible")
			if p.occupant[i].smolPreyData.recieved then
				if p.occupant[i].smolPreyData.update then
					p.smolPreyAnimPath(p.occupant[i])
				end
				animator.setAnimationState( p.occupant[i].seatname.."State", "smol", true )
			end
		else
			world.sendEntityMessage(p.occupant[i].id, "sbqRemoveStatusEffect", "sbqInvisible")
		end
	else
		world.sendEntityMessage(p.occupant[i].id, "applyStatusEffect", "sbqInvisible")
		animator.setAnimationState( p.occupant[i].seatname.."State", "empty", true )
	end
end

function p.smolPreyAnimPath(occupant)
	local seatname = occupant.seatname

	p.setSmolOccupantPart(seatname, "head", occupant.smolPreyData.images.head)
	p.setSmolOccupantPart(seatname, "head1", occupant.smolPreyData.images.head1)
	p.setSmolOccupantPart(seatname, "head2", occupant.smolPreyData.images.head2)
	p.setSmolOccupantPart(seatname, "head3", occupant.smolPreyData.images.head3)

	p.setSmolOccupantPart(seatname, "body", occupant.smolPreyData.images.body)
	p.setSmolOccupantPart(seatname, "belly", occupant.smolPreyData.images.belly)

	p.setSmolOccupantPart(seatname, "tail", occupant.smolPreyData.images.tail)

	p.setSmolOccupantPart(seatname, "cock", occupant.smolPreyData.images.cock)

	p.setSmolOccupantPart(seatname, "backlegs", occupant.smolPreyData.images.backlegs)
	p.setSmolOccupantPart(seatname, "frontlegs", occupant.smolPreyData.images.frontlegs)

	p.setSmolOccupantPart(seatname, "backarm", occupant.smolPreyData.images.backarms)
	p.setSmolOccupantPart(seatname, "frontarm", occupant.smolPreyData.images.frontarms)

	p.setSmolOccupantPart(seatname, "backBalls", occupant.smolPreyData.images.backBalls)
	p.setSmolOccupantPart(seatname, "frontBalls", occupant.smolPreyData.images.frontBalls)

	p.setSmolOccupantPart(seatname, "backBreasts", occupant.smolPreyData.images.backBreasts)
	p.setSmolOccupantPart(seatname, "frontBreasts", occupant.smolPreyData.images.frontBreasts)

	occupant.smolPreyData.update = false
end

function p.setSmolOccupantPart(seatname, part, path)
	if path then p.setPartTag(seatname..part, "smolpath", path) else p.setPartTag(seatname..part, "smolpath", "/empty_image.png") end
end

function p.victimAnimUpdate(eid)
	if eid == nil or not p.lounging[eid] then return end
	local victimAnim = p.lounging[eid].victimAnim
	if not victimAnim.enabled then
		local location = p.lounging[eid].location
		if victimAnim.location ~= location or victimAnim.state ~= p.state then
			if victimAnim.progress == nil or victimAnim.progress == 1 then
				victimAnim.progress = 0
			end
			victimAnim.location = location
			victimAnim.state = p.state
		end
		local seatname = p.lounging[eid].seatname
		local transformGroup = seatname.."Position"
		p.resetTransformationGroup(transformGroup)
		local scale = {victimAnim.last.xs, victimAnim.last.ys}
		p.scaleTransformationGroup(transformGroup, scale)
		p.applyScaleStatusEffect(eid, scale)
		p.rotateTransformationGroup(transformGroup, (victimAnim.last.r * math.pi/180))

		if p.stateconfig[p.state].locationCenters ~= nil and p.stateconfig[p.state].locationCenters[location] ~= nil
		and (victimAnim.progress < 1 )
		then
			victimAnim.progress = math.min(1, victimAnim.progress + p.dt)
			local progress = victimAnim.progress
			local center = p.stateconfig[p.state].locationCenters[location]
			local translation = { (victimAnim.last.x + ((center[1] - victimAnim.last.x) * progress)), (victimAnim.last.y + ((center[2] - victimAnim.last.y) * progress)) }
			p.translateTransformationGroup(transformGroup, translation)
			if progress == 1 then
				victimAnim.last.x = center[1]
				victimAnim.last.y = center[2]
			end
		else
			p.translateTransformationGroup(transformGroup, {victimAnim.last.x, victimAnim.last.y})
		end
		return
	end
	local statename = victimAnim.statename
	local ended, times, time = p.hasAnimEnded(statename)
	local anim = p.victimAnimations[victimAnim.anim]
	if ended and not anim.loop then
		victimAnim.enabled = false
		time = p.animStateData[statename].animationState.cycle
		victimAnim.inside = p.victimAnimations[victimAnim.anim].endInside
	end

	local seatname = p.lounging[eid].seatname
	local speed = p.animStateData[statename].animationState.frames / p.animStateData[statename].animationState.cycle
	local frame = math.floor(time * speed)
	local nextFrame = frame + 1
	local nextFrameIndex = nextFrame + 1

	if victimAnim.prevFrame ~= frame then
		if anim.frames ~= nil then
			for i = 1, #anim.frames do
				if (anim.frames[i] == frame) then
					victimAnim.prevFrame = frame
					victimAnim.prevIndex = i

					victimAnim.frame = anim.frames[i + 1] or frame + 1
					victimAnim.index = i + 1
				end
				if anim.loop and (i == #anim.frames) then
					victimAnim.prevFrame = frame
					victimAnim.prevIndex = i

					victimAnim.frame = 0
					victimAnim.index = 1
				end
			end
		else
			victimAnim.prevFrame = victimAnim.frame
			victimAnim.frame = nextFrame

			victimAnim.prevIndex = victimAnim.index
			victimAnim.index = nextFrameIndex
		end
	end

	p.lounging[eid].visible = (p.getPrevVictimAnimValue(victimAnim, "visible") == 1)
	local e = p.getPrevVictimAnimValue(victimAnim, "e")
	if e ~= 0 then
		world.sendEntityMessage(eid, "applyStatusEffect", e, (victimAnim.frame - victimAnim.prevFrame) * (p.animStateData[statename].animationState.cycle / p.animStateData[statename].animationState.frames) + 0.01, entity.id())
	end
	local sitpos = p.getPrevVictimAnimValue(victimAnim, "sitpos")
	if sitpos ~= 0 then
		vehicle.setLoungeOrientation(seatname, sitpos)
	end
	local emote = p.getPrevVictimAnimValue(victimAnim, "emote")
	if emote ~= 0 then
		vehicle.setLoungeOrientation(seatname, sitpos)
	end
	local dance = p.getPrevVictimAnimValue(victimAnim, "dance")
	if dance ~= 0 then
		vehicle.setLoungeOrientation(seatname, sitpos)
	end

	local currTime = time * speed
	local progress = (currTime - victimAnim.prevFrame)/(victimAnim.frame - victimAnim.prevFrame) * (victimAnim.interpMode or 1)
	if (victimAnim.frame - victimAnim.prevFrame) == 0 then
		progress = 0
	end
	local transformGroup = seatname.."Position"
	local scale = { p.getVictimAnimInterpolatedValue(victimAnim, "xs", progress), p.getVictimAnimInterpolatedValue(victimAnim, "ys", progress)}
	local rotation = p.getVictimAnimInterpolatedValue(victimAnim, "r", progress)
	local translation = { p.getVictimAnimInterpolatedValue(victimAnim, "x", progress), p.getVictimAnimInterpolatedValue(victimAnim, "y", progress)}

	sb.setLogMap("-currTime", currTime)
	sb.setLogMap("-progress", progress)
	sb.setLogMap("-frame", victimAnim.frame)
	sb.setLogMap("-Prevframe", victimAnim.prevFrame)

	p.resetTransformationGroup(transformGroup)
	--could probably use animator.transformTransformationGroup() and do everything below in one matrix but I don't know how those work exactly so
	p.scaleTransformationGroup(transformGroup, scale)
	p.applyScaleStatusEffect(eid, scale)
	p.rotateTransformationGroup(transformGroup, (rotation * math.pi/180))
	p.translateTransformationGroup(transformGroup, translation)
end

function p.applyScaleStatusEffect(eid, scale)
	local scale = {math.abs(scale[1]), math.abs(scale[2])}
	if (scale[1] ~= 1) or (scale[2] ~= 1) then
		world.sendEntityMessage(eid, "sbqApplyScaleStatus", scale)
	else
		world.sendEntityMessage(eid, "sbqRemoveStatusEffect", "sbqScaling")
	end
end

function p.getVictimAnimInterpolatedValue(victimAnim, valName, progress)
	return (p.getPrevVictimAnimValue(victimAnim, valName) + (p.getNextVictimAnimValue(victimAnim, valName) - p.getPrevVictimAnimValue(victimAnim, valName)) * progress)
end

function p.getPrevVictimAnimValue(victimAnim, valName)
	if p.victimAnimations[victimAnim.anim][valName] ~= nil and p.victimAnimations[victimAnim.anim][valName][victimAnim.prevIndex] ~= nil then
		victimAnim.last[valName] = p.victimAnimations[victimAnim.anim][valName][victimAnim.prevIndex] or 0
	end
	return victimAnim.last[valName] or 0
end

function p.getNextVictimAnimValue(victimAnim, valName)
	if p.victimAnimations[victimAnim.anim][valName] ~= nil and p.victimAnimations[victimAnim.anim][valName][victimAnim.index] ~= nil then
		return p.victimAnimations[victimAnim.anim][valName][victimAnim.index] or 0
	end
	return victimAnim.last[valName] or 0
end

local victimAnimArgs = {
	xs = 1,
	ys = 1,
	x = 0,
	y = 0,
	r = 0,
	sitpos = "stand",
	emote = "idle",
	dance = "none"
}

function p.doVictimAnim( occupantId, anim, statename )
	if not p.lounging[occupantId] then return end
	local last = p.lounging[occupantId].victimAnim.last or {}

	local victimAnim = p.victimAnimations[anim]

	p.lounging[occupantId].victimAnim = {
		enabled = true,
		statename = statename,
		anim = anim,
		frame = (victimAnim.frames or {})[2] or 1,
		index = 2,
		prevFrame = 0,
		prevIndex = 1,

		last = last
	}
	if not last.inside then
		for arg, default in pairs(victimAnimArgs) do
			if p.victimAnimations[anim][arg] ~= nil then
				p.lounging[occupantId].victimAnim.last[arg] = p.victimAnimations[anim][arg][1]
			else
				p.lounging[occupantId].victimAnim.last[arg] = default
			end
		end
	end

	p.victimAnimUpdate(occupantId)
end

function p.offsetAnimUpdate()
	if p.offsets == nil or not p.offsets.enabled then return end
	local state = p.offsets.timing.."State"
	local ended, times, time = p.hasAnimEnded(state)
	if ended and not p.offsets.loop then p.offsets.enabled = false end
	local speed = p.animStateData[state].animationState.frames / p.animStateData[state].animationState.cycle
	local frame = math.floor(time * speed) + 1

	for _,r in ipairs(p.offsets.parts) do
		local x = r.x[ frame ] or r.x[#r.x] or 0
		local y = r.y[ frame ] or r.y[#r.y] or 0
		for i = 1, #r.groups do
			p.resetTransformationGroup( r.groups[i] )
			p.translateTransformationGroup( r.groups[i], { x / 8, y / 8 } )
		end
	end
end

function p.rotationAnimUpdate()
	if p.rotating == nil or not p.rotating.enabled then return end
	local state = p.rotating.timing.."State"
	local ended, times, time = p.hasAnimEnded(state)
	if ended and not p.rotating.loop then p.rotating.enabled = false end
	local speed = p.animStateData[state].animationState.frames / p.animStateData[state].animationState.cycle
	local frame = math.floor(time * speed)
	local index = frame + 1
	local nextFrame = frame + 1
	local nextIndex = index + 1

	if p.rotating.prevFrame ~= frame then
		if p.rotating.frames ~= nil then
			for i = 1, #p.rotating.frames do
				if (p.rotating.frames[i] == frame) then
					p.rotating.prevFrame = frame
					p.rotating.prevIndex = i

					p.rotating.frame = p.rotating.frames[i + 1] or frame + 1
					p.rotating.index = i + 1
				end
				if p.rotating.loop and (i == #p.rotating.frames) then
					p.rotating.prevFrame = frame
					p.rotating.prevIndex = i

					p.rotating.frame = 0
					p.rotating.index = 1
				end
			end
		else
			p.rotating.prevFrame = p.rotating.frame
			p.rotating.frame = nextFrame

			p.rotating.prevIndex = p.rotating.index
			p.rotating.index = nextIndex
		end
	end

	local currTime = time * speed
	local progress = (currTime - p.rotating.prevFrame)/(math.abs(p.rotating.frame - p.rotating.prevFrame))

	for _, r in ipairs(p.rotating.parts) do
		local previousRotation = r.rotation[p.rotating.prevIndex] or r.last
		local nextRotation = r.rotation[p.rotating.index] or previousRotation
		local rotation = previousRotation + (nextRotation - previousRotation) * progress
		r.last = previousRotation

		for _, group in ipairs(r.groups) do
			p.resetTransformationGroup( group )
			p.rotateTransformationGroup( group, (rotation * math.pi/180), r.center)
		end
	end
end

function p.queueAnimEndFunction(state, func, newPriority)
	if newPriority then
		p.animStateData[state].animationState.priority = newPriority
	end
	table.insert(p.animFunctionQueue[state], func)
end

function p.doAnim( state, anim, force)
	local oldPriority = (p.animStateData[state].animationState or {}).priority or 0
	local newPriority = (p.animStateData[state].states[anim] or {}).priority or 0
	local isSame = p.animationIs( state, anim )
	local force = force
	local priorityHigher = ((newPriority >= oldPriority) or (newPriority == -1))
	if (not isSame and priorityHigher) or p.hasAnimEnded(state) or force then
		if isSame and (p.animStateData[state].states[animator.animationState(state)].mode == "end") then
			force = true
		end
		p.animStateData[state].animationState = {
			anim = anim,
			priority = newPriority,
			cycle = p.animStateData[state].states[anim].cycle,
			frames = p.animStateData[state].states[anim].frames,
			time = 0
		}
		animator.setAnimationState(state, anim, force)
	end
end

function p.doAnims( anims, force )
	for state,anim in pairs( anims or {} ) do
		if state == "offset" then
			p.offsetAnim( anim )
		elseif state == "rotate" then
			p.rotate( anim )
		elseif state == "tags" then
			p.setAnimTag( anim )
		elseif state == "priority" then
			p.changePriorityLength( anim )
		else
			p.doAnim( state.."State", anim, force)
		end
	end
end

function p.changePriorityLength(anim)
	for state, data in pairs(anim) do
		p.animStateData[state.."State"].animationState.priority = data[1] or p.animStateData[state.."State"].animationState.priority
		p.animStateData[state.."State"].animationState.cycle = data[2] or p.animStateData[state.."State"].animationState.cycle
	end
end

function p.setAnimTag(anim)
	for _,tag in ipairs(anim) do
		p.animStateData[tag.owner.."State"].tag = {
			part = tag.part,
			name = tag.name,
			reset = tag.reset or true
		}
		if tag.part == "global" then
			p.setPartTag( "global", tag.name, tag.value )
		else
			p.setPartTag( tag.part, tag.name, tag.value )
		end
	end
end

p.offsets = {enabled = false, parts = {}}
function p.offsetAnim( data )
	if data == p.offsets.data then
		if not p.offsets.enabled then p.offsets.enabled = true end
		return
	else
		for i, part in ipairs(p.offsets.parts) do
			for j, group in ipairs(part.groups) do
				p.resetTransformationGroup(group)
			end
		end
	end

	p.offsets = {
		enabled = data ~= nil,
		data = data,
		parts = {},
		loop = data.loop or false,
		timing = data.timing or "body"
	}
	local continue = false
	for _, part in ipairs(data.parts or {}) do
		table.insert(p.offsets.parts, {
			x = part.x or {0},
			y = part.y or {0},
			groups = part.groups or {"headbob"},
			})
		if (part.x and #part.x > 1) or (part.y and #part.y > 1) then
			continue = true
		end
	end
	p.offsetAnimUpdate()
	if not continue then
		p.offsets.enabled = false
	end
end

p.rotating = {enabled = false, parts = {}}
function p.rotate( data )
	if data == p.rotating.data and p.rotating.enabled then return
	else
		for i, part in ipairs(p.rotating.parts) do
			for j, group in ipairs(part.groups) do
				p.resetTransformationGroup(group)
			end
		end
	end

	p.rotating = {
		enabled = data ~= nil,
		data = data,
		frames = data.frames,
		parts = {},
		loop = data.loop or false,
		timing = data.timing or "body",

		frame = 1,
		index = 2,
		prevFrame = 0,
		prevIndex = 1

	}
	local continue = false
	for _, r in ipairs(data.parts or {}) do
		table.insert(p.rotating.parts, {
			groups = r.groups or {"frontarmsrotation"},
			center = r.center or {0,0},
			rotation = r.rotation or {0},
			last = r.rotation[1] or 0
		})
		if r.rotation and #r.rotation > 1 then
			continue = true
		end
	end
	p.rotationAnimUpdate()
	if not continue then
		p.rotating.enabled = false
	end
end

function p.hasAnimEnded(state)
	local ended = (p.animStateData[state].animationState.time >= p.animStateData[state].animationState.cycle)
	local times = math.floor(p.animStateData[state].animationState.time/p.animStateData[state].animationState.cycle)
	local currentCycle = (p.animStateData[state].animationState.time - (p.animStateData[state].animationState.cycle*times))
	return ended, times, currentCycle
end

function p.animationIs(state, anim)
	return animator.animationState(state) == anim
end

function p.setColorReplaceDirectives()
	if p.sbqData.replaceColors ~= nil then
		local colorReplaceString = ""
		for i, colorGroup in ipairs(p.sbqData.replaceColors) do
			local basePalette = colorGroup[1]
			local replacePalette = colorGroup[((p.settings.replaceColors or {})[i] or (p.sbqData.defaultSettings.replaceColors or {})[i] or 1) + 1]
			local fullbright = (p.settings.fullbright or {})[i]

			if p.settings.replaceColorTable ~= nil and p.settings.replaceColorTable[i] ~= nil then
				replacePalette = p.settings.replaceColorTable[i]
				if type(replacePalette) == "string" then
					p.settings.directives = replacePalette
					p.setPartTag( "global", "directives", replacePalette )
					return
				end
			end

			for j, color in ipairs(replacePalette) do
				if fullbright and #color <= #"ffffff" then -- don't tack it on it if it already has a defined opacity or fullbright
					color = color.."fb"
				end
				colorReplaceString = colorReplaceString.."?replace;"..basePalette[j].."="..color
			end
		end
		p.settings.directives = colorReplaceString
		p.setPartTag( "global", "directives", colorReplaceString )
	end
end

function p.setSkinPartTags()
	for animPart, skin in pairs(p.settings.skinNames or {}) do
		if skin ~= nil and skin ~= "" and not ((skin:find("//") ~= nil) or (skin:find("%.") ~= nil) or (skin:sub(1,1) == "/") or (skin:sub(-1,-1) == "/") ) then
			p.setPartTag( animPart, "skin", skin )
			p.setPartTag( "global", animPart.."skin", skin )
		end
	end
end

function p.partsAreStruggling(parts)
	for _, part in ipairs(parts) do
		if not p.hasAnimEnded( part.."State" )
		and (
			p.animationIs( part.."State", "s_up" ) or
			p.animationIs( part.."State", "s_front" ) or
			p.animationIs( part.."State", "s_back" ) or
			p.animationIs( part.."State", "s_down" )
		)
		then return true end
	end
end

function p.setPartTag(part, tag, value)
	p.partTags[part][tag] = value

	if part == "global" then
		animator.setGlobalTag( tag, value )
	else
		animator.setPartTag( part, tag, value )
	end
end

p.transformGroupData = {}
function p.resetTransformationGroup(transformGroup)
	p.transformGroupData[transformGroup] = { scale = {}, rotate = {}, translate = {}, translateBR = {} }
end

function p.scaleTransformationGroup(transformGroup, scale)
	table.insert(p.transformGroupData[transformGroup].scale, scale)
end

function p.rotateTransformationGroup(transformGroup, angle, center)
	table.insert(p.transformGroupData[transformGroup].rotate, {angle, center})
end

function p.translateTransformationGroup(transformGroup, translation, beforeRotate)
	if beforeRotate then
		table.insert(p.transformGroupData[transformGroup].translateBR, translation)
	else
		table.insert(p.transformGroupData[transformGroup].translate, translation)
	end
end


function p.copyTransformationFromGroupsToGroup(transformGroups, resultTransformGroup)
	for _, transformGroup in ipairs(transformGroups) do
		for _, transformation in ipairs(p.transformGroupData[transformGroup].scale) do
			table.insert(p.transformGroupData[resultTransformGroup].scale, transformation )
		end
		for _, transformation in ipairs(p.transformGroupData[transformGroup].rotate) do
			table.insert(p.transformGroupData[resultTransformGroup].rotate, transformation )
		end
		for _, transformation in ipairs(p.transformGroupData[transformGroup].translate) do
			table.insert(p.transformGroupData[resultTransformGroup].translate, transformation )
		end
		for _, transformation in ipairs(p.transformGroupData[transformGroup].translateBR) do
			table.insert(p.transformGroupData[resultTransformGroup].translateBR, transformation )
		end
	end
end

function p.applyTransformations()
	for transformGroup in pairs(p.transformGroups) do
		animator.resetTransformationGroup(transformGroup)
		-- apply all the transformations
		for _, transformation in ipairs(p.transformGroupData[transformGroup].translateBR) do
			animator.translateTransformationGroup(transformGroup, transformation )
		end
		for _, transformation in ipairs(p.transformGroupData[transformGroup].scale) do
			animator.scaleTransformationGroup(transformGroup, transformation )
		end
		for _, transformation in ipairs(p.transformGroupData[transformGroup].rotate) do
			animator.rotateTransformationGroup(transformGroup, transformation[1], transformation[2] )
		end
		for _, transformation in ipairs(p.transformGroupData[transformGroup].translate) do
			animator.translateTransformationGroup(transformGroup, transformation )
		end
	end
end

function p.showEmote( emotename ) --helper function to express a emotion particle "emotesleepy","emoteconfused","emotesad","emotehappy","love"
	if p.emoteCooldown < 0 then
		animator.setParticleEmitterBurstCount( emotename, 1 );
		animator.burstParticleEmitter( emotename )
		p.emoteCooldown = 0.2; -- seconds
	end
end
