S2M = map.screenToMap

S = screen
DM = S.drawMap

IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

P = property
PN = P.getNumber

SCR_W, SCR_H = PN("Screen Width"), PN("Screen Height")
MX, MY, ZOOM = 0, 0, 0 -- mapPosX, mapPosY, mapZoom, zoom value

function onTick()
    -- update map pos and zoom
    MX, MY, ZOOM = IN(9), IN(10), IN(11)

    if IB(4) then
        -- on touch
        local mapTargetX, mapTargetY = S2M(MX, MY, ZOOM, SCR_W, SCR_H, IN(7), IN(8))
        -- map touch pulse
        OB(1, true)
        ON(1, mapTargetX)
        ON(2, mapTargetY)
    else
        -- map touch pulse
        OB(1, false)
    end
end

function onDraw()
    -- drawMap
    DM(MX, MY, ZOOM)
end
