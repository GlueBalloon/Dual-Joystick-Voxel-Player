-- A function that attaches a rigid body capsule to an entity and 
--provides a way to push the body along an angle. The body does a small 
-- jump when it bumps into something.
function rigidCapsuleRig(anEntity, scene, shouldShowCapsule)
    if not anEntity.rig then anEntity.rig = {} end
    local rig = anEntity.rig
    rig.GROUP = 1<<11
    rig.speed = 10
    rig.maxForce = 40
    rig.jumpForce = 5.5
    rig.rb = anEntity:add(craft.rigidbody, DYNAMIC, 1)
    rig.rb.angularFactor = vec3(0,0,0) -- disable rotation
    rig.rb.sleepingAllowed = false
    rig.rb.friction = 0.5
    rig.rb.group = rig.GROUP
    anEntity:add(craft.shape.capsule, 0.5, 1.0)  
    scene.physics.gravity = vec3(0,-14.8,0)  
    rig.contollerYInputAllowed = false
    if shouldShowCapsule then        
        anEntity.model = craft.model(asset.builtin.Primitives.Capsule)
        anEntity.material = craft.material(asset.builtin.Materials.Standard)
    end
    function rig.move(direction)
        rig.rb:applyForce(direction * rig.maxForce)
        
        local hit1 = scene.physics:sphereCast(anEntity.position, vec3(0,-1,0), 0.52, 0.48, ~0, ~rig.GROUP)       
        if hit1 and hit1.normal.y > 0.5 then
            rig.grounded = true
        end
        
        local hit2 = scene.physics:sphereCast(anEntity.position, vec3(0,-1,0), 0.5, 0.52, ~0, ~rig.GROUP)
        if hit2 and hit2.normal.y < 0.5 then
            rig.jump()
        end
    end
    function anEntity.update()
       -- rig.rb.friction = 0.95      --seems unnecessary    
        local v = rig.rb.linearVelocity
        v.y = 0
        
        if v:len() > rig.speed then
            v = v:normalize() * rig.speed
            v.y = rig.rb.linearVelocity.y
            rig.rb.linearVelocity = v
        end       
    end
    function rig.jump()
        local v = rig.rb.linearVelocity
        v.y = rig.jumpForce
        rig.rb.linearVelocity = v
    end
    return anEntity
end


function makeCapsuleBodyOn(anEntity, scene, shouldShowCapsule)
    anEntity.GROUP = 1<<11
    anEntity.speed = 10
    anEntity.maxForce = 10
    anEntity.jumpForce = 5.5
    anEntity.rb = anEntity:add(craft.rigidbody, DYNAMIC, 1)
    anEntity.rb.angularFactor = vec3(0,0,0) -- disable rotation
    anEntity.rb.sleepingAllowed = false
    anEntity.rb.friction = 0.5
    anEntity.rb.group = anEntity.GROUP
    anEntity:add(craft.shape.capsule, 0.5, 1.0)  
    scene.physics.gravity = vec3(0,-14.8,0)  
    anEntity.contollerYInputAllowed = false
    if shouldShowCapsule then        
        anEntity.model = craft.model(asset.builtin.Primitives.Capsule)
        anEntity.material = craft.material(asset.builtin.Materials.Standard)
    end
    function anEntity.move(direction)
        anEntity.rb:applyForce(direction * anEntity.maxForce)
        
        local hit1 = scene.physics:sphereCast(anEntity.position, vec3(0,-1,0), 0.52, 0.48, ~0, ~anEntity.GROUP)       
        if hit1 and hit1.normal.y > 0.5 then
            anEntity.grounded = true
        end
        
        local hit2 = scene.physics:sphereCast(anEntity.position, vec3(0,-1,0), 0.5, 0.52, ~0, ~anEntity.GROUP)
        if hit2 and hit2.normal.y < 0.5 then
            anEntity.jump()
        end
    end
    function anEntity.update()
        anEntity.rb.friction = 0.95          
        local v = anEntity.rb.linearVelocity
        v.y = 0
        
        if v:len() > anEntity.speed then
            v = v:normalize() * anEntity.speed
            v.y = anEntity.rb.linearVelocity.y
            anEntity.rb.linearVelocity = v
        end       
    end
    function anEntity.jump()
        local v = anEntity.rb.linearVelocity
        v.y = anEntity.jumpForce
        anEntity.rb.linearVelocity = v
    end
    return anEntity
end