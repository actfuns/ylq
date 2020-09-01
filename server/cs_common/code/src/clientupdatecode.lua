
CLIENT_UPDATE_CODE  = [[
local framever, dllver, resver = C_api.Utils.GetResVersion()
if resver >= 96 or Utils.IsEditor() then
	function CWelfareCtrl.IsOpenCostSave(self)
		local b = false
		local t = g_TimeCtrl:GetTimeS()	
		if self.m_CostSaveStartTime ~= 0 and self.m_CostSaveEndTime ~= 0 and t > self.m_CostSaveStartTime and t < self.m_CostSaveEndTime then
			b = true
		end
		return b
	end
	function CPartnerHireView.IsCanYFRH(self, iParID)
		local d = data.partnerhiredata.DATA
		if table.index(d[iParID]["recommand_list"], "一发入魂") then
			return self:IsCanSSRDraw()
		end
	end
	function CPartnerEquipPage.ChangePart(self)
		local oItem = g_ItemCtrl:GetItem(self.m_CurItemID)
		if oItem and oItem:GetValue("level") == define.Partner.ParEquip.MaxLevel and oItem:GetValue("star") < define.Partner.ParEquip.MaxStar then
			if self.m_CurPart ~= self.m_UpStarPart and self.m_CurPart ~= self.m_UpStonePart then
				self.m_UpStarBtn:SetSelected(true)
				self:SwitchPart()
			end
		end
	end
	data.netdata.BAN["proto"]["herobox"]["item"]["GS2CItemQuickUse"] = true
end
]]
