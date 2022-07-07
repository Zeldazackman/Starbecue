require("/vehicles/sbq/sbq_main.lua")

state = {
	stand = {}
}


function sbq.wrappingframe()
	local victim = sbq.findFirstOccupantIdForLocation("grab")
	if victim ~= nil then
		local progressbar = sbq.lounging[victim].progressBar / 100
		local frame = math.floor(progressbar * sbq.animStateData.wrappingState.states.wrapping.frames) + 1
		sb.logInfo(progressbar)
		sb.logInfo(sbq.animStateData.wrappingState.states.wrapping.frames)
		sb.logInfo(frame)

		sbq.setPartTag("global", "wrappingFrame", frame )
	else
		sbq.doAnim("wrappingState", "none")
	end
end
-- this uses math to not have to deal with defining each percentage individually 
-- heck we can even do this
--Wait, so that will get the right frames regardless of frame amount? Well, as long as I specify the right parts (replace wrappingstate and wrapping with relevant bits if I reuse)?
-- yeah
--Alright, need to keep note of that.
-- also removed the "unwrapping" anim since that won't need to be used now, since if you do make the progress bar go in reverse it will go back down the relevant frames now
--That is cool! It saves on a lot of complications down the line. Should I get rid of the unwrapping bits in the .frames? you don't need to, they just won't do anything
--Safe to attempt a test?
-- should be yeah, save and test
function sbq.update(dt)
	sbq.armRotationUpdate()
	sbq.setGrabTarget()
	sbq.wrappingframe()
end

function state.stand.grab(args, tconfig)
	if sbq.grab("grab") then -- this function has all the stuff for aiming at a player already and such, so its the only thing that needs to be called, only input arg is the location the victim goes
		sbq.doAnim("wrappingState", "wrapping")
	end
end

function state.stand.escape(args, tconfig) -- and this is just for struggling to escape, the animation is handled by the struggle transition, only running if its a success
	return true, function ()
		sbq.letGrabGo("grab") -- grab and eating use the same functions but handle a bit differently, and have some other stuff surrounding them
	end
end
-- the mummy is only ever going to be controlled by a player (though when we add AI to the others at some point we may come back around)
-- you will want that eventually maybe, but for now, we just, want it to work  without the complexities that I don't understand yet
--That makes sense, should leave those comments on this one so I can look back at them later if needed.
_onDeath = sbq.onDeath
function sbq.onDeath(eaten)
	if not eaten then
		world.spawnItem("sbqMummyWraps", mcontroller.position() )
	end
	_onDeath(eaten)
end

_letGrabGo = sbq.letGrabGo
function sbq.letGrabGo(location)
	_letGrabGo(location)
	sbq.doAnim("wrappingState", "none")
end

-- also I am doing an overhaul of the tf effects, so heres one thing that will save you a bit of effort later
function sbq.otherLocationEffects(i, eid, health, bellyEffect, location )
	if (sbq.occupant[i].progressBar <= 0) and sbq.settings.trappedTF then
		sbq.loopedMessage("TF"..eid, eid, "sbqIsPreyEnabled", {"transformImmunity"}, function (immune)
			if not immune then
				transformMessageHandler( eid , 3, { species = "sbqMummy", state = "stand" } )
			end
		end)
	end
end