
function p.setPartTag(part, tag, value)
	p.partTags[part][tag] = value
end

function p.getAnimData()
	p.loopedMessage("getAnimData", p.spawner, "sbqGetAnimData", {p.partTags}, function(animData)
		--p.animStateData = animData[1]
		animator.setFlipped(animData[2]==-1)
		p.direction = animData[2]
	end)
end

function p.doAnims( anims, force )
	world.sendEntityMessage(p.spawner, "sbqDoAnims", anims, force)

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
			--p.doAnim( state.."State", anim, force)
			p.doAnimData(state.."State", anim, force)
		end
	end
end

function p.doAnim( state, anim, force )
	world.sendEntityMessage(p.spawner, "sbqDoAnim", state, anim, force)
	p.doAnimData(state, anim, force)
end

function p.doAnimData(state, anim, force)
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
	end
end
