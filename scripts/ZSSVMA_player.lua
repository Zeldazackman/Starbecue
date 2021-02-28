local oldinit = init
function init()
	oldinit()
	message.setHandler( "loadVSOsettings", function(_,_, vsoMenuName )
		local settings = player.getProperty( "vsoSettings", {} )
		if vsoMenuName then return settings[vsoMenuName] or {} end
		return settings
	end)
	message.setHandler( "openInterface", function(_,_, name, args, appendSettings, sourceEntity)
		local pane = root.assetJson("/interface/scripted/"..name.."/"..name..".config")
		if args then
			pane = sb.jsonMerge(pane, args)
		end
		if appendSettings and appendSettings ~= "" then
			pane.settings = player.getProperty( "vsoSettings", {} )
			if type(appendSettings) == "string" then
				pane.settings = pane.settings[appendSettings] or {}
			end
		end
		player.interact("ScriptPane", pane, sourceEntity or entity.id())
	end)
	message.setHandler( "isLounging", function()
		return player.isLounging(), player.loungingIn()
	end)
	-- override handler from ssvm maybe?? we'll see
	message.setHandler("vsoForcePlayerSit", function( _, _, sourceEntityId, seatindex )
		world.sendEntityMessage( sourceEntityId, "forcedsit", seatindex )
		return player.lounge( sourceEntityId, seatindex );
	end )

	message.setHandler("spawnSmolPrey", function(_,_, species )
		local position = world.entityPosition( entity.id() )
		local settings = player.getProperty( "vsoSettings", {} )[species] or {}
		world.spawnVehicle( "spov"..species, { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = settings, uneaten = true } )
	end )

	message.setHandler("useEnergy", function( _, _, energyUsed)
		return status.overConsumeResource("energy", energyUsed)
	end )

	message.setHandler("getDriverStat", function( _, _, stat)
		return status.stat(stat)
	end )

	message.setHandler("unlockVSO", function(_,_, name )
		local settings = player.getProperty( "vsoSettings", {} )
		if settings.vsos == nil then settings.vsos = {} end
		if not settings.vsos[name] then
			settings.vsos[name] = {}
		end
		player.setProperty( "vsoSettings", settings )
	end)

end