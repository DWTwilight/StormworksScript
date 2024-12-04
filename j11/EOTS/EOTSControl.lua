m = math
pi = m.pi
pi2 = 2 * pi
sin = m.sin
cos = m.cos
atan = m.atan
asin = m.asin

S = screen
DR = S.drawRect
DT = S.drawText

IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

P = property
PN = P.getNumber
PT = P.getText

function clamp(value, min, max)
    return m.min(max, m.max(value, min))
end

function H2RGB(e)
    e = e:gsub("#", "")
    return {
        r = tonumber("0x" .. e:sub(1, 2)),
        g = tonumber("0x" .. e:sub(3, 4)),
        b = tonumber("0x" .. e:sub(5, 6)),
        t = tonumber("0x" .. e:sub(7, 8))
    }
end

function SC(c)
    S.setColor(c.r, c.g, c.b, c.t)
end

function PIR(x, y, rectX, rectY, rectW, rectH)
    return x >= rectX and y >= rectY and x < rectX + rectW and y < rectY + rectH
end

function ToggleButton(x, y, w, h, text, color, toggleColor, toggled, tx, ty)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        text = text,
        c = color,
        tc = toggleColor,
        toggled = toggled,
        tx = tx,
        ty = ty,
        toggle = function(btn, tx, ty)
            if PIR(tx, ty, btn.x, btn.y, btn.w, btn.h) then
                btn.toggled = not btn.toggled
            end
        end,
        draw = function(btn)
            SC(btn.toggled and btn.tc or btn.c)
            DR(btn.x, btn.y, btn.w, btn.h)
            DT(btn.x + tx, btn.y + ty, btn.text)
        end
    }
end

function Eular2RotMat(E)
    local qx, qy, qz = E[1], E[2], E[3]
    return { { cos(qy) * cos(qz), cos(qx) * cos(qy) * sin(qz) + sin(qx) * sin(qy),
        sin(qx) * cos(qy) * sin(qz) - cos(qx) * sin(qy) }, { -sin(qz), cos(qx) * cos(qz), sin(qx) * cos(qz) },
        { sin(qy) * cos(qz), cos(qx) * sin(qy) * sin(qz) - sin(qx) * cos(qy),
            sin(qx) * sin(qy) * sin(qz) + cos(qx) * cos(qy) } }
end

function Mv(M, v)
    local u = {}
    for i = 1, 3 do
        local _ = 0
        for j = 1, 3 do
            _ = _ + M[j][i] * v[j]
        end
        u[i] = _
    end
    return u
end

function tM(M)
    local N = { {}, {}, {} }
    for i = 1, 3 do
        for j = 1, 3 do
            N[i][j] = M[j][i]
        end
    end
    return N
end

function EularRotate(v, B)
    local PN = Mv(B, { v[1], v[3], v[2] })
    return { PN[1], PN[3], PN[2] }
end

UC = H2RGB(PT("UI Primary Color"))
UC2 = H2RGB(PT("UI Secondary Color"))
YAW_MAX = PN("Yaw Max")       -- in radians
PITCH_MAX = PN("Pitch Max")   -- in radians
PITCH_MIN = PN("Pitch Min")   -- in radians
YAW_BASE = PN("Yaw Base")     -- in radians, output will be yaw / YAW_BASE
PITCH_BASE = PN("Pitch Base") -- in radians, output will be pitch / PITCH_BASE
SENSITIVITY = PN("Sensitivity")

TOUCH_FLAG = false
-- btns
IR_BTN = ToggleButton(2, 2, 16, 8, "IR", UC2, UC, false, 4, 2)
STA_BTN = ToggleButton(21, 2, 17, 8, "STA", UC2, UC, false, 2, 2)
BUTTONS = {
    IR_BTN,
    STA_BTN
}
-- options
IR = false
STA = false
-- sta related
STA_FLAG = false
TARGET_ORT = nil
-- camera orientation
CAMERA_PIVOT = { 0, 0 }
ZOOM = 0

function onTick()
    -- handle touchscreen input
    if IB(1) then
        local tx, ty = IN(1), IN(2)
        if not TOUCH_FLAG then
            -- handle touch
            for _, btn in ipairs(BUTTONS) do
                btn:toggle(tx, ty)
            end
            IR = IR_BTN.toggled
            STA = STA_BTN.toggled
        end
        TOUCH_FLAG = true
    else
        TOUCH_FLAG = false
    end
    -- set IR out
    OB(1, IR)
    local B = nil
    if STA and STA_FLAG then
        -- stabilizer on
        B = Eular2RotMat({ IN(4), IN(6), IN(5) })                                      -- global to local matrix
        local cameraTargetVectorLocal = EularRotate(TARGET_ORT, B)
        CAMERA_PIVOT[1] = atan(cameraTargetVectorLocal[1], cameraTargetVectorLocal[3]) -- yaw
        CAMERA_PIVOT[2] = asin(cameraTargetVectorLocal[2])                             -- pitch
    end
    -- apply mannual control
    ZOOM = IN(3)
    local zoomF = (1 - 0.98 * ZOOM * ZOOM)
    local mYaw, mPitch = IN(7), IN(8)
    CAMERA_PIVOT[1] = clamp(CAMERA_PIVOT[1] + mYaw * SENSITIVITY * zoomF, -YAW_MAX, YAW_MAX)
    CAMERA_PIVOT[2] = clamp(CAMERA_PIVOT[2] + mPitch * SENSITIVITY * zoomF, PITCH_MIN, PITCH_MAX)
    -- output camera pivot
    ON(1, CAMERA_PIVOT[1] / YAW_BASE)
    ON(2, CAMERA_PIVOT[2] / PITCH_BASE)
    if STA then
        STA_FLAG = true
        -- update STA target camera orientation
        if B == nil then
            B = Eular2RotMat({ IN(4), IN(6), IN(5) })
        end
        TARGET_ORT = EularRotate({
            cos(CAMERA_PIVOT[2]) * sin(CAMERA_PIVOT[1]),
            sin(CAMERA_PIVOT[2]),
            cos(CAMERA_PIVOT[2]) * cos(CAMERA_PIVOT[1]) }, tM(B))
    else
        STA_FLAG = false
    end
end

function onDraw()
    for _, btn in ipairs(BUTTONS) do
        btn:draw()
    end
end
