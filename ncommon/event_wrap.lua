----------------------------Event 事件类实现--------------------------------------------------
event_wrap = event_wrap or {}
event_wrap.listen_class = event_wrap.listen_class or {}
--注册一些消息
function event_wrap.register_event(event_msg_list, class)
    event_wrap.un_register_event(event_msg_list, class)
    for k, v in pairs(event_msg_list) do
        if (event_wrap.listen_class[v] == nil) then
            event_wrap.listen_class[v] = {}
        end
        eventmgr:removeEventListener(v, event_wrap.on_event)
        eventmgr:addEventListener(v, event_wrap.on_event)
        table.insert(event_wrap.listen_class[v], class)
    end
end

--取消对某一些消息的注册
function event_wrap.un_register_event(event_msg_list, class)
    for k, v in pairs(event_msg_list) do
        local find = 0
        if (event_wrap.listen_class[v] ~= nil) then
            for i = 1, #event_wrap.listen_class[v] do
                if (event_wrap.listen_class[v][i].name == class.name) then
                    table.remove(event_wrap.listen_class[v], i)
                    break
                end
            end
        end
    end
end

function event_wrap.on_event(e)
    if (#event_wrap.listen_class[e.strEvent] > 0) then
        for i = 1, #event_wrap.listen_class[e.strEvent] do
            xpcall(function() event_wrap.listen_class[e.strEvent][i]:on_event(e) end, throw)
        end
    end
end

