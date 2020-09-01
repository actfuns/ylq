-- ./excel/log/shop.xlsx
return {

    ["buy_item"] = {
        desc = "商品购买",
        log_format = {["amount"] = {["id"] = "amount", ["desc"] = "购买数"}, ["coin_type"] = {["id"] = "coin_type", ["desc"] = "货币类型"}, ["cost"] = {["id"] = "cost", ["desc"] = "花费"}, ["item"] = {["id"] = "item", ["desc"] = "商品"}, ["item_id"] = {["id"] = "item_id", ["desc"] = "对应道具"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["reason"] = {["id"] = "reason", ["desc"] = "理由"}, ["rebate"] = {["id"] = "rebate", ["desc"] = "折扣"}, ["shop_id"] = {["id"] = "shop_id", ["desc"] = "商店ID"}},
        subtype = "buy_item",
    },

    ["exchange"] = {
        desc = "兑换",
        log_format = {["max_extra"] = {["id"] = "max_extra", ["desc"] = "最大赠送次数"}, ["pid"] = {["id"] = "pid", ["desc"] = "玩家"}, ["ratio"] = {["id"] = "ratio", ["desc"] = "比例"}, ["remain_extra"] = {["id"] = "remain_extra", ["desc"] = "剩余赠送次数"}, ["source_type"] = {["id"] = "source_type", ["desc"] = "兑换货币"}, ["source_val"] = {["id"] = "source_val", ["desc"] = "兑换数量"}, ["target_type"] = {["id"] = "target_type", ["desc"] = "目标货币"}, ["target_val"] = {["id"] = "target_val", ["desc"] = "目标数量"}},
        subtype = "exchange",
    },

}
