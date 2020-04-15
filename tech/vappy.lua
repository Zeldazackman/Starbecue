local pressed = true
function update(args)
  if args.moves["special1"] and not pressed then
    world.spawnVehicle( "spovvaporeonstandalone", mcontroller.position() )
  end
  pressed = args.moves["special1"]
end