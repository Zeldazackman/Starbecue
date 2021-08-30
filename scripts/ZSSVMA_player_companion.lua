local oldinit = init
function init()
	oldinit()
	message.setHandler( "loadVSOsettings", function(_,_, vsoMenuName )
		local settings = player.getProperty( "vsoSettings" ) or {}
		if vsoMenuName then return settings[vsoMenuName] or {} end
		return settings
	end)
	message.setHandler( "saveVSOsettings", function(_,_, settings )
		player.setProperty( "vsoSettings", settings )
	end)
	message.setHandler( "openPVSOInterface", function(_,_, name, args, appendSettings, sourceEntity)
		local pane = root.assetJson("/interface/scripted/pvso/"..name.."/"..name..".config")
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

	message.setHandler("spawnSmolPrey", function(_,_, species )
		local position = world.entityPosition( entity.id() )
		local settings = player.getProperty( "vsoSettings", {} )[species] or {}
		world.spawnVehicle( "spov"..species, { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = settings, uneaten = true, data = species } )
	end )

	message.setHandler("useEnergy", function( _, _, energyUsed)
		return status.overConsumeResource("energy", energyUsed)
	end )

	message.setHandler("getDriverStat", function( _, _, stat)
		return status.stat(stat)
	end )

	message.setHandler("addHungerHealth", function( _, _, amount)
		if status.resourcePercentage("food") < 1 then
			status.modifyResourcePercentage( "food", amount)
			return 1
		elseif status.resourcePercentage("health") < 1 then
			status.modifyResourcePercentage( "health", amount)
			return 2
		else
			return 3
		end
	end )

	message.setHandler("unlockVSO", function(_,_, name )
		local settings = player.getProperty( "vsoSettings" ) or {}
		if settings.vsos == nil then settings.vsos = {} end
		if not settings.vsos[name] then
			settings.vsos[name] = {}
		end
		player.setProperty( "vsoSettings", settings )
	end)

	message.setHandler("getRadialSelection", function(_,_, stat)
		return player.getProperty("radialSelection")
	end)

	message.setHandler("getVSOseatEquips", function()
		local seatdata = {
			head = player.equippedItem("head"),
			chest = player.equippedItem("chest"),
			legs = player.equippedItem("legs"),
			back = player.equippedItem("back"),
			headCosmetic = player.equippedItem("headCosmetic"),
			chestCosmetic = player.equippedItem("chestCosmetic"),
			legsCosmetic = player.equippedItem("legsCosmetic"),
			backCosmetic = player.equippedItem("backCosmetic"),
		}
		return seatdata
	end)
end
