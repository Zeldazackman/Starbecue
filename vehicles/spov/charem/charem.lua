

require("/scripts/vore/vsosimple.lua")
require("/vehicles/spov/playable_vso.lua")

p.vsoMenuName = "charem"
p.startState = "back"

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)
	p.onForcedReset()
end

function onBegin()	--This sets up the VSO ONCE.
	p.onBegin()
	vsoOnInteract( "state_back", p.onInteraction )
	vsoOnInteract( "state_hug", p.onInteraction )
end

function onEnd()
	p.onEnd()
end

p.registerStateScript( "back", "bed", function( args )
	local index = p.occupants.total + 1

	if p.eat( args.id, index, "hug" ) then
		vsoVictimAnimSetStatus( "occupant"..index, {} );
		return true, nil, {index = index}
	else
		return false
	end
end)

function state_back()
	p.standardState()

	-- simulate npc interaction when nearby
	if p.occupants.total == 0 and p.control.standalone then
		if vsoChance(0.1) then -- every frame, we don't want it too often
			local npcs = world.npcQuery(mcontroller.position(), 4)
			if npcs[1] ~= nil then
				p.doTransition( "bed", {id=npcs[1]} )
			end
		end
	end
end

p.registerStateScript( "back", "unbed", function(args)
	return p.doEscape({index = p.findFirstIndexForLocation("hug")}, "hug", {1.3125, -2.0}, {}, {})
end)

state_hug = p.standardState
