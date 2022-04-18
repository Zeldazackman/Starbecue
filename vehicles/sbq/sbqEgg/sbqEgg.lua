--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/sbq/sbq_main.lua")

state = {
	smol = {}
}

-------------------------------------------------------------------------------

function sbq.init()
	sbq.occupant[0].location = "egg"
	sbq.occupant[0].visible = true
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

	if sbq.settings.skinNames.head == "plastic" then
		if not sbq.settings.firstLoadDone then
			-- get random directives for anyone thats not an avian
			for i = 1, #sbq.sbqData.replaceColors do
				sbq.settings.replaceColorTable[i] = sbq.sbqData.plasticReplaceColors[i][ (math.random( #sbq.sbqData.plasticReplaceColors[i]))]
			end
			sbq.settings.firstLoadDone = true
			sbq.setColorReplaceDirectives()
		end
		animator.setSoundPool("crack", {"/sfx/npc/enemydeathpuff.ogg"})
		sbq.settings.cracks = 3
		sbq.stateconfig.smol.struggle.egg.directions = {
			front = { victimAnimation = "s_front" },
			back = { victimAnimation = "s_back" },
			up = { chances = { min = 0, max = 0}, transition = "crack", victimAnimation = "s_back", indicate = "red" }
		}
		_onDeath = sbq.onDeath
		function sbq.onDeath(eaten)
			if not eaten then
				local item = { name = "sbqPlasticEgg", parameters = { scriptStorage = { settings = { color = sbq.settings.color, replaceColorTable = sbq.settings.replaceColorTable, directives = sbq.settings.directives, skinNames = sbq.settings.skinNames} } } }
				world.spawnItem(item, mcontroller.position() )
			end
			_onDeath(eaten)
		end
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
		local skinNames = sbq.settings.skinNames or {}
		local skin = skinNames.head or "default"
		local shard = ((sbq.sbqData.skinEggShards[skin] or {}).mask or "?addmask=/vehicles/sbq/sbqEgg/skins/shards.png")..":"
		local flip = ""
		local blend = "?blendmult=/vehicles/sbq/sbqEgg/skins/"..skin.."/smol/smol_body.png:3.idle.1?addmask=/vehicles/sbq/sbqEgg/skins/"..skin.."/smol/smol_body.png:3.idle.1;0;0"
		if sbq.direction < 0 then
			flip = "?flipx"
		end
		local shardPath = (sbq.sbqData.skinEggShards[skin] or {}).image
		if shardPath then
			for i = 1, 10 do
				world.spawnProjectile( "sbqEggShard", mcontroller.position(), entity.id(), {(math.random(-1,1) * math.random()), math.random()}, false, {
					processing = "?blendmult="..shardPath..":"..tostring(i).."?addmask="..shardPath..":"..tostring(i)..";0;0"..sbq.settings.directives..flip,
					timeToLive = math.random(1,3) + math.random(),
					speed = math.random(5,10) + math.random()
				})
			end
		else
			for i = 1, 10 do
				world.spawnProjectile( "sbqEggShard", mcontroller.position(), entity.id(), {(math.random(-1,1) * math.random()), math.random()}, false, {
					processing = blend..sbq.settings.directives..shard..tostring(i)..flip,
					timeToLive = math.random(1,3) + math.random(),
					speed = math.random(5,10) + math.random()
				})
			end
		end
		sbq.onDeath()
	else sbq.setPartTag( "global", "cracks", sbq.settings.cracks )
	end
end


-------------------------------------------------------------------------------
