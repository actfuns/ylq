local global = require "global"
local extend = require "base/extend"

function Create(sMiniGame,mArgs)
    local sPath = string.format("minigame/%s",sMiniGame)
    local oModule = import(service_path(sPath))
    assert(oModule,string.format("loadminigame err:%s",sMiniGame))
    local oGame = oModule.NewGame(mArgs)
    oGame:Init()
    return oGame
end