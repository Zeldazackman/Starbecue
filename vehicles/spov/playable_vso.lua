--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/scripts/vore/vsosimple.lua")

_G.movement = {
	jumps = 0,
	jumped = false,
	waswater = false,
	bapped = 0,
	downframes = 0,
	groundframes = 0,
	run = false,
	wasspecial1 = 10, -- Give things time to finish initializing, so it realizes you're holding special1 from spawning vap instead of it being a new press
	E = false,
	wasE = false,
}

function basic_handleinteract()
	if _G.movement.E then -- intercepting vsoForcePlayerSit to get this
		if not _G.movement.wasE then
			local aim = vehicle.aimPosition( controlSeat() )
			local mpos = mcontroller.position()
			local dpos = world.distance( mpos, aim )
			local interactables
			local queryParameters = {
				withoutEntityId = entity.id(), -- don't interact with self
				order = "nearest"
			}
			if world.magnitude( dpos ) < 9 then -- interact range -- and not world.lineTileCollision( mpos, aim )
				interactables = world.entityQuery( aim, 0.5, queryParameters )
			else
				interactables = world.entityQuery( mcontroller.position(), 3, queryParameters )
			end
			local obj = interactables[1]
			local driver = vehicle.entityLoungingIn( controlSeat() )
			if obj == driver then
				obj = interactables[2]
			end
			if obj ~= nil and driver ~= nil then
				local objpos = world.entityPosition( obj )
				vsoDebugRect( objpos[1]-0.5, objpos[2]-0.5, objpos[1]+0.5, objpos[2]+0.5, "red" )

				local name = world.getObjectParameter( obj, "objectName" )
				-- if name ~= nil then -- object
					local interactaction = world.getObjectParameter( obj, "interactAction" )
					local interactdata = world.getObjectParameter( obj, "interactData" )
					local localinteracted = false
					if interactaction == nil then -- some things return that from script? let's try to get that
						local s, e = pcall(function() -- this only works on local entities, pcall should stop it from crashing the game
							local action = world.callScriptedEntity( obj, "onInteraction", {
								source = world.distance( mpos, objpos ),
								sourceId = driver
							} )
							if action ~= nil then
								interactaction = action[1]
								interactdata = action[2]
							end
							localinteracted = true
						end)
						if not s then
							sb.logError(e)
						end
					end
					if interactaction ~= nil then
						if type( interactdata ) == "string" then
							interactdata = root.assetJson( interactdata )
						end
						world.sendEntityMessage( driver, "vsoForceInteract", interactaction, interactdata, obj )
					elseif world.getObjectParameter( obj, "uiConfig" ) ~= nil then
						uiconfig = world.getObjectParameter( obj, "uiConfig" )
						if world.getObjectParameter( obj, "slotCount" ) ~= nil then
							uiconfig = sb.replaceTags( uiconfig, { ["slots"] = world.getObjectParameter( obj, "slotCount" ) } )
						end
						local configdata = root.assetJson( uiconfig )
						world.sendEntityMessage( driver, "vsoForceInteract", "OpenContainer", configdata, obj )
					elseif world.getObjectParameter( obj, "upgradeStates" ) then -- upgradeablecraftingobjects
					elseif not localinteracted then -- call onInteraction for non-local entities, sadly we can't get the return value or this would be earlier
						world.objectQuery( objpos, 1, {
							name = name,
							callScript = "onInteraction",
							callScriptArgs = { {
								source = world.distance( mpos, objpos ),
								sourceId = driver
							} },
						} )
					end
				-- end
			end
		end
		_G.movement.wasE = true
	else
		_G.movement.wasE = false
	end
	_G.movement.E = false
end