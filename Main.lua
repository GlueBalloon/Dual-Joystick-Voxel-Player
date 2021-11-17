-- Dual-Joystick Voxel Player

viewer.mode = OVERLAY

function setup()
    scene = craft.scene()
    
    -- Setup camera and lighting
    scene.sun.rotation = quat.eulerAngles(25, 125, 0)
    scene.ambientColor = color(127, 127, 127, 255)   
    
    -- Setup voxel terrain
    allBlocks = blocks()    
    scene.voxels:resize(vec3(5,1,5))      
    scene.voxels.coordinates = vec3(0,0,0)
    
    -- Create ground out of grass
    scene.voxels:fill("Sand")
    scene.voxels:box(0,10,0,16*5,10,16*5)
    scene.voxels:fill("Dirt")
    scene.voxels:box(0,0,0,16*5,9,16*5)
    
    camThing = makeCameraViewerEntityThing(scene)
    djViewer = doubleJoystickViewerRig(camThing)
    camThing.position = vec3(40, 20, 40)
    rigidCap = makeCapsuleBodyOn(scene:entity(), scene, true)
    rigidCap.position = vec3(46.5, 20, 46.5)
    --create player
   -- player = djvPlayerMaker(scene)
  --  player = voxelWalkerMaker(scene)
end

function update(dt)
    scene:update(dt)
    djViewer:update()
    parameter.watch("player.entity.position")
-- nil:  parameter.watch("player.camera.position")
-- nil:   parameter.watch("player.viewer.position")
    parameter.watch("player.viewer.rx")
    parameter.watch("player.viewer.ry")
-- nil:  parameter.watch("player.viewer.eulerAngles")
    parameter.watch("player.camera.entity.position")
    parameter.watch("player.camera.entity.position")
end

function draw()
    --update and draw scene and player
    update(DeltaTime)
    scene:draw()
    djViewer.draw()
  --  player:draw()
    
    --change boolean to see live updates of simulated dpads
    if false then
        generateTwoStickDpadReport(player)
    end
end

function generateTwoStickDpadReport(player)
    if #player.viewer.joysticks > 0 then
        local dpads = player:dpadStates()
        local diags = player:dpadStates(true)
        print(
        "\n**no diagonals allowed: "..
        "\n-------left stick:\n"
        ..dpadTableReport(dpads.leftStick)
        .."\n-------right stick:\n"
        ..dpadTableReport(dpads.rightStick)
        .."\n\n**diagonals allowed: "
        .."\n-------left stick:\n"
        ..dpadTableReport(diags.leftStick)
        .."\n-------right stick:\n"
        ..dpadTableReport(diags.rightStick)
        )
    end
end

function generateOneDpadStickReport(stick)
    local dpad = stick:activatedDpadDirections()
    local diags = stick:activatedDpadDirections(true)
    return
    "\n--------------"..stick.type
    .."\n--angle: "..stick:angle()
    .."\n--deltas: "..stick.delta.x..", "..stick.delta.y
    .."\n--no diagonals:\n"
    ..dpadTableReport(dpad)
    .."\n--diagonals:\n"
    ..dpadTableReport(diags)
end

function dpadTableReport(dpadTable)
    return 
    "left: "..tostring(dpadTable.left)
    .."\nright: "..tostring(dpadTable.right)
    .."\nup: "..tostring(dpadTable.up)
    .."\ndown: "..tostring(dpadTable.down)
end
