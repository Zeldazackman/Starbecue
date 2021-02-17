local oldinit = init
function init()
	oldinit()
	message.setHandler( "openxeronioussettings", function(_,_, xeronious, occupants, maxOccupants )
		local pane = root.assetJson("/interface/scripted/xeronioussettings/xeronioussettings.config")
		pane.xeronious = xeronious
		pane.occupants = occupants
		pane.maxOccupants = maxOccupants
		player.interact( "ScriptPane", pane, xeronious )
	end)
	message.setHandler( "loadxeronioussettings", function()
		return player.getProperty( "xeronioussettings" ) or {}
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
		local settings = player.getProperty( "xeronioussettings" ) or {}
		world.spawnVehicle( "spov"..species, { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = settings, uneaten = true } )
	end )
end