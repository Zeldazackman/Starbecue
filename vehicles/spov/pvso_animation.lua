
function p.updateAnims(dt)
	for statename, state in pairs(p.animStateData) do
		state.animationState.time = state.animationState.time + dt
	end

	for i = 0, #p.occupant do
		p.victimAnimUpdate(p.occupant[i].id)
		p.updateVisibilityAndSmolprey(p.occupant[i])
	end
	p.offsetAnimUpdate()
	p.rotationAnimUpdate()
	p.armRotationUpdate()

	for statename, state in pairs(p.animStateData) do
		if state.animationState.time >= state.animationState.cycle then
			p.endAnim(state)
		end
	end
end

function p.endAnim(state)
	for _, func in pairs(state.animationState.queue) do
		func()
	end
	state.animationState.queue = {}

	if (state.tag ~= nil) and state.tag.reset then
		if state.tag.part == "global" then
			animator.setGlobalTag( state.tag.name, "" )
		else
			animator.setPartTag( state.tag.part, state.tag.name, "" )
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
		p.faceDirection(p.armRotation.target[1]*p.direction)
	end
	if p.direction > 0 then
		p.rotateArm( p.armRotation.enabledL, "backarms", p.armRotation.groupsL, p.armRotation.occupantL)
		p.rotateArm( p.armRotation.enabledR, "frontarms", p.armRotation.groupsR, p.armRotation.occupantR)
	else
		p.rotateArm( p.armRotation.enabledR, "backarms", p.armRotation.groupsR, p.armRotation.occupantR)
		p.rotateArm( p.armRotation.enabledL, "frontarms", p.armRotation.groupsL, p.armRotation.occupantL)
	end
end

function p.rotateArm(enabled, arm, groups, occupantId)
	if enabled then
		animator.setAnimationState(arm.."_rotationState", p.stateconfig[p.state].rotationArmState or "rotation", true )

		local target = p.armRotation.target
		local center = {(p.stateconfig[p.state].rotationCenters[arm][1] or 0) / 8, (p.stateconfig[p.state].rotationCenters[arm][2] or 0) / 8}
		local handOffset = {(p.stateconfig[p.state].handOffsets[arm][1] or 0) / 8, (p.stateconfig[p.state].handOffsets[arm][2] or 0) / 8}
		local angle = math.atan((target[2] - center[2]), (target[1] - center[1]))

		p.armRotation[arm.."Angle"] = angle

		animator.resetTransformationGroup(arm.."rotation")
		animator.rotateTransformationGroup(arm.."rotation", angle, center)

		for i, group in ipairs(groups) do
			animator.resetTransformationGroup(group)
			animator.translateTransformationGroup(group, handOffset)
			animator.rotateTransformationGroup(group, angle, center)
		end

		if occupantId ~= nil and p.lounging[occupantId] ~= nil then
			local victimAnim = p.lounging[occupantId].victimAnim
			victimAnim.last.x = math.cos(angle) * handOffset[1]
			victimAnim.last.y = math.sin(angle) * handOffset[2]
		end

		animator.setPartTag( arm, "armVisible", "?multiply=FFFFFF00" )
		animator.setPartTag( arm.."_fullbright", "armVisible", "?multiply=FFFFFF00" )
		animator.setPartTag( arm.."_rotation", "armVisible", "" )
		animator.setPartTag( arm.."_fullbright_rotation", "armVisible", "" )
	else
		animator.setPartTag( arm, "armVisible", "" )
		animator.setPartTag( arm.."_fullbright", "armVisible", "" )
		animator.setPartTag( arm.."_rotation", "armVisible", "?multiply=FFFFFF00" )
		animator.setPartTag( arm.."_fullbright_rotation", "armVisible", "?multiply=FFFFFF00" )
	end
end

function p.setGrabTarget()
	local controls = p.seats[p.driverSeat].controls
	if p.driver and (not (((controls.primaryHandItem == "pvsoController") or (controls.altHandItem == "pvsoController"))
	or ((controls.primaryHandItem == nil) and (controls.altHandItem == nil))))
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
		p.wasEating = nil
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


function p.updateVisibilityAndSmolprey(occupant)
	if occupant.id == nil then
		animator.setAnimationState( occupant.seatname.."State", "empty", true )
		return
	end
	if occupant.visible then
		if occupant.species ~= nil then
			if occupant.smolPreyData.recieved then
				if occupant.smolPreyData.update then
					p.smolPreyAnimPath(occupant)
				end
				world.sendEntityMessage(occupant.id, "applyStatusEffect", "pvsoInvisible")
				animator.setAnimationState( occupant.seatname.."State", "smol", true )
			end
		else
			world.sendEntityMessage(occupant.id, "applyStatusEffect", "pvsoRemoveInvisible")
		end
	else
		world.sendEntityMessage(occupant.id, "applyStatusEffect", "pvsoInvisible")
		animator.setAnimationState( occupant.seatname.."State", "empty", true )
	end
end

function p.smolPreyAnimPath(occupant)
	local seatname = occupant.seatname

	local head = occupant.smolPreyData.images.head
	local head_fullbright = occupant.smolPreyData.images.head_fullbright

	local body = occupant.smolPreyData.images.body
	local body_fullbright = occupant.smolPreyData.images.body_fullbright

	local tail = occupant.smolPreyData.images.tail
	local tail_fullbright = occupant.smolPreyData.images.tail_fullbright

	local backlegs = occupant.smolPreyData.images.backlegs
	local backlegs_fullbright = occupant.smolPreyData.images.backlegs_fullbright

	local frontlegs = occupant.smolPreyData.images.frontlegs
	local frontlegs_fullbright = occupant.smolPreyData.images.frontlegs_fullbright

	local backarms = occupant.smolPreyData.images.backarms
	local backarms_fullbright = occupant.smolPreyData.images.backarms_fullbright

	local frontarms = occupant.smolPreyData.images.frontarms
	local frontarms_fullbright = occupant.smolPreyData.images.frontarms_fullbright

	if head then animator.setPartTag(seatname, "smolpath", head) else animator.setPartTag(seatname, "smolpath", "/empty_image.png") end
	if head_fullbright then animator.setPartTag(seatname.."_fullbright", "smolpath", head_fullbright) else animator.setPartTag(seatname.."_fullbright", "smolpath", "/empty_image.png") end

	if body then animator.setPartTag(seatname.."body", "smolpath", body) else animator.setPartTag(seatname.."body", "smolpath", "/empty_image.png") end
	if body_fullbright then animator.setPartTag(seatname.."body_fullbright", "smolpath", body_fullbright) else animator.setPartTag(seatname.."body_fullbright", "smolpath", "/empty_image.png") end

	if tail then animator.setPartTag(seatname.."tail", "smolpath", tail) else animator.setPartTag(seatname.."tail", "smolpath", "/empty_image.png") end
	if tail_fullbright then animator.setPartTag(seatname.."tail_fullbright", "smolpath", tail_fullbright) else animator.setPartTag(seatname.."tail_fullbright", "smolpath", "/empty_image.png") end

	if backlegs then animator.setPartTag(seatname.."backlegs", "smolpath", backlegs) else animator.setPartTag(seatname.."backlegs", "smolpath", "/empty_image.png") end
	if backlegs_fullbright then animator.setPartTag(seatname.."backlegs_fullbright", "smolpath", backlegs_fullbright) else animator.setPartTag(seatname.."backlegs_fullbright", "smolpath", "/empty_image.png") end

	if frontlegs then animator.setPartTag(seatname.."frontlegs", "smolpath", frontlegs) else animator.setPartTag(seatname.."frontlegs", "smolpath", "/empty_image.png") end
	if frontlegs_fullbright then animator.setPartTag(seatname.."frontlegs_fullbright", "smolpath", frontlegs_fullbright) else animator.setPartTag(seatname.."frontlegs_fullbright", "smolpath", "/empty_image.png") end

	if backarms then animator.setPartTag(seatname.."backarms", "smolpath", backarms) else animator.setPartTag(seatname.."backarms", "smolpath", "/empty_image.png") end
	if backarms_fullbright then animator.setPartTag(seatname.."backarms_fullbright", "smolpath", backarms_fullbright) else animator.setPartTag(seatname.."backarms_fullbright", "smolpath", "/empty_image.png") end

	if frontarms then animator.setPartTag(seatname.."frontarms", "smolpath", frontarms) else animator.setPartTag(seatname.."frontarms", "smolpath", "/empty_image.png") end
	if frontarms_fullbright then animator.setPartTag(seatname.."frontarms_fullbright", "smolpath", frontarms_fullbright) else animator.setPartTag(seatname.."frontarms_fullbright", "smolpath", "/empty_image.png") end

	occupant.smolPreyData.update = false
end

function p.victimAnimUpdate(entity)
	if entity == nil or not p.lounging[entity] then return end
	local victimAnim = p.lounging[entity].victimAnim
	if not victimAnim.enabled then
		local location = p.lounging[entity].location
		victimAnim.last.inside = true

		if victimAnim.location ~= location or victimAnim.state ~= p.state then
			if victimAnim.progress == nil or victimAnim.progress == 1 then
				victimAnim.progress = 0
			end
			victimAnim.location = location
			victimAnim.state = p.state
		end

		if p.stateconfig[p.state].locationCenters ~= nil and p.stateconfig[p.state].locationCenters[location] ~= nil
		and (victimAnim.progress < 1 )
		then
			victimAnim.progress = math.min(1, victimAnim.progress + p.dt)
			local progress = victimAnim.progress
			local center = p.stateconfig[p.state].locationCenters[location]
			local seatname = p.lounging[entity].seatname
			local transformGroup = seatname.."Position"
			local translation = { (victimAnim.last.x + ((center[1] - victimAnim.last.x) * progress)), (victimAnim.last.y + ((center[2] - victimAnim.last.y) * progress)) }
			animator.resetTransformationGroup(transformGroup)
			animator.translateTransformationGroup(transformGroup, translation)
			if progress == 1 then
				victimAnim.last.x = center[1]
				victimAnim.last.y = center[2]
			end
		end
		return
	end
	local statename = victimAnim.statename
	local ended, times, time = p.hasAnimEnded(statename)
	local anim = p.victimAnimations[victimAnim.anim]
	if ended and not anim.loop then
		victimAnim.enabled = false
		time = p.animStateData[statename].animationState.cycle
	end

	local seatname = p.lounging[entity].seatname
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

		if anim.e ~= nil and anim.e[victimAnim.prevIndex] ~= nil then
			world.sendEntityMessage(entity, "applyStatusEffect", anim.e[victimAnim.prevIndex], (victimAnim.frame - victimAnim.prevFrame) * (p.animStateData[statename].animationState.cycle / p.animStateData[statename].animationState.frames) + 0.01, entity.id())
		end
		if anim.visible ~= nil and anim.visible[victimAnim.prevIndex] ~= nil then
			p.lounging[entity].visible = (anim.visible[victimAnim.prevIndex] == 1)
		end
		if anim.sitpos ~= nil and anim.sitpos[victimAnim.prevIndex] ~= nil then
			vehicle.setLoungeOrientation(seatname, anim.sitpos[victimAnim.prevIndex])
		end
		if anim.emote ~= nil and anim.emote[victimAnim.prevIndex] ~= nil then
			vehicle.setLoungeEmote(seatname, anim.emote[victimAnim.prevIndex])
			p.lounging[entity].emote = anim.emote[victimAnim.prevIndex]
		end
		if anim.dance ~= nil and anim.dance[victimAnim.prevIndex] ~= nil then
			vehicle.setLoungeDance(seatname, anim.dance[victimAnim.prevIndex])
		end
	end

	local currTime = time * speed
	local progress = (currTime - victimAnim.prevFrame)/(math.abs(victimAnim.frame - victimAnim.prevFrame)) * (victimAnim.interpMode or 1)
	if (victimAnim.frame - victimAnim.prevFrame) == 0 then
		progress = 0
	end
	local transformGroup = seatname.."Position"
	local scale = { p.getVictimAnimInterpolatedValue(victimAnim, "xs", progress), p.getVictimAnimInterpolatedValue(victimAnim, "ys", progress)}
	local rotation = p.getVictimAnimInterpolatedValue(victimAnim, "r", progress)
	local translation = { p.getVictimAnimInterpolatedValue(victimAnim, "x", progress), p.getVictimAnimInterpolatedValue(victimAnim, "y", progress)}

	animator.resetTransformationGroup(transformGroup)
	--could probably use animator.transformTransformationGroup() and do everything below in one matrix but I don't know how those work exactly so
	animator.scaleTransformationGroup(transformGroup, scale)
	animator.rotateTransformationGroup(transformGroup, (rotation * math.pi/180))
	animator.translateTransformationGroup(transformGroup, translation)
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
	r = 0
}

function p.doVictimAnim( occupantId, anim, statename )
	if not p.lounging[occupantId] then return end
	local last = p.lounging[occupantId].victimAnim.last or {}
	p.lounging[occupantId].victimAnim = {
		enabled = true,
		statename = statename,
		anim = anim,
		frame = 1,
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
			animator.resetTransformationGroup( r.groups[i] )
			animator.translateTransformationGroup( r.groups[i], { x / 8, y / 8 } )
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
			animator.resetTransformationGroup( group )
			animator.rotateTransformationGroup( group, (rotation * math.pi/180), r.center)
		end
	end
end

function p.queueAnimEndFunction(state, func, newPriority)
	if newPriority then
		p.animStateData[state].animationState.priority = newPriority
	end
	table.insert(p.animStateData[state].animationState.queue, func)
end

function p.doAnim( state, anim, force)
	local oldPriority = p.animStateData[state].animationState.priority
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
			time = 0,
			queue = {}
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
			animator.setGlobalTag( tag.name, tag.value )
		else
			animator.setPartTag( tag.part, tag.name, tag.value )
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
				animator.resetTransformationGroup(group)
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
				animator.resetTransformationGroup(group)
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
	if p.vso.replaceColors ~= nil then
		local colorReplaceString = ""
		local fullbrightDirectivesString = ""
		for i, colorGroup in ipairs(p.vso.replaceColors) do
			local basePalette = colorGroup[1]
			local replacePalette = colorGroup[(p.settings.replaceColors[i] or p.vso.defaultSettings.replaceColors[i] or 1) + 1]
			local fullbright = p.settings.fullbright[i]

			if p.settings.customDirectives then
				replacePalette = p.settings.customPalette[i]
			end

			if (replacePalette == nil) or (replacePalette == {}) then
				replacePalette = colorGroup[p.vso.defaultSettings.replaceColors[i] + 1]
			end

			for j, color in ipairs(replacePalette) do
				if not fullbright then
					fullbrightDirectivesString = fullbrightDirectivesString.."?replace;"..basePalette[j].."=00000000"
				end
				colorReplaceString = colorReplaceString.."?replace;"..basePalette[j].."="..color
			end
		end
		p.settings.directives = colorReplaceString
		p.settings.fullbrightDirectives = fullbrightDirectivesString
		animator.setGlobalTag( "fullbrightDirectives", fullbrightDirectivesString )
		animator.setGlobalTag( "directives", colorReplaceString )
	end
end

function p.setSkinPartTags()
	for animPart, skin in pairs(p.settings.skinNames or {}) do
		animator.setPartTag( animPart, "skin", skin )
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
