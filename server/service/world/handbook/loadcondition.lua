local global = require "global"

local condition = import(service_path("handbook.conditionobj"))

function CreateCondition(id)
    return condition.NewCondition(id)
end

function LoadCondition(id,data)
    local oCondition = CreateCondition(id)
    oCondition:Load(data)
    return oCondition
end