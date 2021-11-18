-- a rig that combines the joystick rig with the rigid capsule rig
--and makes the left joystck control the capsule motion
function joystickWalkerRig(camEntity, scene, blockCharacterAsset)

    --make an entity with a rigidbody capsule rig
    body = rigidCapsuleRig(scene:entity(), scene)
    body.contollerYInputAllowed = false
    body.rb.linearDamping = 0.97
    
    --make an entity to house the visible character model
    --this can't be the model of the body itself, because it
    --has to be able to scale separately from that body
    --so that the visible model can fit inside the rigid capsule
    characterModelEntity = scene:entity()
    characterModelEntity.model = craft.model(blockCharacterAsset)
    characterModelEntity.position = vec3(0, -0.998, 0)
    characterModelEntity.scale = vec3(0.12485, 0.12485, 0.12485)
    characterModelEntity.parent = body  
    scene.physics.gravity = vec3(0,-14.8,0)
    
    --take the camera entity passed in and give it joysticks
    --and make it a child of the body, so it moves with the body
    local joystickView = doubleJoystickRig(camEntity)
    joystickView.position = vec3(0, 0.95, 0)
    joystickView.parent = body
    body.joystickView = joystickView
    
    --merge the draw and update functions of the body entity and the 
    --camera entity. 'Draw' is easy because the body doesn't have its own 
    --draw function, but the body does have its own update function, so 
    --that has to be combined with the camera update function.
    body.draw = joystickView.draw
    body.touched = joystickView.touched
    local bodyUpdate, jvUpdate = body.update, joystickView.update
    body.update = function()
        bodyUpdate()
        jvUpdate()
    end
    
    --a function for the left joystick to control the body
    function moveCapsule(stick)
        local delta = stick.delta          
        local forward = joystickView.forward * delta.y
        local right = joystickView.right * -delta.x   
        local finalDir = forward + right   
        if not body.contollerYInputAllowed then       
            finalDir.y = 0
        end
        if finalDir:len() > 0 then
            finalDir = finalDir:normalize()
        end    
        finalDir.x = math.min(finalDir.x or 2)
        finalDir.z = math.min(finalDir.z or 2)
        body.move(finalDir)
    end
    
    --assign that function to receive the left joystick output
    joystickView.setOutputReciever(moveCapsule)
    
    --send back the body
    return body
end
    
--a rig that creates two joysticks and a camera
--and sets the right joystick to control the camera
function doubleJoystickRig(camEntity)
    if touches then 
        touches.removeHandler(camEntity) 
        touches.addHandler(camEntity, 0, true)
    end
    camEntity.IDLE = 1
    camEntity.ROTATING = 2
    camEntity.touch = {}
    camEntity.touch.NONE = 1
    camEntity.touch.BEGAN = 2
    camEntity.touch.DRAGGING = 3
    camEntity.touch.LONG_PRESS = 4
    camEntity.state = camEntity.IDLE
    camEntity.start = vec2(0,0)
    camEntity.enabled = true
    camEntity.longPressDuration = longPressDuration or 1.0
    camEntity.dragThreshold = dragThreshold or 5
    camEntity.touchState = camEntity.touch.NONE
    camEntity.outputReceivers = {}
    camEntity.joysticks = {}   
    camEntity.isActive = function()
        return camEntity.state ~= camEntity.IDLE
    end
    
    function camEntity.defaultRightOutputReciever()
        local function setCameraRxRyFrom(stick)
            camEntity.rx = camEntity.rx - stick.delta.y * camEntity.sensitivity * 0.018
            camEntity.ry = camEntity.ry - stick.delta.x * camEntity.sensitivity * 0.018
        end
        return setCameraRxRyFrom
    end
    
    function camEntity.setOutputReciever(functionForLeftStick, functionForRightStick)
        local outputTable = {left = functionForLeftStick, right = functionForRightStick}
        table.insert(camEntity.outputReceivers, outputTable)
    end
    
    camEntity.setOutputReciever(nil, camEntity.defaultRightOutputReciever())
    
    function camEntity.dpadStates(diagonalsAllowed)
        local rightStick = {left = false, right = false, up = false, down = false}
        local leftStick = {left = false, right = false, up = false, down = false}
        if camEntity.joysticks then
            for _, stick in ipairs(camEntity.joysticks) do
                if stick.type == "rightStick" then
                    rightStick = stick:activatedDpadDirections(diagonalsAllowed)
                end
                if stick.type == "leftStick" then
                    leftStick = stick:activatedDpadDirections(diagonalsAllowed)
                end
            end
        end
        return {rightStick = rightStick, leftStick = leftStick}
    end
    
    function camEntity.update()
        --from first person viewer
        if camEntity.enabled then  
            -- clamp vertical rotation between -90 and 90 degrees (no upside down view)
            camEntity.rx = math.min(math.max(camEntity.rx, -90), 90)
            camEntity.camRxRy(camEntity.rx, camEntity.ry)
        end
        for _, stick in ipairs(camEntity.joysticks) do
            for _, outputFunctions in ipairs(camEntity.outputReceivers) do
                if outputFunctions.left and stick.type == "leftStick" then
                    outputFunctions.left(stick)
                elseif outputFunctions.right and stick.type == "rightStick" then
                    outputFunctions.right(stick)
                end 
            end
        end
    end
    
    function camEntity.touched(not_self, touch)
        if touch.state==BEGAN then
            if #camEntity.joysticks < 2 then
                if touch.x<WIDTH/2 then 
                    if #camEntity.joysticks == 0 or (camEntity.joysticks[1] and camEntity.joysticks[1].type ~= "leftStick") then 
                        table.insert(camEntity.joysticks, Joystick(touch.x,touch.y,touch.id,"leftStick")) 
                    end
                elseif #camEntity.joysticks == 0 or (camEntity.joysticks[1] and camEntity.joysticks[1].type ~= "rightStick") then
                    table.insert(camEntity.joysticks,Joystick(touch.x,touch.y,touch.id,"rightStick")) 
                end
            end
        elseif touch.state == ENDED or touch.state == CANCELLED then
            for i=#camEntity.joysticks, 1, -1 do
                if camEntity.joysticks[i].touchID == touch.id then
                    table.remove(camEntity.joysticks, i)
                end
            end
        else 
            for i, stick in ipairs(camEntity.joysticks) do
                if stick.touchID == touch.id then
                    stick:touched(touch)
                end 
            end
        end    

        return true
    end    
    
    function camEntity.draw()
        for a,j in pairs(camEntity.joysticks) do
            j:draw()
        end
    end
    
    return camEntity
end
