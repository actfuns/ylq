-- ./excel/log/question.xlsx
return {

    ["enter_member"] = {
        desc = "学渣答题分组",
        log_format = {["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["qtype"] = {["id"] = "qtype", ["desc"] = "答题类型"}, ["teamid"] = {["id"] = "teamid", ["desc"] = "分组id"}},
        subtype = "enter_member",
    },

    ["sendmail"] = {
        desc = "发奖励邮件",
        log_format = {["mailid"] = {["id"] = "mailid", ["desc"] = "邮件导表id"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["qtype"] = {["id"] = "qtype", ["desc"] = "答题类型"}, ["rank"] = {["id"] = "rank", ["desc"] = "积分排名"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励id"}},
        subtype = "sendmail",
    },

    ["question_status"] = {
        desc = "答题状态",
        log_format = {["qtype"] = {["id"] = "qtype", ["desc"] = "答题类型"}, ["status"] = {["id"] = "status", ["desc"] = "状态"}},
        subtype = "question_status",
    },

    ["answer_question"] = {
        desc = "回答题目",
        log_format = {["answer"] = {["id"] = "answer", ["desc"] = "答案编号"}, ["content"] = {["id"] = "content", ["desc"] = "回答内容"}, ["correct"] = {["id"] = "correct", ["desc"] = "对错"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["idx"] = {["id"] = "idx", ["desc"] = "答题序号"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["qid"] = {["id"] = "qid", ["desc"] = "题目导表id"}, ["qtype"] = {["id"] = "qtype", ["desc"] = "答题类型"}},
        subtype = "answer_question",
    },

    ["get_score_reward"] = {
        desc = "领取积分奖励",
        log_format = {["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["qtype"] = {["id"] = "qtype", ["desc"] = "类型"}, ["rank"] = {["id"] = "rank", ["desc"] = "积分排名"}, ["reason"] = {["id"] = "reason", ["desc"] = "原因"}, ["reward"] = {["id"] = "reward", ["desc"] = "奖励id"}},
        subtype = "get_score_reward",
    },

    ["correct_reward"] = {
        desc = "答对奖励",
        log_format = {["coin"] = {["id"] = "coin", ["desc"] = "金币"}, ["exp"] = {["id"] = "exp", ["desc"] = "经验"}, ["grade"] = {["id"] = "grade", ["desc"] = "等级"}, ["idx"] = {["id"] = "idx", ["desc"] = "答题序号"}, ["name"] = {["id"] = "name", ["desc"] = "玩家名"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["qid"] = {["id"] = "qid", ["desc"] = "题目导表id"}, ["qtype"] = {["id"] = "qtype", ["desc"] = "答题类型"}, ["score"] = {["id"] = "score", ["desc"] = "积分"}},
        subtype = "correct_reward",
    },

}
