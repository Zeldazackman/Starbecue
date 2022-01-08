---@diagnostic disable: undefined-global
sbq = {}

require("/scripts/SBQ_RPC_handling.lua")

local oldUpdate = update

function update(args)
	sbq.checkRPCsFinished(args.dt)
	oldUpdate(args)
end

local voreTypes = { "oralVore", "unbirth" }

function attemptActivate()
	local people = world.entityQuery( tech.aimPosition(), 7, {
		withoutEntityId = entity.id(),
		includedTypes = { "player" },
		boundMode = "CollisionArea"
	})
	if #people == 1 then
		self.target = people[1]

		sbq.addRPC(world.sendEntityMessage( self.target, "sbqIsPreyEnabled", voreTypes[self.context + 1]), function (enabled)
			if enabled then
				activate()
			else
				animator.playSound( "deactivate", 0 )
			end
		end, function ()
			animator.playSound( "deactivate", 0 )
		end)
	else
		animator.playSound( "deactivate", 0 )
	end
end
