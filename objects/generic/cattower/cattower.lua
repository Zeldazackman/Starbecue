local inited = false
function update()
    if inited then return end
    local boxPos = object.toAbsolutePosition({1, 4})
    if world.entityName(world.objectAt(boxPos) or 0) ~= "cattower_box" then
        world.placeObject("cattower_box", boxPos, object.direction(), {unbreakable = true})
    end
    local bedPos = object.toAbsolutePosition({-1, 8})
    if world.entityName(world.objectAt(bedPos) or 0) ~= "cattower_bed" then
        world.placeObject("cattower_bed", bedPos, object.direction(), {unbreakable = true})
    end
    local toyPosRight = object.toAbsolutePosition({2, 2})
    if world.entityName(world.objectAt(toyPosRight) or 0) ~= "cattower_toy" then
        world.placeObject("cattower_toy", toyPosRight, object.direction(), {unbreakable = true})
    end
    local toyPosLeft = object.toAbsolutePosition({-2, 6})
    if world.entityName(world.objectAt(toyPosLeft) or 0) ~= "cattower_toy" then
        world.placeObject("cattower_toy", toyPosLeft, -object.direction(), {unbreakable = true})
    end
    inited = true
end

function die()
    local boxId = world.objectAt(object.toAbsolutePosition({1, 4}))
    if world.entityName(boxId or 0) == "cattower_box" then
        world.breakObject(boxId, true)
    end
    local bedId = world.objectAt(object.toAbsolutePosition({-1, 8}))
    if world.entityName(bedId or 0) == "cattower_bed" then
        world.breakObject(bedId, true)
    end
    local toyIdRight = world.objectAt(object.toAbsolutePosition({2, 2}))
    if world.entityName(toyIdRight or 0) == "cattower_toy" then
        world.breakObject(toyIdRight, true)
    end
    local toyIdLeft = world.objectAt(object.toAbsolutePosition({-2, 6}))
    if world.entityName(toyIdLeft or 0) == "cattower_toy" then
        world.breakObject(toyIdLeft, true)
    end
end