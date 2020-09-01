-- ./excel/log/item.xlsx
return {

    ["role_item_amount"] = {
        desc = "角色道具数量",
        log_format = {["amount"] = {["id"] = "amount", ["desc"] = "变动数量(负数表示减少)"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["now"] = {["id"] = "now", ["desc"] = "现有数量"}, ["old"] = {["id"] = "old", ["desc"] = "原有数量"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["sid"] = {["id"] = "sid", ["desc"] = "物品sid"}, ["traceno"] = {["id"] = "traceno", ["desc"] = "道具流水id"}},
        subtype = "role_item_amount",
    },

}
