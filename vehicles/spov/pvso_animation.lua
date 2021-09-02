
function p.updateAnims(dt)
	for statename, state in pairs(p.animStateData) do
		state.animationState.time = state.animationState.time + dt

		for seatname, victimAnim in pairs(state.victimAnims) do
			p.victimAnimUpdate(statename, seatname, victimAnim )
		end

		if state.animationState.time >= state.animationState.cycle then
			p.endAnim(state)
		end
	end
	p.offsetAnimUpdate()
	p.rotationAnimUpdate()
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

function p.victimAnimUpdate(statename, seatname, victimAnim)
	if victimAnim == nil then return end
	local ended, times, time = p.hasAnimEnded(statename)
	local anim = p.victimAnimations[victimAnim.anim]
	if ended and not anim.loop then victimAnim = nil
	else
		local eid = vehicle.entityLoungingIn(seatname)
		local occupantIndex = tonumber(seatname:sub(#"occupant"+1))
		local speed = p.animStateData[statename].animationState.frames / p.animStateData[statename].animationState.cycle
		local frame = math.floor(time * speed)
		local nextFrame = frame + 1
		local nextFrameIndex = nextFrame + 1

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
					end
				end
			end
			victimAnim.prevFrame = victimAnim.frame
			victimAnim.frame = nextFrame

			victimAnim.prevIndex = victimAnim.index
			victimAnim.index = nextFrameIndex

			if anim.e ~= nil and anim.e[victimAnim.prevIndex] ~= nil then
				world.sendEntityMessage(eid, "applyStatusEffect", anim.e[victimAnim.prevIndex], (victimAnim.frame - victimAnim.prevFrame) * (p.animStateData[statename].animationState.cycle / p.animStateData[statename].animationState.frames) + 0.1, entity.id())
			end
			if anim.invis ~= nil and anim.e[victimAnim.prevIndex] ~= nil then
				if anim.e[victimAnim.prevIndex] == 0 then
					p.removeLoungeStatusFromList(occupantIndex, "pvsoinvisible")
				else
					p.addLoungeStatusToList(occupantIndex, "pvsoinvisible")
				end
			end
			if anim.sitpos ~= nil and anim.sitpos[victimAnim.prevIndex] ~= nil then
				vehicle.setLoungeOrientation(seatname, anim.sitpos[victimAnim.prevIndex])
			end
			if anim.emote ~= nil and anim.emote[victimAnim.prevIndex] ~= nil then
				vehicle.setLoungeEmote(seatname, anim.emote[victimAnim.prevIndex])
			end
			if anim.dance ~= nil and anim.dance[victimAnim.prevIndex] ~= nil then
				vehicle.setLoungeDance(seatname, anim.dance[victimAnim.prevIndex])
			end
		end

		local timeMod = time % (victimAnim.frame - victimAnim.prevFrame)
		local transformGroup = seatname.."Position"
		local scale = {
			(p.getPrevVictimAnimValue(victimAnim, "xs") + (p.getNextVictimAnimValue(victimAnim, "xs") - p.getPrevVictimAnimValue(victimAnim, "xs")) * timeMod),
			(p.getPrevVictimAnimValue(victimAnim, "ys") + (p.getNextVictimAnimValue(victimAnim, "ys") - p.getPrevVictimAnimValue(victimAnim, "ys")) * timeMod)
		}
		local rotation = (p.getPrevVictimAnimValue(victimAnim, "r") + (p.getNextVictimAnimValue(victimAnim, "r") - p.getPrevVictimAnimValue(victimAnim, "r")) * timeMod)
		local translation = {
			(p.getPrevVictimAnimValue(victimAnim, "x") + (p.getNextVictimAnimValue(victimAnim, "x") - p.getPrevVictimAnimValue(victimAnim, "x")) * timeMod),
			(p.getPrevVictimAnimValue(victimAnim, "y") + (p.getNextVictimAnimValue(victimAnim, "y") - p.getPrevVictimAnimValue(victimAnim, "y")) * timeMod)
		}

		animator.resetTransformationGroup(transformGroup)
		--could probably use animator.transformTransformationGroup() and do everything below in one matrix but I don't know how those work exactly so
		animator.scaleTransformationGroup(transformGroup, scale)
		animator.rotateTransformationGroup(transformGroup, (rotation * math.pi/180))
		animator.translateTransformationGroup(transformGroup, translation)
	end
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

function p.doVictimAnim(seatname, anim, statename)
	p.animStateData[statename].victimAnims[seatname] = {
		anim = anim,
		frame = 0,
		index = 1,
		prevFrame = 0,
		prevIndex = 1,

		last = {}
	}
	for arg, default in pairs(victimAnimArgs) do
		if p.victimAnimations[anim][arg] ~= nil then
			p.animStateData[statename].victimAnims[seatname].last[arg] = p.victimAnimations[anim][arg][1]
		else
			p.animStateData[statename].victimAnims[seatname].last[arg] = default
		end
	end

	p.victimAnimUpdate(statename, seatname, p.animStateData[statename].victimAnims[seatname])
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
