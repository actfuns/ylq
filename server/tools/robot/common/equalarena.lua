local war = {}

war.GS2CLoginRole = function(self, args)
    self:sleep(15+math.random(10))
    self:run_cmd("C2GSGMCmd", {cmd="supermode"})
    --self:run_cmd("C2GSGMCmd", {cmd="huodong equalarena 120"})
    self:run_cmd("C2GSSetEqualArenaPartner",{partner={1,2,}})
    
    --self:run_cmd("C2GSEqualArenaMatch", {})
end


war.GS2CWarResult = function (self,args)
    self:sleep(5)
    self:run_cmd("C2GSEqualArenaMatch", {})
end


war.GS2CSelectEqualArena = function(self,args)
    self:run_cmd("C2GSSelectEqualArena", {})
end

war.GS2CConfigEqualArena = function(self,args)
    self:run_cmd("C2GSConfigEqualArena",{select_par={1,2,3,4,},select_item={1,2,3,4},handle_type=1})
    --print("=====GS2CConfigEqualArena==========",args.pinfo)
end

return war



