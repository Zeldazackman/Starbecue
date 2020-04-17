local vappy
local bellyeffects = {
	[-1] = "", [0] = "heal", [1] = "digest", [2] = "softdigest",
	[""] = -1, ["heal"] = 0, ["digest"] = 1, ["softdigest"] = 2 -- reverse lookup
}
local clickmodes = {
	[-1] = "attack", [0] = "build",
	["attack"] = -1, ["build"] = 0

}
local rpcGet

function init()
	vappy = config.getParameter( "vappy" )
	rpcGet = world.sendEntityMessage( vappy, "settingsMenuGet" )
	widget.setChecked( "autoDeploy", player.getProperty( "vappyAutoDeploy" ) or false )
end

function update( dt )
	if rpcGet ~= nil and rpcGet:finished() then
		if rpcGet:succeeded() then
			local result = rpcGet:result()
			widget.setSelectedOption( "bellyEffect", bellyeffects[result.bellyeffect] )
			widget.setSelectedOption( "clickMode", clickmodes[result.clickmode] )
		else
			sb.logError( "Couldn't get data for Vappy settings menu." )
			sb.logError( rpcGet:error() )
		end
		rpcGet = nil
		-- rpcGet = world.sendEntityMessage( vappy, "settingsMenuGet" )
	end
end

function setBellyEffect()
	local value = widget.getSelectedOption( "bellyEffect" )
	local bellyeffect = bellyeffects[value]
	world.sendEntityMessage( vappy, "settingsMenuSet", "bellyeffect", bellyeffect )
	player.setProperty( "vappyBellyEffect", bellyeffect )
end
function setClickMode()
	local value = widget.getSelectedOption( "clickMode" )
	local clickmode = clickmodes[value]
	world.sendEntityMessage( vappy, "settingsMenuSet", "clickmode", clickmode )
	player.setProperty( "vappyClickMode", clickmode )
end
function autoDeploy()
	local value = widget.getChecked( "autoDeploy" )
	player.setProperty( "vappyAutoDeploy", value )
end

function despawn()
	world.sendEntityMessage( vappy, "despawn" )
end