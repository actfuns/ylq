-- ./excel/log/task.xlsx
return {

    ["add_task"] = {
        desc = "添加任务",
        log_format = {["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["taskid"] = {["id"] = "taskid", ["desc"] = "任务id"}, ["tasktype"] = {["id"] = "tasktype", ["desc"] = "任务类型"}},
        subtype = "add_task",
    },

    ["receive_task"] = {
        desc = "领取任务",
        log_format = {["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["taskid"] = {["id"] = "taskid", ["desc"] = "任务id"}, ["tasktype"] = {["id"] = "tasktype", ["desc"] = "任务类型"}},
        subtype = "receive_task",
    },

    ["remove_task"] = {
        desc = "删任务",
        log_format = {["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["status"] = {["id"] = "status", ["desc"] = "当前状态"}, ["taskid"] = {["id"] = "taskid", ["desc"] = "任务id"}, ["tasktype"] = {["id"] = "tasktype", ["desc"] = "任务类型"}},
        subtype = "remove_task",
    },

    ["statuschange_task"] = {
        desc = "任务状态改变",
        log_format = {["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["new_status"] = {["id"] = "new_status", ["desc"] = "新状态"}, ["old_status"] = {["id"] = "old_status", ["desc"] = "旧状态"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["taskid"] = {["id"] = "taskid", ["desc"] = "任务id"}, ["tasktype"] = {["id"] = "tasktype", ["desc"] = "任务类型"}},
        subtype = "statuschange_task",
    },

    ["reward"] = {
        desc = "任务领奖",
        log_format = {["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["owner"] = {["id"] = "owner", ["desc"] = "任务属主"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励"}, ["taskid"] = {["id"] = "taskid", ["desc"] = "任务id"}, ["tasktype"] = {["id"] = "tasktype", ["desc"] = "任务类型"}},
        subtype = "reward",
    },

}
