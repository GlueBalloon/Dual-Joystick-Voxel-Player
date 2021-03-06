-- a rig that combines the joystick rig with the rigid capsule rig
--and makes the left joystck control the capsule motion
function joystickWalkerRig(entity, scene, blockCharacterAsset, strokeColor1, strokeColor2)
    --give the entity a rigidbody capsule rig
    --which DOES NOT INCLUDE a camera
    entity = rigidCapsuleRig(entity, scene)
    rig = entity.rig
    rig.contollerYInputAllowed = false
    rig.rb.linearDamping = 0.97
    
    --make a new entity to house the visible model
    --this can't be the model of the entity itself, because it
    --has to be able to scale separately from the rigid capsule
    rig.entityWithModel = scene:entity()
    if blockCharacterAsset then
        rig.entityWithModel.model = craft.model(blockCharacterAsset)
    end
    rig.entityWithModel.position = vec3(0, -0.998, 0)
    rig.entityWithModel.scale = vec3(0.12485, 0.12485, 0.12485)
    rig.entityWithModel.parent = entity
    scene.physics.gravity = vec3(0,-60.8,0) --was -14.8
    
    --make another new separate camEntity, give it a joystick camera rig,
    --and make it a child of the body, so it moves with the body
    --THIS IS THE ACTUAL CAMERA
    rig.joystickView = makeCameraViewerEntityThing(scene)
    rig.joystickView = doubleJoystickRig(rig.joystickView, strokeColor1, strokeColor2)
    rig.headPosition = vec3(0, 0.95, 0)
    rig.joystickView.parent = entity
    rig.isThirdPersonView = false
    
    --a function to align the camera and body if in third-person view
    function orientCamera()
        --change the camera centering if needed 
        if rig.isThirdPersonView and rig.joystickView.z == 0 then
            rig.entityWithModel.active = true
        elseif (not rig.isThirdPersonView) and rig.joystickView.z ~= 0 then 
            rig.joystickView.position = rig.headPosition
            rig.entityWithModel.active = false
        end
        --offset the camera if needed
        if rig.isThirdPersonView then
            local jView = rig.joystickView
            local pointToOffsetFrom = vec3(0, 1.5, -0.25) --includes offset for back of head
            local distanceMultiplier = 7
            local newPosition = pointToOffsetFrom - jView.forward * distanceMultiplier
            --at higher angles move camera closer to body
            while newPosition.y < -0.9 do
                distanceMultiplier = distanceMultiplier * 0.999
                newPosition = pointToOffsetFrom - jView.forward * distanceMultiplier
            end
            jView.position = newPosition
        end
    end
    
    --a function for the left joystick to control the rigidBody
    function moveCapsule(stick)
        local delta = stick.delta          
        local forward = rig.joystickView.forward * delta.y
        local right = rig.joystickView.right * -delta.x   
        local finalDir = forward + right   
        if not rig.contollerYInputAllowed then       
            finalDir.y = 0
        end
        if finalDir:len() > 0 then
            finalDir = finalDir:normalize()
        end    
        finalDir.x = math.min(finalDir.x or 2)
        finalDir.z = math.min(finalDir.z or 2)
        rig.move(finalDir)
        --hopefully this eliminates model jittering
        orientCamera()
    end
    
    --assign the new joystick functions
    --(the joystickView is a separate entity with its own rig)
    rig.joystickView.rig.setOutputReceiver(moveCapsule, orientCamera)
    
    --merge the draw and update functions of the entity and the 
    --joystick entity. 'Draw' is easy because the entity doesn't have its own 
    --draw function, but the entity does have its own update function, so 
    --that has to be combined with the camera update function
    entity.draw = rig.joystickView.draw
    entity.touched = rig.joystickView.touched
    local rbUpdate, jvUpdate = entity.update, rig.joystickView.update
    entity.update = function()
        rbUpdate()
        jvUpdate()
        --angle the body to keep back of head facing camera
        rig.entityWithModel.eulerAngles = vec3(0,  rig.joystickView.rig.ry, 0)
        orientCamera()
    end
    
    --an option to remove the rigidbody
    rig.removeRigidbody = function()
        entity:remove(craft.rigidbody)
        rig.move = nil
        rig.jump = nil
        rig.rb = nil
        for _, funcs in ipairs(rig.joystickView.rig.outputReceivers) do
            if funcs.left == moveCapsule then
                funcs.left = nil
            end
        end
        entity.update = function() 
            jvUpdate()
            orientCamera()
        end
    end
    
    --send back the entity
    --the structure created is:
      --the main entity, with a rig table:
        --a rigidbody (rig.rb) attached to the main entity
        --a separate entity with the visible model (rig.entityWithModel)
        --a separate entity with the joystick camera (rig.joystickView)
    --both the visible model and the joystickView are children of the 
    --main entity
    return entity
end

--a rig that creates two joysticks and a camera
--and sets the right joystick to control the camera
function doubleJoystickRig(camEntity, strokeColor1, strokeColor2)
    if touches then 
        touches.removeHandler(camEntity) 
        touches.addHandler(camEntity, 0, true)
    end
    if not camEntity.rig then camEntity.rig = {} end
    local rig = camEntity.rig
    rig.IDLE = 1
    rig.ROTATING = 2
    rig.touch = {}
    rig.touch.NONE = 1
    rig.touch.BEGAN = 2
    rig.touch.DRAGGING = 3
    rig.touch.LONG_PRESS = 4
    rig.state = rig.IDLE
    rig.start = vec2(0,0)
    rig.enabled = true
    rig.longPressDuration = longPressDuration or 1.0
    rig.dragThreshold = dragThreshold or 5
    rig.touchState = rig.touch.NONE
    rig.outputReceivers = {}
    rig.joysticks = {}   
    rig.isActive = function()
        return rig.state ~= rig.IDLE
    end
    
    function rig.defaultRightOutputReciever()
        local function setCameraRxRyFrom(stick)
            rig.rx = rig.rx - stick.delta.y * rig.sensitivity * 0.018
            rig.ry = rig.ry - stick.delta.x * rig.sensitivity * 0.018
        end
        return setCameraRxRyFrom
    end
    
    function rig.setOutputReceiver(functionForLeftStick, functionForRightStick)
        local outputTable = {left = functionForLeftStick, right = functionForRightStick}
        table.insert(rig.outputReceivers, outputTable)
    end
    
    rig.setOutputReceiver(nil, rig.defaultRightOutputReciever())
    
    function rig.dpadStates(diagonalsAllowed)
        local rightStick = {left = false, right = false, up = false, down = false}
        local leftStick = {left = false, right = false, up = false, down = false}
        if rig.joysticks then
            for _, stick in ipairs(rig.joysticks) do
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
        if rig.enabled and #rig.joysticks > 0 then  
            -- clamp vertical rotation between -90 and 90 degrees (no upside down view)
            rig.rx = math.min(math.max(rig.rx, -90), 90)
            rig.camRxRy(rig.rx, rig.ry)
        end
        for _, stick in ipairs(rig.joysticks) do
            for _, outputFunctions in ipairs(rig.outputReceivers) do
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
            if #rig.joysticks < 2 then
                if touch.x<WIDTH/2 then 
                    if #rig.joysticks == 0 or (rig.joysticks[1] and rig.joysticks[1].type ~= "leftStick") then 
                        table.insert(rig.joysticks, Joystick(touch.x,touch.y,touch.id,"leftStick", strokeColor1, strokeColor2)) 
                    end
                elseif #rig.joysticks == 0 or (rig.joysticks[1] and rig.joysticks[1].type ~= "rightStick") then
                    table.insert(rig.joysticks,Joystick(touch.x,touch.y,touch.id,"rightStick", strokeColor1, strokeColor2)) 
                end
            end
        elseif touch.state == ENDED or touch.state == CANCELLED then
            for i=#rig.joysticks, 1, -1 do
                if rig.joysticks[i].touchID == touch.id then
                    table.remove(rig.joysticks, i)
                end
            end
        else 
            for i, stick in ipairs(rig.joysticks) do
                if stick.touchID == touch.id then
                    stick:touched(touch)
                end 
            end
        end    
        
        return true
    end    
    
    function camEntity.draw()
        for a,j in pairs(rig.joysticks) do
            j:draw()
        end
    end
    
    return camEntity
end
