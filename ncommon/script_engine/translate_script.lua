 -- 文件名　：translate_script.lua
-- 创建者　：lj
-- 创建时间：2014-05-07 15：00：00
-- 文件描述：
-------------------------------------------------------

translate_script = translate_script or class("translate_script", script)

function translate_script:__init()
    self.cs_translator = nil
    self.tb_translator = {}
    self.sz_raw_script = ""
    self.n_script_type = 0
    self.sz_script = ""
end

-- 返回一个翻译后的脚本
function translate_script:lua_script()
    if self.cs_translator == nil then
        TraceError(" 请初始化翻译器 translate_script.sc_translator ")
        return
    end
    if not self.cs_translator.class:isSubclassOf(script_translator) then
        TraceError(" 翻译器必须继承自 class script_translator ");
        return 
    end
    if (self.sz_script == "") then 
        self.sz_script = self.cs_translator:translate(self.sz_raw_script, self.n_script_type)
    end
    return self.sz_script
end

-- 返回脚本类型
function translate_script:get_script_type()
    return self.n_script_type
end

-- 返回脚本
function translate_script:get_script()
    return self.sz_raw_script
end


--脚本翻译
--返回1通过，0不通过
function script_engine:translate()
end

