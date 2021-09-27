p = {}

function init()
	p.settings = player.getProperty("vsoSettings") or {}

	p.occupantList = "vsoScrollArea.vsoList"

	if p.settings and p.settings.vsos then
		local i = 1
		for vsoname, data in pairs(p.settings.vsos) do
			local skin = (p.settings[vsoname].skinNames or {}).head or "default"
			local directives = p.settings[vsoname].directives or ""

			local listItem = widget.addListItem(p.occupantList)
			p.listItems[vsoname] = listItem

			widget.setImage(p.occupantList.."."..listItem..".icon", "/vehicles/spov/"..vsoname.."/spov/"..skin.."/icon.png"..directives)
			widget.setText(p.occupantList.."."..listItem..".indexLabel", data.index or "")
			widget.setText(p.occupantList.."."..listItem..".enableLabel", tostring(data.enable) or "false")
			widget.setText(p.occupantList.."."..listItem..".name", vsoname)
		end
	end
end

p.listItems = {}

p.listItem = nil
function update()
	local listItem = widget.getListSelected(p.occupantList)
	if listItem ~= p.listItem then
		if not listItem then return end
		local name
		for vsoname, list in pairs(p.listItems) do
			if list == listItem then
				name = vsoname
			end
		end
		local index = p.settings.vsos[name].index
		local enabled = p.settings.vsos[name].enable
		widget.setText(p.occupantList.."."..listItem..".enableLabel", tostring(enabled) or "false")
		widget.setText(p.occupantList.."."..listItem..".indexLabel", index or "" )
		widget.setText("textbox", index or "" )
	end
end

function toggle()
	local listItem = widget.getListSelected(p.occupantList)
	if not listItem then return end
	local name
	for vsoname, list in pairs(p.listItems) do
		if list == listItem then
			name = vsoname
		end
	end
	local enabled = not p.settings.vsos[name].enable
	widget.setText(p.occupantList.."."..listItem..".enableLabel", tostring(enabled) or "false")

	p.settings.vsos[name].enable = enabled
	player.setProperty("vsoSettings", p.settings)
	world.sendEntityMessage(pane.sourceEntity(), "refreshVSOsettings", p.settings)
end

function textbox()
	local listItem = widget.getListSelected(p.occupantList)
	if not listItem then return end
	local name
	for vsoname, list in pairs(p.listItems) do
		if list == listItem then
			name = vsoname
		end
	end
	local index = tonumber(widget.getText("textbox"))
	widget.setText(p.occupantList.."."..listItem..".indexLabel", index or "" )

	p.settings.vsos[name].index = index
	player.setProperty("vsoSettings", p.settings)
	world.sendEntityMessage(pane.sourceEntity(), "refreshVSOsettings", p.settings)
end
