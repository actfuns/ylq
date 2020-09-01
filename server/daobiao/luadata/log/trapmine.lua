-- ./excel/log/trapmine.xlsx
return {

    ["warwin"] = {
        desc = "战斗胜利",
        log_format = {["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["map_id"] = {["id"] = "map_id", ["desc"] = "地图id"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励"}},
        subtype = "warwin",
    },

    ["race_monster"] = {
        desc = "每日稀有怪物统计次数",
        log_format = {["daily_fight"] = {["id"] = "daily_fight", ["desc"] = "全服当天挑战次数"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["map_id"] = {["id"] = "map_id", ["desc"] = "地图id"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["npcid"] = {["id"] = "npcid", ["desc"] = "怪物sid"}, ["personal_fight"] = {["id"] = "personal_fight", ["desc"] = "玩家当天挑战次数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "race_monster",
    },

    ["box_monster"] = {
        desc = "宝箱怪",
        log_format = {["daily_fight"] = {["id"] = "daily_fight", ["desc"] = "全服当天挑战次数"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["map_id"] = {["id"] = "map_id", ["desc"] = "地图id"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["npcid"] = {["id"] = "npcid", ["desc"] = "怪物sid"}, ["personal_fight"] = {["id"] = "personal_fight", ["desc"] = "玩家当天挑战次数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "box_monster",
    },

    ["trigger"] = {
        desc = "触发暗雷",
        log_format = {["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["map_id"] = {["id"] = "map_id", ["desc"] = "地图id"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名字"}, ["npcid"] = {["id"] = "npcid", ["desc"] = "怪物id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}},
        subtype = "trigger",
    },

}
