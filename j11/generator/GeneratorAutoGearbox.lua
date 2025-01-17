-- for testing only
-- require("StormworksScript.j11.generator.test_data")

M = math
MAX = M.max

IN = input.getNumber
IB = input.getBool
OB = output.setBool

PN = property.getNumber

T = table
TI = T.insert
IPR = ipairs

GEN_RPS_MIN = PN("Generator Min RPS")
GB_COUNT = PN("Gearbox Count")

GB_DATA = {}
GBS = {} -- gearboxSwitches, for temp calculation
FRM = {} -- final ratio mapping, for distinct
RATIO_DATA = {}

-- get gearbox ratio data
for i = 1, GB_COUNT do
    TI(GB_DATA, {
        offRatio = PN(string.format("GBR_%d_OFF", i)),
        onRatio = PN(string.format("GBR_%d_ON", i))
    })
    TI(GBS, false)
end

-- calculate possible ratio combination
function calRatio(curIndex)
    local function calFinalRatio()
        local finalRatio = 1
        for i, gearbox in IPR(GB_DATA) do
            if GBS[i] then
                -- on
                finalRatio = finalRatio * gearbox.onRatio
            else
                -- off
                finalRatio = finalRatio * gearbox.offRatio
            end
        end

        if FRM[finalRatio] == nil then
            FRM[finalRatio] = true
            TI(RATIO_DATA, {
                ratio = finalRatio,
                switches = T.move(GBS, 1, GB_COUNT, 1, {})
            })
        end
    end

    if curIndex == GB_COUNT then
        calFinalRatio()
        GBS[curIndex] = true
        calFinalRatio()
        GBS[curIndex] = false
    else
        calRatio(curIndex + 1)
        GBS[curIndex] = true
        calRatio(curIndex + 1)
        GBS[curIndex] = false
    end
end

calRatio(1)

-- sort ratio data (in acending order of finalRatio)
function compByRatio(ratioDataA, ratioDataB)
    return ratioDataA.ratio < ratioDataB.ratio
end

T.sort(RATIO_DATA, compByRatio)

function findGear(targetRatio)
    for _, ratioData in IPR(RATIO_DATA) do
        if ratioData.ratio >= targetRatio then
            return ratioData
        end
    end
    -- return the largest ratio
    return RATIO_DATA[#RATIO_DATA]
end

function processGenerator(index)
    if IB(index) then
        -- engine L
        local targetRatio = GEN_RPS_MIN / MAX(0.1, IN(index))
        local ratioData = findGear(targetRatio)
        -- set gear outputs
        for i, switch in IPR(ratioData.switches) do
            OB((index - 1) * GB_COUNT + i, switch)
        end
    end
end

function onTick()
    -- engine L generator
    processGenerator(1)
    -- engine R generator
    processGenerator(2)
end

-- for test only
-- onTick()
