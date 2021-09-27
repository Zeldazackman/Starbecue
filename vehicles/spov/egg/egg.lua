--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/spov/playable_vso.lua")

state = {
	smol = {}
}

-------------------------------------------------------------------------------

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

end

function onBegin()
	p.occupant[0].location = "egg"
	p.occupants.total = 1
	p.occupants.egg = 1
	p.includeDriver = true
	p.driving = false

	if not p.settings.cracks then
		p.settings.cracks = 0
	end

	if p.settings.escapeModifier == "noEscape" then
		p.settings.escapeModifier = "antiEscape"
	end

	animator.setGlobalTag( "cracks", p.settings.cracks )
end

function onEnd()
end

-- don't want warp effects on this ever
function p.warpInEffect() end
function p.warpOutEffect() end

-------------------------------------------------------------------------------

function state.smol.crack( args )
	p.settings.cracks = p.settings.cracks + 1
	animator.playSound("crack")

	if p.settings.cracks > 3 then
		local path = "/vehicles/spov/egg/spov/"..(p.settings.skinNames.body or "default" ).."/smol/smol_body.png:0.idle.1?addmask=/vehicles/spov/egg/spov/shards.png:"

		for i = 1, 10 do
			world.spawnProjectile( "eggShard", mcontroller.position(), entity.id(), {(math.random(-1,1) * math.random()), math.random()}, false, {
				image = path..tostring(i)
			})
		end
		p.onDeath()
	else animator.setGlobalTag( "cracks", p.settings.cracks )
	end
end


-------------------------------------------------------------------------------
