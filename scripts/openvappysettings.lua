local oldinit = init
function init()
	oldinit()
	message.setHandler( "openvappysettings", function(_,_, vappy, firstOccupant, secondOccupant, firstSpecies, secondSpecies )
		local pane = root.assetJson("/interface/scripted/vappysettings/vappysettings.config")
		pane.vappy = vappy
		pane.firstOccupant = firstOccupant
		pane.secondOccupant = secondOccupant
		pane.firstSpecies = firstSpecies
		pane.secondSpecies = secondSpecies
		player.interact( "ScriptPane", pane, vappy )
	end)
	message.setHandler( "loadvappysettings", function()
		return player.getProperty( "vappySettings" ) or {}
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
		local settings = player.getProperty( "vappySettings" ) or {}
		world.spawnVehicle( "spov"..species, { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = settings, uneaten = true } )
	end )
end