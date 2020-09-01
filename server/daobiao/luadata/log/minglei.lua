-- ./excel/log/minglei.xlsx
return {

    ["enter_fight"] = {
        desc = "进入战斗",
        log_format = {["ave_grade"] = {["id"] = "ave_grade", ["desc"] = "队伍平均等级"}, ["fightid"] = {["id"] = "fightid", ["desc"] = "战斗ID"}, ["monster_grade"] = {["id"] = "monster_grade", ["desc"] = "怪物等级"}, ["npcid"] = {["id"] = "npcid", ["desc"] = "npcid"}, ["player"] = {["id"] = "player", ["desc"] = "参与者"}, ["scene_name"] = {["id"] = "scene_name", ["desc"] = "怪物所在地图"}},
        subtype = "enter_fight",
    },

    ["win_fight"] = {
        desc = "战斗胜利",
        log_format = {["fightid"] = {["id"] = "fightid", ["desc"] = "战斗ID"}, ["npcid"] = {["id"] = "npcid", ["desc"] = "npcid"}, ["player"] = {["id"] = "player", ["desc"] = "参与者"}, ["reward"] = {["id"] = "reward", ["desc"] = "获得奖励"}},
        subtype = "win_fight",
    },

    ["fail_fight"] = {
        desc = "战斗失败",
        log_format = {["fightid"] = {["id"] = "fightid", ["desc"] = "战斗ID"}, ["npcid"] = {["id"] = "npcid", ["desc"] = "npcid"}, ["player"] = {["id"] = "player", ["desc"] = "参与者"}},
        subtype = "fail_fight",
    },

}
