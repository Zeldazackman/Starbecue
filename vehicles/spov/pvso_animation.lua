
function p.updateAnims(dt)
	for i = 1, #p.animPartLists.stateTypes do
		p.animationState[p.animPartLists.stateTypes[i]].time = p.animationState[p.animPartLists.stateTypes[i]].time + dt
		if p.animationState[p.animPartLists.stateTypes[i]].time >= p.animationState[p.animPartLists.stateTypes[i]].cycle then -- anim end stuff here

			for j = 1, #p.animationState[p.animPartLists.stateTypes[i]].queue[j] do -- end of anim function queue
				local func = p.animationState[p.animPartLists.stateTypes[i]].queue[j]
				func()
			end
			p.animationState[p.animPartLists.stateTypes[i]].queue = {}
		end
	end
	for owner,tag in pairs( p.currentTags ) do
		if p.animationState[owner.."State"].ended then
			if tag.reset then
				if tag.part == "global" then
					animator.setGlobalTag( tag.name, "" )
				else
					animator.setPartTag( tag.part, tag.name, "" )
				end
				p.currentTags[owner] = nil
			end
		end
	end
	p.offsetAnimUpdate()
	p.rotationAnimUpdate()
	p.victimAnimUpdate()
end

function p.victimAnimUpdate()
	local seat = p.victimAnim.seat
	local state = p.victimAnim.state
	local ended, times, time = p.hasAnimEnded(state)
	local anim = p.victimAnimations[anim]
	if ended and not anim.loop then p.victimAnim.enabled = false
	else
		local eid = vehicle.entityLoungingIn(seat)
		local occupantIndex = tonumber(seat:sub(#"occupant"+1))
		local speed = p.animationState[state].frames / p.animationState[state].cycle
		local frame = math.floor(time * speed)
		local nextFrame = frame + 1
		local nextFrameIndex = nextFrame + 1

		if p.victimAnim.prevFrame ~= frame then
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
			p.victimAnim.prevFrame = p.victimAnim.frame
			p.victimAnim.frame = nextFrame

			p.victimAnim.prevIndex = p.victimAnim.index
			p.victimAnim.index = nextFrameIndex

			if anim.e ~= nil and anim.e[p.victimAnim.prevIndex] ~= nil then
				world.sendEntityMessage(eid, "applyStatusEffect", anim.e[p.victimAnim.prevIndex], (p.victimAnim.frame - p.victimAnim.prevFrame) * (p.animationState[state].cycle / p.animationState[state].frames) + 0.1, entity.id())
			end
			if anim.invis ~= nil and anim.e[p.victimAnim.prevIndex] ~= nil then
				if anim.e[p.victimAnim.prevIndex] == 0 then
					p.removeLoungeStatusFromList(occupantIndex, "pvsoinvisible")
				else
					p.addLoungeStatusToList(occupantIndex, "pvsoinvisible")
				end
			end
			if anim.sitpos ~= nil and anim.sitpos[p.victimAnim.prevIndex] ~= nil then
				vehicle.setLoungeOrientation(anim.sitpos[p.victimAnim.prevIndex])
			end
			if anim.emote ~= nil and anim.emote[p.victimAnim.prevIndex] ~= nil then
				vehicle.setLoungeEmote(anim.emote[p.victimAnim.prevIndex])
			end
			if anim.dance ~= nil and anim.dance[p.victimAnim.prevIndex] ~= nil then
				vehicle.setLoungeDance(anim.dance[p.victimAnim.prevIndex])
			end
		end

		local timeMod = time % (p.victimAnim.frame - p.victimAnim.prevFrame)
		local transformGroup = p.victimAnim.seat.."Position"
		local scale = {(anim[p.victimAnim.prevIndex].xs + (anim[p.victimAnim.index].xs - anim[p.victimAnim.prevIndex].xs) * timeMod), (anim[p.victimAnim.prevIndex].ys + (anim[p.victimAnim.index].ys - anim[p.victimAnim.prevIndex].ys) * timeMod)}
		local rotation = anim[p.victimAnim.prevIndex].r + (anim[p.victimAnim.index].r - anim[p.victimAnim.prevIndex].r) * timeMod
		local translation = {(anim[p.victimAnim.prevIndex].x + (anim[p.victimAnim.index].x - anim[p.victimAnim.prevIndex].x) * timeMod), (anim[p.victimAnim.prevIndex].y + (anim[p.victimAnim.index].y - anim[p.victimAnim.prevIndex].y) * timeMod)}

		animator.resetTransformationGroup(transformGroup)
		--could probably use animator.transformTransformationGroup() and do everything below in one matrix but I don't know how those work exactly so
		animator.scaleTransformationGroup(transformGroup, scale)
		animator.rotateTransformationGroup(transformGroup, (rotation * math.pi/180))
		animator.translateTransformationGroup(transformGroup, translation)
	end
end

p.victimAnim = { enabled = false }
function p.doVictimAnim(seatname, anim, state)
	p.victimAnim = {
		enabled = true,
		seatname = seatname,
		state = state,
		anim = anim,
		frame = 0,
		index = 1,
		prevFrame = 0,
		prevIndex = 1,
	}
	p.victimAnimUpdate()
end

function p.offsetAnimUpdate()
	if p.offsets == nil or not p.offsets.enabled then return end
	local state = p.offsets.timing.."State"
	local ended, times, time = p.hasAnimEnded(state)
	if ended and not p.offsets.loop then p.offsets.enabled = false end
	local speed = p.animationState[state].frames / p.animationState[state].cycle
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
	local speed = p.animationState[state].frames / p.animationState[state].cycle
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
		p.animationState[state].priority = newPriority
	end
	table.insert(p.animationState[state].queue, func)
end

function p.doAnim( state, anim, force)
	local oldPriority = p.animationState[state].priority
	local newPriority = (p.animStateData[state].states[anim] or {}).priority or 0
	local isSame = p.animationIs( state, anim )
	local force = force
	local priorityHigher = (tonumber(newPriority) >= tonumber(oldPriority)) or (tonumber(newPriority) == -1)
	if (not isSame and priorityHigher) or p.hasAnimEnded(state) or force then
		p.animationState[state] = {
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

p.currentTags = {}
function p.doAnims( anims, force )
	for state,anim in pairs( anims or {} ) do
		if state == "offset" then
			p.offsetAnim( anim )
		elseif state == "rotate" then
			p.rotate( anim )
		elseif state == "tags" then
			for _,tag in ipairs(anim) do
				p.currentTags[tag.owner] = {
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
		else
			p.doAnim( state.."State", anim, force)
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
	local ended = (p.animationState[state].time >= p.animationState[state].cycle)
	local times = math.floor(p.animationState[state].time/p.animationState[state].cycle)
	local currentCycle = (p.animationState[state].time - (p.animationState[state].cycle*times))
	return ended, times, currentCycle
end

function p.animationIs(state, anim)
	return animator.animationState(state) == anim
end
