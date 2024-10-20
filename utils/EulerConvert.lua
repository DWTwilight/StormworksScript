m = math
sin = m.sin
cos = m.cos

function Eular2RotMat(E)
    local qx, qy, qz = E[1], E[2], E[3]
    return { { cos(qy) * cos(qz), cos(qx) * cos(qy) * sin(qz) + sin(qx) * sin(qy),
        sin(qx) * cos(qy) * sin(qz) - cos(qx) * sin(qy) }, { -sin(qz), cos(qx) * cos(qz), sin(qx) * cos(qz) },
        { sin(qy) * cos(qz), cos(qx) * sin(qy) * sin(qz) - sin(qx) * cos(qy),
            sin(qx) * sin(qy) * sin(qz) + cos(qx) * cos(qy) } }
end

function Mv(M, v) -- Multiply matrix and vector
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
    local N = { {}, {}, {} }
    for i = 1, 3 do
        for j = 1, 3 do
            N[i][j] = M[j][i]
        end
    end
    return N
end

function L2G(x, y, z, rx, ry, rz, x0, y0, z0)
    local B = Eular2RotMat({ rx, rz, ry }) -- Basis (Global to Local)
    local b = tM(B)                        -- Basis (Local to Global)
    local PN = Mv(b, { x, z, y })          -- Calculate global coordinate
    local PO = { x0, z0, y0 }
    for i = 1, 3 do
        PN[i] = PN[i] + PO[i]
    end
    return PN[1], PN[3], PN[2]
end

function G2L(v, rx, ry, rz)
    local B = Eular2RotMat({ rx, rz, ry })
    local PN = { v[1], v[3], v[2] }
    PN = Mv(B, PN)
    return PN[1], PN[3], PN[2]
end
