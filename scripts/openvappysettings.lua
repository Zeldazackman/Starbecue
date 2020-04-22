local oldinit = init
function init()
	oldinit()
	message.setHandler( "openvappysettings", function(_,_, vappy, firstOccupant, secondOccupant )
		local pane = root.assetJson("/interface/scripted/vappysettings/vappysettings.config")
		pane.vappy = vappy
		pane.firstOccupant = firstOccupant
		pane.secondOccupant = secondOccupant
		player.interact( "ScriptPane", pane, vappy )
	end)
	message.setHandler( "loadvappysettings", function()
		return player.getProperty( "vappySettings" )
	end)
	message.setHandler( "isLounging", function()
		return player.isLounging()
	end)
	-- override handler from ssvm maybe?? we'll see
	message.setHandler("vsoForcePlayerSit", function( _, _, sourceEntityId, seatindex )
		world.sendEntityMessage( sourceEntityId, "forcedsit", seatindex )
		return player.lounge( sourceEntityId, seatindex );
	end )
end