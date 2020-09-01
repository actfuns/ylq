local global = require "global"

local mState = {}

function NewState(iState)
    local sPath = string.format("state/s%d",iState)
    local oModule = import(service_path(sPath))
    assert(oModule,string.format("NewState err:%d",iState))
    local oState = oModule.NewState(iState)
    return oState
end

function GetState(iState)
    local oState = mState[iState]
    if not oState then
        oState = NewState(iState)
        mState[iState] = oState
    end
    return oState
end

function LoadState(iState,mData)
    local oState = NewState(iState)
    oState:Load(mData)
    return oState
end