
local this = {exiting = false}

-- 板卡名称对照表
this.CARDS_NAME = {
    [0x01] = "主控",
    [0x02] = "仪表校验板卡",
    [0x03] = "防护系统测试板卡1",
    [0x04] = "防护系统测试板卡2",
    [0x05] = "通讯板卡1",
    [0x06] = "通讯板卡2",
    [0x07] = '综电板卡'
}

-- 判定table是否包含某值
this.contains = function (t, v)
    for _i, _v in ipairs(t) do
        if _v == v then
            return true
        end
    end
    return false
end

-- 创建主协议数据
this.creat_main = function(cmd, da, buffer)
    local main = message(protocol.SEND_MAIN)
    main.BUFFER = buffer
    main.SA = 0x01
    main.CMD = cmd
    main.DA = da
    return pack(main)
end

-- 由message到record记录
this.msg_record = function (pre, msg, keys)
    for i, k in ipairs(keys) do
        if string.sub(k, 1, 1) == '$' then
            local seg = string.sub(k, 2, #k)
            local ov = msg[seg]
            if ov and ov.x2_3 == -50 and ov.x2_5 == -50 then
                record[pre .. k] = 1
            elseif ov and ov.x2_3 == 500 and ov.x2_5 == 500 then
                record[pre .. k] = 1
            elseif ov and ov.x2_3 == 200 and ov.x2_5 == 200 then
                record[pre .. k] = 3
            else
                record[pre .. k] = 0
            end
        else
            record[pre .. k] = (msg[k] or 0)
        end
    end

end

-- 由命令参数到协议值
this.cmd_msg = function (params)
    local msg = {}
    for k, v in pairs(params) do
        if string.sub(k, 1, 1) == '$' then
            local seg = string.sub(k, 2, #k)
            if v == 1 then
                msg[seg] = {
                    x2_3 = -50,
                    x2_5 = -50,
                    x2_7 = 0,
                    x2_9 = 0,
                }
            elseif v == 2 then
                msg[seg] = {
                    x2_3 = 500,
                    x2_5 = 500,
                    x2_7 = 0,
                    x2_9 = 0,
                }
            elseif v == 3 then
                msg[seg] = {
                    x2_3 = 200,
                    x2_5 = 200,
                    x2_7 = 0,
                    x2_9 = 0,
                }
            else
                msg[seg] = {
                    x2_3 = 0,
                    x2_5 = 0,
                    x2_7 = 0,
                    x2_9 = 0,
                }
            end
        else
            msg[k] = v
        end
    end
    return msg
end

-- 退出测试
this.do_exit = function(vars, need_send_stop)
    local cards = vars.cards

    if this.exiting then
        return
    end
    this.exiting = true

    if need_send_stop then
        for k, v in ipairs(cards) do
            local msg = message(protocol[v.test_prot], (v.test_data or {}))
            msg.device_type = nil
            msg.device_code = nil
            msg.test_code = vars.test_code
            msg.test_state = 0x02
            async.send(device.main_ctr.conn, this.creat_main(0x30, v.card, pack(msg)))
            delay(100)
        end
    end

    if DEBUG then
        print("END")
    end
    exit()
end
this.stop_init = function(vars, need_send_stop)
    local cards = vars.cards
    if need_send_stop then
        for k, v in ipairs(cards) do
            local msg = message(protocol[v.test_prot], (v.test_data or {}))
            msg.device_type = nil
            msg.device_code = nil
            msg.test_code = vars.test_code
            msg.test_state = 0x02
            async.send(device.main_ctr.conn, this.creat_main(0x30, v.card, pack(msg)))
            delay(40)
            local init_msg = message(protocol[v.test_prot], (v.test_data or {}))
            init_msg.device_type = nil
            init_msg.device_code = nil
            init_msg.test_code = vars.test_code
            async.send(device.main_ctr.conn, this.creat_main(0x02, v.card, pack(msg)))
        end
    end

    delay(100)
    -- print("step=",Step)
    if DEBUG then
        print("END")
    end
end
this.list2str = function (vars, list)
    local s = ''
    local errs = vars.labels or {}
    for i, value in ipairs(list) do
        local err = errs[value] or value
        s = ((i==1) and s or (s .. ',')) .. err
    end
    return s
end

-- 打印日志
this.print_recv = function(msg, opt)
    -- print("recv len=",msg.LEN)
    if msg.CMD == 0x01 then
        print("收到来自" .. (this.CARDS_NAME[msg.SA] or string.format("%02X", msg.DA)) .. "的握手回复(" .. msg.LEN .. ")")
    elseif msg.CMD == 0x02 then
        print("收到来自" .. (this.CARDS_NAME[msg.SA] or string.format("%02X", msg.DA)) .. "的初始化回复(" .. msg.LEN .. ")")
    elseif msg.CMD == 0x31 then
        print("收到来自" .. (this.CARDS_NAME[msg.SA] or string.format("%02X", msg.DA)) .. "的测试项状态上报(" .. msg.LEN .. ")")
    elseif msg.CMD == 0x32 then
        print("收到来自" .. (this.CARDS_NAME[msg.SA] or string.format("%02X", msg.DA)) .. "的测试项时间数据(" .. msg.LEN .. ")")
    elseif msg.CMD == 0x33 then
        print("收到来自" .. (this.CARDS_NAME[msg.SA] or string.format("%02X", msg.DA)) .. "的测试项波形数据(" .. msg.LEN .. ")")
    end
end

return this