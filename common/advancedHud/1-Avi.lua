M = math
PI = M.pi
PI2 = 2 * PI
SIN = M.sin
COS = M.cos
TAN = M.tan
ABS = M.abs
DEG = M.deg
RAD = M.rad
FL = M.floor
MAX = M.max

IN = input.getNumber
IB = input.getBool

S = screen
DL = S.drawLine
DR = S.drawRect
DC = S.drawCircle
DT = S.drawText
DRF = S.drawRectF
DTAF = S.drawTriangleF
SSC = S.setColor

P = property
PN = P.getNumber
PT = P.getText

SF = string.format
TN = tonumber

function H2RGB(e)
    e = e:gsub("#", "")
    return {
        r = TN("0x" .. e:sub(1, 2)),
        g = TN("0x" .. e:sub(3, 4)),
        b = TN("0x" .. e:sub(5, 6)),
        t = TN("0x" .. e:sub(7, 8))
    }
end

function SC(c)
    if c == nil then
        SSC(0, 0, 0)
    else
        SSC(c.r, c.g, c.b, c.t)
    end
end

UC = H2RGB(PT("UI Primary Color"))
SCRW = PN("Screen Width")
HSCRW = SCRW / 2
LOF = PN("Look Offset Factor")
LOXF = PN("Look Offset X Factor")
COY = PN("Center Offset Y")
FOV = PN("FOV(rad)")
SDP = HSCRW / TAN(FOV / 2) -- screen px distance

OX, OY = 0, 0
ROLL, PITCH, YAW, SPD, ALT = 0, 0, 0, 0, 0
SPDX, SPDY, SPDZ = 0, 0, 0

function onTick()
    OX, OY = SIN(IN(1) * PI2) * LOF * LOXF + HSCRW + 0.5, -SIN(IN(2) * PI2) * LOF - COY + HSCRW + 0.5
    ROLL, PITCH, YAW = IN(3), IN(4), IN(5)
    SPD, ALT = IN(6) * 3.6, IN(7)
    SPDX, SPDY, SPDZ = IN(8), IN(9), MAX(1, IN(10))
end

-- convert screen pos according to roll
function rollR(x, y)
    local r = -ROLL
    return
        x * COS(r) - y * SIN(r),
        x * SIN(r) + y * COS(r)
end

-- (0, 0) is center viewpoint
function CDL(x1, y1, x2, y2)
    DL(
        FL(x1 + OX),
        FL(y1 + OY),
        FL(x2 + OX),
        FL(y2 + OY)
    )
end

function CDR(x, y, w, h)
    DR(FL(x + OX), FL(y + OY), w, h)
end

function CDRF(x, y, w, h)
    DRF(FL(x + OX), FL(y + OY), w, h)
end

function CDT(x, y, t)
    DT(FL(x + OX), FL(y + OY), t)
end

function CDC(x, y, r)
    DC(FL(x + OX), FL(y + OY), r)
end

-- draw line that converts with current roll
function CDLR(x1, y1, x2, y2)
    x1, y1 = rollR(x1, y1)
    x2, y2 = rollR(x2, y2)
    CDL(x1, y1, x2, y2)
end

-- draw dash line (horizontal) that converts with current roll
-- x2 - x1 should be gap * n (n is odd)
function CDDLR(x1, x2, y, gap)
    for x = x1, x2, 2 * gap do
        CDLR(x, y, x + gap, y)
    end
end

-- draw text that converts with current roll
function CDTR(x, y, t)
    -- get text center
    x, y = rollR(x + #t * 2, y + 2)
    -- convert back to drawText coord
    x = x - #t * 2
    y = y - 2
    -- draw Text
    CDT(x, y, t)
end

function drawHorizon()
    -- crosshair
    CDL(-2, 0, 0, 0)
    CDL(1, 0, 3, 0)
    CDL(0, -2, 0, 0)
    CDL(0, 1, 0, 3)
    -- draw scaleplate
    local pi = DEG(PITCH) // 1
    -- up
    for d = -15 - pi % 5, 20, 5 do
        local ang = pi + d
        local oy = -TAN(RAD(ang) - PITCH) * SDP
        -- check if if outof boundray
        if ABS(oy) < 54 then
            -- convert ang to (-90, 90]
            if ang > 90 then
                ang = ang - 180
            elseif ang <= -90 then
                ang = 180 + ang
            end
            local a, b = 14, 4
            if ang == 0 then
                CDLR(-40, oy, -b, oy)
                CDLR(40, oy, b, oy)
            else
                if ang > 0 then
                    CDLR(-a, oy, -b, oy)
                    CDLR(a, oy, b, oy)
                    CDLR(-a, oy, -a, oy + 3)
                    CDLR(a, oy, a, oy + 3)
                else
                    CDDLR(-a, -b, oy, 2)
                    CDDLR(a, b, oy, -2)
                    CDLR(-a, oy, -a, oy - 3)
                    CDLR(a, oy, a, oy - 3)
                end
                -- draw ang text
                local angText = SF("%d", ABS(ang))
                CDTR(-a - #angText * 5, oy - 2, angText)
                CDTR(a + 2, oy - 2, angText)
            end
        end
    end
end

function drawHeading(oy)
    local headingAng = (DEG(YAW) + 360) % 360
    -- draw scaleplate
    for i = -20 - (headingAng // 1) % 5, 25, 5 do
        local ox = 2 * i
        if ABS(ox) < 35 then
            local curAng = ((headingAng + i) % 360) // 1
            if curAng % 10 == 0 then
                CDL(ox, oy + 7, ox, oy + 11)
                local currentHeadingText = SF("%d", curAng // 10)
                CDT(ox - #currentHeadingText * 2, oy, currentHeadingText)
            else
                CDL(ox, oy + 9, ox, oy + 11)
            end
        end
    end
    -- draw current headingAng
    SC(nil)
    CDRF(-8, oy - 2, 17, 8)
    SC(UC)
    local h = SF("%.0f", headingAng)
    CDT(#h * -2, oy, h)
    CDR(-8, oy - 2, 17, 8)
end

function drawSpeed(ox, oy)
    local speedInt = SPD // 1
    -- draw scaleplate
    for i = -20 - speedInt % 2, 22, 2 do
        local currentSpeed = speedInt + i
        local offsetY = (currentSpeed - SPD) * 1.5
        if ABS(offsetY) < 25 then
            local oh = oy - offsetY
            if currentSpeed % 10 == 0 then
                CDL(ox, oh, ox - 4, oh)
                local currentSpeedText = SF("%d", currentSpeed // 10)
                CDT(ox - 3 - 5 * #currentSpeedText, oh - 2, currentSpeedText)
            else
                CDL(ox, oh, ox - 2, oh)
            end
        end
    end
    -- draw current air speed
    SC(nil)
    CDRF(ox - 22, oy - 4, 22, 8)
    SC(UC)
    local s = SF("%d", speedInt)
    CDT(ox - 5 * #s, oy - 2, s)
    CDR(ox - 22, oy - 4, 22, 8)
    -- draw speed vector
    local svOx, svOy =
        SDP / SPDZ * SPDX,
        -SDP / (SPDZ ^ 2 + SPDX ^ 2) ^ 0.5 * SPDY
    CDC(svOx, svOy, 3)
    CDL(svOx, svOy - 3, svOx, svOy - 6)
    CDL(svOx - 3, svOy, svOx - 6, svOy)
    CDL(svOx + 3, svOy, svOx + 6, svOy)
end

function drawAlt(ox, oy)
    local altInt = ALT // 1
    -- draw scaleplate
    for i = -200 - altInt % 20, 220, 20 do
        local currentAlt = altInt + i
        local offsetY = (currentAlt - ALT) * 0.15
        if ABS(offsetY) < 25 then
            local oh = oy - offsetY
            if currentAlt % 100 == 0 then
                CDL(ox, oh, ox + 4, oh)
                local currentAltText = SF("%d", currentAlt // 100)
                CDT(ox + 5, oh - 2, currentAltText)
            else
                CDL(ox, oh, ox + 2, oh)
            end
        end
    end
    -- draw current altitude
    SC(nil)
    CDRF(ox, oy - 4, 26, 8)
    SC(UC)
    local s = SF("%d", altInt)
    CDT(ox + 2, oy - 2, s)
    CDR(ox, oy - 4, 26, 8)
end

function onDraw()
    SC(UC)

    -- draw horizon
    drawHorizon()

    -- draw heading
    drawHeading(-70)

    -- draw air speed
    drawSpeed(-50, -15)

    -- draw altitude
    drawAlt(50, -15)

    -- erase boarder, put in last draw()
    SC(nil)
    DTAF(0, 0, 55, 0, 0, 100)
    DTAF(0, 130, 30, 130, 0, -10)
    DTAF(0, 145, 0, 115, 75, 145)
    DTAF(223, 0, 168, 0, 223, 100)
    DTAF(223, 130, 193, 130, 223, -10)
    DTAF(223, 145, 223, 115, 148, 145)
    DRF(223, 0, 2, 224)
    DRF(0, 145, 224, 224)
end
