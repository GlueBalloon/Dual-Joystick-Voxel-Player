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
    --something to bump into to test jumps
    scene.voxels:fill("Red Brick")
    scene.voxels:box(20,11,30, 50,11,60)
    scene.voxels:fill("empty")
    scene.voxels:fillStyle(REPLACE)
    scene.voxels:box(21,11,31, 49,11,59)
    
    camThing = makeCameraViewerEntityThing(scene)
    djViewer = doubleJoystickViewerRig(camThing)
    djViewer.position = vec3(0, 5, -6)
    rigidCap = makeCapsuleBodyOn(scene:entity(), scene, true)
    rigidCap.position = vec3(46.5, 20, 46.5)
    djViewer.parent = rigidCap
    
    function moveCapsule(stick)
        local delta = stick.delta          
        local forward = djViewer.forward * delta.y
        local right = djViewer.right * -delta.x   
        local finalDir = forward + right   
        if not rigidCap.contollerYInputAllowed then       
            finalDir.y = 0
        end
        if finalDir:len() > 0 then
            finalDir = finalDir:normalize()
        end    
        finalDir.x = math.min(finalDir.x or 2)
        finalDir.z = math.min(finalDir.z or 2)
        rigidCap.move(finalDir)
    end
    djViewer.setOutputReciever(moveCapsule)
    parameter.boolean("parent", false, function(shouldEnter)
        if shouldEnter then
            djViewer.position = vec3(0, 0.85, 0)

        else
            djViewer.parent = nil
            djViewer.position = vec3(40, 20, 40) 
        end
    end)
end

function update(dt)
    scene:update(dt)
    djViewer:update()
end

function draw()
    --update and draw scene and player
    update(DeltaTime)
    scene:draw()
    djViewer.draw()    
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
