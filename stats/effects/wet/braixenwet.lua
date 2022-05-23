function init()
	script.setUpdateDelta(5)

  end

  function update(dt)
	--Check if our wet status hook set "braix-braixenwet" to 1, if the property does not exist, default to 0 which is effectively false
	if status.statusProperty("braix-braixenwet", 0) == 1 then
		--fuck the taking damage from water I am just going to make that not happen

		--If not wet
	else
	  --Effect for when the player is not wet
	end
  end

  function uninit()
  end
