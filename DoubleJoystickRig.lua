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
