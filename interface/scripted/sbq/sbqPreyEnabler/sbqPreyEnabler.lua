p = {}
function init()
	p.config = root.assetJson( "/sbqGeneral.config")
	p.preySettings = sb.jsonMerge(p.config.defaultPreyEnabled.player, status.statusProperty("sbqPreyEnabled"))

	for voreType, enabled in pairs(p.preySettings) do
		widget.setChecked(voreType, enabled or false)
	end
	status.setStatusProperty("sbqPreyEnabled", p.preySettings)
end

function update()
end

function uninit()
end

function changeSetting(voreType)
	p.preySettings[voreType] = widget.getChecked(voreType)
	status.setStatusProperty("sbqPreyEnabled", p.preySettings)
end

function enabled()
	changeSetting("enabled")
end

function held()
	changeSetting("held")
end

function oralVore()
	changeSetting("oralVore")
end

function analVore()
	changeSetting("analVore")
end

function absorbVore()
	changeSetting("absorbVore")
end

function tailVore()
	changeSetting("tailVore")
end

function unbirth()
	changeSetting("unbirth")
end

function cockVore()
	changeSetting("cockVore")
end

function breastVore()
	changeSetting("breastVore")
end
