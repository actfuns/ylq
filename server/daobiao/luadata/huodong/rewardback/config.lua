-- ./excel/huodong/rewardback/config.xlsx
return {

    [2001] = {
        after_reward = {{["num"] = 5000, ["sid"] = "1005"}, {["num"] = 10000, ["sid"] = "1002"}},
        before_reward = {{["num"] = 10000, ["sid"] = "1005"}, {["num"] = 20000, ["sid"] = "1002"}},
        cost = 30,
        desc = "学渣的逆袭",
        free_reward = {1001, 1002},
        gold_reward = {1001, 1002},
        key = 2001,
        limit = 1,
        name = "question",
        open_limit = 0,
    },

    [2002] = {
        after_reward = {{["num"] = 5000, ["sid"] = "1005"}, {["num"] = 10000, ["sid"] = "1002"}},
        before_reward = {{["num"] = 10000, ["sid"] = "1005"}, {["num"] = 20000, ["sid"] = "1002"}},
        cost = 30,
        desc = "学霸去哪儿",
        free_reward = {1001, 1002},
        gold_reward = {1001, 1002},
        key = 2002,
        limit = 1,
        name = "question2",
        open_limit = 0,
    },

    [2003] = {
        after_reward = {{["num"] = 10000, ["sid"] = "1002"}, {["num"] = 100, ["sid"] = "1011"}},
        before_reward = {{["num"] = 20000, ["sid"] = "1002"}, {["num"] = 200, ["sid"] = "1011"}},
        cost = 20,
        desc = "封印之地",
        free_reward = {1001, 1003},
        gold_reward = {1001, 1003},
        key = 2003,
        limit = 1,
        name = "worldboss",
        open_limit = 0,
    },

    [2004] = {
        after_reward = {{["num"] = 10000, ["sid"] = "1002"}, {["num"] = 100, ["sid"] = "1011"}},
        before_reward = {{["num"] = 20000, ["sid"] = "1002"}, {["num"] = 200, ["sid"] = "1011"}},
        cost = 20,
        desc = "怪物攻城",
        free_reward = {1001, 1003},
        gold_reward = {1001, 1003},
        key = 2004,
        limit = 1,
        name = "msattack",
        open_limit = 0,
    },

    [2005] = {
        after_reward = {{["num"] = 2500, ["sid"] = "1005"}, {["num"] = 12000, ["sid"] = "1002"}},
        before_reward = {{["num"] = 5000, ["sid"] = "1005"}, {["num"] = 24000, ["sid"] = "1002"}},
        cost = 20,
        desc = "帝都宅急便",
        free_reward = {2003, 4001},
        gold_reward = {2003, 4001},
        key = 2005,
        limit = 3,
        name = "convoy",
        open_limit = 1,
    },

    [2006] = {
        after_reward = {{["num"] = 7500, ["sid"] = "1005"}, {["num"] = 1, ["sid"] = "10024"}},
        before_reward = {{["num"] = 15000, ["sid"] = "1005"}, {["num"] = 2, ["sid"] = "10024"}},
        cost = 50,
        desc = "杂务巡查",
        free_reward = {4002, 5002},
        gold_reward = {4002, 5002},
        key = 2006,
        limit = 2,
        name = "shimen",
        open_limit = 1,
    },

}
