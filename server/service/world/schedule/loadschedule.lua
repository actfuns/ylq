
REGISTER_LIST =list_key_table({1001,1002,1003,1004,1005,
    1006,1007,1009,
    1011,1012,1013,1014,1015,1016,1017,1018,1019,
    2003,2005},true)

function CreateSchedule(id,mArg)
    local oModule
    if REGISTER_LIST[id] then
       local sPath = string.format("schedule/entity/s%d",id)
        oModule = import(service_path(sPath))
    else
        oModule = import(service_path("schedule.scheduleobj"))
    end
    local oSchedule = oModule.NewSchedule(id)
    oSchedule:Init(mArg)
    return oSchedule
end

function LoadSchedule(id, data,mArg)
    local oSchedule = CreateSchedule(id,mArg)
    oSchedule:Load(data)
    return oSchedule
end