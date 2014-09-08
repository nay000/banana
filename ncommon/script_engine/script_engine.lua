 -- 文件名　：script_engine.lua
-- 创建者　：lj
-- 创建时间：2014-05-07 15：00：00
-- 文件描述：
-------------------------------------------------------

script_engine = script_engine or class("script_engine")

function script_engine:__init()
end

--执行一个lua脚本
--返回1执行成功，0不成功
function script_engine:execute(contex, script)
end

--语法检查
--返回1通过，0不通过
function script_engine:check_syntax(raw_script)

end

