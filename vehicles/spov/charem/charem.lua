

require("/vehicles/spov/playable_vso.lua")

state = {
	back = {},
	hug = {}
}

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)
end

function onBegin()	--This sets up the VSO ONCE.
end

function onEnd()
end

function state.back.eat( args )
	return p.doVore(args, "belly", {"vsoindicatemaw"}, "swallow")
end

function state.back.anal( args )
	return p.doVore(args, "belly", {"vsoindicateguts"}, "swallow")
end

function state.back.analescape( args )
	return p.doEscape(args, "belly", {-3, -3.5}, {"vsoindicateguts"}, {"droolsoaked", 5} )
end

function state.back.bed( args )
	if p.eat( args.id, "hug" ) then
		--vsoVictimAnimSetStatus( "occupant"..index, {} );
		return true
	else
		return false
	end
end

function state.back.update()
	-- simulate npc interaction when nearby
	if p.occupants.total == 0 and p.standalone then
		if p.randomChance(1) then -- every frame, we don't want it too often
			local npcs = world.npcQuery(mcontroller.position(), 4)
			if npcs[1] ~= nil then
				p.doTransition( "bed", {id=npcs[1]} )
			end
		end
	end
end

function state.back.unbed(args)
	return p.doEscapeNoDelay({index = p.findFirstIndexForLocation("hug")}, "hug", {1.3125, -2.0}, {})
end

---------------------------------------------------------------------------

function state.hug.eat( args )
	return p.doVore(args, "belly", {"vsoindicatemaw"}, "swallow")
end

function state.hug.anal( args )
	return p.doVore(args, "belly", {"vsoindicateguts"}, "swallow")
end

function state.hug.analescape( args )
	return p.doEscape(args, "belly", {-3, -2.5}, {"vsoindicateguts"}, {"droolsoaked", 5} )
end
