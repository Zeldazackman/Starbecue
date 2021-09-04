local oldinit = init
require("/scripts/everything_primary.lua")
function init()
	oldinit()
	everything_primary()
end
