function init()
	activeItem.setHoldingItem(false)
	local hand = activeItem.hand()

	message.setHandler( hand.."ItemData", function(_,_, data)
		if not storage.clickAction and data.defaultClickAction ~= nil then
			activeItem.setInventoryIcon("/items/active/pvsoController/"..data.defaultClickAction..".png")
		end
	end)
	if storage.clickAction ~= nil then
		activeItem.setInventoryIcon("/items/active/pvsoController/"..storage.clickAction..".png")
	end
end

function update()

end
