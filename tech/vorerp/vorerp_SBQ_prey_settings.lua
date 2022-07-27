---@diagnostic disable: undefined-global
sbq = {}

require("/scripts/SBQ_RPC_handling.lua")

local oldUpdate = update

function update(args)
	sbq.checkRPCsFinished(args.dt)
	oldUpdate(args)
end

local voreTypes = { "oralVore", "unbirth" }
-- a function from SSVM getting overwritten to have better parity and use Starbecue's settings
function attemptActivate()
	local people = world.entityQuery( tech.aimPosition(), 7, {
		withoutEntityId = entity.id(),
		includedTypes = { status.statusProperty("sbqSSVMTargeting") or "player" },
		boundMode = "CollisionArea"
	})
	if #people == 1 then
		self.target = people[1]

		sbq.addRPC(world.sendEntityMessage( self.target, "sbqIsPreyEnabled", voreTypes[self.context + 1]), function (enabled)
			if enabled and enabled.enabled then
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
