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
    --[[
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
    if gesture.state == BEGAN then 
        return true
    elseif gesture.state == MOVING then
        self.rx = self.rx - gesture.delta.y * self.sensitivity
        self.ry = self.ry - gesture.delta.x * self.sensitivity    
    end
end

function FPSWalkerViewer:touched(touch)
    
    if touch.state==BEGAN then
        if #self.joysticks < 2 then
            if touch.x<WIDTH/2 then 
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
    
    
voxelWalkerMaker = function(currentScene, x, y, z)
    return currentScene:entity():add(VoxelWalker, currentScene, currentScene.camera:get(craft.camera), x, y, z)
end

VoxelWalker = class()
VoxelWalker.GROUP = 1<<11

function VoxelWalker:init(entity, currentScene, sceneCamera, x, y, z)
    local x = x or 40
    local y = y or 20
    local z = z or 40
    assert(touches, "Please include Touches project as a dependency")
    self.scene = currentScene
    self.entity = self.scene:entity()  
    self.camera = sceneCamera
    self.viewer = self.camera.entity:add(FPSWalkerViewer, 0.6, 5, {})
    self.viewer:setOutputReciever(self:defaultLeftStickFunction(), self:defaultRightStickFunction())
    self.camera.ortho = false    
    self.speed = 10
    self.maxForce = 35
    self.jumpForce = 5.5
    self.viewer.rx = 45
    self.viewer.ry = -45   
    self.entity.position = vec3(x, y, z)
    self.camera.entity.parent = self.entity
    self.camera.entity.position = vec3(0,0.85,0)    
    touches.addHandler(self, 0, true)    
    -- Player physics
    self.rb = self.entity:add(craft.rigidbody, DYNAMIC, 1)
    self.rb.angularFactor = vec3(0,0,0) -- disable rotation
    self.rb.sleepingAllowed = false
    self.rb.friction = 0.5
    self.rb.group = VoxelWalker.GROUP
    self.entity:add(craft.shape.capsule, 0.5, 1.0)    
    self.scene.physics.gravity = vec3(0,-14.8,0)
    self.contollerYInputAllowed = false
end

function VoxelWalker:setOutputReciever(functionForLeftStick, functionForRightStick)
    self.viewer:setOutputReciever(functionForLeftStick, functionForRightStick)
end

function VoxelWalker:setupCameras()
    if not self.camera then
        self.camera = self.scene.camera:get(craft.camera)
    end
    if not self.viewer then
        self.viewer = self.camera.entity:add(FPSWalkerViewer, 0.6, 5, {})
    end
end

function VoxelWalker:touched(touch)
    if (not self.camera) or (not self.viewer) or (not self.viewer.touch) then
        self:setupCameras()
    end
    if self.viewer then
        self.viewer:touched(touch)
    end
    return true
end

function VoxelWalker:defaultLeftStickFunction()
    return function(stick)
        local delta = stick.delta          
        local forward = self.camera.entity.forward * delta.y
        local right = self.camera.entity.right * -delta.x   
        local finalDir = forward + right   
        if not self.contollerYInputAllowed then       
            finalDir.y = 0
        end
        if finalDir:len() > 0 then
            finalDir = finalDir:normalize()
        end    
        finalDir.x = math.min(finalDir.x or 2)
        finalDir.z = math.min(finalDir.z or 2)
        self.rb:applyForce(finalDir * self.maxForce)
        
        local hit1 = self.scene.physics:sphereCast(self.entity.position, vec3(0,-1,0), 0.52, 0.48, ~0, ~VoxelWalker.GROUP)
        
        if hit1 and hit1.normal.y > 0.5 then
            self.grounded = true
        end
        
        local hit2 = self.scene.physics:sphereCast(self.entity.position, vec3(0,-1,0), 0.5, 0.52, ~0, ~VoxelWalker.GROUP)
        if hit2 and hit2.normal.y < 0.5 then
            self:jump()
        end
    end
end

function VoxelWalker:defaultRightStickFunction()
    return function(_)
        if self.viewer.enabled then  
            -- clamp vertical rotation between -90 and 90 degrees (no upside down view)
            self.viewer.rx = math.min(math.max(self.viewer.rx, -90), 90)
            local rotation = quat.eulerAngles(self.viewer.rx,  self.viewer.ry, 0)
            self.viewer.camera.rotation = rotation
        end
    end
end

function VoxelWalker:update()
    
    if (not self.camera) or (not self.viewer) or (not self.viewer.touch)  then
        self:setupCameras()
    end
    if not self.viewer.joysticks then
        self.viewer.joysticks = {}
    end
    
    for _, stick in ipairs(self.viewer.joysticks) do
        ----------
    end
    
    self.rb.friction = 0.95          
    local v = self.rb.linearVelocity
    v.y = 0
    
    if v:len() > self.speed then
        v = v:normalize() * self.speed
        v.y = self.rb.linearVelocity.y
        self.rb.linearVelocity = v
    end       
end

function VoxelWalker:dpadStates(diagonalsAllowed)
    local rightStick = {left = false, right = false, up = false, down = false}
    local leftStick = {left = false, right = false, up = false, down = false}
    if self.viewer.joysticks then
        for _, stick in ipairs(self.viewer.joysticks) do
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

function VoxelWalker:draw()
    if (not self.camera) or (not self.viewer) or (not self.viewer.touch)  then
        self:setupCameras()
    end
    if self.viewer and self.viewer.draw then 
        self.viewer:draw()
    end
end

function VoxelWalker:jump()
    local v = self.rb.linearVelocity
    v.y = self.jumpForce
    self.rb.linearVelocity = v
end