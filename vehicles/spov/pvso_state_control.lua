
function p.standardState()
end


function p.setState(state)
	if state == nil then
		sb.logError( "nil state from ".. p.state )
	end
	p.state = state
	animator.setGlobalTag( "state", state )
	vsoNext( "state_"..state )
	p.doAnims( p.stateconfig[state].idle )
end

p.statescripts = {}

function p.registerStateScript( state, name, func )
	if p.statescripts[state] == nil then
		p.statescripts[state] = {}
	end
	p.statescripts[state][name] = func
end

local _ptransition = {}

function p.doTransition( direction, scriptargs )
	if not p.stateconfig[p.state].transitions[direction] then return end
	local tconfig = p.occupantArray( p.stateconfig[p.state].transitions[direction] )
	if tconfig == nil then return end
	local continue = true
	local after = function() end
	if tconfig.script then
		local statescript = p.statescripts[p.state][tconfig.script]
		local _continue, _after, _tconfig = statescript( scriptargs or {} )
		if _continue ~= nil then continue = _continue end
		if _after ~= nil then after = _after end
		if _tconfig ~= nil then tconfig = _tconfig end
	end
	if not continue then return end
	_ptransition.after = after
	_ptransition.state = tconfig.state or p.state
	_ptransition.timing = tconfig.timing or "body"
	if tconfig.animation ~= nil then
		p.doAnims( tconfig.animation )
	end
	if tconfig.victimAnimation ~= nil then
		local i = (scriptargs or {}).index
		if i == nil then
			i = p.occupants.total
			if p.justAte then
				i = i + 1
				p.justAte = false
			elseif tconfig.victimAnimLocation ~= nil then
				i = p.findFirstIndexForLocation(tconfig.victimAnimLocation)
			end
		end
		if i then p.doVictimAnim( "occupant"..i, tconfig.victimAnimation, _ptransition.timing.."State" ) end
	end
	return true
end

-- somehow, even though I change the animation tag *after* vsoAnimEnded, it's too early

-- this itself as well as the _ptransition.after() thing should be changed to use p.queueAnimEndFunction
local _endedframes = 0
function state__ptransition()
	if p.hasAnimEnded( _ptransition.timing.."State" ) then
		_endedframes = _endedframes + 1
		if _endedframes > 2 then
			_endedframes = 0
			_ptransition.after()
			p.setState( _ptransition.state )
			p.doAnims( p.stateconfig[p.state].idle )
		end
	end
	if not p.stateconfig[p.state].noPhysicsTransition then
		 p.doPhysics()
	end
end

function p.idleStateChange()
	if not p.control.probablyOnGround() or not p.control.notMoving() or p.movement.animating then return end

	if p.randomTimer( "idleStateChange", 5.0, 5.0 ) then -- every 5 seconds? this is arbitrary, oh well
		local transitions = p.stateconfig[p.state].transitions
		if not p.control.driving then
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
