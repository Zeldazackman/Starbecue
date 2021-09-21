

function p.updateState(dt)
	if p.prevState == p.state then
		if state[p.state] ~= nil and state[p.state].update ~= nil then
			state[p.state].update(dt)
		else
			p.standardState(dt)
		end
	else
		if state[p.prevState] ~= nil and state[p.prevState].ending ~= nil then
			state[p.prevState].ending(dt)
		end
		if state[p.state] ~= nil and state[p.state].begin ~= nil then
			state[p.state].begin(dt)
		end
		if p.stateconfig[p.state].control ~= nil and p.stateconfig[p.state].control.defaultActions ~= nil and p.driver ~= nil then
			world.sendEntityMessage(p.driver, "primaryItemData", {
				defaultClickAction = p.stateconfig[p.state].control.defaultActions[1]
			})
			world.sendEntityMessage(p.driver, "altItemData", {
				defaultClickAction = p.stateconfig[p.state].control.defaultActions[2]
			})
		end
		p.prevState = p.state
	end
end

function p.setState(state)
	if state == nil then
		sb.logError( "nil state from ".. p.state )
	end
	p.prevState = p.state
	p.state = state
	animator.setGlobalTag( "state", state )
	p.doAnims( p.stateconfig[state].idle, true )
end

p.transitionLock = false
p.movementLock = false

function p.doTransition( direction, scriptargs )
	if (not p.stateconfig[p.state].transitions[direction]) then return "no data" end
	if p.transitionLock then return "locked" end
	local tconfig = p.occupantArray( p.stateconfig[p.state].transitions[direction] )
	if tconfig == nil then return "no data" end
	local id = p.getTransitionVictimId(scriptargs, tconfig)

	if tconfig.voreType ~= nil and id ~= nil then
		p.addRPC(world.sendEntityMessage(id, "pvsoIsPreyEnabled", tconfig.voreType), function(enabled)
			if enabled then
				p.doingTransition(tconfig, direction, scriptargs)
			end
		end)
	else
		return p.doingTransition(tconfig, direction, scriptargs)
	end
end

function p.doingTransition(tconfig, direction, scriptargs)
	if p.transitionLock then return "locked" end
	local continue = true
	local after
	if tconfig.script then
		local statescript = state[p.state][tconfig.script]
		local _continue, _tconfig
		if statescript ~= nil then
			_continue, after, _tconfig = statescript( scriptargs or {} )
			if _continue ~= nil then continue = _continue end
			if _tconfig ~= nil then tconfig = _tconfig end
		else
			sb.logError("no script named: ["..tconfig.script.."] in state: ["..p.state.."]")
		end
	end
	if not continue then return "script fail" end

	if tconfig.timing == nil then
		tconfig.timing = "body"
	end
	if tconfig.animation ~= nil then
		p.doAnims( tconfig.animation )
	end
	if after ~= nil then
		p.queueAnimEndFunction(tconfig.timing.."State", after)
	end
	if (tconfig.state ~= nil) and (tconfig.state ~= p.state) then
		p.movementLock = true
		p.transitionLock = true

		p.queueAnimEndFunction(tconfig.timing.."State", function()
			p.setState( tconfig.state )
			p.doAnims( p.stateconfig[p.state].idle )
			p.transitionLock = false
			p.movementLock = false
		end)
	end
	if tconfig.lock then
		p.transitionLock = true
		p.queueAnimEndFunction(tconfig.timing.."State", function()
			p.transitionLock = false
		end)
	end
	if tconfig.victimAnimation ~= nil then -- lets make this use the id to get the index
		local id = p.getTransitionVictimId(scriptargs, tconfig)
		if id ~= nil then p.doVictimAnim( id, tconfig.victimAnimation, tconfig.timing.."State" or "bodyState" ) end
	end
	return "success", p.animStateData[tconfig.timing.."State" or "bodyState"].animationState.cycle
end

function p.getTransitionVictimId(scriptargs, tconfig)
	local id = (scriptargs or {}).id
	if id == nil then
		id = p.justAte
	end
	if tconfig.victimAnimLocation ~= nil then
		id = p.findFirstOccupantIdForLocation(tconfig.victimAnimLocation)
	end
	return id
end

function p.idleStateChange()
	if not p.notMoving() or p.movement.animating or p.transitionLock then return end

	if p.randomTimer( "idleStateChange", 5.0, 5.0 ) then -- every 5 seconds? this is arbitrary, oh well
		local transitions = p.stateconfig[p.state].transitions
		if not p.driver then
			local percent = math.random(100)
			for name, t in pairs(transitions) do
				local transition = p.occupantArray( t )
				if transition and transition.chance and transition.chance > 0 then
					percent = percent - transition.chance
					if percent <= 0 then
						p.doTransition( name )
						return
					end
				end
			end
		end
	end

	p.doAnims( p.stateconfig[p.state].idle )

	p.nextIdle = p.nextIdle - 1
	if p.nextIdle <= 0 then
		p.nextIdle = math.random(50, 300)
		local idles = p.stateconfig[p.state].idleAnimations
		if idles ~= nil and #idles >= 1 then
			local which = math.random(#idles)
			p.doAnims( idles[which] )
		end
	end
end
