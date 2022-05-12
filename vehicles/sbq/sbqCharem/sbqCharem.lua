

require("/vehicles/sbq/sbq_main.lua")

state = {
	back = {},
	hug = {}
}

function state.back.eat( args, tconfig )
	return sbq.doVore(args, "belly", {}, "swallow", tconfig.voreType)
end

function state.back.anal( args, tconfig )
	return sbq.doVore(args, "belly", {}, "swallow", tconfig.voreType)
end

function state.back.analescape( args, tconfig )
	return sbq.doEscape(args, {}, {}, tconfig.voreType )
end

function state.back.escape( args, tconfig )
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {}, tconfig.voreType )
end

function state.back.bed( args )
	return sbq.eat( args.id, "hug" )
end

function state.back.update()
	-- simulate npc interaction when nearby
	if sbq.occupants.total == 0 and not sbq.isObject then
		if sbq.randomChance(1) then -- every frame, we don't want it too often
			local npcs = world.npcQuery(mcontroller.position(), 4)
			if npcs[1] ~= nil then
				sbq.doTransition( "bed", {id=npcs[1]} )
			end
		end
	end
end

function state.back.unbed(args)
	return sbq.uneat(sbq.findFirstOccupantIdForLocation("hug"))
end

---------------------------------------------------------------------------

function state.hug.eat( args, tconfig )
	return sbq.doVore(args, "belly", {}, "swallow", tconfig.voreType)
end

function state.hug.anal( args, tconfig )
	return sbq.doVore(args, "belly", {}, "swallow", tconfig.voreType)
end

function state.hug.analescape( args, tconfig )
	return sbq.doEscape(args, {}, {}, tconfig.voreType )
end

function state.hug.escape( args, tconfig )
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {}, tconfig.voreType )
end
