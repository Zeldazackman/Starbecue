require "/vehicles/spov/vaporeon/vaporeon.lua"
function standaloneinit()
    local nearby = world.playerQuery( mcontroller.position(), 20, {order = "nearest"} )
    local vappydriver = "vappydriver"
    if #nearby > 0 then
        storage._vsoSpawnOwner = nearby[1]
        storage._vsoSpawnOwnerName = world.entityName( nearby[1] )
        vsoEat( nearby[1], "driver" )
        vsoVictimAnimVisible( "driver", false )
        vsoSetTarget( vappydriver, nearby[1] )
    end
end
function controlSeat()
    return "driver"
end