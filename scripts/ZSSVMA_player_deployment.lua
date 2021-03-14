local oldinit = init
function init()
	oldinit()

	message.setHandler("PVSOClear", function(_,_)
		localAnimator.clearDrawables()
		localAnimator.clearLightSources()
	end)

	message.setHandler("PVSONightVision", function(_,_, light)
		localAnimator.clearLightSources()
		localAnimator.addLightSource({
			position = entity.position(),
			color = light.color,
			pointLight = true
		})
	end)

	message.setHandler("PVSOCursor", function(_,_, aim, cursor)
		localAnimator.clearDrawables()
		draw = {
			image = cursor,
			position = aim,
			fullbright = true
		}
		localAnimator.addDrawable( draw, "overlay" )
	end)

end