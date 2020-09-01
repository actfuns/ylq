local global = require "global"

CWarRecord = {}
CWarRecord.__index = CWarRecord
inherit(CWarRecord,logic_base_cls())

function CWarRecord:New(iWarId)
    local o = super(CWarRecord).New(self,iWarId)
    o.m_iWarId = iWarId
    o.m_mAttack = {}
    o.m_mAttacked = {}
    o.m_mReceiveDamage = {}
    o.m_mAttackDamage = {}
    --战斗录像相关记录信息
    o.m_mBoutCmd = {}
    o.m_mClientPacket = {}
    o.m_mBoutTime = {}
    return o
end

function CWarRecord:GetWarId()
    return self.m_iWarId
end

function CWarRecord:GetWar()
    local oWarMgr = global.oWarMgr
    return oWarMgr:GetWar(self:GetWarId())
end

function CWarRecord:AddAttack(oAttack,oVictim,iDamage)
    if  oAttack:IsPlayer() then
        local iPid = oAttack:GetData("pid",0)
        local iAttackCnt = self.m_mAttack[iPid] or 0
        self.m_mAttack[iPid] = iAttackCnt + 1
    end
    if oVictim:IsPlayer() then
        local iPid = oVictim:GetData("pid",0)
        local iAttacked = self.m_mAttacked[iPid] or 0
        self.m_mAttacked[iPid] = iAttacked + 1
    end
    local oWar = oAttack:GetWar()
    local iBout = oWar.m_iBout
    local iAttack = oAttack:GetWid()
    if not self.m_mAttackDamage[iAttack] then
        self.m_mAttackDamage[iAttack] = {}
    end
    local mDamage = self.m_mAttackDamage[iAttack]
    local i = mDamage[iBout] or 0
    i = i + iDamage
    mDamage[iBout] = i
    self.m_mAttackDamage[iAttack] = mDamage
end

function CWarRecord:GetAttackDamage(oAttack,iStartBout)
    local iAttack = oAttack:GetWid()
    local mDamage = self.m_mAttackDamage[iAttack]
    local iRet = 0
    for iBout,iDamage in pairs(mDamage) do
        if iBout >= iStartBout then
            iRet = iRet + iDamage
        end
    end
    return iRet
end

function CWarRecord:AddReceiveDamage(oVictim,oAttack,iDamage)
    local oWar = oVictim:GetWar()
    local iBout = oWar.m_iBout
    local iVictim = oVictim:GetWid()
    local iAttack = oAttack:GetWid()
    if not self.m_mReceiveDamage[iVictim] then
        self.m_mReceiveDamage[iVictim] = {}
    end
    local mDamage = self.m_mReceiveDamage[iVictim]
    if not mDamage[iBout] then
        mDamage[iBout] = {}
    end
    if not mDamage[iBout][iAttack] then
        mDamage[iBout][iAttack] = 0
    end
    mDamage[iBout][iAttack] = mDamage[iBout][iAttack] + iDamage
    self.m_mReceiveDamage[iVictim] = mDamage
end

function CWarRecord:IsAttacked(oVictim,oAttack)
    local oWar = oVictim:GetWar()
    if not oWar then
        return false
    end
    local iBout = oWar.m_iBout
    local iVictimWid = oVictim:GetWid()
    local iAttackWid = oAttack:GetWid()
    local mDamage = self.m_mReceiveDamage[iVictimWid] or {}
    mDamage  = mDamage[iBout] or {}
    if not mDamage[iAttackWid] then
        return false
    end
    if mDamage[iAttackWid] <= 0 then
        return false
    end
    return true
end

function CWarRecord:GetReceiveDamage(oVictim,iStartBout)
    local iVictim = oVictim:GetWid()
    local mDamage = self.m_mReceiveDamage[iVictim] or {}
    local iDamage = 0
    iStartBout = iStartBout or 0
    for iBout,mReceiveDamage in pairs(mDamage) do
        if iBout >= iStartBout then
            for iAttack,iReceiveDamage in pairs(mReceiveDamage) do
                iDamage = iDamage + iReceiveDamage
            end
        end
    end
    return iDamage
end

function CWarRecord:PackRecordInfo(pid)
    return {
        attack_cnt = self.m_mAttack[pid] or 0,
        attacked_cnt = self.m_mAttacked[pid] or 0,
    }
end

function CWarRecord:AddBoutCmd(sMessage,mData)
    local oWar = self:GetWar()
    local iBout = oWar.m_iBout
    iBout = tostring(iBout)
    if not self.m_mBoutCmd[iBout] then
        self.m_mBoutCmd[iBout] = {}
    end
    table.insert(self.m_mBoutCmd[iBout],{sMessage,mData})
end

--记录发给客户端协议
function CWarRecord:AddClientPacket(sMessage,mData)
    local oWar = self:GetWar()
    local iBout = oWar.m_iBout
    iBout = tostring(iBout)
    if not self.m_mClientPacket[iBout] then
        self.m_mClientPacket[iBout] = {}
    end
    table.insert(self.m_mClientPacket[iBout],{sMessage,mData})
end

--下回合开始时间
function CWarRecord:AddBoutTime(iBout,iTime)
    iBout = tostring(iBout)
    self.m_mBoutTime[iBout] = iTime
end

function CWarRecord:PackFilmData()
    local oWar = self:GetWar()
    if oWar:IsWarRecord() then  
        return {
            bout_cmd = self.m_mBoutCmd,
            client_packet = self.m_mClientPacket,
            bout_time = self.m_mBoutTime,
            bout_end = oWar.m_iBout,
            war_id = self.m_iWarId,
        }
    else
        return {}
    end
end

function NewRecord(iWarId)
    local o = CWarRecord:New(iWarId)
    return o
end