--create an entity that houses a camera and provides get/set functions for 
--the camera properties; this entity attempts to act like a camera,
--viewer, and entity all in one
function makeCameraViewerEntityThing(scene)
    local cameraEntity = scene:entity()
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
    cameraEntity.rx = 0
    cameraEntity.ry = 0
    cameraEntity.sensitivity = 0.25
    function cameraEntity.camRxRy(rx, ry)
        if (not rx) and (not ry) then
            return cameraEntity.rx, cameraEntity.ry
        end
        cameraEntity.rx, cameraEntity.ry = rx, ry
        cameraEntity.eulerAngles = vec3(cameraEntity.rx,  cameraEntity.ry, 0)
    end
    return cameraEntity
end

--clear any of the functions set by the following rigs
--(this also acts a schematic of the functions available 
--when designing your own rigs)
function clearRig(camEntity)
    if touches then 
        touches.removeHandler(camEntity)
    end
    camEntity.update = nil
    camEntity.touched = nil
    camEntity.scroll = nil
    camEntity.hover = nil
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
    camEntity.IDLE = 1
    camEntity.ROTATE = 2
    camEntity.state = camEntity.IDLE
    camEntity.start = vec2(0,0)
    camEntity.enabled = true
    camEntity.isActive = function()
        return camEntity.state ~= camEntity.IDLE
    end
    camEntity.update = function()
        if camEntity.enabled and camEntity.state == camEntity.ROTATE then  
            -- clamp vertical rotation between -90 and 90 degrees (no upside down view)
            camEntity.rx = math.min(math.max(camEntity.rx, -90), 90)
            camEntity.camRxRy(camEntity.rx, camEntity.ry)
        end
    end
    camEntity.touched = function(not_self, touch)
        if camEntity.state == camEntity.IDLE then
            if touch.state == BEGAN then
                camEntity.start = vec2(touch.x, touch.y)
            elseif touch.state == MOVING then
                local length = (vec2(touch.x, touch.y) - camEntity.start):len()
                if length >= 5 then
                    camEntity.state = camEntity.ROTATE
                end        
            end       
        elseif camEntity.state == camEntity.ROTATE then
            if touch.state == MOVING then
                camEntity.rx = camEntity.rx - touch.deltaY * camEntity.sensitivity
                camEntity.ry = camEntity.ry - touch.deltaX * camEntity.sensitivity
            elseif touch.state == ENDED then
                camEntity.state = camEntity.IDLE
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
    camEntity.target = target or vec3(0,0,0)
    camEntity.origin = camEntity.target    
    camEntity.zoom = 5
    camEntity.minZoom = 1
    camEntity.maxZoom = 20    
    camEntity.touches = {}
    camEntity.prev = {}    
    -- Angular momentum
    camEntity.mx = 0
    camEntity.my = 0
    -- Project a 2D point z units from the camera
    function camEntity.project(p, z)
        local origin, dir = camEntity.camera:screenToRay(p)   
        return origin + dir * z
    end
    -- Calculate overscroll curve for zooming
    function camEntity.scrollDamping(x,s)
        return s * math.log(x + s) - s * math.log(s)
    end
    -- Calculate the distance between the current two touches
    function camEntity.pinchDist()
        local p1 = vec2(camEntity.touches[1].x, camEntity.touches[1].y)
        local p2 = vec2(camEntity.touches[2].x, camEntity.touches[2].y)
        return p1:dist(p2)
    end
    
    -- Calculate the mid point between the current two touches
    function camEntity.pinchMid()
        local p1 = vec2(camEntity.touches[1].x, camEntity.touches[1].y)
        local p2 = vec2(camEntity.touches[2].x, camEntity.touches[2].y)
        return (p1 + p2) * 0.5
    end
    
    function camEntity.clampZoom(zoom)
        if zoom > camEntity.maxZoom then
            local overshoot = zoom - camEntity.maxZoom
            overshoot = camEntity.scrollDamping(overshoot, 10.0)
            zoom = camEntity.maxZoom + overshoot
        elseif zoom < camEntity.minZoom then
            local overshoot = camEntity.minZoom - zoom
            overshoot = camEntity.scrollDamping(overshoot, 10.0)
            zoom = camEntity.minZoom - overshoot
        end
        return zoom
    end
    
    function camEntity.rotate(x, y)
        camEntity.rx = camEntity.rx - y * camEntity.sensitivity
        camEntity.ry = camEntity.ry - x * camEntity.sensitivity   
        camEntity.camRxRy(camEntity.rx, camEntity.ry)
    end
    
    function camEntity.pan(p1, p2)
        local p1 = camEntity.project(p1, camEntity.zoom)  
        local p2 = camEntity.project(p2, camEntity.zoom)
        
        camEntity.target = camEntity.target + (p1-p2)  
    end
    
    function camEntity.scroll(not_self, gesture)
        local panMode = gesture.shift
        local zoomMode = gesture.alt
        
        if gesture.state == BEGAN then
            if #camEntity.touches > 0 then return false end
            
            camEntity.capturedScroll = true
            camEntity.prev.zoom = camEntity.zoom
            camEntity.prev.mid = gesture.location
            
            return true
        elseif gesture.state == MOVING then
            if panMode then
                camEntity.pan(gesture.location - gesture.delta, gesture.location)            
            elseif zoomMode then
                camEntity.zoom = camEntity.clampZoom(camEntity.prev.zoom + (gesture.location - camEntity.prev.mid).y * camEntity.sensitivity)
            else
                camEntity.rotate(gesture.delta.x, gesture.delta.y)
            end
            camEntity.prevGestureDelta = gesture.delta
        elseif gesture.state == ENDED or gesture.state == CANCELLED then
            camEntity.capturedScroll = false
            
            if not panMode and not zoomMode then
                local delta = camEntity.prevGestureDelta
                camEntity.mx = -delta.y / DeltaTime * camEntity.sensitivity
                camEntity.my = -delta.x / DeltaTime * camEntity.sensitivity        
            end
        end
    end
    
    function camEntity.update()
        if #camEntity.touches == 0 and not camEntity.capturedScroll then
            -- Apply momentum from previous swipe
            camEntity.rx = camEntity.rx + camEntity.mx * DeltaTime
            camEntity.ry = camEntity.ry + camEntity.my * DeltaTime
            camEntity.mx = camEntity.mx * 0.9
            camEntity.my = camEntity.my * 0.9 
            
            -- If zooming past min or max interpolate back to limits
            if camEntity.zoom > camEntity.maxZoom then
                local overshoot = camEntity.zoom - camEntity.maxZoom
                overshoot = overshoot * 0.9
                camEntity.zoom = camEntity.maxZoom + overshoot
            elseif camEntity.zoom < camEntity.minZoom then
                local overshoot = camEntity.minZoom - camEntity.zoom
                overshoot = overshoot * 0.9
                camEntity.zoom = camEntity.minZoom - overshoot
            end
            
        elseif #camEntity.touches == 2 then
            camEntity.position = camEntity.prev.target - camEntity.forward * camEntity.zoom
            
            local mid = camEntity.pinchMid()  
            local dist = camEntity.pinchDist()
            
            local p1 = camEntity.project(camEntity.prev.mid, camEntity.zoom)  
            local p2 = camEntity.project(mid, camEntity.zoom)
            
            camEntity.target = camEntity.prev.target + (p1-p2)  
            camEntity.zoom = camEntity.clampZoom(camEntity.prev.zoom * (camEntity.prev.dist / dist))
        end  
        
        -- Clamp vertical rotation between -90 and 90 degrees (no upside down view)
        camEntity.rx = math.min(math.max(camEntity.rx, -90), 90)
        
        -- Calculate the camera's position and rotation
        --[[
        local rotation = quat.eulerAngles(self.rx,  self.ry, 0)
        self.entity.rotation = rotation
    ]]
camEntity.camRxRy(camEntity.rx, camEntity.ry)
local t = vec3(camEntity.target.x, camEntity.target.y, camEntity.target.z)
--self.entity.position = t + self.entity.forward * -self.zoom
--not sure how above translates to this paradigm...
camEntity.position = t + camEntity.forward * -camEntity.zoom
end

function camEntity.touched(not_self, touch)
if touch.tapCount == 2 then
    camEntity.target = camEntity.origin
end

if camEntity.capturedScroll then return false end

-- Allow a maximum of 2 touches
if touch.state == BEGAN and #camEntity.touches < 2 then
    table.insert(camEntity.touches, touch)
    if #camEntity.touches == 2 then
        camEntity.prev.target = vec3(camEntity.target:unpack())
        camEntity.prev.mid = camEntity.pinchMid()
        camEntity.prev.dist = camEntity.pinchDist()
        camEntity.prev.zoom = camEntity.zoom
        camEntity.mx = 0
        camEntity.my = 0
    end        
    return true
    -- Cache updated touches
elseif touch.state == MOVING then
    for i = 1,#camEntity.touches do
        if camEntity.touches[i].id == touch.id then
            camEntity.touches[i] = touch
        end
    end
    -- Remove old touches
elseif touch.state == ENDED or touch.state == CANCELLED then
    for i = #camEntity.touches,1,-1 do
        if camEntity.touches[i].id == touch.id then
            table.remove(camEntity.touches, i)
            break
        end
    end
    
    if #camEntity.touches == 1 then
        camEntity.mx = 0
        camEntity.my = 0
    end
end

-- When all touches are finished apply momentum if moving fast enough
if #camEntity.touches == 0 then
    camEntity.mx = -touch.deltaY / DeltaTime * camEntity.sensitivity
    camEntity.my = -touch.deltaX / DeltaTime * camEntity.sensitivity
    if math.abs(camEntity.mx) < 70 then 
        camEntity.mx = 0
    end
    if math.abs(camEntity.my) < 70 then 
        camEntity.my = 0
    end
    -- When only one touch is active simply rotate the camera
elseif #camEntity.touches == 1 then
    camEntity.rotate(touch.deltaX, touch.deltaY)
end

return false
end
end
