require "/vehicles/spov/vaporeon/vaporeon.lua"
function standaloneinit()
    local nearby = world.playerQuery( mcontroller.position(), 20, {order = "nearest"} )
    if #nearby > 0 then
        storage._vsoSpawnOwner = nearby[1]
        storage._vsoSpawnOwnerName = world.entityName( nearby[1] )
        vsoEat( nearby[1], "driver" )
        vsoVictimAnimVisible( "driver", false )
    end
end
function controlSeat()
    return "driver"
end