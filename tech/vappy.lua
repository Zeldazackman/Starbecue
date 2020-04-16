local pressed = true
function update(args)
  if args.moves["special1"] and not pressed then
    local position = mcontroller.position()
    world.spawnVehicle( "spovvaporeonstandalone", { position[1], position[2] + 1.5 } )
  end
  pressed = args.moves["special1"]
end