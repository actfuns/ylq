local scene = {}

scene.GS2CEnterScene = function(self, args)
    local iScene = args.scene_id
    local iEid = args.eid
    local mPosInfo = args.pos_info
    local iX = mPosInfo.x
    local iY = mPosInfo.y
    local iZ = mPosInfo.z
    local iV = mPosInfo.v
    self.m_mCurPosInfo = {["iScene"]=iScene,["x"]=iX,["y"]=iY,["z"]=iZ,["v"]=iV,["iEid"] = iEid}
end
scene.GS2CAutoFindPath = function(self,mArgs)
            local iAutoType,iMapId,iNpcId,iPosX,iPosY = mArgs.autotype,mArgs.map_id,mArgs.npcid,mArgs.pos_x,mArgs.pos_y
            self:sleep(1)
            self:run_cmd("C2GSSyncPosQueue", {
                scene_id = self.m_mCurPosInfo.iScene,
                eid = self.m_mCurPosInfo.iEid,
                pos = {{x = self.m_mCurPosInfo.x,y = self.m_mCurPosInfo.y,}},
                })
            local iSLeepTime = math.floor((math.abs(iPosX-self.m_mCurPosInfo.x)+math.abs(iPosY-self.m_mCurPosInfo.y)))/1000
            self.m_mCurPosInfo.x = iPosX
            self.m_mCurPosInfo.y = iPosY

            self:sleep(iSLeepTime)
            self.m_oTaskMgr:TriggerEventByProto("GS2CAutoFindPath",mArgs)
    end

return scene
