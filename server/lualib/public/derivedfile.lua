--import module

DERIVED_TREE = {
    war = {"buff"},
    partner = {"item"},
    world = {"item", "npc", "task","title"},
    assist = {"item"},
}

function NewDerivedFileMgr(...)
    return CDerivedFileMgr:New(...)
end


CDerivedFileMgr = {}
CDerivedFileMgr.__index = CDerivedFileMgr

function CDerivedFileMgr:New()
    local o = setmetatable({}, self)
    o.m_mFileTrees = {}
    o:Init()
    return o
end

function CDerivedFileMgr:Init()
    self:ScanDirs()
end

function CDerivedFileMgr:Release()
    release(self)
end

function CDerivedFileMgr:Reload()
    self:ScanDirs()
end

function CDerivedFileMgr:ScanDirs()
    if not DERIVED_TREE[MY_SERVICE_NAME] then
        return
    end
    for _, sDirs in pairs(DERIVED_TREE[MY_SERVICE_NAME]) do
        self:ScanFiles(sDirs)
    end
end

function CDerivedFileMgr:ScanFiles(...)
    local lfs = require "lfs"

    local lRoot = table.pack(...)
    local sRoot = service_file_path(table.concat(lRoot, "/"))
    for n in lfs.dir(sRoot) do
        if n == "." or n == ".." then
            goto continue
        end
        local sPath = sRoot.."/"..n
        local sFileMode = lfs.attributes(sPath, "mode")
        if sFileMode == "directory" then
            self:ScanFiles(..., n)
        elseif sFileMode == "file" then
            if string.sub(n, -4, -1) == ".lua" then
                local sName = string.sub(n, 1, -5)
                local mTree = self.m_mFileTrees
                for _, sNode in ipairs(lRoot) do
                    if not mTree[sNode] then
                        mTree[sNode] = {}
                    end
                    mTree = mTree[sNode]
                end
                mTree[sName] = true
            end
        end
        ::continue::
    end
end

function CDerivedFileMgr:ExistFile(...)
    local mTree = self.m_mFileTrees
    for _, sNode in ipairs(table.pack(...)) do
        if not mTree[sNode] then
            return false
        end
        mTree = mTree[sNode]
    end
    return true
end
