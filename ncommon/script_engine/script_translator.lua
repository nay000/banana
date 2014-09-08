 -- 文件名　：translate_script.lua
-- 创建者　：xk
-- 创建时间：2014-06-05 10：00：00
-- 文件描述：
-------------------------------------------------------

script_translator = script_translator or class("script_translator", script)

function script_translator:__init()
end

-- 请重载此函数
function script_translator:translate(sz_raw_script, n_script_type)
    return "请重载此函数"
end

function script_translator:help()
    return "使用说明"
end













