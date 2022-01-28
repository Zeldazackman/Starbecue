---@diagnostic disable:undefined-global

local oldUpdate = update
local oldInit = init

sbq = {}

require("/scripts/SBQ_RPC_handling.lua")

function init()
	oldInit()
	sbqPredType = config.getParameter("sbqPredType")
end

function update(dt)
	sbq.checkRPCsFinished(dt)
	oldUpdate(dt)
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
	sbq.addRPC(world.sendEntityMessage(tempTarget, "sbqIsPreyEnabled", sbqPredType), function(enabled)
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
	sbq.addRPC(world.sendEntityMessage(input.sourceId, "sbqIsPreyEnabled", sbqPredType), function(enabled)
		if enabled then
			oldReqFeed(input)
		end
	end)
end
