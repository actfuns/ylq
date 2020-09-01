-- ./excel/schedule/schedule.xlsx
return {

    [1001] = {
        banvirtual = 0,
        blockkey = "lilian",
        close = 1,
        desc = [=[[81654d]时刻遵循荆鸣大人的教导，不断鞭策自己不忘每日之修行！
[81654d]◇[159a7f]每天0:00[-]获得[159a7f]60次[-]修行次数；修行次数储存上限为[159a7f]420次[-]。
[81654d]◇点击每日修行后，可选择单人队长或加入队伍进行修行。]=],
        every = 1,
        icon = "pic_meirixiuxing_1001",
        id = 1001,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：25级以上 组队[-]]=],
        limit = 2,
        name = "每日修行",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1005"}, {["num"] = 1, ["sid"] = "1007"}},
        sort = 2,
        tag = {1, 5},
        times = {},
    },

    [1002] = {
        banvirtual = 0,
        blockkey = "endless_pve",
        close = 1,
        desc = [=[[81654d]现世为引，入镜窥心，破幻重生。
[81654d]◇使用[159a7f]【镜花水月】[-]可开启幻境；可单人或组队挑战。
[81654d]◇[159a7f]10分钟内[-]击退波次越多，获得奖励越多。]=],
        every = 1,
        icon = "pic_richang_1002",
        id = 1002,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：41级以上 单人/组队[-]]=],
        limit = 2,
        name = "月见幻境",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1002"}, {["num"] = 1, ["sid"] = "16031"}},
        sort = 5,
        tag = {2, 5},
        times = {},
    },

    [1003] = {
        banvirtual = 0,
        blockkey = "equipfuben",
        close = 1,
        desc = [=[[81654d]人类渴望力量，却又恐惧力量。在这之下，埋藏的是……
[81654d]◇[159a7f]固定时间[-]内，通关星数越多，可获得更好的装备。
[81654d]◇[159a7f]累积[-]一定星数，[159a7f]必定[-]获得紫色装备。]=],
        every = 1,
        icon = "pic_maigu_1003",
        id = 1003,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：30级以上 单人[-]]=],
        limit = 2,
        name = "装备副本",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1012"}, {["num"] = 1, ["sid"] = "11001"}, {["num"] = 1, ["sid"] = "16021"}},
        sort = 10,
        tag = {3, 5},
        times = {},
    },

    [1004] = {
        banvirtual = 0,
        blockkey = "pata",
        close = 1,
        desc = [=[[81654d]这是一场力量和胆量的试炼！
[81654d]◇胜利后可到达下一层；每天可[159a7f]扫荡1次、重置1次[-]，每天00:00重置。
[81654d]◇可[159a7f]邀请好友伙伴[-]一起进行战斗，每日可进行3次。]=],
        every = 1,
        icon = "pic_dilao_1004",
        id = 1004,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：45级以上 单人[-]]=],
        limit = 2,
        name = "地 牢",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1011"}, {["num"] = 1, ["sid"] = "1003"}, {["num"] = 1, ["sid"] = "16021"}, {["num"] = 1, ["sid"] = "11001"}},
        sort = 11,
        tag = {3, 5},
        times = {},
    },

    [2001] = {
        banvirtual = 0,
        blockkey = "question",
        close = 1,
        desc = [=[[81654d]这是学渣的华丽逆袭还是学渣的……坟墓？
[81654d]◇活动时间：每周一、三、五、日[159a7f]12:00-12:20[-]。
[81654d]◇抢答越快，可获得更高的奖励；答题结束后，奖励统一发放至邮箱。]=],
        every = 1,
        icon = "pic_xuezha_2001",
        id = 2001,
        jointips = [=[[81654d]活动时间：周一、三、五、日[-]
[81654d]参与条件：36级以上 单人[-]]=],
        limit = 1,
        name = "学渣的逆袭",
        notopentips = "未在活动时间，每周一、三、五、日12:00-12:20开启学渣逆袭。",
        openday = 0,
        openweek = {1, 3, 5, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1005"}, {["num"] = 1, ["sid"] = "1002"}},
        sort = 18,
        tag = {5},
        times = {{["opentime"] = "12:00", ["endtime"] = "12:20"}},
    },

    [2002] = {
        banvirtual = 0,
        blockkey = "worldboss",
        close = 1,
        desc = [=[[81654d]Boss带着一大波奖励降临的那一刻，我整个世界都亮了。
[81654d]◇每周一、二、四、五[159a7f]20:00-21:00[-]；世界BOSS出现后，玩家可[159a7f]多次挑战[-]。
[81654d]◇攻打BOSS[159a7f]伤害越高[-]，可获得[159a7f]奖励越多[-]。]=],
        every = 1,
        icon = "pic_fengyin_2002",
        id = 2002,
        jointips = [=[[81654d]活动时间：周一、二、四、五[-]
[81654d]参与条件：33级以上 单人[-]]=],
        limit = 1,
        name = "封印之地",
        notopentips = "未在活动时间，每周一、二、四、五20:00-21:00开启封印之地。",
        openday = 0,
        openweek = {1, 2, 4, 5},
        rewardlist = {{["num"] = 1, ["sid"] = "1003"}, {["num"] = 1, ["sid"] = "1011"}, {["num"] = 1, ["sid"] = "14011"}},
        sort = 21,
        tag = {5},
        times = {{["opentime"] = "20:00", ["endtime"] = "21:00"}},
    },

    [2003] = {
        banvirtual = 0,
        blockkey = "arenagame",
        close = 1,
        desc = [=[[81654d]世上没有什么是打一架解决不了的。如果不行，就打两架！
[81654d]◇每周一~周五[159a7f]21:00-22:00[-]开启；[159a7f]每周一00:00[-]，根据段位发放奖励。
[81654d]◇进行战斗，系统自动匹配段位相近的玩家。]=],
        every = 1,
        icon = "pic_jingji_2003",
        id = 2003,
        jointips = [=[[81654d]活动时间：周一~周五[-]
[81654d]参与条件：28级以上 单人[-]]=],
        limit = 1,
        name = "段位比武",
        notopentips = "未在活动时间，每周一~周五21:00-22:00进行段位比武。",
        openday = 0,
        openweek = {1, 2, 3, 4, 5},
        rewardlist = {{["num"] = 1, ["sid"] = "1009"}, {["num"] = 1, ["sid"] = "1003"}},
        sort = 20,
        tag = {5},
        times = {{["opentime"] = "21:00", ["endtime"] = "22:00"}},
    },

    [3001] = {
        banvirtual = 0,
        blockkey = "",
        close = 1,
        desc = [=[[81654d]满满的金子，眼睛快闪瞎了。
[81654d]◇购买两次金币，可获得活跃值
]=],
        every = 1,
        icon = "pic_shangdian_tubiao",
        id = 3001,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：1级以上 单人[-]]=],
        limit = 0,
        name = "购买金币",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1013"}},
        sort = 24,
        tag = {5},
        times = {},
    },

    [3002] = {
        banvirtual = 0,
        blockkey = "draw_card",
        close = 1,
        desc = [=[[81654d]宝贝，宝贝，我的小宝贝。
[81654d]◇招募1次
]=],
        every = 1,
        icon = "pic_zhaomu_tubiao",
        id = 3002,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：2级以上 单人[-]]=],
        limit = 0,
        name = "王者招募",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1013"}},
        sort = 25,
        tag = {5},
        times = {},
    },

    [1005] = {
        banvirtual = 0,
        blockkey = "",
        close = 1,
        desc = [=[[81654d]异空之中，流放之地，生命还在延续……
[81654d]◇转盘中[159a7f]随机抽取[-]御灵，进入战斗，胜利后，可获得大量御灵。
[81654d]◇同时，也可通过[159a7f]锁定套装/部位[-]来控制最终获得的御灵。]=],
        every = 1,
        icon = "pic_yuling_1005",
        id = 1005,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：42级以上 单人[-]]=],
        limit = 2,
        name = "御灵副本",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "16041"}},
        sort = 7,
        tag = {4, 5},
        times = {},
    },

    [3003] = {
        banvirtual = 0,
        blockkey = "pefuben",
        close = 1,
        desc = [=[[81654d]小伙伴们，变身吧！
[81654d]◇培育1次伙伴
]=],
        every = 1,
        icon = "partner",
        id = 3003,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：1级以上，15级以下 单人[-]]=],
        limit = 0,
        name = "培育伙伴",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1013"}},
        sort = 26,
        tag = {5},
        times = {},
    },

    [3004] = {
        banvirtual = 0,
        blockkey = "",
        close = 1,
        desc = [=[[81654d]总是不按套路出牌，真是头痛。
[81654d]◇强化1次符文
]=],
        every = 1,
        icon = "partner",
        id = 3004,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：1级以上，15级以下 单人[-]]=],
        limit = 0,
        name = "强化符文",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1013"}},
        sort = 27,
        tag = {5},
        times = {},
    },

    [3005] = {
        banvirtual = 0,
        blockkey = "",
        close = 1,
        desc = [=[[81654d]小哥哥又补货了，真开心。
[81654d]◇在道具商城购买1次商品。
]=],
        every = 1,
        icon = "pic_shangdian_3005",
        id = 3005,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：9级以上 单人[-]]=],
        limit = 0,
        name = "购买商品",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1013"}},
        sort = 17,
        tag = {5},
        times = {},
    },

    [1006] = {
        banvirtual = 0,
        blockkey = "minglei",
        close = 1,
        desc = [=[[81654d]茶已备好，就等小伙伴来了~喵~请帮小萌请他们来好吗？
[81654d]◇[159a7f]每天整点[-]野外地图会出现茶会贵宾；需要组队进行挑战。
[81654d]◇每天可进行[159a7f]10次挑战[-]，还可额外[159a7f]购买2次[-]。]=],
        every = 1,
        icon = "pic_chahui_1006",
        id = 1006,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：35级以上 组队[-]]=],
        limit = 2,
        name = "喵萌茶会",
        notopentips = "每天整点时，世界各地会出现茶会贵宾，可组队前往挑战~",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "16010"}},
        sort = 9,
        tag = {4, 5},
        times = {},
    },

    [1007] = {
        banvirtual = 0,
        blockkey = "trapmine",
        close = 1,
        desc = [=[[81654d]不要拦着我，我要去探索新世界！
[81654d]◇[159a7f]每天00:00[-]系统提供[159a7f]50探索点[-]，探索点上限为[159a7f]350点[-]。
[81654d]◇野外地图使用1点探索点可发现普通怪；还有概率遇见稀有怪和宝箱怪。]=],
        every = 1,
        icon = "pic_tansuo_1007",
        id = 1007,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：38级以上 单人/组队[-]]=],
        limit = 2,
        name = "探 索",
        notopentips = "据说野外有很多宝藏，到达野外可看到探索按钮哦~",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1002"}, {["num"] = 1, ["sid"] = "14001"}, {["num"] = 1, ["sid"] = "16031"}, {["num"] = 1, ["sid"] = "14021"}},
        sort = 4,
        tag = {2, 5},
        times = {},
    },

    [1009] = {
        banvirtual = 0,
        blockkey = "treasure",
        close = 1,
        desc = [=[[81654d]菠萝菠萝菠萝黑凤梨~宝箱快快出来！
[81654d]◇使用[159a7f]【星象图】[-]即可开始挖宝；每累计[159a7f]5次[-]，奖励内容会进行提高。
[81654d]◇挖宝时，有机率触发一拳胜负和树叶飞舞的奇遇玩法。]=],
        every = 0,
        icon = "pic_jineng_tubiao",
        id = 1009,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：17级以上 单人[-]]=],
        limit = 2,
        name = "星象图",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "11001"}, {["num"] = 1, ["sid"] = "11001"}, {["num"] = 1, ["sid"] = "1017"}, {["num"] = 1, ["sid"] = "1002"}},
        sort = 28,
        tag = {5},
        times = {},
    },

    [3008] = {
        banvirtual = 0,
        blockkey = "",
        close = 1,
        desc = [=[[81654d]快来建设公会吧，我们的公会我们来担当！
[81654d]◇活跃任务
]=],
        every = 1,
        icon = "pic_org_3008",
        id = 3008,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：14级以上 单人[-]]=],
        limit = 0,
        name = "公会建设",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1014"}, {["num"] = 1, ["sid"] = "1015"}},
        sort = 12,
        tag = {5},
        times = {},
    },

    [1011] = {
        banvirtual = 0,
        blockkey = "org_activity",
        close = 1,
        desc = [=[[81654d]通缉那些无恶不作的逃犯~！
[81654d]◇加入公会后，每天可进行[159a7f]2次战斗[-]；每周一公会可[159a7f]免费重置一次[-]。
[81654d]◇每缉拿一个boss，都可以获得丰富的奖励。]=],
        every = 1,
        icon = "pic_org_3008",
        id = 1011,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：14级以上 单人[-]]=],
        limit = 2,
        name = "赏 金",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1014"}},
        sort = 13,
        tag = {5},
        times = {},
    },

    [3009] = {
        banvirtual = 0,
        blockkey = "house",
        close = 1,
        desc = [=[[81654d]女神有点伤心，寻求你的安慰呢！
[81654d]◇去宅邸互动与女神互动
]=],
        every = 1,
        icon = "pic_zhaidi_3009",
        id = 3009,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：20级以上 单人[-]]=],
        limit = 0,
        name = "宅邸互动",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1002"}},
        sort = 15,
        tag = {5},
        times = {},
    },

    [1012] = {
        banvirtual = 0,
        blockkey = "yjfuben",
        close = 1,
        desc = [=[[81654d]打败梦魇！狂爆极品橙武、绿装材料！
[81654d]◇战斗胜利，可获得[159a7f]大量套装材料[-]。
[81654d]◇成功驱散所有梦魇，可获得丰厚的[159a7f]翻牌奖励[-]！]=],
        every = 1,
        icon = "pic_mengyan_1012",
        id = 1012,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：50级以上 单人/组队[-]]=],
        limit = 2,
        name = "梦魇狩猎",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "11004"}, {["num"] = 1, ["sid"] = "16024"}, {["num"] = 1, ["sid"] = "16023"}, {["num"] = 1, ["sid"] = "11016"}},
        sort = 12,
        tag = {3, 5},
        times = {},
    },

    [1013] = {
        banvirtual = 0,
        blockkey = "fieldboss",
        close = 1,
        desc = [=[[81654d]桀桀~前线来电。专干大事儿的人形怪物已经从炼狱归来。
[81654d]◇人形怪物会在[159a7f]一定时间[-]内刷出；挑战成功后可获得丰厚的[159a7f]珍惜材料[-]。
[81654d]◇战场中险恶万分，建议大家[159a7f]邀请公会成员[-]一起前往。]=],
        every = 0,
        icon = "btn_renxingtaofa2017",
        id = 1013,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：42级以上 单人/组队[-]]=],
        limit = 2,
        name = "人形讨伐",
        notopentips = "BOSS未刷新，请稍作休息~",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "11004"}, {["num"] = 1, ["sid"] = "16024"}, {["num"] = 1, ["sid"] = "16023"}, {["num"] = 1, ["sid"] = "16021"}},
        sort = 29,
        tag = {5},
        times = {},
    },

    [1014] = {
        banvirtual = 0,
        blockkey = "travel",
        close = 1,
        desc = [=[[81654d]乘风破浪，游历世界的每一个角落！
[81654d]◇可[159a7f]派遣4个伙伴[-]进行游历以及派遣1个伙伴加入他人的队伍。
[81654d]◇游历开始后每隔[159a7f]15分钟[-]会获得一次奖励，还有机会遇到奇遇商人。]=],
        every = 1,
        icon = "pic_youli",
        id = 1014,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：28级以上 单人[-]]=],
        limit = 2,
        name = "游历",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1002"}, {["num"] = 1, ["sid"] = "16022"}, {["num"] = 1, ["sid"] = "1007"}},
        sort = 30,
        tag = {5},
        times = {},
    },

    [1015] = {
        banvirtual = 0,
        blockkey = "EqualArena",
        close = 1,
        desc = [=[[81654d]这是一场关于荣誉的势均力敌的谋略较量。
[81654d]◇每周六、日[159a7f]16:00[-]，对战双方将使用系统提供的随机伙伴和御灵进行战斗。
[81654d]◇伙伴全部为满级、觉醒和满技能；比赛可获得荣誉，用于兑换奖励。]=],
        every = 1,
        icon = "pic_jingji_2003",
        id = 1015,
        jointips = [=[[81654d]活动时间：周六、周日[-]
[81654d]参与条件：53级以上 单人[-]]=],
        limit = 1,
        name = "公平比武",
        notopentips = "未在活动时间，每周六、日16:00-18:20开启公平比武。",
        openday = 0,
        openweek = {6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1009"}},
        sort = 19,
        tag = {5},
        times = {{["opentime"] = "16:00", ["endtime"] = "18:00"}},
    },

    [2004] = {
        banvirtual = 0,
        blockkey = "terrawars",
        close = 1,
        desc = [=[[81654d]战争的钟声悄悄响起，谁将是最后的赢家！
[81654d]◇[159a7f]开服第三天[-]开启据点攻防战，共开启[159a7f]三天[-]。
[81654d]◇开启后，可争夺帝都中出现的据点，胜利后可获得荣誉和奖励！]=],
        every = 0,
        icon = "pic_judianzhan",
        id = 2004,
        jointips = [=[[81654d]活动时间：开服第2天[-]
[81654d]参与条件：14级以上 单人[-]]=],
        limit = 1,
        name = "据点攻防战",
        notopentips = "开服第二天00:00开启据点攻防战。",
        openday = 0,
        openweek = {1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1014"}, {["num"] = 1, ["sid"] = "1015"}},
        sort = 31,
        tag = {5},
        times = {{["opentime"] = "00:00", ["endtime"] = "24:00"}},
    },

    [1016] = {
        banvirtual = 0,
        blockkey = "chapterfb",
        close = 1,
        desc = [=[[81654d]绝不服输，想要成为真正的冒险家还有很长的路要走！
[81654d]◇消耗[159a7f]体力[-]可[159a7f]挑战[-]、[159a7f]扫荡[-]关卡，通关后可获得[159a7f]经验[-]、[159a7f]金币[-]和[159a7f]伙伴相关[-]奖励。
[81654d]◇累计[159a7f]星级数量[-]还可开启[159a7f]章节宝箱[-]！]=],
        every = 1,
        icon = "pic_zhanyi_1016",
        id = 1016,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：2级以上 单人[-]]=],
        limit = 2,
        name = "战役",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "14021"}, {["num"] = 1, ["sid"] = "16032"}, {["num"] = 1, ["sid"] = "16010"}},
        sort = 6,
        tag = {4, 5},
        times = {},
    },

    [1017] = {
        banvirtual = 0,
        blockkey = "shimen",
        close = 1,
        desc = [=[[81654d]不付出劳动力怎么可能赚到钱？身无分文赚钱的最快方式！
[81654d]◇[159a7f]每日0点[-]可以领取[159a7f]20次[-]巡查任务，完成后可获得[159a7f]大量经验[-]
[81654d]◇未完成任务次日可继续进行，每[159a7f]完成10环[-]可获得丰厚[159a7f]道具奖励[-]。]=],
        every = 1,
        icon = "pic_jiaoxue_1017",
        id = 1017,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：15级以上 单人[-]]=],
        limit = 2,
        name = "杂务巡查",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1005"}, {["num"] = 1, ["sid"] = "1007"}, {["num"] = 1, ["sid"] = "10024"}},
        sort = 1,
        tag = {1, 5},
        times = {},
    },

    [1018] = {
        banvirtual = 0,
        blockkey = "convoy",
        close = 1,
        desc = [=[[81654d]枪林弹雨、高山深海；帝都宅急便，使命必达。
[81654d]◇[159a7f]每天0:00[-]获得[159a7f]3次[-]护送次数，护送完成后可以获得[159a7f]大量[-]的[159a7f]金币[-]和[159a7f]经验[-]。
[81654d]◇护送的人物[159a7f]档次越高[-]，获得的[159a7f]奖励也会越好[-]。
]=],
        every = 1,
        icon = "pic_husong_1018",
        id = 1018,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：43级以上 单人[-]]=],
        limit = 2,
        name = "帝都宅急便",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1002"}, {["num"] = 1, ["sid"] = "1005"}},
        sort = 3,
        tag = {2, 5},
        times = {},
    },

    [1021] = {
        banvirtual = 0,
        blockkey = "teampvp",
        close = 1,
        desc = [=[[81654d]若有同伴做后盾，我们就有了变强的理由和弑神的力量。
[81654d]◇每周六、周日[159a7f]21:00-22:00[-]，活动结束后根据[159a7f]排名[-]可获得奖励
[81654d]◇每场战斗双方[159a7f]各有2名[-]玩家合作战斗，默契的合作会让战斗更加轻松
]=],
        every = 1,
        icon = "pic_jingji_2003",
        id = 1021,
        jointips = [=[[81654d]活动时间：周六、周日[-]
[81654d]参与条件：28级以上 单人/组队[-]]=],
        limit = 1,
        name = "协同比武",
        notopentips = "未在活动时间，每周六、日21:00-22:00开启协同比武。",
        openday = 0,
        openweek = {6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1009"}, {["num"] = 1, ["sid"] = "1003"}},
        sort = 20,
        tag = {5},
        times = {{["opentime"] = "21:00", ["endtime"] = "22:00"}},
    },

    [1020] = {
        banvirtual = 0,
        blockkey = "msattack",
        close = 1,
        desc = [=[[81654d]突然出现的怪物们正蓄势待发，准备向帝都发起猛烈攻势……
[81654d]◇每周三、六[159a7f]20:00-21:00[-]将开启怪物攻城。
[81654d]◇阻止怪物攻击帝都，阻止越多可获得更多的奖励。
[81654d]◇活动结束后，根据防御值结算奖励发放给参与玩家。]=],
        every = 1,
        icon = "pic_gwgongcheng_1020",
        id = 1020,
        jointips = [=[[81654d]活动时间：周三、周六[-]
[81654d]参与条件：33级以上 单人/组队[-]]=],
        limit = 1,
        name = "怪物攻城",
        notopentips = "未在活动时间，每周三、六20:00-21:20开启怪物攻城。",
        openday = 0,
        openweek = {3, 6},
        rewardlist = {{["num"] = 1, ["sid"] = "1003"}, {["num"] = 1, ["sid"] = "1011"}, {["num"] = 1, ["sid"] = "14011"}},
        sort = 21,
        tag = {5},
        times = {{["opentime"] = "20:00", ["endtime"] = "21:00"}},
    },

    [1019] = {
        banvirtual = 0,
        blockkey = "question2",
        close = 1,
        desc = [=[[81654d]秘诀：能跑能跳、腰好腿好、情商爆表、会抱团跟着学霸跑~
[81654d]◇每周二、四、六[159a7f]12:00-12:20[-]，我们都要抱团跟着学霸走！
[81654d]◇活动结束后，奖励统一发放至邮箱。

]=],
        every = 1,
        icon = "pic_xueba_1019",
        id = 1019,
        jointips = [=[[81654d]活动时间：周二、四、六[-]
[81654d]参与条件：36级以上 单人[-]]=],
        limit = 1,
        name = "学霸去哪儿",
        notopentips = "未在活动时间，每周二、四、六12:00-12:20开启学霸去哪儿。",
        openday = 0,
        openweek = {2, 4, 6},
        rewardlist = {{["num"] = 1, ["sid"] = "1005"}, {["num"] = 1, ["sid"] = "1002"}},
        sort = 18,
        tag = {5},
        times = {{["opentime"] = "12:00", ["endtime"] = "12:20"}},
    },

    [2005] = {
        banvirtual = 0,
        blockkey = "orgwar",
        close = 1,
        desc = [=[[81654d]活到最后，才是最强的公会！
[81654d]◇每周日[159a7f]19:45-21:00[-]；玩家加入公会后即可进入战场，让我们一起为公会荣誉而战！
[81654d]◇摧毁敌方公会的[159a7f]水晶[-]，或者击败敌方公会的[159a7f]所有防御人员[-]。]=],
        every = 1,
        icon = "pic_org_3008",
        id = 2005,
        jointips = [=[[81654d]活动时间：每周日19:45-20:00进场[-]
[81654d]         每周日20:00-21:00开战[-]
[81654d]参与条件：20级以上 加入公会玩家[-]]=],
        limit = 1,
        name = "公会战",
        notopentips = "未在活动时间。每周日19：:4-20:00进场，20:00-21:00开战。",
        openday = 0,
        openweek = {7},
        rewardlist = {{["num"] = 1, ["sid"] = "1014"}, {["num"] = 1, ["sid"] = "1015"}},
        sort = 22,
        tag = {5},
        times = {{["opentime"] = "19:45", ["endtime"] = "21:00"}},
    },

    [1022] = {
        banvirtual = 0,
        blockkey = "hunt",
        close = 1,
        desc = [=[[81654d]冒险的道路上你将遇到哪些大神呢？
[81654d]◇点击即可有强者帮你猎灵，遇到大神还可获得稀有御灵。
[81654d]◇还等什么，快来寻求大神的帮助吧。]=],
        every = 1,
        icon = "pic_lieling_1022",
        id = 1022,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：40级以上玩家[-]]=],
        limit = 2,
        name = "猎灵",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "16041"}},
        sort = 8,
        tag = {4, 5},
        times = {},
    },

    [1023] = {
        banvirtual = 0,
        blockkey = "OrgWish",
        close = 1,
        desc = [=[[81654d]公会小哥哥、小姐姐们，请满足我的愿望吧。
[81654d]◇公会成员期间可互相许愿伙伴碎片和装备材料。
]=],
        every = 1,
        icon = "guild",
        id = 1023,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：14级以上 加入公会玩家[-]]=],
        limit = 2,
        name = "公会许愿",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1014"}},
        sort = 14,
        tag = {5},
        times = {},
    },

    [1024] = {
        banvirtual = 0,
        blockkey = "clubarena",
        close = 1,
        desc = [=[[81654d]成功不是终点，失败也不是终结，只有勇气才是永恒。
[81654d]◇每天可挑战武馆守护者，同馆挑战5次还可挑战馆主。
[81654d]◇每次挑战可获得荣誉，结算时还可根据武馆获得丰厚的奖励噢！]=],
        every = 1,
        icon = "pic_jingji_2003",
        id = 1024,
        jointips = [=[[81654d]活动时间：全天[-]
[81654d]参与条件：28级以上玩家[-]]=],
        limit = 2,
        name = "武馆挑战",
        notopentips = "",
        openday = 0,
        openweek = {0, 1, 2, 3, 4, 5, 6, 7},
        rewardlist = {{["num"] = 1, ["sid"] = "1009"}, {["num"] = 1, ["sid"] = "1003"}},
        sort = 16,
        tag = {5},
        times = {},
    },

}
