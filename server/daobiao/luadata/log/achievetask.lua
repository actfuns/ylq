-- ./excel/log/achievetask.xlsx
return {

    ["task_open"] = {
        desc = "任务开启",
        log_format = {["degree"] = {["id"] = "degree", ["desc"] = "进度"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["taskid"] = {["id"] = "taskid", ["desc"] = "任务ID"}},
        subtype = "task_open",
    },

    ["task_finish"] = {
        desc = "任务完成",
        log_format = {["degree"] = {["id"] = "degree", ["desc"] = "进度"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["taskid"] = {["id"] = "taskid", ["desc"] = "任务ID"}},
        subtype = "task_finish",
    },

    ["task_reward"] = {
        desc = "任务领奖",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家ID"}, ["taskid"] = {["id"] = "taskid", ["desc"] = "任务ID"}},
        subtype = "task_reward",
    },

}
