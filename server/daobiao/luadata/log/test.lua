-- ./excel/log/test.xlsx
return {

    ["test_test"] = {
        desc = "log测试",
        log_format = {["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "test_test",
    },

    ["gm"] = {
        desc = "gm测试",
        log_format = {["arg"] = {["id"] = "arg", ["desc"] = "参数"}, ["cmd"] = {["id"] = "cmd", ["desc"] = "指令"}, ["name"] = {["id"] = "name", ["desc"] = "gm名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "gmID"}},
        subtype = "gm",
    },

}
