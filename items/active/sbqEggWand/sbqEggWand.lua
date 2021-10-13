local oldinit = init
function init()
	local spawnProjectile = world.spawnProjectile
	oldinit()
	world.spawnProjectile = spawnProjectile -- stardust lib does stuff with this, so here, we undo that... hopefully
end
