--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/sbq/sbq_main.lua")

state = {
	smol = {}
}

-------------------------------------------------------------------------------

function sbq.init()
	sbq.occupant[0].location = "egg"
	sbq.occupants.total = 1
	sbq.occupants.egg = 1
	sbq.includeDriver = true
	sbq.driving = false

	if not sbq.settings.cracks then
		sbq.settings.cracks = 0
	end

	if sbq.settings.impossibleEscape then
		sbq.settings.impossibleEscape = false
	end

	sbq.setPartTag( "global", "cracks", sbq.settings.cracks )
end

-- don't want warp effects on this ever
function sbq.warpInEffect() end
function sbq.warpOutEffect() end

-------------------------------------------------------------------------------

function state.smol.crack( args )
	sbq.settings.cracks = sbq.settings.cracks + 1
	animator.playSound("crack")
	sbq.doAnim("bodyState", "s_"..args.direction)

	if sbq.settings.cracks > 3 then
		local shard = "?addmask=/vehicles/sbq/sbqEgg/skins/shards.png:"
		local skinNames = sbq.settings.skinNames or {}
		local skin = skinNames.body or "default"
		local flip = ""
		local blend = "?blendmult=/vehicles/sbq/sbqEgg/skins/"..skin.."/smol/smol_body.png:0.idle.1"
		if sbq.direction < 0 then
			flip = "?flipx"
		end

		for i = 1, 10 do
			world.spawnProjectile( "sbqEggShard", mcontroller.position(), entity.id(), {(math.random(-1,1) * math.random()), math.random()}, false, {
				processing = blend..sbq.settings.directives..shard..tostring(i)..flip,
				timeToLive = math.random(0,3) + math.random(),
				speed = math.random(5,10) + math.random()
			})
		end
		sbq.onDeath()
	else sbq.setPartTag( "global", "cracks", sbq.settings.cracks )
	end
end


-------------------------------------------------------------------------------
