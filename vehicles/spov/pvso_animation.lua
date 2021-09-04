
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

function p.updateVisibilityAndSmolprey(occupant)
	if occupant.id == nil then return end
	if occupant.visible then
		if occupant.species ~= nil then
			if occupant.smolPreyData.recieved then
				p.smolPreyAnimPath(occupant)
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
	local skin = settings.skin or "default"

	local directives = "" -- this will be fixed when I figure out the

	local head = "/assetmissing.png"
	local body = "/assetmissing.png"
	local tail = "/assetmissing.png"
	local backlegs = "/assetmissing.png"
	local frontlegs = "/assetmissing.png"
	local backarms = "/assetmissing.png"
	local frontarms = "/assetmissing.png"

	if state.idle.head ~= nil then
		head = p.fixPathTags(animatedParts.parts.head.partStates.headState[state.idle.head].properties.image, skin, directives)
	end
	if state.idle.body ~= nil then
		body = p.fixPathTags(animatedParts.parts.background.partStates.bodyState[state.idle.body].properties.image, skin, directives)
	end
	if state.idle.tail ~= nil then
		tail = p.fixPathTags(animatedParts.parts.tail.partStates.tailState[state.idle.tail].properties.image, skin, directives)
	end
	if state.idle.legs ~= nil then
		backlegs = p.fixPathTags(animatedParts.parts.backlegs.partStates.legsState[state.idle.legs].properties.image, skin, directives)
		frontlegs = p.fixPathTags(animatedParts.parts.frontlegs.partStates.legsState[state.idle.legs].properties.image, skin, directives)
	end
	if state.idle.arms ~= nil then
		backarms = p.fixPathTags(animatedParts.parts.backarms.partStates.legsState[state.idle.arms].properties.image, skin, directives)
		frontarms = p.fixPathTags(animatedParts.parts.frontarms.partStates.legsState[state.idle.arms].properties.image, skin, directives)
	end

	animator.setAnimationState( occupant.seatname.."State", "smol", true )
	animator.setPartTag(seatname, "<smolpath>", head)
	animator.setPartTag(seatname.."body", "<smolpath>", body)
	animator.setPartTag(seatname.."tail", "<smolpath>", tail)
	animator.setPartTag(seatname.."backlegs", "<smolpath>", backlegs)
	animator.setPartTag(seatname.."frontlegs", "<smolpath>", frontlegs)
	animator.setPartTag(seatname.."backarms", "<smolpath>", backarms)
	animator.setPartTag(seatname.."frontarms", "<smolpath>", frontarms)
end

function p.fixPathTags(path, skin, directives)
	local path = path
	path = sb.replaceTags(path, "<skin>", skin)
	path = sb.replaceTags(path, "<directives>", directives)
	path = sb.replaceTags(path, "<bap>", "")
	return path
end

function p.victimAnimUpdate(entity)
	if entity == nil then return end
	local victimAnim = p.entity[entity].victimAnim
	if not victimAnim.enabled then return end
	local statename = p.entity[entity].victimAnim.statename
	local ended, times, time = p.hasAnimEnded(statename)
	local anim = p.victimAnimations[victimAnim.anim]
	if ended and not anim.loop then victimAnim.enabled = false return
	else
		local occupantIndex = p.entity[entity].index
		local seatname = p.entity[entity].seatname
		local speed = p.animStateData[statename].animationState.frames / p.animStateData[statename].animationState.cycle
		local frame = math.floor(time * speed)
		local nextFrame = frame + 1
		local nextFrameIndex = nextFrame + 1
		local lastframe = false

		if victimAnim.prevFrame ~= frame then
			if anim.frames then
				for i = 1, #anim.frames do
					if (anim.frames[i] == frame) and (i ~= #anim.frames) then
						nextFrame = anim.frames[i + 1]
						nextFrameIndex = i + 1
					end
					if anim.loop and (i == #anim.frames) then
						nextFrame = 0
						nextFrameIndex = 1
					elseif (i == #anim.frames) then
						lastframe = true
					end
				end
			end
			victimAnim.prevFrame = victimAnim.frame
			victimAnim.frame = nextFrame

			victimAnim.prevIndex = victimAnim.index
			victimAnim.index = nextFrameIndex

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
		local progress = (currTime - victimAnim.prevFrame)/(victimAnim.frame - victimAnim.prevFrame) * (victimAnim.interpMode or 1)
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
	p.entity[occupantId].victimAnim = {
		enabled = true,
		statename = statename,
		anim = anim,
		frame = 1,
		index = 2,
		prevFrame = 0,
		prevIndex = 1,

		last = {}
	}
	for arg, default in pairs(victimAnimArgs) do
		if p.victimAnimations[anim][arg] ~= nil then
			p.entity[occupantId].victimAnim.last[arg] = p.victimAnimations[anim][arg][1]
		else
			p.entity[occupantId].victimAnim.last[arg] = default
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
	local frame = math.floor(time * speed) + 1

	for _,r in ipairs(p.rotating.parts) do
		local previousRotation = r.rotation[frame] or 0
		local nextRotation = r.rotation[frame + 1] or previousRotation
		local rotation = previousRotation + (nextRotation - previousRotation) * (time % 1)
		for i = 1, #r.groups do
			animator.resetTransformationGroup( r.groups[i] )
			animator.rotateTransformationGroup(r.groups[i], (rotation * math.pi/180), r.center)
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
		p.endAnim(p.animStateData[state])

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
		else
			p.doAnim( state.."State", anim, force)
		end
	end
end

function p.setAnimTag(anim)
	for _,tag in ipairs(anim) do
		p.animStateData[tag.owner.."State"].tags = {
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
		if not p.offsets.enabled then p.offsets.time = 0 p.offsets.enabled = true end
		return
	end
	p.offsets = {
		enabled = data ~= nil,
		data = data,
		parts = {},
		loop = data.loop or false,
		timing = data.timing or "body"
	}
	local continue = false
	for _,r in ipairs(data.parts or {}) do
		table.insert(p.offsets.parts, {
			x = r.x or {0},
			y = r.y or {0},
			groups = r.groups or {"headbob"},
			})
		if (r.x and #r.x > 1) or (r.y and #r.y > 1) then
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
	if data == p.rotating.data then
		if not p.rotating.enabled then p.rotating.enabled = true end
		return
	end
	p.rotating = {
		enabled = data ~= nil,
		data = data,
		parts = {},
		loop = data.loop or false,
		timing = data.timing or "body"
	}
	local continue = false
	for _,r in ipairs(data.parts or {}) do
		table.insert(p.rotating.parts, {
			groups = r.groups or {"frontarmrotation"},
			center = r.center or {0,0},
			rotation = r.rotation or {0}
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
