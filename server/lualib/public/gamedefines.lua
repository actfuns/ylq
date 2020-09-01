
--import module

local geometry = require "base.geometry"

SCENE_GRID_DIS_X = 10
SCENE_GRID_DIS_Y = 5
SCENE_PLAYER_SEE_LIMIT = 40

SERVER_GRADE_LIMIT = 300

TEAM_MAX_SIZE = 4

RENAME_COST = 580       --改名消耗

ENDLESS_PVE_END_TIME = 5*60 --无尽pve时长
ENDLESS_PVE_MAX_RING = 15   --无尽pve最大波数

PARTNER_MAX_AMOUNT = 3000   --伙伴数量上限
MAX_BREED_VAL = 1500 --七日孵化值上限
SHIMEN_MAXRING = 10

GUIDE_VERSION = 2

ERRCODE = {
    ok = 0,
    common = 1,
--login
    in_login = 1001,
    in_logout = 1002,
    not_exist_player = 1003,
    name_exist = 1004,
    in_maintain = 1005,
    reenter = 1006,
    error_id = 1007,
    role_max_limit = 1008,
    error_account_env = 1009,
    script_error = 1010,
    invalid_token = 1011,
    invalid_role_token = 1012,
    login_player_limit = 1013,
    client_version_error = 1014,
    invalid_platform = 1015,
    invalid_channel = 1016,
}

GAME_CHANNEL = {
    develop = "pc",        -- 开发版本
}

PUBLISHER = {
    none = 0,    -- 无（全）发行
    kp = 1,    -- 靠谱
    sm = 2,     -- 手盟
}

PLATFORM = {
    android = 1,
    rootios = 2,
    ios = 3,
    pc = 4,
}

PLATFORM_DESC = {
    [1] = "ANDROID", -- 安卓
    [2] = "ROOTIOS", -- 越狱ios
    [3] = "IOS", -- ios
    [4] = "PC", -- windows
}

function GetPlatformName(iPlatform)
    return PLATFORM_DESC[iPlatform] or ""
end

function GetPlatformNo(sName)
    return PLATFORM[sName] or 0
end

LOGIN_CONNECTION_STATUS = {
    no_account = 1,
    in_login_account = 2,
    login_account = 3,
    in_login_role = 4,
    login_role = 5,
    in_create_role = 6,
}

SCENE_ENTITY_TYPE = {
    ENTITY_TYPE = 0,
    PLAYER_TYPE = 1,
    NPC_TYPE = 2,
    TEAM_TYPE = 3,
}

WAR_WARRIOR_TYPE = {
    WARRIOR_TYPE = 0,
    PLAYER_TYPE = 1,
    NPC_TYPE = 2,
    SUMMON_TYPE = 3,
    PARTNER_TYPE = 4,
    ROM_PLAYER_TYPE = 5,
    ROM_PARTNER_TYPE = 6,
}

WAR_STATUS = {
    NULL = 0,
    CONFIG = 1,
    START = 2,
    STOP = 3,
}

WAR_WARRIOR_STATUS = {
    NULL = 0,
    ALIVE = 1,
    DEAD = 2,
}

WAR_BOUT_STATUS = {
    NULL = 0,
    OPERATE = 1,
    ANIMATION = 2,
}

WAR_ACTION_STATUS = {
    NULL = 0,
    OPERATE = 1,
    ANIMATION = 2,
}


WAR_RECV_DAMAGE_FLAG = {
    NULL = 0,
    MISS = 1,
    DEFENSE = 2,
    CRIT = 3,
}

WAR_PERFORM_TYPE = {
    PHY = 1,
    MAGIC = 2,
}

WAR_ACTION_TYPE = {
    ATTACK = 1,
    SEAL = 2,
    FUZHU = 3,
    CURE = 4,
}

WAR_BUFF_CLASS = {
    NORMAL = 1,
    CONTROL = 2,
    GAIN = 3,
    DEBUFF = 4,
    SP_GAIN = 5,
    SP_DEBUFF = 6,
}

WAR_BUFF_TYPE = {
    ABNORMAL = 1,
    AUXILIARG = 2,
    TEMPORARY = 3,
    SPECIAL = 4,
}


SCHEDULE_TYPE = {
    GAME_CLOSE = 0,
    GAME_START = 1,
    GAME_OVER = 2,
}

TASK_TYPE = {
    TASK_FIND_NPC    = 1,
    TASK_FIND_ITEM   = 2,
    TASK_FIND_PLACE = 3,
    TASK_NPC_FIGHT  = 4,
    TASK_CHANGESHAPE  = 5,
    TASK_PICK   = 6,
    TASK_USE_ITEM = 7,
    TASK_ACHIEVE = 8,
    TASK_TRACE = 9,
    TASK_ESCORT = 10,
    TASK_TEACH = 11,
    TASK_LEGENDPARTNER = 12,
    TASK_SLIP = 13,
    TASK_PATROL = 14,
    TASK_SOCIAL = 15,
}

ACHIEVE_TASK_TYPE = {
    TASK_UPGRADE = 1,
    TASK_ADDFRIEND = 2,
    TASK_ADDPARTNER = 3,
    TASK_ADDPOWER = 4,
    TASK_CHOUKA = 5,
}

TASK_STATUS = {
    TASK_HASACCEPT = 1,
    TASK_CANACCEPT = 2,
    TASK_FAILED = 3,
    TASK_CANCOMMIT = 4,
    TASK_HASCOMMIT = 5,
}

TEAM_MEMBER_STATUS = {
    MEMBER = 1,
    SHORTLEAVE = 2,
    OFFLINE = 3,
}

TEAM_CREATE_TYPE = {
    NORMAL = 1,
    LILIAN = 2,
}

CHANNEL_TYPE = {
    BASE_TYPE = 0,
    WORLD_TYPE = 1,
    TEAM_TYPE = 2,
    ORG_TYPE = 3,
    CURRENT_TYPE = 4,
    SYS_TYPE = 5,
    MSG_TYPE = 6,
    FRIEND_TYPE = 7,
    TEAMPVP_TYPE = 8,
}

INTERFACE_TYPE = {
    BASE_TYPE = 0,
    BARRAGE_TYPE = 1,
    WORLD_BOSS = 2,
    WAR_RESULT = 3,
    MS_BOSS = 4,
}

BROADCAST_TYPE = {
    BASE_TYPE = 0,
    WORLD_TYPE = 1,
    TEAM_TYPE = 2,
    INTERFACE_TYPE = 3,
    FRIEND_FOCUS_TYPE = 4,
    ORG_TYPE = 5,
    ORG_FUBEN = 6,
    FIELD_BOSS = 7,
    TEAMPVP_TYPE = 8,
}

SYS_CHANNEL_TAG = {
    NOTICE_TAG = 0,
    RUMOUR_TAG = 1,
    HELP_TAG = 2,
}

WAR_TYPE = {
    NPC_TYPE = 1,   --pve
    PVP_TYPE = 2,
    BOSS_TYPE = 3,
    PATA_TYPE = 4,
    ENDLESS_PVE_TYPE = 5,   --无尽pve
    ARENA_TYPE = 6,
    LILIAN_TYPE = 7,
    EQUIP_TYPE = 8, --装备副本
    TRAPMINE_TYPE = 9, --暗雷副本
    ORG_FUBEN = 10, -- 公会BOSS
    EQUAL_ARENA = 11, --公平竞技
    TERRAWARS_TYPE = 12,
    YJFUBEN_TYPE = 13, --月间行者
    FIELDBOSS_TYPE = 14,
    FIELDBOSSPVP_TYPE = 15, --野外BOSS PK
    PE_FUBEN = 16, -- 符文副本
    CHAPTERFB_TYPE = 17,
    CONVOY_TYPE = 18,
    TEAM_PVP = 19,--协同战斗
    MSATTACK = 20, --怪物攻城
    SHIMEN =21,--师门
    BOSS_TYPE2 = 22, -- 特殊类型的世界BOSS
    TRAIN_TYPE = 23,    ----每日修行
    ORG_WAR_TYPE = 24,   --公会战
    CLUB_TYPE = 25, -- 武馆
}

AI_TYPE = {
    COMMON = 101,
    AI_SMART = 102,
    ROM_AI_SMART = 103,
}

AI_CHOOSE_TARGET = {
    NULL = 0,
    LIKE_BUFF = 1,
    NO_BUFF = 2,
    LOW_HP = 3,
    HIGH_HP = 4,
    LOW_HP2 = 5,
    CALL_SUMMON = 6,
}


BUFF_TYPE = {
    CLASS_ABNORMAL = 1,
    CLASS_FUZHU = 2,
    CLASS_TMP = 3,
    CLASS_SPE = 4,
}

TEXT_TYPE = {
    SECOND_CONFIRM = 1001,
    WINDOW_TIPS = 1003,
}

COIN_FLAG = {
COIN_GOLD = 1,          --水晶
COIN_COIN = 2,          --金币
COIN_MEDAL = 3,        --勋章
COIN_ARENA = 4,        --荣誉
COIN_ACTIVE = 5,        --活跃度
COIN_ORG_OFFER = 6, --帮派贡献
COIN_ORG_CASH = 7,  --帮派资金
COIN_TRAPMINE_POINT = 8, --暗雷探索点
COIN_SKIN = 9, --皮肤卷0_0
COIN_TRAVEL = 10, --游历积分
COIN_ORG_PRESTIGE = 11 , --公会声望
COIN_COLOR =  12, --彩晶
COIN_RMB = 13, --人民币
COIN_ENERGY = 14,--体力
}

COIN_TYPE = {
    [COIN_FLAG.COIN_GOLD] = {name = "水晶", item = {1003,1004}, type = "gold",max=2100000000,icon="#w2",},
    [COIN_FLAG.COIN_COIN] = {name = "金币", item ={1002,}, type = "coin",max=2100000000,icon="#w1",},
    [COIN_FLAG.COIN_MEDAL] = {name = "勋章",type = "medal",max=2100000000,icon="#w3",},
    [COIN_FLAG.COIN_ARENA] = {name = "荣誉",type = "arenamedal",max=2100000000,icon="#w4",},
    [COIN_FLAG.COIN_ACTIVE] = {name = "活跃度",type = "active",max=2100000000,icon="#w5",},
    [COIN_FLAG.COIN_ORG_OFFER] = {name = "贡献",type = "orgoffer",max = 2100000000,icon="#w6",},
[COIN_FLAG.COIN_ORG_CASH] = {name = "公会资金",type = "orgcash",max = 2100000000,icon="#w7",},
    [COIN_FLAG.COIN_TRAPMINE_POINT] = {name = "暗雷探索点",type = "trapmine_point",max = 200,icon="#w8",},
    [COIN_FLAG.COIN_SKIN] = {name = "皮肤卷",type = "skin",max=2100000000,icon="#w9",},
    [COIN_FLAG.COIN_TRAVEL] =  {name = "游历积分", type="travel_score", max = 2100000000, tips = "兑换"},
    [COIN_FLAG.COIN_ORG_PRESTIGE] = {name = "公会声望",type = "orgprestige",max = 2100000000},
    [COIN_FLAG.COIN_COLOR] = {name = "彩晶", item = {1001,}, type = "color",max=2100000000,icon="#wa",},
    [COIN_FLAG.COIN_RMB] = {name="人民币",type="rmb",max=2100000000,icon="#tl",},
    [COIN_FLAG.COIN_ENERGY] = {name="体力",type="energy",max=2100000000,icon="#tl",},
}

QUESTION_TYPE = {
    RANDOM = 1,
    SCORE = 2,
    SCENE = 3,
}
QUESTION_STATUS = {
    READY = 1,
    START = 2,
    END = 3,
    WAIT = 4,
}

FIGHTFAIL_CODE = {
    HASTEAM = 1,
}

ADDTEAMFAIL_CODE={
    PERSONAL_TASK = 1,
    LILIANING = 2,
    IS_TRAPMINE = 3, --正在探索
    IN_HOUSE = 4, --正在宅邸
    HAS_TEAM = 5,
    ON_TASKSHOW = 6,--剧场中
    PREPARE_TERRAWARS = 7,--据点战准备中
    GRADE_LIMIT = 8,
    CONVOY = 9,
    SCENE_QUESTION = 10, --场景答题
}

--角色装备性别类型
EQUIP_SEX_TYPE = {
    COMMON = 0,
    MALE = 1,
    FEMALE = 2,
}

--確認框的類型
CONFIRM_WND_TYPE = {
    TEAM_INVITE = 1,
}

VIRTUAL_SCENE_ID = 100000

PARTNER_STATUS = {
    ON_LOCK = 1;        --上锁
    ON_SHOW = 2;        --好友展示
    ON_EQUAL_ARENA = 3; --公平竞技
    ON_FOLLOW = 4;      --跟随
    ON_TERRAWARS = 5;       --驻守据点
    ON_TRAVEL = 6; --游历
    ON_FRD_TRAVEL = 7; --挂在好友游历
}

TRAPMINE_STATUS = {
    NORMAL = 0, --非探索
    START = 1,  --探索
    MONSTER = 2, --打怪
    OFFLINE = 3, --离线托管
}

TRAPMINE_MONSTER = {
    RARE = 1, --稀有怪
    BOX = 2,    --宝箱怪
    NORMAL = 3, --普通怪
}

PARTNER_AWAKE_TYPE = {
    ADD_SKILL = 1,                  --添加技能
    UNLOCK_SKILL = 2,           --解锁技能
    IMPROVE_SKILL = 3,         --强化技能
    ADD_ATTR = 4,                   --添加属性
}

VOICE_TYPE = {
    SALE_SUCCESS = 1,   --出售成功
}

ITEM_CONTAINER = {
    COMMON = 1,     --普通道具
    MATERIAL = 2,   --材料
    GEM = 3,            --宝石
    EQUIP = 4,          --角色装备
    PARTNER_EQUIP = 5, --伙伴符文装备
    EQUIP_STONE = 6,       --装备灵石
    PARTNER_CHIP = 7, --伙伴碎片
    PARTNER_AWAKE = 8, --伙伴觉醒道具
    PARTNER_SKIN = 9,   --伙伴皮肤
    PARTNER_TRAVEL = 10, --游历道具
    PARTNER_STONE = 11, --伙伴符石
    PARTNER_SOUL = 12, --伙伴御灵
}

--部分格子
ITEM_CONTAINER_SIZE = {
    [ITEM_CONTAINER.COMMON] = 200,
    [ITEM_CONTAINER.MATERIAL] = 100,
    [ITEM_CONTAINER.GEM] = 100,
    [ITEM_CONTAINER.EQUIP_STONE] = 200,
    [ITEM_CONTAINER.PARTNER_EQUIP] = 200,
    [ITEM_CONTAINER.PARTNER_SOUL] = 999,
}

--图鉴
HANDBOOK_TYPE = {
    PARTNER = 1,
    PARTNER_EQUIP = 2,
    PERSON = 3,
}

TRAVEL_CARD_STATUS = {
    END = 0,
    WATCH = 1,
    START = 2,
}

TRAVEL_REWARD_TYPE = {
    EXP = 1; --奖励经验
    ITEM = 2; --奖励道具
}

ORG_POSITION = {
    LEADER = 1,         --帮主
    DEPUTY = 2,        --副帮主
    ELITE = 3,             --精英
    FINE = 4,              --成员
    MEMBER = 5,      --新手
}

WALK_SPEED = 2.8
HALF_SCREEN = 5
CHECK_SCREEN = 4*HALF_SCREEN
CHECK_SCREEN2 = CHECK_SCREEN^2

function OverPosRange(x1,y1,x2,y2)
        return ((x1 - x2)^2 + (y1-y2)^2) < CHECK_SCREEN2
end

function CoverPos(mPos)
    return {
        v = mPos.v and geometry.Cover(mPos.v),
        x = mPos.x and geometry.Cover(mPos.x),
        y = mPos.y and geometry.Cover(mPos.y),
        z = mPos.z and geometry.Cover(mPos.z),
        face_x = mPos.face_x and geometry.Cover(mPos.face_x),
        face_y = mPos.face_y and geometry.Cover(mPos.face_y),
        face_z = mPos.face_z and geometry.Cover(mPos.face_z),
    }
end

function RecoverPos(mPos)
    return {
        v = mPos.v and geometry.Recover(mPos.v),
        x = mPos.x and geometry.Recover(mPos.x),
        y = mPos.y and geometry.Recover(mPos.y),
        z = mPos.z and geometry.Recover(mPos.z),
        face_x = mPos.face_x and geometry.Recover(mPos.face_x),
        face_y = mPos.face_y and geometry.Recover(mPos.face_y),
        face_z = mPos.face_z and geometry.Recover(mPos.face_z),
    }
end

STAR_LIST = {
    "摩羯座", "水瓶座", "双鱼座", "白羊座", "金牛座", "双子座", "巨蟹座",
    "狮子座", "处女座", "天枰座", "天蝎座", "射手座", "摩羯座"
}

function GetStar(month, day)
    local daylist = {20, 19, 21, 21, 21, 22, 23, 23, 23, 23, 22, 22}
    local idx = month
    if day<daylist[month] then
        idx = month
    else
        idx = month + 1
    end
    return STAR_LIST[idx]
end