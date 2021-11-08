--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/sbq/sbq_main.lua")

state = {
	smol = {}
}

-------------------------------------------------------------------------------

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

	p.setPartTag( "global", "cracks", p.settings.cracks )
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
	p.doAnim("bodyState", "s_"..args.direction)

	if p.settings.cracks > 3 then
		local shard = "?addmask=/vehicles/sbq/sbqEgg/skins/shards.png:"
		local skinNames = p.settings.skinNames or {}
		local skin = skinNames.body or "default"
		local flip = ""
		local blend = "?blendmult=/vehicles/sbq/sbqEgg/skins/"..skin.."/smol/smol_body.png:0.idle.1"
		if p.direction < 0 then
			flip = "?flipx"
		end

		for i = 1, 10 do
			world.spawnProjectile( "sbqEggShard", mcontroller.position(), entity.id(), {(math.random(-1,1) * math.random()), math.random()}, false, {
				processing = blend..p.settings.directives..shard..tostring(i)..flip,
				timeToLive = math.random(0,3) + math.random(),
				speed = math.random(5,10) + math.random()
			})
		end
		p.onDeath()
	else p.setPartTag( "global", "cracks", p.settings.cracks )
	end
end


-------------------------------------------------------------------------------
