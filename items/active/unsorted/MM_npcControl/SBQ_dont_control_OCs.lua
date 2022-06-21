local _init = init

function init()
	_init()
	message.setHandler( "sbqResetCamera", function()
		activeItem.setCameraFocusEntity()
		player.setProperty("MM_npcControl", nil)
	end)
end
