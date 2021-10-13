p = {}

function init()
	p.settings = player.getProperty("sbqSettings") or {}

	p.occupantList = "sbqScrollArea.sbqList"

	if p.settings and p.settings.sbqs then
		local i = 1
		for sbqname, data in pairs(p.settings.sbqs) do
			local skin = (p.settings[sbqname].skinNames or {}).head or "default"
			local directives = p.settings[sbqname].directives or ""

			local listItem = widget.addListItem(p.occupantList)
			p.listItems[sbqname] = listItem

			widget.setImage(p.occupantList.."."..listItem..".icon", "/vehicles/sbq/"..sbqname.."/skins/"..skin.."/icon.png"..directives)
			widget.setText(p.occupantList.."."..listItem..".indexLabel", data.index or "")
			widget.setText(p.occupantList.."."..listItem..".enableLabel", tostring(data.enable) or "false")
			widget.setText(p.occupantList.."."..listItem..".name", sbqname)
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
		for sbqname, list in pairs(p.listItems) do
			if list == listItem then
				name = sbqname
			end
		end
		local index = p.settings.sbqs[name].index
		local enabled = p.settings.sbqs[name].enable
		widget.setText(p.occupantList.."."..listItem..".enableLabel", tostring(enabled) or "false")
		widget.setText(p.occupantList.."."..listItem..".indexLabel", index or "" )
		widget.setText("textbox", index or "" )
	end
end

function toggle()
	local listItem = widget.getListSelected(p.occupantList)
	if not listItem then return end
	local name
	for sbqname, list in pairs(p.listItems) do
		if list == listItem then
			name = sbqname
		end
	end
	local enabled = not p.settings.sbqs[name].enable
	widget.setText(p.occupantList.."."..listItem..".enableLabel", tostring(enabled) or "false")

	p.settings.sbqs[name].enable = enabled
	player.setProperty("sbqSettings", p.settings)
	world.sendEntityMessage(pane.sourceEntity(), "sbqRefreshSettings", p.settings)
end

function textbox()
	local listItem = widget.getListSelected(p.occupantList)
	if not listItem then return end
	local name
	for sbqname, list in pairs(p.listItems) do
		if list == listItem then
			name = sbqname
		end
	end
	local index = tonumber(widget.getText("textbox"))
	widget.setText(p.occupantList.."."..listItem..".indexLabel", index or "" )

	p.settings.sbqs[name].index = index
	player.setProperty("sbqSettings", p.settings)
	world.sendEntityMessage(pane.sourceEntity(), "sbqRefreshSettings", p.settings)
end
