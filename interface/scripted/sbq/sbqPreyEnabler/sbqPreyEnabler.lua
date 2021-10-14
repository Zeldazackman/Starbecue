
function init()
	self.config = root.assetJson( "/sbqGeneral.config")
	self.preySettings = sb.jsonMerge(self.config.defaultPreyEnabled.player, status.statusProperty("sbqPreyEnabled"))

	for voreType, enabled in pairs(self.preySettings) do
		widget.setChecked(voreType, enabled or false)
	end
	status.setStatusProperty("sbqPreyEnabled", self.preySettings)
end

function update()
end

function uninit()
end

function changeSetting(voreType)
	self.preySettings[voreType] = widget.getChecked(voreType)
	status.setStatusProperty("sbqPreyEnabled", self.preySettings)
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
