-- ./excel/log/mail.xlsx
return {

    ["add_mail"] = {
        desc = "添加邮件",
        explain = "添加邮件",
        log_format = {["attach"] = {["id"] = "attach", ["desc"] = "附件"}, ["keep_time"] = {["id"] = "keep_time", ["desc"] = "有效时间"}, ["mail_time"] = {["id"] = "mail_time", ["desc"] = "邮件时间"}, ["mail_title"] = {["id"] = "mail_title", ["desc"] = "邮件标题"}, ["mailid"] = {["id"] = "mailid", ["desc"] = "邮件ID"}, ["receiver_id"] = {["id"] = "receiver_id", ["desc"] = "接收者id"}, ["sender_id"] = {["id"] = "sender_id", ["desc"] = "发送者id"}},
        subtype = "add_mail",
    },

    ["del_mail"] = {
        desc = "删除邮件",
        explain = "删除邮件",
        log_format = {["attach"] = {["id"] = "attach", ["desc"] = "附件"}, ["keep_time"] = {["id"] = "keep_time", ["desc"] = "有效时间"}, ["mail_time"] = {["id"] = "mail_time", ["desc"] = "邮件时间"}, ["mail_title"] = {["id"] = "mail_title", ["desc"] = "邮件标题"}, ["mailid"] = {["id"] = "mailid", ["desc"] = "邮件ID"}, ["reason"] = {["id"] = "reason", ["desc"] = "删除原因"}, ["receiver_id"] = {["id"] = "receiver_id", ["desc"] = "接收者id"}, ["sender_id"] = {["id"] = "sender_id", ["desc"] = "发送者id"}},
        subtype = "del_mail",
    },

    ["rec_mail"] = {
        desc = "领取邮件",
        explain = "领取邮件",
        log_format = {["attach"] = {["id"] = "attach", ["desc"] = "附件"}, ["keep_time"] = {["id"] = "keep_time", ["desc"] = "有效时间"}, ["mail_time"] = {["id"] = "mail_time", ["desc"] = "邮件时间"}, ["mail_title"] = {["id"] = "mail_title", ["desc"] = "邮件标题"}, ["mailid"] = {["id"] = "mailid", ["desc"] = "邮件ID"}, ["receiver_id"] = {["id"] = "receiver_id", ["desc"] = "接收者id"}, ["sender_id"] = {["id"] = "sender_id", ["desc"] = "发送者id"}},
        subtype = "rec_mail",
    },

}
