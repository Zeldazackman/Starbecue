require "/vehicles/spov/vaporeon/vaporeon.lua"
function standaloneinit()
    local driver = config.getParameter( "driver" )
    storage._vsoSpawnOwner = driver
    storage._vsoSpawnOwnerName = world.entityName( driver )
    vsoEat( driver, "driver" )
    vsoVictimAnimVisible( "driver", false )
end
function controlSeat()
    return "driver"
end