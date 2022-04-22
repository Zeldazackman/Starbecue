
function sbq.doRadialMenu(playerid, menuName, open, onOpen, openLoop, onClose )
	if open then
		if not sbq.radialMenuOpen then
			sbq.radialMenuOpen = true
			world.sendEntityMessage( playerid, "sbqOpenInterface", "sbqRadialMenu", {options = onOpen(), type = menuName }, true )
			return true
		else
			sbq.loopedMessage("radialSelection", playerid, "sbqGetRadialSelection", {}, function(data)
				if data.selection ~= nil and data.type == menuName then
					sbq.lastRadialData = data
					openLoop(data)
					sbq.click = data.pressed
				end
			end)
		end
		return true
	elseif sbq.radialMenuOpen then
		world.sendEntityMessage( playerid, "sbqOpenInterface", "sbqClose" )
		if (sbq.lastRadialData or {}).type == menuName then
			onClose(sbq.lastRadialData)
		end
		sbq.radialMenuOpen = nil
	end
end
