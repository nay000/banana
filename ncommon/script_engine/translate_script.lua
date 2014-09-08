 -- �ļ�������translate_script.lua
-- �����ߡ���lj
-- ����ʱ�䣺2014-05-07 15��00��00
-- �ļ�������
-------------------------------------------------------

translate_script = translate_script or class("translate_script", script)

function translate_script:__init()
    self.cs_translator = nil
    self.tb_translator = {}
    self.sz_raw_script = ""
    self.n_script_type = 0
    self.sz_script = ""
end

-- ����һ�������Ľű�
function translate_script:lua_script()
    if self.cs_translator == nil then
        TraceError(" ���ʼ�������� translate_script.sc_translator ")
        return
    end
    if not self.cs_translator.class:isSubclassOf(script_translator) then
        TraceError(" ����������̳��� class script_translator ");
        return 
    end
    if (self.sz_script == "") then 
        self.sz_script = self.cs_translator:translate(self.sz_raw_script, self.n_script_type)
    end
    return self.sz_script
end

-- ���ؽű�����
function translate_script:get_script_type()
    return self.n_script_type
end

-- ���ؽű�
function translate_script:get_script()
    return self.sz_raw_script
end


--�ű�����
--����1ͨ����0��ͨ��
function script_engine:translate()
end

