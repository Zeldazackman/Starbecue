local _init = init
function init()
	_init()

	message.setHandler("sbqPotionDartGunData", function ()
		return activeItem.callOtherHandScript("dartGunData")
	end)
end

function isDartGun()
	return true
end
