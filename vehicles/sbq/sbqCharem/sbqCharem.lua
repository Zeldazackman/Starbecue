

require("/vehicles/sbq/sbq_main.lua")

state = {
	back = {},
	hug = {}
}

function state.back.eat( args )
	return sbq.doVore(args, "belly", {}, "swallow", "oralVore")
end

function state.back.anal( args )
	return sbq.doVore(args, "belly", {}, "swallow", "analVore")
end

function state.back.analescape( args )
	return sbq.doEscape(args, {}, {}, "analVore" )
end

function state.back.escape( args )
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {}, "oralVore" )
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

function state.hug.eat( args )
	return sbq.doVore(args, "belly", {}, "swallow", "oralVore")
end

function state.hug.anal( args )
	return sbq.doVore(args, "belly", {}, "swallow", "analVore")
end

function state.hug.analescape( args )
	return sbq.doEscape(args, {}, {}, "analVore" )
end

function state.hug.escape( args )
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {}, "oralVore" )
end
