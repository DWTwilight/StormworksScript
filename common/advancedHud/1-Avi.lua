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

IN = input.getNumber
IB = input.getBool

S = screen
DL = S.drawLine
DR = S.drawRect
DC = S.drawCircle
DT = S.drawText
DRF = S.drawRectF
DTAF = S.drawTriangleF

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
    S.setColor(c.r, c.g, c.b, c.t)
end

UC = H2RGB(PT("UI Primary Color"))
SCRW = PN("Screen Width")
HSCRW = SCRW / 2
LOF = PN("Look Offset Factor")
LOXF = PN("Look Offset X Factor")
COY = PN("Center Offset Y")
FOV = PN("FOV(rad)")
SPD = HSCRW / TAN(FOV / 2) -- screen px distance

OX, OY = 0, 0
ROLL, PITCH, YAW = 0, 0, 0

function onTick()
    OX, OY = SIN(IN(1) * PI2) * LOF * LOXF + HSCRW + 0.5, -SIN(IN(2) * PI2) * LOF - COY + HSCRW + 0.5
    ROLL, PITCH, YAW = IN(3), IN(4), IN(5)
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

function CDT(x, y, t)
    DT(FL(x + OX), FL(y + OY), t)
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

-- draw pitch line
-- ang: integer
function DPL(ang)
    -- calculate pitchLine y offset
    local oy = -TAN(RAD(ang) - PITCH) * SPD
    -- check if if outof boundray
    if ABS(oy) > 50 then
        return false
    end
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
        return true
    elseif ang > 0 then
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
    return true
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
    for d = 5 - pi % 5, 90, 5 do
        if not DPL(pi + d) then
            break
        end
    end
    -- down
    for d = pi % 5, 90, 5 do
        if not DPL(pi - d) then
            break
        end
    end
end

-- draw heading line
function DHL(headingAng, ox, oy)
    if (headingAng // 1) % 10 == 0 then
        CDL(ox, oy + 7, ox, oy + 11)
        if ABS(ox) > 12 then
            local chs = SF("%d", headingAng // 10)
            CDT(ox - #chs * 2, oy, chs)
        end
    else
        CDL(ox, oy + 9, ox, oy + 11)
    end
end

function drawHeading(oy)
    local headingAng = (DEG(YAW) + 360) % 360
    local h = SF("%.0f", headingAng)
    CDT(FL(#h * -2.5), oy, h)
    CDR(-10, oy - 2, 17, 8)
    -- draw scaleplate
    local headingInterval, headingGap, headingWidth = 5, 10, 35
    -- left
    for i = (headingAng // 1) % headingInterval, 180, headingInterval do
        local x = (-i * headingGap / headingInterval)
        if x < -headingWidth then
            break
        end
        DHL((headingAng - i + 360) % 360, x, oy)
    end
    -- right
    for i = headingInterval - (headingAng // 1) % headingInterval, 180, headingInterval do
        local x = (i * headingGap / headingInterval)
        if x > headingWidth then
            break
        end
        DHL((headingAng + i) % 360, x, oy)
    end
end

function onDraw()
    -- draw crosshair
    SC(UC)

    -- drawHorizon
    drawHorizon()

    -- drawHeading
    drawHeading(-70)

    -- erase boarder, put in last draw()
    S.setColor(0, 0, 0)
    DTAF(0, 0, 55, 0, 0, 100)
    DTAF(0, 130, 30, 130, 0, -10)
    DTAF(0, 145, 0, 115, 75, 145)
    DTAF(223, 0, 168, 0, 223, 100)
    DTAF(223, 130, 193, 130, 223, -10)
    DTAF(223, 145, 223, 115, 148, 145)
    DRF(223, 0, 2, 224)
    DRF(0, 145, 224, 224)
end
