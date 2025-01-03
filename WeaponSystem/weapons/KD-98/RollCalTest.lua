m = math
sin = m.sin
cos = m.cos
acos = m.acos
atan = m.atan
abs = m.abs
pi = m.pi

IN = input.getNumber
ON = output.setNumber
OB = output.setBool
PN = property.getNumber

function Eular2RotMat(E)
    local qx, qy, qz = E[1], E[2], E[3]
    return {{cos(qy) * cos(qz), cos(qx) * cos(qy) * sin(qz) + sin(qx) * sin(qy),
             sin(qx) * cos(qy) * sin(qz) - cos(qx) * sin(qy)}, {-sin(qz), cos(qx) * cos(qz), sin(qx) * cos(qz)},
            {sin(qy) * cos(qz), cos(qx) * sin(qy) * sin(qz) - sin(qx) * cos(qy),
             sin(qx) * sin(qy) * sin(qz) + cos(qx) * cos(qy)}}
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

function tM(M) -- Transpose matrix
    local N = {{}, {}, {}}
    for i = 1, 3 do
        for j = 1, 3 do
            N[i][j] = M[j][i]
        end
    end
    return N
end

function EularRotate(v, B)
    local p = Mv(B, {v[1], v[3], v[2]})
    return p[1], p[3], p[2]
end

function callAngleDiff(target, current)
    local function dotProduct(v1, v2)
        return v1[1] * v2[1] + v1[2] * v2[2] + v1[3] * v2[3]
    end
    local function magnitude(v)
        return (v[1] ^ 2 + v[2] ^ 2 + v[3] ^ 2) ^ 0.5
    end
    local dot = dotProduct(target, current)
    local mag1 = magnitude(target)
    local mag2 = magnitude(current)
    if mag1 == 0 or mag2 == 0 then
        return 0
    end
    return acos(dot / (mag1 * mag2))
end

function onTick()
    -- roll sta to keep level
    local b = Eular2RotMat({IN(4), IN(6), IN(5)})
    local tb = tM(b) -- local to global matrix
    -- get forward vector
    local fx, fy, fz = EularRotate({0, 0, 1}, tb)
    -- get baseline vector
    local bx, bz = fz, -fx
    -- get right vector
    local rx, ry, rz = EularRotate({1, 0, 0}, tb)
    local roll = callAngleDiff({bx, 0, bz}, {rx, ry, rz})
    if bx * ry * fz < 0 then
        -- upside down
        roll = -roll
    end
    ON(1, roll)
end
