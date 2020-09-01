-- ./excel/log/pay.xlsx
return {

    ["payerror"] = {
        explain = "支付失败日志",
        log_format = {["cbdata"] = {["id"] = "cbdata", ["desc"] = "回调数据"}, ["order_id"] = {["id"] = "order_id", ["desc"] = "订单号"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家id"}, ["server"] = {["id"] = "server", ["desc"] = "所在服务器"}, ["type"] = {["id"] = "type", ["desc"] = "错误类型"}},
        subtype = "payerror",
    },

}
