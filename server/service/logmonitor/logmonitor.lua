local skynet = require "skynet"
local global = require "global"

function NewLogMonitor(...)
    return CLogMonitor:New(...)
end

CLogMonitor = {}
CLogMonitor.__index = CLogMonitor
inherit(CLogMonitor, logic_base_cls())


function CLogMonitor:New(...)
    local o = super(CLogMonitor).New(self)
    o.m_iLastSize = 0
    o.m_iDelayTime = 60*1000
    o:AnalyseLogFile()
    return o
end

function CLogMonitor:GetDelayTime()
    return self.m_iDelayTime
end

function CLogMonitor:CheckDelayTime(iAmount)
    --每分钟报错频次
    local iFreq = iAmount / (self.m_iDelayTime / 60 / 1000)
    
    local mFreq2Delay = {
        [10] = 5 * 60 * 1000,
        [20] = 10 * 60 * 1000,
    }
    local iDelay = 60 * 1000
    for iCnt, iValue in pairs(mFreq2Delay) do
        if iFreq >= iCnt then
            iDelay = iValue
        end
    end
    self.m_iDelayTime = iDelay
end

function CLogMonitor:AnalyseLogFile()
    if not is_production_env() then
        return
    end

    local mResult = {}
    local lContent = {}
    local fp = assert(io.open(skynet.getenv("logger"), "r"))
    fp:seek("set", self.m_iLastSize)
    local logger = fp:read("*lines")

    while logger do
        if string.find(logger, "%[:%d--%d-_%d--%d--%d-%]") then
            if string.find(logger, "WARNING", 1, true) or string.find(logger, "ERROR", 1, true) then
                self:RecordErrorInfo(mResult, logger)
            end

            if string.find(logger, "lua call", 1, true) or string.find(logger, ".lua", 1, true) then
                if next(lContent) then
                    self:RecordErrorInfo(mResult, table.concat(lContent, "\n"))
                    lContent = {}
                end
                table.insert(lContent, logger)
            end
        else
            table.insert(lContent, logger)
        end
        logger = fp:read("*lines")
    end

    if next(lContent) then
        self:RecordErrorInfo(mResult, table.concat(lContent, "\n"))
    end

    self.m_iLastSize = fp:seek("end")
    fp:close()
    self:SendErrorInfo(mResult)

    local func = function()
        if global.oLogMonitor then
            global.oLogMonitor:AnalyseLogFile()
        end
    end
    local iDelay = self:GetDelayTime()
    self:DelTimeCb("_CheckAnalyseLogFile")
    self:AddTimeCb("_CheckAnalyseLogFile", iDelay, func)
end

function CLogMonitor:RecordErrorInfo(mTable, sErr)
    local sTime = string.sub(sErr, 1, 17)
    sErr = string.sub(sErr, 18, -1)
    if not mTable[sErr] then
        mTable[sErr] = {amount=0, time=sTime}
    end
    mTable[sErr].amount = mTable[sErr].amount + 1
end

function CLogMonitor:SendErrorInfo(mResult)
    if not next(mResult) then
        self:CheckDelayTime(0)
        return
    end

    local iTotal = 0
    local sTitle = "server:" .. MY_SERVER_KEY
    local sContent = ""
    for k, v in pairs(mResult) do
        sContent = sContent .. string.format("amount:%s\n%s%s\n\n", v.amount, v.time, k)
        iTotal = iTotal + v.amount
    end

    self:CheckDelayTime(iTotal)

    local sCmd = string.format([[sh ./shell/sendmail.sh "%s" "%s"]], sTitle, sContent)
    os.execute(sCmd)

--    local fp = io.open("log/debug.log", "w")
--    fp:write(sContent)
--    fp:flush()
--    fp:close()
end

