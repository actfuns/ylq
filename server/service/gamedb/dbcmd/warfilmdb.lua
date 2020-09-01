--import module
local global = require "global"
local skynet = require "skynet"
local mongoop = require "base.mongoop"
local interactive = require "base.interactive"

local sWarFilmTableName = "warfilm"

function LoadWarFilm(mCond, mData)
    local oGameDb = global.oGameDb
    local m = oGameDb:FindOne(sWarFilmTableName, {film_id = mData.film_id}, {film_info = true})

    local mRet
    if m then
        mRet = {
            success = true,
            data = m.film_info,
            film_id = mData.film_id,
        }
    else
        mRet = {
            success = false,
        }
    end
    return mRet
end

function SaveWarFilm(mCond, mData)
    local oGameDb = global.oGameDb
    oGameDb:Update(sWarFilmTableName, {film_id = mData.film_id}, {["$set"]={film_info = mData.data}},true)
end