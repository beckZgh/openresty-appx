
-- 子目录列表 v20.08.09 --------------------------------------------------------

--【升级说明】v20.08.09
-- 1) 不输出 _bk 目录

--------------------------------------------------------------------------------

local lfs       = require "lfs" -- LuaFileSystem
local _sub      = string.sub
local _match    = string.match
local _find     = string.find
local _len      = string.len

local __ = {}

-- 文件名(不含后缀名)
__.file_name = function(file)
    local idx = _match(file, ".+()%.%w+$")
    if(idx) then
        return _sub(file, 1, idx-1)
    else
        return file
    end
end

-- 后缀名
__.exe_name = function(file)
    return _match(file, ".+%.(%w+)$")
end

-- lua文件列表
__.file_list = function(path)

    local list, index = {}, 0

    for f in lfs.dir(path) do
        if f ~= "." and f ~= '..' then
            local p = path .. "/" .. f
            local t = lfs.attributes(p).mode
            if t == "file" and __.exe_name(f) == "lua" then
                index = index + 1
                list[index] = __.file_name(f)
            end
        end
    end

    return list

end

-- 子目录列表
__.path_list = function(path)

    local list, index = {}, 0

    for f in lfs.dir(path) do
        if f ~= "." and f ~= '..' and f ~= "_bk" then
            local p = path .. "/" .. f
            local t = lfs.attributes(p).mode
            if t == "directory" then
                index = index + 1
                list[index] = f
            end
        end
    end

    return list

end

-- 错误日志输出
__.err_log = function(err, ...)

    ngx.status = 500
    ngx.header["content-type"] = "text/plain"

    ngx.say "------ 出 错 啦 ------"

    if type(err)=="string" then
        ngx.say(err, ...)
    else
        local log = debug.traceback(err)
        ngx.log(ngx.ERR, "\n------ 出 错 啦 ------\n\n", log, "\n\n")
        ngx.say(log)
    end

    ngx.exit(500)
end

-- 分割字符串
__.split = function(str, sep)

    local arr   = {}
    if type(str) ~= "string" or type(sep) ~= "string" then
        return arr
    end

    local i     = 1
    local index = 1
    local len   = _len(sep)

    while true do
        local j = _find(str, sep, i)
        if not j then
            local temp = _sub(str, i, _len(str))
            if _len(temp)>0 then arr[index] = temp end
            break
        end
        local temp = _sub(str, i, j - 1)
            if _len(temp) >0 then
                arr[index] = temp
                index = index + 1
            end
        i = j + len
    end

    return arr

end

return __
