

require("/vehicles/sbq/sbq_main.lua")

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
	return p.doEscape(args, {"vsoindicateguts"}, {"droolsoaked", 5} )
end

function state.back.escape( args )
	return p.doEscape(args, {"vsoindicatemaw"}, {"droolsoaked", 5} )
end

function state.back.bed( args )
	return p.eat( args.id, "hug" )
end

function state.back.update()
	-- simulate npc interaction when nearby
	if p.occupants.total == 0 and not p.isObject then
		if p.randomChance(1) then -- every frame, we don't want it too often
			local npcs = world.npcQuery(mcontroller.position(), 4)
			if npcs[1] ~= nil then
				p.doTransition( "bed", {id=npcs[1]} )
			end
		end
	end
end

function state.back.unbed(args)
	return p.uneat(p.findFirstOccupantIdForLocation("hug"))
end

---------------------------------------------------------------------------

function state.hug.eat( args )
	return p.doVore(args, "belly", {"vsoindicatemaw"}, "swallow")
end

function state.hug.anal( args )
	return p.doVore(args, "belly", {"vsoindicateguts"}, "swallow")
end

function state.hug.analescape( args )
	return p.doEscape(args, {"vsoindicateguts"}, {"droolsoaked", 5} )
end

function state.hug.escape( args )
	return p.doEscape(args, {"vsoindicatemaw"}, {"droolsoaked", 5} )
end
