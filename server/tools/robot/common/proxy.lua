local res = require "data"

local scene = {}

scene.GS2CEnterScene = function(self, args)
    while 1 do
        self:sleep(10)

        if not self.m_iWait then
            self.m_iWait = os.time()
            self.m_iRecord = 100
            self:run_cmd("C2GSCheckProxy",{
                record = self.m_iRecord,
                type = 1,
            })
        end
    end
end

scene.GS2CCheckProxy = function (self, args)
    if args.record == self.m_iRecord then
        print("lxldebug check proxy(1):", os.time()-self.m_iWait)
        self.m_iWait = nil
    end
end

scene.GS2CCheckProxyMerge = function (self, args)
    local record_list = args.record_list
    for _, v in ipairs(record_list) do
        if v.record == self.m_iRecord then
            print("lxldebug check proxy(2):", os.time()-self.m_iWait)
            self.m_iWait = nil           
            break
        end
    end
end

return scene
