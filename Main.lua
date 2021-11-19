-- Dual-Joystick Voxel Player

viewer.mode = OVERLAY

function setup()
    
    scene = craft.scene()
    
    makeGround()
    
    
    --make a player body controlled by joysticks, with separate camera entity
    --its camera is initially placed inside the body for a first-person view
    playerBody = joystickWalkerRig(scene:entity(), scene, asset.builtin.Blocky_Characters.Soldier)
    playerBody.position = vec3(46.5, 20, 46.5)
    
    --a control to switch between first and third person views
    parameter.boolean("thirdPersonView", false, function(shouldBe3rdPerson)      
        if shouldBe3rdPerson then
            playerBody.rig.joystickView.position = vec3(0, 4.5, -7)
            playerBody.rig.joystickView.rx = 25
        else
            playerBody.rig.joystickView.position = vec3(0, 0.85, 0) 
            playerBody.rig.joystickView.rx = 0          
        end
    end)
end

function makeGround()
    -- Setup voxel terrain
    allBlocks = blocks()    
    scene.voxels:resize(vec3(5,1,5))      
    scene.voxels.coordinates = vec3(0,0,0)    
    -- Create ground out of grass
    scene.voxels:fill("Planks")
    scene.voxels:box(0,10,0,16*5,10,16*5)
    scene.voxels:fill("Dirt")
    scene.voxels:box(0,0,0,16*5,9,16*5)
    --something to bump into, for testing jumps
    scene.voxels:fill("Red Brick")
    scene.voxels:box(20,11,30, 50,11,60)
    scene.voxels:fill("empty")
    scene.voxels:fillStyle(REPLACE)
    scene.voxels:box(21,11,31, 49,11,59)
end

function update(dt)
    scene:update(dt)
    playerBody.update()
end

function draw()
    --update and draw scene and player
    update(DeltaTime)
    scene:draw()
    playerBody.draw()    
    --change boolean to see live updates of simulated dpads
    if false then
        generateTwoStickDpadReport(playerBody.joystickView)
    end
end

function generateTwoStickDpadReport(player)
    if #player.joysticks > 0 then
        local dpads = player.dpadStates()
        local diags = player.dpadStates(true)
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
