m = math
pi = m.pi
pi2 = 2 * pi
sin = m.sin
cos = m.cos
as = m.asin
ac = m.acos
at = m.atan
IN = input.getNumber
ON = output.setNumber

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

function L2G(v, b)
    local PN = Mv(b, { v[1], v[3], v[2] })
    return PN[1], PN[3], PN[2]
end

function G2L(v, B)
    local PN = Mv(B, { v[1], v[3], v[2] })
    return PN[1], PN[3], PN[2]
end

function inPro(u, v)
    local _ = 0
    for i = 1, 3 do
        _ = _ + u[i] * v[i]
    end
    return _
end

function magnitude(v)
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end

function calculateAngle(v1, v2)
    local function dotProduct(v1, v2)
        return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
    end

    local dot = dotProduct(v1, v2)
    local mag1 = magnitude(v1)
    local mag2 = magnitude(v2)

    local angle = math.acos(dot / (mag1 * mag2))

    return angle
end

function onTick()
    local B = Eular2RotMat({ IN(4), IN(6), IN(5) })
    local b = tM(B)

    local lax, lay, laz = G2L({ IN(10), IN(11), IN(12) }, B)

    local pitch = IN(15) * pi2
    local yaw = -IN(17) * pi2
    local x, y, z = L2G({ 0, 1, 0 }, b)
    local ux, uy, uz = -sin(pitch) * sin(yaw), cos(pitch), -sin(pitch) * cos(yaw)
    local roll = calculateAngle({
        x = x,
        y = y,
        z = z
    }, {
        x = ux,
        y = uy,
        z = uz
    })
    x, y, z = L2G({ 1, 0, 0 }, b)
    if y > 0 then
        roll = -roll
    end

    -- cal distance to ground
    local dtgSensor, dtg = IN(21), 500
    if dtgSensor < 500 then
        x, y, z = L2G({ 0, -dtgSensor, 0 }, b)
        dtg = -y
    end

    -- cal windSpeed
    local windSpeed, windDirection = IN(22), IN(23) * pi2
    local windSpeedX, windSpeedZ =
        windSpeed * cos(windDirection),
        windSpeed * sin(windDirection)

    ON(1, IN(1))
    ON(2, IN(2))
    ON(3, IN(3))
    ON(4, IN(4))
    ON(5, IN(5))
    ON(6, IN(6))
    ON(7, IN(7))
    ON(8, IN(8))
    ON(9, IN(9))
    ON(10, -lax * pi2)
    ON(11, lay * pi2)
    ON(12, -laz * pi2)
    ON(13, IN(13))
    ON(14, IN(14))
    ON(15, pitch)
    ON(16, roll)
    ON(17, yaw)
    ON(18, IN(18))
    ON(19, IN(19))
    ON(20, IN(20))
    ON(21, dtg)
    ON(22, windSpeedX)
    ON(23, windSpeedZ)
    ON(24, IN(24))
    ON(32, IN(25))
end
