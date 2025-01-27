
-- 初始化 v22.11.19 by Killsen ------------------

local lfs   = require "lfs"
local pcall = pcall
local type  = type
local ssub  = string.sub
local gsub  = string.gsub

-- nginx 运行目录
local prefix = ngx.config.prefix()
do
    if not prefix or prefix == "./" or prefix == "" then
        prefix = lfs.currentdir()
    end
    prefix = gsub(prefix, [[%\]], "/")
    if ssub(prefix, -1) ~= "/" then
        prefix = prefix .. "/"
    end
end

do
    -- 兼容处理 Windows 下 ffi.load 路径问题
    local ffi = require "ffi"
    if ffi.os == "Windows" then
        local ffi_load = ffi.load
        ffi.load = function(filename)
            local pok, clib

            pok, clib = pcall(ffi_load, filename)
            if pok then return clib end

            pok, clib = pcall(ffi_load, prefix .. filename)
            if pok then return clib end
        end
    end

end

do
    local io_open = io.open
    _G.openx = function(filename, mode)
        return io_open(prefix .. filename, mode)
    end
    rawset(io, "openx", _G.openx)
end

do
    local dofile = dofile
    _G.dofilex = function(filename)
        return dofile(prefix .. filename)
    end
end

-- 检查路径
local function check_path(path)
    if type(path) ~= "string" then return nil, "path must be a string" end

    path = gsub(path, [[%\]], "/")

    if ssub(path, 2, 3) ~= ":/" and  -- 盘符根目录
       ssub(path, 1, 1) ~= "/" then  -- 根目录
        path = prefix .. path
    end

    if ssub(path, -1) == "/" and path ~= "/" then
        if not (#path == 3 and ssub(path, 2, 3) == ":/") then
            path = ssub(path, 1, -2)  -- 非(盘符)根目录去掉最后的斜杠
        end
    end

    return path

end

do
    local lfs_dir = lfs.dir
    lfs.lfs_dir = lfs_dir
    lfs.dir = function(filepath)
        local path = check_path(filepath)
        if not path then
            return function() end
        end

        -- 兼容 linux 目录不存在时抛错的问题
        local pok, f, a, b = pcall(lfs_dir, path)
        if pok then
            return f, a, b
        else
            return function() end
        end
    end
end

do
    local lfs_mkdir = lfs.mkdir
    lfs.lfs_mkdir = lfs_mkdir
    lfs.mkdir = function(filepath)
        local  path, err = check_path(filepath)
        if not path then return nil, err end

        local  pok, res, err = pcall(lfs_mkdir, path)
        if not pok then return nil, res end
        return res, err
    end
end

do
    local lfs_rmdir = lfs.rmdir
    lfs.lfs_rmdir = lfs_rmdir
    lfs.rmdir = function(filepath)
        local  path, err = check_path(filepath)
        if not path then return nil, err end

        local  pok, res, err = pcall(lfs_rmdir, path)
        if not pok then return nil, res end
        return res, err
    end
end

do
    local lfs_attributes = lfs.attributes
    lfs.lfs_attributes = lfs_attributes
    lfs.attributes = function(filepath, aname)
        local  path, err = check_path(filepath)
        if not path then return nil, err end

        local  pok, res, err = pcall(lfs_attributes, path, aname)
        if not pok then return nil, res end
        return res, err
    end
end
