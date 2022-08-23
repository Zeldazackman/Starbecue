function update()
	local position = activeItemAnimation.ownerPosition()
	local rooms = world.objectQuery(position, 10, {
		name = "sbqMouseRoom"
	})
	local holes = world.objectQuery(position, 10, {
		name = "sbqMouseHole"
	})

	localAnimator.clearDrawables()
	for _, object in ipairs(rooms) do
		localAnimator.addDrawable(
			{
				image = "/items/active/sbqMouseRoomTool/indicator.png",
				centered = false,
				position = world.entityPosition(object)
			},
			"ForegroundOverlay+2"
		)
	end
	for _, object in ipairs(holes) do
		localAnimator.addDrawable(
			{
				image = "/items/active/sbqMouseRoomTool/indicator.png?hueshift=180",
				centered = false,
				position = world.entityPosition(object)
			},
			"ForegroundOverlay+2"
		)
	end
end
