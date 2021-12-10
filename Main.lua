-- Joystick Player

viewer.mode = OVERLAY

function setup()    
    --setup the scene
    scene = craft.scene()   
    makeGround()
    
    --make a player body controlled by joysticks
    --it contains a separate camera entity put inside the body 
    playerBody = joystickWalkerRig(scene:entity(), scene, asset.builtin.Blocky_Characters.Soldier)
    playerBody.position = vec3(46.5, 40, 46.5)
    playerBody.rig.isThirdPersonView = true
    
    --a control to switch between first and third person views
    parameter.boolean("thirdPersonView", true, function(value) 
        playerBody.rig.isThirdPersonView = value
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
    if true then
        pushStyle()
        local report = generateTwoStickDpadReport(playerBody.rig.joystickView) or ""
        fontSize(14)
        local w, h = textSize(report)
        fill(255, 200, 0)
        textMode(CORNER)
        text(report, WIDTH - (w * 1.15), HEIGHT - (h * 1.05) )
        popStyle()
    end
end

--functions to check the dpad-simulating outputs
function generateTwoStickDpadReport(player)
    local rig = player.rig
    if #rig.joysticks > 0 then
        local dpads = rig.dpadStates()
        local diags = rig.dpadStates(true)
        return
        "DPAD OUTPUTS:"
        .."\n\nLEFT stick:\n"
        ..dpadTableReport(dpads.leftStick)
        .."\nif diagonals allowed:\n"
        ..dpadTableReport(diags.leftStick)
        .."\n\nRIGHT stick:\n"
        ..dpadTableReport(dpads.rightStick)
        .."\nif diagonals allowed:\n"
        ..dpadTableReport(diags.rightStick)
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
    "\tleft: "..tostring(dpadTable.left)
    .."\n\tright: "..tostring(dpadTable.right)
    .."\n\tup: "..tostring(dpadTable.up)
    .."\n\tdown: "..tostring(dpadTable.down)
end
