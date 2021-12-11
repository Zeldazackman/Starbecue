

require("/vehicles/sbq/sbq_main.lua")

state = {
	back = {},
	hug = {}
}

function state.back.eat( args )
	return p.doVore(args, "belly", {}, "swallow")
end

function state.back.anal( args )
	return p.doVore(args, "belly", {}, "swallow")
end

function state.back.analescape( args )
	return p.doEscape(args, {}, {} )
end

function state.back.escape( args )
	return p.doEscape(args, {wet = { power = 5, source = entity.id()}}, {} )
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
	return p.doVore(args, "belly", {}, "swallow")
end

function state.hug.anal( args )
	return p.doVore(args, "belly", {}, "swallow")
end

function state.hug.analescape( args )
	return p.doEscape(args, {}, {} )
end

function state.hug.escape( args )
	return p.doEscape(args, {wet = { power = 5, source = entity.id()}}, {} )
end
