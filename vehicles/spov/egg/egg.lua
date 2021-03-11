--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/scripts/vore/vsosimple.lua")
require("/vehicles/spov/playable_vso.lua")

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

p.vsoMenuName = "egg"

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

	p.onForcedReset()

end

function onBegin()	--This sets up the VSO ONCE.

	p.onBegin()

	vsoOnInteract( "state_stand", p.onInteraction )

end

function onEnd()

	p.onEnd()

end

-------------------------------------------------------------------------------

function state_stand()
	p.handleStruggles()
end

p.cracks = 0

p.registerStateScript( "stand", "crack", function( args )
	p.cracks = p.cracks + 1

	if p.cracks > 3 then _vsoOnDeath()
	else animator.setGlobalTag( "cracks", tostring(p.cracks) )
	end
end)


-------------------------------------------------------------------------------
