IN = input.getNumber
ON = output.setNumber

function onTick()
    local guideMethod = IN(1)
    ON(1, guideMethod == -1 and 0 or IN(guideMethod + 2)) -- 2 -> hud... and so on
end
