local oldinit = init
function init()
	oldinit()
	message.setHandler( "openVSOsettings", function(_,_, vso, occupants, maxOccupants, vsoMenuName )
		local pane = root.assetJson("/interface/scripted/" "settings/"vsoMenuName.."settings.config")
		pane.vso = vso
		pane.occupants = occupants
		pane.maxOccupants = maxOccupants
		player.interact( "ScriptPane", pane, vso )
	end)
	message.setHandler( "load"vsoMenuName.."settings", function()
		return player.getProperty( vsoMenuName.."Settings" ) or {}
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
		local settings = player.getProperty( vsoMenuName.."Settings" ) or {}
		world.spawnVehicle( "spov"..species, { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = settings, uneaten = true } )
	end )
end