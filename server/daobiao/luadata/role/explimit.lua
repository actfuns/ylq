-- ./excel/role/servergrade.xlsx
return {

    [1] = {
        exp_percent = 1.2,
        grade = {["max"] = -6, ["min"] = -99999999},
        help_desc = "[00ff00]额外获得主角经验：20%",
        id = 1,
        war_desc = "[00ff00]额外获得主角经验：20%",
    },

    [2] = {
        exp_percent = 1.0,
        grade = {["max"] = -1, ["min"] = -5},
        help_desc = "[00ff00]获得主角经验：100%",
        id = 2,
        war_desc = "",
    },

    [3] = {
        exp_percent = 0.2,
        grade = {["max"] = 4, ["min"] = 0},
        help_desc = "[ff0000]超出服务器等级，经验降低为20%",
        id = 3,
        war_desc = "[ff0000]超出服务器等级，经验降低为20%",
    },

    [4] = {
        exp_percent = 0.0,
        grade = {["max"] = 99999999, ["min"] = 5},
        help_desc = "[ff0000]超出服务器等级5级不再获得经验",
        id = 4,
        war_desc = "[ff0000]超出服务器等级5级不再获得经验",
    },

}
