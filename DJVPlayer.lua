djvPlayerMaker = function(currentScene, x, y, z)
    return currentScene:entity():add(DJVPlayer, currentScene, currentScene.camera:get(craft.camera), x, y, z)
end

DJVPlayer = class()
DJVPlayer.GROUP = 1<<11

function DJVPlayer:init(entity, currentScene, sceneCamera, x, y, z)
    local x = x or 40
    local y = y or 20
    local z = z or 40
    assert(touches, "Please include Touches project as a dependency")
    self.scene = currentScene
    self.camera = sceneCamera
    print(self.camera)
    self.entity = self.camera.entity 
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
  --  self.camera.entity.position = vec3(0,0,0)    
    touches.addHandler(self, 0, true)    
    -- Player physics
    self.rb = self.entity:add(craft.rigidbody, DYNAMIC, 1)
    self.rb.angularFactor = vec3(0,0,0) -- disable rotation
    self.rb.sleepingAllowed = false
    self.rb.friction = 0.5
    self.rb.group = DJVPlayer.GROUP
    self.entity:add(craft.shape.capsule, 0.5, 1.0)    
    self.scene.physics.gravity = vec3(0,-14.8,0)
    self.contollerYInputAllowed = false
end

function DJVPlayer:setOutputReciever(functionForLeftStick, functionForRightStick)
    self.viewer:setOutputReciever(functionForLeftStick, functionForRightStick)
end

function DJVPlayer:setupCameras()
    if not self.camera then
        self.camera = self.scene.camera:get(craft.camera)
    end
    if not self.viewer then
        self.viewer = self.camera.entity:add(FPSWalkerViewer, 0.6, 5, {})
    end
end

function DJVPlayer:touched(touch)
    if (not self.camera) or (not self.viewer) or (not self.viewer.touch) then
        self:setupCameras()
    end
    if self.viewer then
        self.viewer:touched(touch)
    end
    return true
end

function DJVPlayer:defaultLeftStickFunction()
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
        
        local hit1 = self.scene.physics:sphereCast(self.entity.position, vec3(0,-1,0), 0.52, 0.48, ~0, ~DJVPlayer.GROUP)
        
        if hit1 and hit1.normal.y > 0.5 then
            self.grounded = true
        end
        
        local hit2 = self.scene.physics:sphereCast(self.entity.position, vec3(0,-1,0), 0.5, 0.52, ~0, ~DJVPlayer.GROUP)
        if hit2 and hit2.normal.y < 0.5 then
            self:jump()
        end
    end
end

function DJVPlayer:defaultRightStickFunction()
    return function(_)
        if self.viewer.enabled then  
            -- clamp vertical rotation between -90 and 90 degrees (no upside down view)
            self.viewer.rx = math.min(math.max(self.viewer.rx, -90), 90)
            local rotation = quat.eulerAngles(self.viewer.rx,  self.viewer.ry, 0)
            self.viewer.camera.rotation = rotation
        end
    end
end

function DJVPlayer:update()
    
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

function DJVPlayer:dpadStates(diagonalsAllowed)
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

function DJVPlayer:draw()
    if (not self.camera) or (not self.viewer) or (not self.viewer.touch)  then
        self:setupCameras()
    end
    if self.viewer and self.viewer.draw then 
        self.viewer:draw()
    end
end

function DJVPlayer:jump()
    local v = self.rb.linearVelocity
    v.y = self.jumpForce
    self.rb.linearVelocity = v
end