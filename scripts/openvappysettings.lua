local oldinit = init
function init()
	oldinit()
	message.setHandler( "openvappysettings", function(_,_, vappy )
		local pane = root.assetJson("/interface/scripted/vappysettings/vappysettings.config")
		pane.vappy = vappy
		player.interact( "ScriptPane", pane, vappy )
	end)
	message.setHandler( "vappyautodeploy", function()
		return player.getProperty( "vappyAutoDeploy" )
	end)
end