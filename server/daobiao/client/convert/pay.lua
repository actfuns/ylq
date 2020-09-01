module(..., package.seeall)
function main()
	local s =table.dump(require("pay.pay"), "AndroidPay")
	local s2 =table.dump(require("pay.ios_pay"), "IOSPay")
	SaveToFile("pay", s..s2)
end
