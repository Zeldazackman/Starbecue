local oldUpdate = update
local oldInit = init

function init()
	oldInit()
	sbqPredType = config.getParameter("sbqPredType")
end

function update(dt)
	checkRPCsFinished(dt)
	oldUpdate(dt)
end

rpcList = {}
function addRPC(rpc, callback, failCallback)
	if callback ~= nil or failCallback ~= nil  then
		table.insert(rpcList, {rpc = rpc, callback = callback, failCallback = failCallback, dt = 0})
	end
end

function checkRPCsFinished(dt)
	for i, list in pairs(rpcList) do
		list.dt = list.dt + dt -- I think this is good to have, incase the time passed since the RPC was put into play is important
		if list.rpc:finished() then
			if list.rpc:succeeded() and list.callback ~= nil then
				list.callback(list.rpc:result(), list.dt)
			elseif list.failCallback ~= nil then
				list.failCallback(list.dt)
			end
			table.remove(rpcList, i)
		end
	end
end

-------------------------------------------------------------------------------------------------------------------------------------------

local oldFeed = feed
function feed() -- function copied from SSVM mostly because it gets its target within it, can't put some check surrounding it
	--check area for prey
	local people = world.entityQuery( mcontroller.position(), 7, {
		withoutEntityId = entity.id(),
		includedTypes = {"npc", "player"},
		boundMode = "CollisionArea"
	})

	if #people == 0 then
--		sb.logInfo("No prey found")
		do return end
	end
--	sb.logInfo("Food Found")
	--check for projectiles

	local eggCheck = world.entityQuery( mcontroller.position(), 7, {
		withoutEntityId = entity.id(),
		includedTypes = {"npc", "player", "projectile"},
		boundMode = "CollisionArea"
	})

	if #people ~= #eggCheck then
--		sb.logInfo("Projectile found")
		do return end
	end

	--select a random victim

	tempTarget = people[math.random(#people)]

	--check the exclusions

	if not exclusionCheck(tempTarget) then
--		sb.logInfo("Exclusion Found")
		do return end
	end

	--check already eaten

	if isVictim(tempTarget) then
		do return end
	end

	--check space between them

	local collisionBlocks = world.collisionBlocksAlongLine(mcontroller.position(), world.entityPosition( tempTarget ), {"Null", "Block", "Dynamic"}, 1)
	if #collisionBlocks ~= 0 then
--		sb.logInfo("No line of sight")
		return
	end

	-- [SBQ] taking off the bottom of feed() now that we have the target to get SBQ's prey enabling options
	addRPC(world.sendEntityMessage(tempTarget, "sbqIsPreyEnabled", sbqPredType), function(enabled)
		if enabled then
			doFeed(tempTarget)
		end
	end)

end

function doFeed(tempTarget) -- bottom part of feed() from ssvm, now that is has the target and has cleared SBQ prey checks, its allowed to eat

	if not world.isNpc(tempTarget)then
		if math.random() < playerChance then
			isPlayer[#victim+1] = true
		else
			do return end
		end
	elseif math.random() > npcChance then
		do return end
	end

	--send message

	victim[#victim+1] = tempTarget
	world.sendEntityMessage( tempTarget, "applyStatusEffect", effect, duration, entity.id() )
	spawnSoundProjectile( "swallowprojectile" )

	--adjust states
	dress()
	feedHook()
end

local oldReqFeed = reqFeed
function reqFeed(input) -- since reqFeed() has an input source from the start, we can just wrap our check around it
	addRPC(world.sendEntityMessage(input.sourceId, "sbqIsPreyEnabled", sbqPredType), function(enabled)
		if enabled then
			oldReqFeed(input)
		end
	end)
end
