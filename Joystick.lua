-- A class that draws a simulated joystick and tracks the angle and 
--length of the current touch from the  touch that it spawned woth.
--it also can represent the joystick position as a directional-pad state.
Joystick = class()

function Joystick:init(x,y,id,ty, strokeColor1, strokeColor2)
    self.ox=x
    self.oy=y
    self.cx=x
    self.cy=y
    self.dx=0
    self.dy=0
    self.type=ty
    self.c=20
    self.touchID = id
    self.touchX = x
    self.touchY = y
    self.delta = vec2(0,0)
    self.smallRadius = 80
    self.largeRadius = 150
    self.stroke1 = strokeColor1 or color(255, 103)
    self.stroke2 = strokeColor2 or color(255, 163)
end

function Joystick:draw()
    local bigCircleFill = color(self.stroke1.r, self.stroke1.g, self.stroke1.b, 8)
    local smallCircleFill = color(self.stroke1.r, self.stroke1.g, self.stroke1.b, 16)
    pushStyle()
    stroke(self.stroke1)
    strokeWidth(2)
    fill(bigCircleFill)
    ellipse(self.ox,self.oy, self.largeRadius)
    stroke(self.stroke2)
    fill(smallCircleFill)
    ellipse(self.touchX,self.touchY, self.smallRadius)
    popStyle()
end

function Joystick:angle()
    return math.atan2(self.delta.y, self.delta.x) * 180 / math.pi
end

--returns table with booleans for the state of left, right, up, and down buttons
function Joystick:activatedDpadDirections(diagonalsAllowed)
    --note: angle 0 points right, 90 points up, -90 points down
    local padState = {left = false, right = false, up = false, down = false}
    local angle = self:angle()
    --ignore stick position if it's basically centered
    if math.abs(self.delta.x) < self.largeRadius * 0.2
    and math.abs(self.delta.y) < self.largeRadius * 0.2
    then return padState end
    --set ranges to convert angles to dpad presses
    local downRange = {under = -45, over = -125}
    local upRange = {under = 125, over = 45}
    local rightRange = {under = upRange.over, over = downRange.under}
    local leftRange = {under = downRange.over, over = upRange.under}
    --if diagonals are allowed, expand all ranges a bit so there's overlap
    if diagonalsAllowed then
        local variance = 25
        upRange.under = upRange.under + variance
        upRange.over = upRange.over - variance
        downRange.under = downRange.under + variance
        downRange.over = downRange.over - variance
        leftRange.under = leftRange.under + variance
        leftRange.over = leftRange.over - variance
        rightRange.under = rightRange.under + variance
        rightRange.over = rightRange.over - variance
    end
    --calculate up and down button states
    if angle < upRange.under and angle > upRange.over then
        padState.up = true
    elseif angle < downRange.under and angle > downRange.over then
        padState.down = true
    end
    --calculate left and right button states
    if angle < leftRange.under or angle > leftRange.over then
        padState.left = true
    elseif (angle < rightRange.under and angle > 0 ) or (angle > rightRange.over and angle < 0) then
        padState.right = true
    end
    return padState
end

function Joystick:dpadButtonsIfCameraRotated(angle, cameraAngle, diagonalsAllowed)
    --note: angle 0 points right, 90 points up, -90 points down
    local padState = {left = false, right = false, up = false, down = false}
    local angle = self:angle()
end

function Joystick:touched(t)
    if t.id == self.touchID then
        self.touchX = t.x
        self.touchY = t.y
        self.delta = vec2(self.touchX - self.ox, self.touchY - self.oy)
    end
end

