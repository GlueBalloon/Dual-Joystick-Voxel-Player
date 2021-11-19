--create an entity that houses a camera and provides get/set functions for 
--the camera properties; this entity attempts to act like a camera,
--viewer, and entity all in one
function makeCameraViewerEntityThing(scene)
    local cameraEntity = scene:entity()
    if not cameraEntity.rig then cameraEntity.rig = {} end
    local rig = cameraEntity.rig
    cameraEntity:add(craft.camera, 45, 0.1, 1000, false)
    cameraEntity.camera = cameraEntity:get(craft.camera)
    cameraEntity.fieldOfView = function(floatOrNil)
        if floatOrNil then
            cameraEntity.camera.fieldOfView = floatOrNil
        else
            return cameraEntity.camera.fieldOfView
        end 
    end
    cameraEntity.ortho = function(boolOrNil)
        if boolOrNil ~= nil then
            cameraEntity.camera.ortho = boolOrNil
        else
            return cameraEntity.camera.ortho
        end 
    end
    cameraEntity.nearPlane = function(floatOrNil)
        if floatOrNil then
            cameraEntity.camera.nearPlane = floatOrNil
        else
            return cameraEntity.camera.nearPlane
        end 
    end
    cameraEntity.farPlane = function(floatOrNil)
        if floatOrNil then
            cameraEntity.camera.farPlane = floatOrNil
        else
            return cameraEntity.camera.farPlane
        end 
    end
    cameraEntity.clearDepthEnabled = function(boolOrNil)
        if boolOrNil ~= nil then
            cameraEntity.camera.clearDepthEnabled = boolOrNil
        else
            return cameraEntity.camera.clearDepthEnabled
        end 
    end
    cameraEntity.clearColorEnabled = function(boolOrNil)
        if boolOrNil ~= nil then
            cameraEntity.camera.clearColorEnabled = boolOrNil
        else
            return cameraEntity.camera.clearColorEnabled
        end 
    end
    cameraEntity.clearColor = function(colorOrNil)
        if colorOrNil then
            cameraEntity.camera.clearColor = colorOrNil
        else
            return cameraEntity.camera.clearColor
        end 
    end
    rig.rx = 0
    rig.ry = 0
    rig.sensitivity = 0.25
    function rig.camRxRy(rx, ry)
        if (not rx) and (not ry) then
            return rig.rx, rig.ry
        end
        rig.rx, rig.ry = rx, ry
        cameraEntity.eulerAngles = vec3(rig.rx,  rig.ry, 0)
    end
    return cameraEntity
end

--clear any of the functions set by the following rigs
--(this also acts a schematic of the functions available 
--when designing your own rigs)
function clearRig(camEntity)
    if touches then     touches.removeHandler(camEntity)
    end
    camEntity.update = nil
    camEntity.touched = nil
    camEntity.scroll = nil
    camEntity.hover = nil
    camEntity.rig = nil
end

--applying a rig to a cameraViewerEntityThing is similar
--to using one of the built-in Craft viewers, except the
--properties and functions that the viewers use are here
--set directly on the entity, so that the entity itself
--is the viewer, instead of the entity being a property 
---of the viewer object

--a rig that copies the functionality of the built-in
--FirstPersonViewer
function firstPersonRig(camEntity)
    if touches then 
        touches.removeHandler(camEntity) 
        touches.addHandler(camEntity, 0, false)
    end
    if not camEntity.rig then camEntity.rig = {} end
    local rig = camEntity.rig
    rig.IDLE = 1
    rig.ROTATE = 2
    rig.state = rig.IDLE
    rig.start = vec2(0,0)
    rig.enabled = true
    rig.isActive = function()
        return rig.state ~= rig.IDLE
    end
    camEntity.update = function()
        if rig.enabled and rig.state == rig.ROTATE then  
            -- clamp vertical rotation between -90 and 90 degrees (no upside down view)
            rig.rx = math.min(math.max(rig.rx, -90), 90)
            rig.camRxRy(rig.rx, rig.ry)
        end
    end
    camEntity.touched = function(not_self, touch)
        if rig.state == rig.IDLE then
            if touch.state == BEGAN then
                rig.start = vec2(touch.x, touch.y)
            elseif touch.state == MOVING then
                local length = (vec2(touch.x, touch.y) - rig.start):len()
                if length >= 5 then
                    rig.state = rig.ROTATE
                end        
            end       
        elseif rig.state == rig.ROTATE then
            if touch.state == MOVING then
                rig.rx = rig.rx - touch.deltaY * rig.sensitivity
                rig.ry = rig.ry - touch.deltaX * rig.sensitivity
            elseif touch.state == ENDED then
                rig.state = rig.IDLE
            end           
        end
        return true
    end    
end

--a rig that copies the functionality of the built-in
--OrbitViewer
function orbitViewerRig(camEntity)
    if touches then 
        touches.removeHandler(camEntity) 
        touches.addHandler(camEntity, 0, true)
    end
    if not camEntity.rig then camEntity.rig = {} end
    local rig = camEntity.rig
    rig.target = target or vec3(0,0,0)
    rig.origin = rig.target    
    rig.zoom = 5
    rig.minZoom = 1
    rig.maxZoom = 20    
    rig.touches = {}
    rig.prev = {}    
    -- Angular momentum
    rig.mx = 0
    rig.my = 0
    -- Project a 2D point z units from the camera
    function rig.project(p, z)
        local origin, dir = camEntity.camera:screenToRay(p)   
        return origin + dir * z
    end
    -- Calculate overscroll curve for zooming
    function rig.scrollDamping(x,s)
        return s * math.log(x + s) - s * math.log(s)
    end
    -- Calculate the distance between the current two touches
    function rig.pinchDist()
        local p1 = vec2(rig.touches[1].x, rig.touches[1].y)
        local p2 = vec2(rig.touches[2].x, rig.touches[2].y)
        return p1:dist(p2)
    end
    
    -- Calculate the mid point between the current two touches
    function rig.pinchMid()
        local p1 = vec2(rig.touches[1].x, rig.touches[1].y)
        local p2 = vec2(rig.touches[2].x, rig.touches[2].y)
        return (p1 + p2) * 0.5
    end
    
    function rig.clampZoom(zoom)
        if zoom > rig.maxZoom then
            local overshoot = zoom - rig.maxZoom
            overshoot = rig.scrollDamping(overshoot, 10.0)
            zoom = rig.maxZoom + overshoot
        elseif zoom < rig.minZoom then
            local overshoot = rig.minZoom - zoom
            overshoot = rig.scrollDamping(overshoot, 10.0)
            zoom = rig.minZoom - overshoot
        end
        return zoom
    end
    
    function rig.rotate(x, y)
        rig.rx = rig.rx - y * rig.sensitivity
        rig.ry = rig.ry - x * rig.sensitivity   
        rig.camRxRy(rig.rx, rig.ry)
    end
    
    function rig.pan(p1, p2)
        local p1 = rig.project(p1, rig.zoom)  
        local p2 = rig.project(p2, rig.zoom)
        
        rig.target = rig.target + (p1-p2)  
    end
    
    function rig.scroll(not_self, gesture)
        local panMode = gesture.shift
        local zoomMode = gesture.alt
        
        if gesture.state == BEGAN then
            if #rig.touches > 0 then return false end
            
            rig.capturedScroll = true
            rig.prev.zoom = rig.zoom
            rig.prev.mid = gesture.location
            
            return true
        elseif gesture.state == MOVING then
            if panMode then
                rig.pan(gesture.location - gesture.delta, gesture.location)            
            elseif zoomMode then
                rig.zoom = rig.clampZoom(rig.prev.zoom + (gesture.location - rig.prev.mid).y * rig.sensitivity)
            else
                rig.rotate(gesture.delta.x, gesture.delta.y)
            end
            rig.prevGestureDelta = gesture.delta
        elseif gesture.state == ENDED or gesture.state == CANCELLED then
            rig.capturedScroll = false
            
            if not panMode and not zoomMode then
                local delta = rig.prevGestureDelta
                rig.mx = -delta.y / DeltaTime * rig.sensitivity
                rig.my = -delta.x / DeltaTime * rig.sensitivity        
            end
        end
    end
    
    function camEntity.update()
        if #rig.touches == 0 and not rig.capturedScroll then
            -- Apply momentum from previous swipe
            rig.rx = rig.rx + rig.mx * DeltaTime
            rig.ry = rig.ry + rig.my * DeltaTime
            rig.mx = rig.mx * 0.9
            rig.my = rig.my * 0.9 
            
            -- If zooming past min or max interpolate back to limits
            if rig.zoom > rig.maxZoom then
                local overshoot = rig.zoom - rig.maxZoom
                overshoot = overshoot * 0.9
                rig.zoom = rig.maxZoom + overshoot
            elseif rig.zoom < rig.minZoom then
                local overshoot = rig.minZoom - rig.zoom
                overshoot = overshoot * 0.9
                rig.zoom = rig.minZoom - overshoot
            end
            
        elseif #rig.touches == 2 then
            camEntity.position = rig.prev.target - camEntity.forward * rig.zoom
            
            local mid = rig.pinchMid()  
            local dist = rig.pinchDist()
            
            local p1 = rig.project(rig.prev.mid, rig.zoom)  
            local p2 = rig.project(mid, rig.zoom)
            
            rig.target = rig.prev.target + (p1-p2)  
            rig.zoom = rig.clampZoom(rig.prev.zoom * (rig.prev.dist / dist))
        end  
        
        -- Clamp vertical rotation between -90 and 90 degrees (no upside down view)
        rig.rx = math.min(math.max(rig.rx, -90), 90)
        
        -- Calculate the camera's position and rotation
        --[[
        local rotation = quat.eulerAngles(self.rx,  self.ry, 0)
        self.entity.rotation = rotation
    ]]
rig.camRxRy(rig.rx, rig.ry)
local t = vec3(rig.target.x, rig.target.y, rig.target.z)
--self.entity.position = t + self.entity.forward * -self.zoom
--not sure how above translates to this paradigm...
camEntity.position = t + camEntity.forward * -rig.zoom
end

function camEntity.touched(not_self, touch)
if touch.tapCount == 2 then
    rig.target = rig.origin
end

if rig.capturedScroll then return false end

-- Allow a maximum of 2 touches
        if touch.state == BEGAN and #rig.touches < 2 then
    table.insert(rig.touches, touch)
    if #rig.touches == 2 then
        rig.prev.target = vec3(rig.target:unpack())
                rig.prev.mid = rig.pinchMid()
        rig.prev.dist = rig.pinchDist()
        rig.prev.zoom = rig.zoom
        rig.mx = 0
        rig.my = 0
    end        
    return true
    -- Cache updated touches
elseif touch.state == MOVING then
    for i = 1,#rig.touches do
        if rig.touches[i].id == touch.id then
            rig.touches[i] = touch
        end
    end
    -- Remove old touches
elseif touch.state == ENDED or touch.state == CANCELLED then
    for i = #rig.touches,1,-1 do
        if rig.touches[i].id == touch.id then
            table.remove(rig.touches, i)
            break
        end
    end
    
    if #rig.touches == 1 then
        rig.mx = 0
        rig.my = 0
    end
end

-- When all touches are finished apply momentum if moving fast enough
if #rig.touches == 0 then
    rig.mx = -touch.deltaY / DeltaTime * rig.sensitivity
    rig.my = -touch.deltaX / DeltaTime * rig.sensitivity
    if math.abs(rig.mx) < 70 then 
        rig.mx = 0
    end
    if math.abs(rig.my) < 70 then 
        rig.my = 0
    end
    -- When only one touch is active simply rotate the camera
elseif #rig.touches == 1 then
    rig.rotate(touch.deltaX, touch.deltaY)
end

return false
end
end
