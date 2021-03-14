local oldinit = init
function init()
	oldinit()

	message.setHandler("PVSOClear", function(_,_)
		localAnimator.clearDrawables()
		localAnimator.clearLightSources()
	end)

	message.setHandler("PVSOAddLocalLight", function(_,_, light)
		localAnimator.clearLightSources()
		localAnimator.addLightSource( light )
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
