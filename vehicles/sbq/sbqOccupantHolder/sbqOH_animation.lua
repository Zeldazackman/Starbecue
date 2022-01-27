
function sbq.setPartTag(part, tag, value)
	sbq.partTags[part][tag] = value
	animator.setPartTag(part, tag, value)
end

function sbq.getAnimData()
	sbq.loopedMessage("getAnimData", sbq.spawner, "sbqGetAnimData", {sbq.partTags}, function(animData)
		--p.animStateData = animData[1]
		animator.setFlipped(animData[2]==-1)
		sbq.direction = animData[2]
	end)
end

function sbq.doAnims( anims, force )
	world.sendEntityMessage(sbq.spawner, "sbqDoAnims", anims, force)

	for state,anim in pairs( anims or {} ) do
		if state == "offset" then
			sbq.offsetAnim( anim )
		elseif state == "rotate" then
			sbq.rotate( anim )
		elseif state == "tags" then
			sbq.setAnimTag( anim )
		elseif state == "priority" then
			sbq.changePriorityLength( anim )
		else
			--p.doAnim( state.."State", anim, force)
			sbq.doAnimData(state.."State", anim, force)
		end
	end
end

function sbq.doAnim( state, anim, force )
	world.sendEntityMessage(sbq.spawner, "sbqDoAnim", state, anim, force)
	sbq.doAnimData(state, anim, force)
end

function sbq.doAnimData(state, anim, force)
	local oldPriority = (sbq.animStateData[state].animationState or {}).priority or 0
	local newPriority = (sbq.animStateData[state].states[anim] or {}).priority or 0
	local isSame = sbq.animationIs( state, anim )
	local force = force
	local priorityHigher = ((newPriority >= oldPriority) or (newPriority == -1))
	if (not isSame and priorityHigher) or sbq.hasAnimEnded(state) or force then
		if isSame then
			local mode = sbq.animStateData[state].animationState.mode == "end"
			if mode == "end" then
				force = true
			elseif mode == "loop" then
				return
			end
		end
		sbq.animStateData[state].animationState = {
			anim = anim,
			priority = newPriority,
			cycle = sbq.animStateData[state].states[anim].cycle,
			frames = sbq.animStateData[state].states[anim].frames,
			mode = sbq.animStateData[state].states[anim].mode,
			speed = sbq.animStateData[state].states[anim].frames / sbq.animStateData[state].states[anim].cycle,
			frame = 1,
			time = 0
		}
	end
end
