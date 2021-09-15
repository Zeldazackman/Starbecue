
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
	groupsL = {}
}
function p.armRotationUpdate()
	if p.armRotation.enabledR or p.armRotation.enabledL then
		p.movement.aimingLock = 0.1
		p.faceDirection(p.armRotation.target[1]*p.direction)
	end
	if p.direction > 0 then
		p.rotateArm( p.armRotation.enabledR, "frontarms", p.armRotation.groupsR)
		p.rotateArm( p.armRotation.enabledL, "backarms", p.armRotation.groupsL)
	else
		p.rotateArm( p.armRotation.enabledL, "frontarms", p.armRotation.groupsL)
		p.rotateArm( p.armRotation.enabledR, "backarms", p.armRotation.groupsR)
	end
end

function p.rotateArm(enabled, arm, groups)
	if enabled then
		animator.setAnimationState(arm.."_rotationState", p.stateconfig[p.state].rotationArmState or "rotation", true )

		local target = p.armRotation.target
		local center = {(p.stateconfig[p.state].rotationCenters[arm][1] or 0) / 8, (p.stateconfig[p.state].rotationCenters[arm][2] or 0) / 8}
		local handOffset = {(p.stateconfig[p.state].handOffsets[arm][1] or 0) / 8, (p.stateconfig[p.state].handOffsets[arm][2] or 0) / 8}
		local angle = math.atan((target[2] - center[2]), (target[1] - center[1]))

		animator.resetTransformationGroup(arm.."rotation")
		animator.rotateTransformationGroup(arm.."rotation", angle, center)

		for i, group in ipairs(groups) do
			animator.resetTransformationGroup(group)
			animator.translateTransformationGroup(group, handOffset)
			animator.rotateTransformationGroup(group, angle, center)
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
	local path = occupant.smolPreyData.path
	local settings = occupant.smolPreyData.settings
	local state = occupant.smolPreyData.state
	local animatedParts = occupant.smolPreyData.animatedParts
	local seatname = occupant.seatname

	local head = ""
	local head_fullbright = ""

	local body = ""
	local body_fullbright = ""

	local tail = ""
	local tail_fullbright = ""

	local backlegs = ""
	local backlegs_fullbright = ""

	local frontlegs = ""
	local frontlegs_fullbright = ""

	local backarms = ""
	local backarms_fullbright = ""

	local frontarms = ""
	local frontarms_fullbright = ""

	if state.idle.head ~= nil then
		local skin = settings.skinNames.head or "default"
		head = p.fixPathTags(animatedParts.parts.head.partStates.headState[state.idle.head].properties.image, skin, settings)
		if animatedParts.parts.head_fullbright ~= nil then
			head_fullbright = p.fixPathTags(animatedParts.parts.head_fullbright.partStates.headState[state.idle.head].properties.image, skin, settings)
		end
	end
	if state.idle.body ~= nil then
		local skin = settings.skinNames.body or "default"
		body = p.fixPathTags(animatedParts.parts.body.partStates.bodyState[state.idle.body].properties.image, skin, settings)
		if animatedParts.parts.body_fullbright ~= nil then
			body_fullbright = p.fixPathTags(animatedParts.parts.body_fullbright.partStates.bodyState[state.idle.body].properties.image, skin, settings)
		end
	end
	if state.idle.tail ~= nil then
		local skin = settings.skinNames.tail or "default"
		tail = p.fixPathTags(animatedParts.parts.tail.partStates.tailState[state.idle.tail].properties.image, skin, settings)
		if animatedParts.parts.tail_fullbright ~= nil then
			tail_fullbright = p.fixPathTags(animatedParts.parts.tail_fullbright.partStates.tailState[state.idle.tail].properties.image, skin, settings)
		end
	end
	if state.idle.legs ~= nil then
		local skin = settings.skinNames.legs or "default"
		backlegs = p.fixPathTags(animatedParts.parts.backlegs.partStates.legsState[state.idle.legs].properties.image, skin, settings)
		frontlegs = p.fixPathTags(animatedParts.parts.frontlegs.partStates.legsState[state.idle.legs].properties.image, skin, settings)
		if animatedParts.parts.backlegs_fullbright ~= nil then
			backlegs_fullbright = p.fixPathTags(animatedParts.parts.backlegs_fullbright.partStates.legsState[state.idle.legs].properties.image, skin, settings)
		end
		if animatedParts.parts.frontlegs_fullbright ~= nil then
			frontlegs_fullbright = p.fixPathTags(animatedParts.parts.frontlegs_fullbright.partStates.legsState[state.idle.legs].properties.image, skin, settings)
		end
	end
	if state.idle.arms ~= nil then
		local skin = settings.skinNames.arms or "default"
		backarms = p.fixPathTags(animatedParts.parts.backarms.partStates.armsState[state.idle.arms].properties.image, skin, settings)
		frontarms = p.fixPathTags(animatedParts.parts.frontarms.partStates.armsState[state.idle.arms].properties.image, skin, settings)
		if animatedParts.parts.backarms_fullbright ~= nil then
			backarms_fullbright = p.fixPathTags(animatedParts.parts.backarms_fullbright.partStates.armsState[state.idle.arms].properties.image, skin, settings)
		end
		if animatedParts.parts.frontarms_fullbright ~= nil then
			frontarms_fullbright = p.fixPathTags(animatedParts.parts.frontarms_fullbright.partStates.armsState[state.idle.arms].properties.image, skin, settings)
		end
	end

	animator.setPartTag(seatname, "smolpath", path..head)
	animator.setPartTag(seatname.."fullbright", "smolpath", path..head_fullbright)

	animator.setPartTag(seatname.."body", "smolpath", path..body)
	animator.setPartTag(seatname.."body_fullbright", "smolpath", path..body_fullbright)

	animator.setPartTag(seatname.."tail", "smolpath", path..tail)
	animator.setPartTag(seatname.."tail_fullbright", "smolpath", path..tail_fullbright)

	animator.setPartTag(seatname.."backlegs", "smolpath", path..backlegs)
	animator.setPartTag(seatname.."backlegs_fullbright", "smolpath", path..backlegs_fullbright)

	animator.setPartTag(seatname.."frontlegs", "smolpath", path..frontlegs)
	animator.setPartTag(seatname.."frontlegs_fullbright", "smolpath", path..frontlegs_fullbright)

	animator.setPartTag(seatname.."backarms", "smolpath", path..backarms)
	animator.setPartTag(seatname.."backarms_fullbright", "smolpath", path..backarms_fullbright)

	animator.setPartTag(seatname.."frontarms", "smolpath", path..frontarms)
	animator.setPartTag(seatname.."frontarms_fullbright", "smolpath", path..frontarms_fullbright)

	occupant.smolPreyData.update = false
end

function p.fixPathTags(path, skin, settings)
	return sb.replaceTags(path, {
		skin = skin,
		fullbrightDirectives = settings.fullbrightDirectives or "",
		directives = settings.directives or "",
		bap = "",
		frame = "1",
		bellyoccupants = "0",
		cracks = settings.cracks or "0"
	})
end

function p.victimAnimUpdate(entity)
	if entity == nil then return end
	local victimAnim = p.entity[entity].victimAnim
	if not victimAnim.enabled then
		local location = p.entity[entity].location
		p.entity[entity].victimAnim.inside = true

		if p.entity[entity].victimAnim.location ~= location or p.entity[entity].victimAnim.state ~= p.state then
			if p.entity[entity].victimAnim.progress == nil or p.entity[entity].victimAnim.progress == 1 then
				p.entity[entity].victimAnim.progress = 0
			end
			p.entity[entity].victimAnim.location = location
			p.entity[entity].victimAnim.state = p.state
		end

		if p.stateconfig[p.state].locationCenters ~= nil and p.stateconfig[p.state].locationCenters[location] ~= nil
		and (p.entity[entity].victimAnim.progress < 1 )
		then
			p.entity[entity].victimAnim.progress = math.min(1, p.entity[entity].victimAnim.progress + p.dt)
			local progress = p.entity[entity].victimAnim.progress
			local center = p.stateconfig[p.state].locationCenters[location]
			local seatname = p.entity[entity].seatname
			local transformGroup = seatname.."Position"
			local translation = { (victimAnim.last.x + ((center[1] - victimAnim.last.x) * progress)), (victimAnim.last.y + ((center[2] - victimAnim.last.y) * progress)) }
			animator.resetTransformationGroup(transformGroup)
			animator.translateTransformationGroup(transformGroup, translation)
			if progress == 1 then
				p.entity[entity].victimAnim.last.x = center[1]
				p.entity[entity].victimAnim.last.y = center[2]
			end
		end
		return
	end
	local statename = p.entity[entity].victimAnim.statename
	local ended, times, time = p.hasAnimEnded(statename)
	local anim = p.victimAnimations[victimAnim.anim]
	if ended and not anim.loop then
		victimAnim.enabled = false
		time = p.animStateData[statename].animationState.cycle
	end

	local seatname = p.entity[entity].seatname
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
			p.entity[entity].visible = (anim.visible[victimAnim.prevIndex] == 1)
		end
		if anim.sitpos ~= nil and anim.sitpos[victimAnim.prevIndex] ~= nil then
			vehicle.setLoungeOrientation(seatname, anim.sitpos[victimAnim.prevIndex])
		end
		if anim.emote ~= nil and anim.emote[victimAnim.prevIndex] ~= nil then
			vehicle.setLoungeEmote(seatname, anim.emote[victimAnim.prevIndex])
			p.entity[entity].emote = anim.emote[victimAnim.prevIndex]
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
		victimAnim.last[valName] = p.victimAnimations[victimAnim.anim][valName][victimAnim.prevIndex]
	end
	return victimAnim.last[valName]
end

function p.getNextVictimAnimValue(victimAnim, valName)
	if p.victimAnimations[victimAnim.anim][valName] ~= nil and p.victimAnimations[victimAnim.anim][valName][victimAnim.index] ~= nil then
		return p.victimAnimations[victimAnim.anim][valName][victimAnim.index]
	end
	return victimAnim.last[valName]
end

local victimAnimArgs = {
	xs = 1,
	ys = 1,
	x = 0,
	y = 0,
	r = 0
}

function p.doVictimAnim( occupantId, anim, statename )
	if not p.entity[occupantId] then return end
	local last = p.entity[occupantId].victimAnim.last or {}
	p.entity[occupantId].victimAnim = {
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
				p.entity[occupantId].victimAnim.last[arg] = p.victimAnimations[anim][arg][1]
			else
				p.entity[occupantId].victimAnim.last[arg] = default
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
		local colorReplaceString = "?replace"
		local fullbrightDirectivesString = "?replace"
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
					fullbrightDirectivesString = fullbrightDirectivesString..";"..basePalette[j].."=00000000"
				end
				colorReplaceString = colorReplaceString..";"..basePalette[j].."="..color
			end
		end
		p.settings.directives = colorReplaceString
		p.settings.fullbrightDirectives = fullbrightDirectivesString
		animator.setGlobalTag( "fullbrightDirectives", fullbrightDirectivesString )
		animator.setGlobalTag( "directives", colorReplaceString )
	end
end

function p.setSkinPartTags()
	if p.vso.replaceSkin ~= nil then
		for part, index in pairs(p.settings.replaceSkin) do
			local skin = p.vso.replaceSkin[part].skins[index]
			p.settings.skinNames[part] = skin
			for _, animPart in ipairs(p.vso.replaceSkin[part].parts) do
				animator.setPartTag( animPart, "skin", skin )
			end
		end
	end
end
