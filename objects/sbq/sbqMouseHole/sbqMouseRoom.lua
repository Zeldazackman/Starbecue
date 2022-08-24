function init()

	message.setHandler("saveSettings", function(_, _, spaces, data)
		object.setConfigParameter("coverSpaces", spaces)
		object.setConfigParameter("savedData", data)
	end)
end
