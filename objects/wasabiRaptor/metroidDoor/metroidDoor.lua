function init()
	if type(storage.doorState) == "nil" then
		storage.doorTimer = 0
		storage.doorState = true
		local position = object.position()
		local offset = {0,0}
		if object.direction() >= 1 then
			offset = config.getParameter("rightCollissionOffset")
		else
			offset = config.getParameter("leftCollissionOffset")
		end
		storage.offset = offset
		storage.position = {position[1] + offset[1], position[2] + offset[2]}
		placeDoorCollission(object.isInputNodeConnected(0))
	end
	processWireInput()
end

function onNodeConnectionChange(args)
	processWireInput(args)
end

function onInputNodeChange(args)
	processWireInput(args)
end

function placeDoorCollission(unbreakable)
	local doorObject = world.objectAt(storage.position)
	local params = { doorOffset = storage.offset, unbreakable = unbreakable, smashable = not unbreakable}
	if doorObject then
		removeDoorCollission()
	end
	storage.door = world.placeObject(config.getParameter("collissionObject"), storage.position, object.direction(), params )
end
function removeDoorCollission()
	local doorObject = world.objectAt(storage.position)
	if type(doorObject) == "number" and world.entityName(doorObject) == config.getParameter("collissionObject") then
		world.breakObject(doorObject, true)
	end
end

function update(dt)
	if storage.doorTimer <= 0 and not storage.doorState and not object.isInputNodeConnected(0) then
		closeDoor(object.isInputNodeConnected(0))
	else
		storage.doorTimer = math.max(0, storage.doorTimer - dt)
	end
	if not storage.door and storage.doorState then
		closeDoor(storage.lock)
	end
end


function openDoor()
	if (storage.doorState or storage.wasConnected ~= object.isInputNodeConnected(0)) and not (object.getInputNodeLevel(1) or storage.wasLocked) then
		removeDoorCollission()
		storage.doorTimer = 10
		if storage.doorState then
			animator.setAnimationState("doorState", "open", true)
			animator.playSound("doorOpen")
		end

		storage.doorState = false
		object.setOutputNodeLevel(0, not storage.doorState)
	end
end
function closeDoor(lock)
	if not storage.doorState or storage.wasConnected ~= object.isInputNodeConnected(0) or storage.wasLocked ~= object.getInputNodeLevel(1) or not storage.door then
		placeDoorCollission(lock)
		storage.doorTimer = 0
		if not storage.doorState then
			animator.setAnimationState("doorState", "close", true)
			animator.playSound("doorClose")
		end
		storage.lock = lock
		storage.doorState = true
		object.setOutputNodeLevel(0, not storage.doorState)
	end
end

function processWireInput(args)
	if object.getInputNodeLevel(1) then
		animator.setGlobalTag("lockVisible", "")
		closeDoor(true)
	elseif object.isInputNodeConnected(0) then
		animator.setGlobalTag("lockVisible", "")
		animator.setGlobalTag("doorDirectives", "")
		if not object.getInputNodeLevel(0) then
			closeDoor(true)
		else
			openDoor()
		end
	else
		animator.setGlobalTag("lockVisible", "?crop;0;0;0;0")
		animator.setGlobalTag("doorDirectives", config.getParameter("doorDirectives").normal)
		closeDoor()
	end
	storage.wasLocked = object.getInputNodeLevel(1)
	storage.wasConnected = object.isInputNodeConnected(0)
end

function die()
	removeDoorCollission()
end
