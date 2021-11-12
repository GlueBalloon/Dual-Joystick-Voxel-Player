-- Basic Player

viewer.mode = OVERLAY

function setup()
    scene = craft.scene()
    
    -- Setup camera and lighting
    scene.sun.rotation = quat.eulerAngles(25, 125, 0)
    
    -- Set the scenes ambient lighting
    scene.ambientColor = color(127, 127, 127, 255)   
    
    allBlocks = blocks()    
    
    -- Setup voxel terrain
    scene.voxels:resize(vec3(5,1,5))      
    scene.voxels.coordinates = vec3(0,0,0)
    
    -- Create ground out of grass
    scene.voxels:fill("Redstone Ore")
    scene.voxels:box(0,10,0,16*5,10,16*5)
    scene.voxels:fill("Dirt")
    scene.voxels:box(0,0,0,16*5,9,16*5)
    player = voxelWalkerMaker(scene)
end

function update(dt)
    scene:update(dt)
end

function draw()
    update(DeltaTime)
    scene:draw()
    player:draw()
    if #player.viewer.joysticks > 0 then
        print(#player.viewer.joysticks..generateReportOfBothSticks(player))
    end
end

function generateReportOfBothSticks(player)
    local dpads = player:dpadStates()
    local diags = player:dpadStates(true)
    local returnString = 
    "\n-------left stick:\n"
    ..dpadTableReport(dpads.leftStick)
    .."\n-------right stick:\n"
    ..dpadTableReport(dpads.rightStick)
    return returnString
end

function generateDpadStickReport(stick)
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
