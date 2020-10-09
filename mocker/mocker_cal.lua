MOCKER_ERROR = false    -- 模拟错误

IU_TICK = 1  -- 电流电压采集周期ms

function entry(vars, option)
    Test_out = vars

    _entry()
end

-- 通用入口函数
function _entry()
    -- 订阅所有数据的接收
    async.on_recv(device.board1.conn, protocol.SEND_MAIN, Recv_data)
    Device_type = -1
    Device_code = -1
    Test_code = -1
    Step = nil
end

-- 板卡名称对照表
CARDS_NAME = {
    [0xFF] = "广播地址",
    [0x01] = "主控",
    [0x02] = "仪表校验板卡",
    [0x03] = "防护系统测试板卡1",
    [0x04] = "防护系统测试板卡2",
    [0x05] = "通讯板卡1",
    [0x06] = "通讯板卡2"
}

-- 创建主协议数据
function CreatSendMain(cmd, sa, buffer)
    local main = message(protocol.RECV_MAIN)
    main.BUFFER = buffer
    main.SA = sa
    main.CMD = cmd
    main.DA = 0x01
    return pack(main)
end

-- 创建普通真值的测试结果数据
function CreateTrueData(t_data)
    -- 测试结果子协议和真值对象
    local rd = math.random(1, 10)
    local tcopy = {}
    for k, v in pairs(t_data) do
        tcopy[k] = v
    end
    -- 随机产生一个假值
    if rd % 2 == 0 and MOCKER_ERROR then
        Step = "test_fail"
        local len = 0
        for k, v in pairs(t_data) do
            len = len + 1
        end
        local rd1 = math.random(1, len)

        for k, v in pairs(tcopy) do
            rd1 = rd1 - 1
            if rd1 <= 0 then
                if v == 0 then
                    tcopy[k] = 1
                else
                    tcopy[k] = 0
                end
            end
        end
    else
        Step = "test_ok"
    end
    return tcopy
end

-- 创建回复时间的数据
function CreateTimeReply(recvtime)

    local len = 0
    for k, v in pairs(recvtime) do
        len = len + 1
    end
    local rd = math.random(1, 13)
    local badi = 0
    if rd < 7 and MOCKER_ERROR then
        badi = math.random(1, len)
        Step2 = "test_fail"
    else
        Step2 = "test_ok"
    end

    local res = {}
    local i = 0
    for k, v in pairs(recvtime) do
        i = i + 1
        -- print(i, k, v)
        if i == badi then
            table.insert(res, {[k] = v.time+1})
        else
            table.insert(res, {[k] = v.time})
        end
    end
    return res
end

-- 创建自动回复的测试结果数据
function CreateAutoReply(reply_map)

    local len = 0
    for k, v in pairs(reply_map) do
        len = len + 1
    end
    local rd = math.random(1, 13)
    local badi = 0
    if rd < 7 and MOCKER_ERROR then
        badi = math.random(1, len)
        Step1 = "test_fail"
    else
        Step1 = "test_ok"
    end

    local res = {}
    local i = 0
    for k, v in pairs(reply_map) do
        i = i + 1
        -- print(i, k, v)
        if i ~= badi then
            table.insert(res, {[k] = 1})
        end
    end
    -- print(i, #res)
    return res
end

-- 查找真值
function Find_t_data(test_code)
    for i, v in ipairs(Test_out) do
        if v.device_code == Device_code and v.device_type == Device_type and v.test_code == test_code then
            return v
        end
    end
    log.info("未找到真值定义:" .. Device_type .. "-" .. Device_code .. "(" .. test_code .. ")")
end

-- 回复测试结果
function Test_res(test_code)
    if Step == "test" or Step == "test_ok" or Step == "test_fail" then
        return
    elseif Step == "init" then
        Step = "test"
        local t = Find_t_data(test_code)
        if not t then
            return
        end
        
        local rd = math.random(1, 20)
        if rd == 1 and MOCKER_ERROR then
            log.warn("已模拟测试超时")
            return
        end

        if t.t_data then    -- 普通真值
            local r_data = CreateTrueData(t.t_data)
            local res = message(protocol[t.t_prot], r_data)
            local msg = CreatSendMain(t.t_cmd, t.t_card, pack(res))
            -- 延时一段时间回复测试结果
            delay(500)
            send(device.board1.conn, msg)
            if Step == "test_ok" then
                log.info("测试成功数据已发送")
            else
                log.warn("测试失败数据已发送")
            end
        elseif t.t_reply or t.t_recvtime then   -- 自动回复或者回复时间

            -- 自动回复数据
            if t.t_reply then
                local datas1 = CreateAutoReply(t.t_reply.map)
                for i, v in ipairs(datas1) do
                    local res = message(protocol[t.t_reply.prot], v)
                    local msg = CreatSendMain(t.t_cmd, t.t_reply.card, pack(res))
                    delay(10)   -- 每隔10ms发送一个结果
                    send(device.board1.conn, msg)
                end
                if t.t_reply.result_data then
                    local r_data = CreateTrueData(t.t_reply.result_data)
                    local res = message(protocol[t.t_reply.prot], r_data)
                    local msg = CreatSendMain(t.t_cmd, t.t_reply.card, pack(res))
                    -- 延时一段时间回复测试结果
                    delay(10)
                    send(device.board1.conn, msg)
                end
                delay(100)
            else
                Step1 = 'test_ok'
            end

            -- 回复时间值
            if t.t_recvtime then
                local datas2 = CreateTimeReply(t.t_recvtime)
                for i, v in ipairs(datas2) do
                    local res = message(protocol.recv_time, v)
                    local msg = CreatSendMain(0x32, t.t_card, pack(res))
                    delay(10)   -- 每隔10ms发送一个结果
                    send(device.board1.conn, msg)
                end
                -- print('Step2', Step2)
                delay(100)
            else
                Step2 = 'test_ok'
            end

            if Step1 == "test_ok" and Step2 == 'test_ok' then
                Step = 'test_ok'
                log.info("测试成功数据已发送")
            else
                Step = 'test_fail'
                log.warn("测试失败数据已发送")
            end
        end

        
    else
        log.error("不应该呀！！！")
    end
end

-- 通用的接收总函数
function Recv_data(msg, opt)
    if not CARDS_NAME[msg.DA] then
        log.error("收到指令，但无法识别目标地址：" .. string.format("%02X", msg.DA))
        return
    end
    if msg.CMD == 0x01 then --握手
        Do_hand(msg)
    elseif msg.CMD == 0x02 then --初始化
        Do_init(msg)
    elseif msg.CMD == 0x03 then --AD校准
        Do_ad(msg, protocol.send_check_ad)
    elseif msg.CMD == 0x04 then --DA校准
        Do_da(msg, protocol.send_check_da)
    elseif msg.CMD == 0x30 then -- 控制
        if msg.DA == 0x02 then
            Do_test_iur(msg, protocol.send_nobus)
        elseif msg.DA == 0x03 then
            Do_test(msg, protocol.send_fanghu1)
        elseif msg.DA == 0x04 then
            Do_test(msg, protocol.send_fanghu2)
        else
            log.error(CARDS_NAME[msg.DA] .. "收到无法识别的控制指令")
        end
    elseif msg.CMD == 0x50 then-- 通讯
        if msg.DA == 0x05 then
            Do_test_fanghutx1(msg)
        elseif msg.DA == 0x06 then
            Do_test_fanghutx2(msg)
        else
            log.error(CARDS_NAME[msg.DA] .. "收到无法识别的通信指令")
        end
    else
        log.error(CARDS_NAME[msg.DA] .. "收到无法识别的指令，CMD =", msg.CMD)
    end
end

-- 处理握手指令
function Do_hand(msg)
    print(CARDS_NAME[msg.DA] .. "收到：握手指令(" .. msg.LEN .. ")")

    if Timer_id then
        async.clear(Timer_id)
    end

    -- 保存全局状态数据
    Step = "hand_ok"
    local msg_hand = unpack(protocol.send_hand, msg.BUFFER)
    Device_type = msg_hand.device_type
    Device_code = msg_hand.device_code

    -- 回复主控的握手响应
    local res = 1
    local rd = math.random(1, 20)
    if rd == 1 and MOCKER_ERROR then --模拟自检超时
        log.warn("已模拟握手超时")
        return
    elseif rd == 2 and MOCKER_ERROR then --模拟自检失败
        res = 0
        log.warn("握手失败数据已发送")
    end
    local msg_sub = message(protocol.recv_hand, {result = res})
    local buf_sub = pack(msg_sub)
    async.send(device.board1.conn, CreatSendMain(0x01, 0x02, buf_sub))
    async.send(device.board1.conn, CreatSendMain(0x01, 0x03, buf_sub))
    async.send(device.board1.conn, CreatSendMain(0x01, 0x04, buf_sub))
    async.send(device.board1.conn, CreatSendMain(0x01, 0x05, buf_sub))
    async.send(device.board1.conn, CreatSendMain(0x01, 0x06, buf_sub))
end

-- 处理初始化指令
function Do_init(msg)
    if Step ~= "hand_ok" and Step ~= "init" and Step ~= "test_ok" then
        log.error(CARDS_NAME[msg.DA] .. "收到：错误的初始化指令, Step(" .. (Step or "nil") .. ")")
        return
    end
    Step = "init"
    print(CARDS_NAME[msg.DA] .. "收到：初始化指令(" .. msg.LEN .. ")")

    -- 保存全局状态数据
    local msg_init
    if msg.DA == 0x02 then
        msg_init = unpack(protocol.send_init_nobus, msg.BUFFER)
    elseif msg.DA == 0x03 then
        msg_init = unpack(protocol.send_init_fanghu1, msg.BUFFER)
    elseif msg.DA == 0x04 then
        msg_init = unpack(protocol.send_init_fanghu2, msg.BUFFER)
    else
        log.error(CARDS_NAME[msg.DA] .. "收到：无法识别的控制指令")
    end
    Device_type = msg_init.device_type
    Device_code = msg_init.device_code

    -- 初始化回复
    local res = 1
    local rd = math.random(1, 20)
    if rd == 1 and MOCKER_ERROR then --模拟初始化超时
        log.warn("已模拟初始化超时")
        return
    elseif rd == 2 and MOCKER_ERROR then --模拟初始化失败
        res = 0
        log.warn("初始化失败数据已发送")
    end
    local msg_sub = message(protocol.recv_init, {result = res})
    async.send(device.board1.conn, CreatSendMain(0x02, msg.DA, pack(msg_sub)))
end

-- 回复测试结果
function Do_test(msg, sub_prot)
    if Step ~= "test_ok" and Step ~= "init" and Step ~= "test_fail" and Step ~= "test" then
        log.error(CARDS_NAME[msg.DA] .. "收到：错误的测试指令")
        return
    end

    local sub_msg = unpack(sub_prot, msg.BUFFER)

    -- 结束指令不进行任何处理
    if sub_msg.test_state == 0x02 then
        print(CARDS_NAME[msg.DA] .. "收到：测试结束指令(" .. msg.LEN .. ")")
        return
    elseif sub_msg.test_state ~= 0x01 then
        log.error(CARDS_NAME[msg.DA] .. "收到错误的测试状态")
    end

    print(CARDS_NAME[msg.DA] .. "收到：测试开始指令(" .. msg.LEN .. ")")
    Test_res(sub_msg.test_code)
end

-- ad校准指令
function Do_ad(msg, prot)
    print(CARDS_NAME[msg.DA] .. "收到：AD校准指令(" .. msg.LEN .. ")")

    --解包子协议的数据
    --local sub_msg = unpack(prot, msg.BUFFER)
    local cb = function ()
        local sub = message(protocol.recv_caiji)
        sub.adc_60 = math.random(10,1000)
        async.send(device.board1.conn,CreatSendMain(0x31, msg.DA, pack(sub)))
        print("已发送AD校准数据！")
    end
    async.timeout(1000, cb)
end

-- da校准指令
function Do_da(msg, prot)
    print(CARDS_NAME[msg.DA] .. "收到：DA校准指令(" .. msg.LEN .. ")")

    --解包子协议的数据
    local sub_msg = unpack(prot, msg.BUFFER)
    local cb = function ()
        local sub = message(protocol.recv_caiji)
        sub.adc_60 = math.random(10,1000)
        async.send(device.board1.conn,CreatSendMain(0x31, msg.DA, pack(sub)))
        print("已发送DA校准数据！")
    end
    async.timeout(1000, cb)
end

-- 测试仪表
function Do_test_yibiao(msg)
    print(CARDS_NAME[msg.DA] .. "收到：测试仪表指令(" .. msg.LEN .. ")")
end

-- 测试防护通信1
function Do_test_fanghutx1(msg)
    print(CARDS_NAME[msg.DA] .. "收到：测试？指令(" .. msg.LEN .. ")")
end

-- 测试防护通信2
function Do_test_fanghutx2(msg)
    print(CARDS_NAME[msg.DA] .. "收到：测试？指令(" .. msg.LEN .. ")")
end

function Do_result_r(sub_msg,da)
    local cb = function ()
        local sub = message(protocol.recv_caiji)
        sub.state = 0x02
        sub.dianchineizu = math.random(1, 100)
        async.send(device.board1.conn,CreatSendMain(0x31, da, pack(sub)))
        print("已发送电池内阻采集数据！")
    end
    async.timeout(1000, cb)
end

function Do_result_iu(sub_msg,da)
    local t = Find_t_data(sub_msg.test_code)
    if not t then
        return
    end
    local rcds = Create_data_iu()
    if(t.t_data.boxing_I) then
        local sub = message(protocol[t.t_prot])
        sub.boxing = t.t_data.boxing_I
        sub.data_text = {}
        for i = 1, 100 do
            table.insert(sub.data_text,{time=rcds[i].time,data=rcds[i].I})
        end
        async.send(device.board1.conn,CreatSendMain(0x33, da, pack(sub)))
        print("已发送电流采集数据！")
    end

    if(t.t_data.boxing_U) then
        local sub = message(protocol[t.t_prot])
        sub.boxing = t.t_data.boxing_U
        sub.data_text = {}
        for i = 1, 100 do
            table.insert(sub.data_text,{time=rcds[i].time,data=rcds[i].U})
        end
        async.send(device.board1.conn,CreatSendMain(0x33, da, pack(sub)))
        print("已发送电压采集数据！")
    end
    
end

function Create_data_iu()
    local t = now("us")
    local rcds = {}
    for i = 1, 100 do
        local d
        local plus = math.random(1, 3)
        if plus == 1 then
            d = 8
        elseif plus == 2 then
            d = 5
        elseif plus == 3 then
            d = 3
        end
        I = (I or math.random(1, 100)) + (math.random(1,10)-d) * (Sca1 or 1)
        if I < 0 then
            I = 0
        end
        U = (U or math.random(1, 240)) + (math.random(1,10)-d) * (Sca2 or 1)
        t = t + 1000 * IU_TICK
        table.insert(rcds, {I = I, U = U, time = t})
    end

    if I > 300 then
        Sca1 = -1
    elseif I < 10 then
        Sca1 = 1
    end

    if U > 300 then
        Sca2 = -1
    elseif U < -300 then
        Sca2 = 1
    end

    return rcds
        
end


function Do_test_iur(msg, prot)

    if Device_type == 0x01 then
        return
    end

    --解包子协议的数据
    local sub_msg = unpack(prot, msg.BUFFER)
    if sub_msg.test_state == 0x01 then
        if sub_msg.dianzu_check == 0x01 or sub_msg.dianzu_check == 0x02 then
            return Do_result_r(sub_msg, msg.DA)
        else
            Timer_id = async.interval(100, 100*IU_TICK, Do_result_iu, sub_msg, msg.DA)            
        end
    elseif sub_msg.test_state == 0x02 then
        print(CARDS_NAME[msg.DA] .. "收到：测试结束指令(" .. msg.LEN .. ")")
        if Timer_id then
            async.clear(Timer_id)
        end
    else
        log.error(CARDS_NAME[msg.DA] .. "收到错误的测试状态")
    end
end