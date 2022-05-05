local _init = init
function init()
	_init()

	message.setHandler("sbqTFDartGetData", function ()
		local data = {}
		return data
	end)
end
