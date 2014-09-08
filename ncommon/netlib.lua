
netlib = 
{
    ip = 0,
    port = 0,
    split_num = 20,
    cur_pos = 1,
    borcast_target = 
    {
        playingOnly = 1,		--ֻ���������
    	watchingOnly = 2,			--ֻ�����Ϲ�ս��
    	all = 3,				--��������
    }
}

netlib.send = function(func_send, ip, port, target)
    if(target == nil) then
        target = netlib.borcast_target.playing
    end

    --�ж��Ƿ���Ҫ�㲥�������û�
    if(target == netlib.borcast_target.playing or target == netlib.borcast_target.all) then
        tools.FireEvent2(func_send, ip, port)
    end
    if (userlist ~= nil) then
        local userinfo = userlist[string.format("%s:%s", ip, port)]
        --�Ƿ���Ҫ�㲥��ÿ���û��������Ĺ�ս�û�
        if(userinfo and userinfo.desk and userinfo.site and 
    	   (target == netlib.borcast_target.watching or target == netlib.borcast_target.all)) then
            for k,v in pairs(userinfo.watchingList) do
                tools.FireEvent2(func_send, v.ip, v.port)
            end
        end
    end
end
	
netlib.close_connect = function(ip, port)
	tools.CloseConn(ip, port)
end
	
netlib.send_to_gs = function(cmd, gs_id, gs_ip, gs_port)
	tools.SendBufToGameSvr(cmd, gs_id, gs_ip, gs_port)
end
	
netlib.send_to_gc = function(game_name, cmd)
	tools.SendBufToGameCenter(game_name, cmd)
end

--����һ��buf������gameserver��
netlib.send_buf_to_gamesvr_by_use_id = function(from_user_id, to_user_id, func, err_msg)
    --�⼸����������Ҫ��ֵ����������ܻ����
    room.arg.gspp_from_user_id = from_user_id
    room.arg.gspp_to_user_id = to_user_id
    room.arg.gspp_szErrorMsg = err_msg or ""
    room.arg.func = func
    tools.SendBufToGameCenter(getRoomType(), "GSPP")
end
--�������һ��buf���û��ͻ���
netlib.send_buf_to_user = function(user_id, func, err_msg)
    --�⼸����������Ҫ��ֵ����������ܻ����
    room.arg.gspp_from_user_id = -1
    room.arg.gspp_to_user_id = user_id
    room.arg.gspp_szErrorMsg = err_msg or ""
    room.arg.func = function(buf)
        buf:writeString("GS_TO_GS_TO_USER")
        buf:writeInt(user_id)
        func(buf)
    end
    tools.SendBufToGameCenter(getRoomType(), "GSPP")
end


--���͹㲥�����е�gs������
netlib.send_buf_to_all_game_svr = function(func, game_name)
    cmdHandler["GSSG"] = function(buf)
        buf:writeString("GSSG")
        func(buf)
    end
    tools.SendBufToGameCenter(game_name or "", "GSSG")
end

-- ������η������ݷ�װ
netlib.split_start = function(ip, port, protocol_start, split_num)
    netlib.ip = ip
    netlib.port = port
    netlib.split_num = split_num or 20
    netlib.cur_pos = 1

    netlib.send(
        function(out_buf)
            out_buf:writeString(protocol_start)
        end
    , netlib.ip, netlib.port)
    --TraceError("�ֲ������ݿ�ʼ��"..protocol_start)
end

-- ʹ��ʱ��Ҫ�ش�һ���ص�����������
netlib.split_send = function(protocal_send, data, cb_record)
    local count = #data - netlib.cur_pos + 1
    if count > netlib.split_num then
        count = netlib.split_num
    elseif count <= 0 then
        --TraceError("û�пɷ��͵����ݣ�ֱ�ӷ���")
        return 0
    end
    --TraceError("���η��͵�������:"..tostring(count))
    netlib.send(
        function(out_buf)
            -- ���㵱ǰӦ�����Ͷ�������
            -- ����Э��
            out_buf:writeString(protocal_send)
            -- ���ͱ��μ�¼��
            out_buf:writeInt(count)

            -- ���ÿһ����¼��buf�У����ⲿ�ص���������
            local loop_start = netlib.cur_pos
            local loop_end = netlib.cur_pos + count - 1
            for offset = loop_start, loop_end do
                --TraceError("׼�����͵�"..offset.."������")
                xpcall(function() return cb_record(out_buf, data[offset]) end, throw)
                netlib.cur_pos = offset + 1
            end
        end
    , netlib.ip, netlib.port)
    --TraceError("�ֲ������ݣ�"..tostring(count))
    return count
end

netlib.split_end = function(protocol_end)
    netlib.send(
        function(out_buf)
            out_buf:writeString(protocol_end)
        end
    , netlib.ip, netlib.port)	
    --TraceError("�ֲ������ݽ�����"..protocol_end)
end


