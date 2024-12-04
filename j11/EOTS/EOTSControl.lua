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

function TBTN(x, y, w, h, text, color, toggleColor, toggled, tx, ty)
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

function ER(v, B)
    local PN = Mv(B, { v[1], v[3], v[2] })
    return { PN[1], PN[3], PN[2] }
end

UC = H2RGB(PT("UI Primary Color"))
UC2 = H2RGB(PT("UI Secondary Color"))
YMAX = PN("Yaw Max")     -- in radians
PMAX = PN("Pitch Max")   -- in radians
PMIN = PN("Pitch Min")   -- in radians
YBASE = PN("Yaw Base")   -- in radians, output will be yaw / YAW_BASE
PBASE = PN("Pitch Base") -- in radians, output will be pitch / PITCH_BASE
SEN = PN("Sensitivity")

TF = false
-- btns
IR_BTN = TBTN(2, 2, 16, 8, "IR", UC2, UC, false, 4, 2)
STA_BTN = TBTN(21, 2, 17, 8, "STA", UC2, UC, false, 2, 2)
BTNS = {
    IR_BTN,
    STA_BTN
}
-- options
IR = false
STA = false
-- sta related
STAF = false
TORT = nil
-- camera orientation
CP = { 0, 0 }
ZOOM = 0

function onTick()
    -- handle touchscreen input
    if IB(1) then
        local tx, ty = IN(1), IN(2)
        if not TF then
            -- handle touch
            for _, btn in ipairs(BTNS) do
                btn:toggle(tx, ty)
            end
            IR = IR_BTN.toggled
            STA = STA_BTN.toggled
        end
        TF = true
    else
        TF = false
    end
    -- set IR out
    OB(1, IR)
    local B = nil
    if STA and STAF then
        -- stabilizer on
        B = Eular2RotMat({ IN(4), IN(6), IN(5) })                            -- global to local matrix
        local cameraTargetVectorLocal = ER(TORT, B)
        CP[1] = atan(cameraTargetVectorLocal[1], cameraTargetVectorLocal[3]) -- yaw
        CP[2] = asin(cameraTargetVectorLocal[2])                             -- pitch
    end
    -- apply mannual control
    ZOOM = IN(3)
    local zoomF = (1 - 0.98 * ZOOM * ZOOM)
    local mYaw, mPitch = IN(7), IN(8)
    CP[1] = clamp(CP[1] + mYaw * SEN * zoomF, -YMAX, YMAX)
    CP[2] = clamp(CP[2] + mPitch * SEN * zoomF, PMIN, PMAX)
    -- output camera pivot
    ON(1, CP[1] / YBASE)
    ON(2, CP[2] / PBASE)
    if STA then
        STAF = true
        -- update STA target camera orientation
        if B == nil then
            B = Eular2RotMat({ IN(4), IN(6), IN(5) })
        end
        TORT = ER({
            cos(CP[2]) * sin(CP[1]),
            sin(CP[2]),
            cos(CP[2]) * cos(CP[1]) }, tM(B))
    else
        STAF = false
    end
end

function onDraw()
    for _, btn in ipairs(BTNS) do
        btn:draw()
    end
end
