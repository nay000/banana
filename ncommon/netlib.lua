
netlib = 
{
    ip = 0,
    port = 0,
    split_num = 20,
    cur_pos = 1,
    borcast_target = 
    {
        playingOnly = 1,		--只对桌上玩家
    	watchingOnly = 2,			--只对桌上观战人
    	all = 3,				--对所有人
    }
}

netlib.send = function(func_send, ip, port, target)
    if(target == nil) then
        target = netlib.borcast_target.playing
    end

    --判断是否需要广播给桌上用户
    if(target == netlib.borcast_target.playing or target == netlib.borcast_target.all) then
        tools.FireEvent2(func_send, ip, port)
    end
    if (userlist ~= nil) then
        local userinfo = userlist[string.format("%s:%s", ip, port)]
        --是否需要广播给每个用户所附属的观战用户
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

--发送一个buf到其他gameserver上
netlib.send_buf_to_gamesvr_by_use_id = function(from_user_id, to_user_id, func, err_msg)
    --这几个参数必须要赋值，否侧程序可能会出错
    room.arg.gspp_from_user_id = from_user_id
    room.arg.gspp_to_user_id = to_user_id
    room.arg.gspp_szErrorMsg = err_msg or ""
    room.arg.func = func
    tools.SendBufToGameCenter(getRoomType(), "GSPP")
end
--跨服发送一个buf到用户客户端
netlib.send_buf_to_user = function(user_id, func, err_msg)
    --这几个参数必须要赋值，否侧程序可能会出错
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


--发送广播到所有的gs服务器
netlib.send_buf_to_all_game_svr = function(func, game_name)
    cmdHandler["GSSG"] = function(buf)
        buf:writeString("GSSG")
        func(buf)
    end
    tools.SendBufToGameCenter(game_name or "", "GSSG")
end

-- 分批多次发送数据封装
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
    --TraceError("分拆发送数据开始："..protocol_start)
end

-- 使用时需要回传一个回调来解释数据
netlib.split_send = function(protocal_send, data, cb_record)
    local count = #data - netlib.cur_pos + 1
    if count > netlib.split_num then
        count = netlib.split_num
    elseif count <= 0 then
        --TraceError("没有可发送的数据，直接返回")
        return 0
    end
    --TraceError("本次发送的数据量:"..tostring(count))
    netlib.send(
        function(out_buf)
            -- 计算当前应当发送多少数据
            -- 发送协议
            out_buf:writeString(protocal_send)
            -- 发送本次记录数
            out_buf:writeInt(count)

            -- 添加每一个记录到buf中，由外部回调解释数据
            local loop_start = netlib.cur_pos
            local loop_end = netlib.cur_pos + count - 1
            for offset = loop_start, loop_end do
                --TraceError("准备发送第"..offset.."条数据")
                xpcall(function() return cb_record(out_buf, data[offset]) end, throw)
                netlib.cur_pos = offset + 1
            end
        end
    , netlib.ip, netlib.port)
    --TraceError("分拆发送数据："..tostring(count))
    return count
end

netlib.split_end = function(protocol_end)
    netlib.send(
        function(out_buf)
            out_buf:writeString(protocol_end)
        end
    , netlib.ip, netlib.port)	
    --TraceError("分拆发送数据结束："..protocol_end)
end


