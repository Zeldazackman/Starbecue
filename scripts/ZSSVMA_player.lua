local oldinit = init
function init()
	oldinit()

	message.setHandler("pvsoApplyStatusEffects", function(_,_, effects, source)
		status.addEphemeralEffects(effects, source)
	end)

	message.setHandler("getVSOseatInformation", function()
		local seatdata = {
			mass = mcontroller.mass(),
			powerMultiplier = status.stat("powerMultiplier")
		}
		return seatdata
	end)

end
