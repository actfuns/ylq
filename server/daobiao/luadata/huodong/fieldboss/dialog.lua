-- ./excel/huodong/fieldboss/dialog.xlsx
return {

    [1] = {
        content = "邪恶的人形怪物【黑暗·$name】就在里面，要进去吗？桀桀桀桀桀桀~今天又有大新闻了。",
        dialog_id = 100,
        last_action = {{["content"] = "立即进入", ["event"] = "go"}, {["content"] = "我再准备准备"}},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

    [2] = {
        content = "看着我，你在害怕什么？邪恶的人形怪物【黑暗·$name】就在里面，还不快进去？",
        dialog_id = 101,
        last_action = {{["content"] = "一探究竟", ["event"] = "go"}, {["content"] = "我再准备准备"}},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

    [3] = {
        content = "邪恶的人形怪物【黑暗·$name】就在里面暗中观察，你要进去吗？桀桀桀桀桀桀~",
        dialog_id = 102,
        last_action = {{["content"] = "去瞅瞅", ["event"] = "go"}, {["content"] = "我再准备准备"}},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

    [4] = {
        content = "你要对我做什么？嘘，等会轻点哈，我怕痛。[ff0000] （建议组队进行挑战）",
        dialog_id = 103,
        last_action = {{["content"] = "忍一忍，很快就好", ["event"] = "fieldbossF"}, {["content"] = "我也怕痛"}},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

    [5] = {
        content = "我喜欢别人单挑我。每次看别人做这种不靠谱的事情，我就知道自己有多靠谱。[ff0000] （建议组队进行挑战）",
        dialog_id = 104,
        last_action = {{["content"] = "看看你有多靠谱", ["event"] = "fieldbossF"}, {["content"] = "还是算了！"}},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

    [6] = {
        content = "哎呦喂~麻麻，这群人要燎我。飞吻飞吻飞吻~[ff0000] （建议组队进行挑战）",
        dialog_id = 105,
        last_action = {{["content"] = "自恋狂，掌嘴", ["event"] = "fieldbossF"}, {["content"] = "真恶心，逃~"}},
        next = "0",
        pre_id_list = "0",
        status = 2,
        subid = 1,
        type = 2,
        ui_mode = 2,
        voice = 0,
    },

}
