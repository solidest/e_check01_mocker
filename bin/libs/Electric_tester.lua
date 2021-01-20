
local helper = require "Helper"
local this = { dog = 0, }

-- 状态机
local state = nil

this._clear_timer = function ()
    if this.timer then
        async.clear(this.timer)
        this.timer = nil
    end
end

-- 解析上报的子协议，并返回msg、type
-- 报文类型: tick_reply心跳、init_reply初始化回复、stop_reply停止指令回复、uart_reply串口测试回复、unkown_reply未知回复
this.parse_sub = function (buff)
    print('recved', string.buff2hex(buff))
    local msg = unpack(protocol.recv_total, buff)
    local sub_type
    if (not msg) then
        sub_type = nil
    elseif msg.function_type == 250 then
        sub_type = 'tick_reply'
    elseif msg.function_type == 251 then
        sub_type = 'init_reply'
    elseif msg.function_type == 252 then
        sub_type = 'stop_reply'
    --总线通信
    elseif msg.function_type == 1 then
        if msg.test_code == 3 then  --串口
            sub_type = 'uart_reply'
        elseif msg.test_code == 2 then  --CAN
            sub_type = 'can_reply'
        elseif msg.test_code == 4 then  --Len
            sub_type = 'lan_reply'
        elseif msg.test_code == 1 then  --MIC
            sub_type = 'mic_reply'
        else
            sub_type = 'unkown_reply'
        end
    elseif (msg.function_type == 2 and msg.test_code == 101) or (msg.function_type == 2 and  msg.test_code == 102) or (msg.function_type == 2 and  msg.test_code == 103) then
        sub_type = 'kaiche_reply'
    --信号采集
    elseif msg.function_type == 2 or msg.function_type == 3 or msg.function_type == 5 then
        sub_type = 'signal_reply'
    end
    return msg, sub_type
end

-- 启动心跳
this.start_tick = function (vars)
    if this.ticker then
        return
    end
    local send_tick = function()
        local msg = message(protocol.start_electric)
        msg.device_type = vars.device_type
        msg.function_type = 250
        msg.test_code = vars.test_code
        msg.test_code_child = vars.test_code_child
        print("fasongxintiao = ",string.buff2hex(helper.creat_main(vars.result_cmd, vars.card, pack(msg))))
        async.send(device.main_ctr.conn, helper.creat_main(vars.result_cmd, vars.card, pack(msg)))
        this.dog = this.dog + 1
        if this.dog > 3 then
            log.error('综电测试单元不在线')
        end
    end
    this.ticker = async.interval(0, 1000, send_tick)
end

-- 处理心跳回复
this.handle_tick = function (vars, submsg)
    -- print('handle_tick')

    this.dog = 0
    if state ~= nil then
        return state
    end

    -- 心跳状态一致时开始初始化
    if submsg.device_type == vars.device_type then
        state = 'tick_ok'
    end
    return state
end

-- 发送初始化指令
this.send_init = function (vars)

    if state ~= nil then
        return
    end

    this._clear_timer()
    local tout = function()
        log.check(helper.CARDS_NAME[vars.card] .. "初始化响应超时", false)
        exit()
    end

    -- 启动超时定时器
    this.timer = async.timeout(vars.timeout_init, tout)
    state = 'waiting_init'
    local start_msg = message(protocol.start_electric, {
        function_type = 251,
        device_type = vars.device_type,
        test_code = vars.test_code,
        test_code_child = vars.test_code_child,
        other = vars.other or 0,
    })
    print('send_init', string.buff2hex( pack(start_msg)))
    async.send(device.main_ctr.conn, helper.creat_main(vars.result_cmd, vars.card, pack(start_msg)))
end

-- 处理初始化回复指令
this.handle_init = function (vars, submsg)
    -- print('handle_init')
    if state ~= 'waiting_init' then
        return
    end

    this._clear_timer()
    if submsg.test_code == 1 then
        state = 'init_ok'
        record.init_state = 'ok'
    else
        log.error("初始化失败")
        this.do_stop(vars, true)
        state = 'init_fail'
    end
    return state
end

-- 执行测试结束 is_exit:是否退出程序
this.do_stop = function (vars, is_exit)
    this._clear_timer()
    local end_msg = message(protocol.start_electric, {function_type = 252, device_type=vars.device_type })
    async.send(device.main_ctr.conn, helper.creat_main(vars.result_cmd, 0x07, pack(end_msg)))

    if is_exit then
        exit()
    end
end







--------------------------------------------------------------------------------------------------------------------------------

-- -- 综电回复数据处理函数
-- this.handle_recv = function (vars, main)
--     if state == 'waiting_init' then
--         local recv_msg = unpack(protocol[vars.init_prot], main.BUFFER)
--         if recv_msg then
--             if recv_msg.function_type == 251 then   --初始化回复
--                 this._clear_timer()
--                 if recv_msg.test_code == 1 then
--                     state = 'init_ok'
--                     record.init_state = 'ok'
--                 else
--                     log.error("初始化失败")
--                     this.do_stop(vars, true)
--                     state = 'init_fail'
--                 end
--             elseif recv_msg.function_type == 250 then   --心跳数据包
--                 print('收到心跳数据包')
--             end
--         end
--     elseif state == 'waiting_uart_open' or res == 'waiting_uart_close' then
--         local recv_msg = unpack(protocol.recv_total, main.BUFFER)
--         print("recv = ", string.buff2hex(main.BUFFER))
--         if recv_msg.function_type ==3 and recv_msg.other == 1 then
--             if state == 'waiting_uart_open' then
--                 record.open_uart = {result='ok', text='测试通过'}
--             elseif state == 'waiting_uart_close' then
--                 record.close_uart = {result='ok', text='测试通过'}
--             end
--             state = 'uart_ok'
--         else
--             if state == 'waiting_uart_open' then
--                 record.open_uart = {result='error', text='测试失败'}
--             elseif state == 'waiting_uart_close' then
--                 record.close_uart = {result='error', text='测试失败'}
--             end
--             state = 'uart_fail'
--         end
--         --TODO 串口测试结果判读与记录
--     elseif state == 'test_waiting' then
--         local status_msg = unpack(protocol.recv_total, main.BUFFER)
--         if status_msg then
--         end
--     end
-- end

-- -- 综电测试结果上报处理函数
-- this.test_recv = function (vars, main)
--     if state ~= "test_waiting" then
--         return
--     end
--     print(string.buff2hex(main.BUFFER))

--     local recv_msg = unpack(protocol.recv_total, main.BUFFER)
--     if recv_msg.other == 1 then
--         record.data = {result='ok', text='测试通过'}
--         return "ok"
--     elseif recv_msg.other == 2 then
--         record.data = {result='error', text='测试失败'}
--         return "fail"
--     end
-- end

-- -- 开始综电系统测试发送指令
-- this.status_test = function (vars)
--     -- 操作提示
--     if vars.strtip_test then
--         ask("ok", {title = "检测准备测试项", msg = vars.strtip_test})
--     end
--     vars.strtip_test = vars.info
--     state = 'test_waiting'

--     if vars.timeout_test then
--         this._clear_timer()
--         local tout = function()
--             log.check(helper.CARDS_NAME[vars.card] .. "测试失败", false)
--             exit()
--         end
--         this.timer = async.timeout(vars.timeout_test, tout)
--     end

--     local test_msg = msgs.new_msg(vars.test_prot, vars.test_data)
--     async.send(device.main_ctr.conn, helper.creat_main(vars.result_cmd, vars.card, pack(test_msg)))
-- end



return this