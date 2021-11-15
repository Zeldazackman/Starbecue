
function p.setPartTag(part, tag, value)
	p.partTags[part][tag] = value
end

function p.sendAnimData()
end

function p.doAnims( anims, force )
	world.sendEntityMessage(p.spawner, "sbqDoAnims", anims, force)
end

function p.doAnim( state, anim, force )
	world.sendEntityMessage(p.spawner, "sbqDoAnim", state, anim, force)
end

function p.doVictimAnim()
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

function p.hasAnimEnded(state)
	local ended = (p.animStateData[state].animationState.time >= p.animStateData[state].animationState.cycle)
	local times = math.floor(p.animStateData[state].animationState.time/p.animStateData[state].animationState.cycle)
	local currentCycle = (p.animStateData[state].animationState.time - (p.animStateData[state].animationState.cycle*times))
	return ended, times, currentCycle
end

function p.animationIs(state, anim)
	return p.animStateData[state].animationState.anim == anim
end
