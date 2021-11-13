-----------------------------------------
-- FirstPersonViewer
-- Written by John Millard
-----------------------------------------
-- Description:
-- A basic viewer for first person cameras.
-- Attach to a camera's entity for basic first person controls:
-- i.e. scene.camera:add(FirstPersonViewer)
-----------------------------------------

FPSWalkerViewer = class()

local IDLE = 1
local ROTATE = 2

FPSWalkerViewer.NONE = 1
FPSWalkerViewer.BEGAN = 2
FPSWalkerViewer.DRAGGING = 3
FPSWalkerViewer.LONG_PRESS = 4

function FPSWalkerViewer:init(camera, longPressDuration, dragThreshold, callbacks)
    self.camera = camera
    self.rx = 0
    self.ry = 0
    self.state = IDLE
    self.enabled = true
    self.sensitivity = 0.25
    self.longPressDuration = longPressDuration or 1.0
    self.dragThreshold = dragThreshold or 5
    self.touchState = FPSWalkerViewer.NONE
    self.outputs = {}
    self.joysticks = {}   
end

function FPSWalkerViewer:setOutputReciever(functionForLeftStick, functionForRightStick)
    local outputTable = {left = functionForLeftStick, right = functionForRightStick}
    table.insert(self.outputs, outputTable)
end

function FPSWalkerViewer:isActive()
    return self.state ~= IDLE
end

function FPSWalkerViewer:longPressProgress()
    if self.touchState == FPSWalkerViewer.BEGAN then
        return (ElapsedTime - self.startTime) / self.longPressDuration
    elseif self.touchState == FPSWalkerViewer.LONG_PRESS then
        return 1.0
    end
    return 0
end

function FPSWalkerViewer:update()
    --[[
    if self.touchState == FPSWalkerViewer.BEGAN then
        if ElapsedTime - self.startTime >= self.longPressDuration then
            self.touchState = FPSWalkerViewer.LONG_PRESS
            touches.share(self, self.lastTouch, 0)
            --if self.callbacks.longPressed then self.callbacks.longPressed(self.lastTouch) end
        end
    end
    
    if self.touchState == FPSWalkerViewer.LONG_PRESS then
       -- if self.callbacks.longPressing then self.callbacks.longPressing(self.lastTouch) end
    end
    
    if self.touchState == FPSWalkerViewer.DRAGGING then
    --    if self.callbacks.dragging then self.callbacks.dragging(self.lastTouch) end
    end

    if self.enabled then  
        -- clamp vertical rotation between -90 and 90 degrees (no upside down view)
        self.rx = math.min(math.max(self.rx, -90), 90)
        local rotation = quat.eulerAngles(self.rx,  self.ry, 0)
        self.camera.rotation = rotation
    end
    ]]
    for _, stick in ipairs(self.joysticks) do
        for _, outputTable in ipairs(self.outputs) do
            if outputTable.left and stick.type == "leftStick" then
                outputTable.left(stick)
            elseif outputTable.right and stick.type == "rightStick" then
                outputTable.right(stick)
            end 
        end
    end
end

function FPSWalkerViewer:scroll(gesture)
--[[
    if gesture.state == BEGAN then 
        return true
    elseif gesture.state == MOVING then
        self.rx = self.rx - gesture.delta.y * self.sensitivity
        self.ry = self.ry - gesture.delta.x * self.sensitivity    
    end ]]
    end
    
function FPSWalkerViewer:setJoysticksFrom(touch)
    
end
    
function FPSWalkerViewer:touched(touch)
    local leftTouch, rightTouch
    if touch.x<WIDTH/2 then 
        leftTouch = true
    else
        rightTouch = true
    end
    if touch.state==BEGAN then
        if #self.joysticks < 2 then
            if leftTouch then 
                if #self.joysticks == 0 or (self.joysticks[1] and self.joysticks[1].type ~= "leftStick") then 
                    table.insert(self.joysticks,Joystick(touch.x,touch.y,touch.id,"leftStick")) 
                end
            elseif #self.joysticks == 0 or (self.joysticks[1] and self.joysticks[1].type ~= "rightStick") then
                 table.insert(self.joysticks,Joystick(touch.x,touch.y,touch.id,"rightStick")) 
            end
        end
    elseif touch.state == ENDED or touch.state == CANCELLED then
        for i=#self.joysticks, 1, -1 do
            if self.joysticks[i].touchID == touch.id then
                table.remove(self.joysticks, i)
            end
        end
    else 
        for i, stick in ipairs(self.joysticks) do
            if stick.touchID == touch.id then
                stick:touched(touch)
            end 
        end
    end    
    
    if leftTouch then return end
    
    if self.state == IDLE then
        if touch.state == BEGAN then
            self.start = vec2(touch.x, touch.y)
        elseif touch.state == MOVING and self.start then
            local length = (vec2(touch.x, touch.y) - self.start):len()
            if length >= 5 then
                self.state = ROTATE
            end        
        end       
    elseif self.state == ROTATE then
        if touch.state == MOVING then
            self.rx = self.rx - touch.deltaY * self.sensitivity
            self.ry = self.ry - touch.deltaX * self.sensitivity
        elseif touch.state == ENDED then
            self.state = IDLE
        end           
    end 
    
    self.lastTouch = touch
    
    if self.touchState == FPSWalkerViewer.NONE then
        if touch.state == BEGAN then
            self.startPos = vec2(touch.x, touch.y)
            self.startTime = ElapsedTime
            self.touchState = FPSWalkerViewer.BEGAN
          --  if self.callbacks.began then self.callbacks.began(touch) end
            return true
        end
    end
    
    if self.touchState ~= FPSWalkerViewer.NONE then
        if touch.state == ENDED or touch.state == CANCELLED then
            if self.touchState == FPSWalkerViewer.BEGAN then
              --  if self.callbacks.tapped then self.callbacks.tapped(touch) end
            end
         --   if self.callbacks.ended then self.callbacks.ended(touch) end
            self.touchState = FPSWalkerViewer.NONE
        end
    end
    
    
    if self.touchState == FPSWalkerViewer.BEGAN then
        if touch.state == MOVING then
            self.endPos = vec2(touch.x, touch.y)
            if self.startPos:dist(self.endPos) >= self.dragThreshold then
                self.touchState = FPSWalkerViewer.DRAGGING
                touches.share(self, touch, 0)
            end
        end
    end
    
    return true
end

function FPSWalkerViewer:draw()
    for a,j in pairs(self.joysticks) do
        j:draw()
    end
end