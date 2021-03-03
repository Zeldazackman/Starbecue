--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @ ZMakesThingsGo & Sheights

function init()
	local x = effect.duration() -1000
	local y = effect.sourceEntity()
	self.position = { x, y } --WE DOING SOME WONKY SHIT HERE TO CHEAT HAHAHAHAHAHA
	status.removeEphemeralEffect( "vsomonsterbind" );
	mcontroller.setPosition( self.position );
	mcontroller.setVelocity( {0,0} );
	effect.expire();
end

function update(dt)
end

function uninit()
end
