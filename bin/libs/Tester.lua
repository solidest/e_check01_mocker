

local helper = require "Helper"
local msgs = require "Message"
local rcd = require "Record"
local this = { }
local res = nil
local err_keys = nil    -- 测试结果出错的keys
local bak_step = nil
local FOUR_MS = 400
local Start_time = nil --延时接收数据开始时间
local End_time = nil --延时接收数据结束时间
local time_id = nil
local Hand_time = nil


-- 开始普通测试
this.start_normal = function(vars)
    if this.timer then
        async.clear(this.timer)
        this.timer = nil
    end

    res = 'testing'

    -- 操作提示
    if vars.look_test then
        local answer = ask('yesno',  {title=vars.look_test, msg='请回答yes或no', default=true})
        if not answer then
            log.check(vars.test_name .. '测试失败', false)
            exit()
        end
    end
    if vars.strtip_test and not SKIP_TIP then
        ask("ok", {title = "检测准备测试项", msg = vars.strtip_test})
    elseif vars.test_user and not SKIP_TIP then
        for i, v in ipairs(vars.test_user.items) do
            v.readonly = true
        end
        ask("multiswitch", vars.test_user)
    end

    -- 当存在测试超时时间就启动定时器
    if vars.timeout_test then
        -- 测试超时处理函数
        local tout = function()
            -- log.check(vars.test_name .. "检测失败", false)
            -- helper.do_exit(vars, true)
            math.randomseed(os.time())
            record.R1 = "线缆连接异常或电池异常"
            this.stop(vars, 'fail', true)
        end

        -- 启动超时定时器
        this.timer = async.timeout(vars.timeout_test, tout)
    end

    Start_time = now()
    -- 发送测试中指令
    local cards = vars.cards
    for k, v in ipairs(cards) do
        local msg = msgs.new_msg(v.test_prot, v.test_data) --message(protocol[v.test_prot], v.test_data)
        msg.device_type = nil
        msg.device_code = nil
        msg.test_code = vars.test_code
        msg.test_state = 0x01
        async.send(device.main_ctr.conn, helper.creat_main(0x30, v.card, pack(msg)))
        msgs.set_msg(v.test_prot, msg)
        rcd.record_send(vars, msg, v.test_prot)
        delay(40)
    end

end

-- 开始仪表测试
this.start_meter = function (vars)
    local meter = vars.meter
    local cards = vars.cards
    local all_ok = true
    for i, v in ipairs(meter.test_data) do
        log.step('第' .. i .. '组数据')
        log.doing('正在测试')
        local msg = message(protocol[meter.test_prot], meter.test_data_main or {})
        msg.test_code = vars.test_code
        msg.test_state = 0x01
        if meter.test_seg then
            msg[meter.test_seg] = v.value
        end
        if meter.test_seg1 then
            msg[meter.test_seg1] = v.value1
        end
        async.send(device.main_ctr.conn, helper.creat_main(0x30, cards[1].card, pack(msg)))
        rcd.record_send(vars, msg, meter.test_prot)
        delay(500)
        local res = ask('number', {
            title='请输入', 
            msg='输入' .. meter.name .. '上显示的数值',
            default = v.input,
            min = meter.result_min, 
            max = meter.result_max, 
            fixed = meter.result_fixed,
            option = meter.option,
        });
        res = tonumber(res)
        local d = res - v.input
        local ok
        if v.diff_down then
            local v_down = v.input + v.diff_down
            local v_up = v.input +v.diff_up
            ok = (res > v_down) and (res < v_up)
            if (math.abs(res - v_down) < 0.0001) or (math.abs(res - v_up) < 0.0001) then
                ok = true
            end
        else 
            ok = (math.abs(d) <= math.abs(v.diff*v.input))
        end
        record.x = v.input
        record.y = res
        record.ok = ok
        record.d = ((d > 0) and '+' or '-') .. math.abs(d)
        if ok then
            log.check('测试通过', true)
        else
            log.check('测试失败', false)
            all_ok = false
        end
        delay(100)
    end

    return all_ok and 'ok' or 'fail'
end

--单次无序测试 单次有序测试
this.start_steps = function (vars)
 
    -- 发送测试数据
    this.start_normal(vars)

    if vars.is_order then
        delay(500)
    end

    -- 发送置低的数据
    -- local msg = message(protocol[vars.test_prot])
    -- for key, value in pairs(vars.test_after) do
    --     msg[key] = value
    -- end
    local msg = msgs.update_msg(vars.test_prot, vars.test_after)
    msg.test_code = vars.test_code
    msg.test_state = 0x01
    async.send(device.main_ctr.conn, helper.creat_main(0x30, vars.test_card, pack(msg)))
    msgs.set_msg(vars.test_prot, msg)
    rcd.record_send(vars, msg, vars.test_prot)
end

-- 开始can协议测试
this.start_can = function(vars)
    if this.timer then
        async.clear(this.timer)
        this.timer = nil
    end

    res = 'testing'
    Start_time = now()
    -- 操作提示
    if vars.strtip_test and not SKIP_TIP then
        ask("ok", {title = "检测准备测试项", msg = vars.strtip_test})
    elseif vars.test_user and not SKIP_TIP then
        for i, v in ipairs(vars.test_user.items) do
            v.readonly = true
        end
        ask("multiswitch", vars.test_user)
    end

    -- 当存在测试超时时间就启动定时器
    if vars.timeout_test then
        -- 测试超时处理函数
        local tout = function()
            -- log.check(vars.test_name .. "检测失败", false)
            this.stop(vars, 'fail', true)
        end

        -- 启动超时定时器
        this.timer = async.timeout(vars.timeout_test, tout)
    end

    -- 发送测试中指令
    local cards = vars.cards
    for k, v in ipairs(cards) do
        local msg = msgs.new_msg(v.test_prot, v.test_data) --message(protocol[v.test_prot], v.test_data)
        msg.device_type = nil
        msg.device_code = nil
        msg.test_code = vars.test_code
        msg.test_state = 0x01
        print('v.test_data = ', v.test_data, 'msg = ', msg)
        async.send(device.main_ctr.conn, helper.creat_main(0x30, v.card, pack(msg)))
        msgs.set_msg(v.test_prot, msg)
        rcd.record_send(vars, msg, v.test_prot)
        -- 如果引脚置高，直接设置对应接收信号为高
        if vars.special then
            for key, value in pairs(vars.special) do
                if msg[key] == value.when then
                    value.hook = true
                end
            end
        end
        delay(40)
    end

    local can_cards = vars.can
    if can_cards then
        local send_can = function(info)
            for k, v in ipairs(info) do
                local msg = message(protocol[can_cards[1].test_prot], v)
                if can_cards[1].data_change then
                    msg.data[1] = (os.time())%255
                end
                async.send(device.main_ctr.conn, helper.creat_main(0x50, can_cards[1].card, pack(msg)))
                delay(40)
            end
        end
        if can_cards[1].send_count then
            for i=1, can_cards[1].send_count do
                send_can(can_cards[1].test_data)
                delay(100)
            end
        else
            time_id = async.interval(40, 1000, send_can, can_cards[1].test_data)
        end
    end
end


this.can_steps = function (vars)
 
    -- 发送测试数据
    this.start_can(vars)

    if vars.is_order then
        delay(500)
    end

    -- 发送置低的数据
    -- local msg = message(protocol[vars.test_prot])
    -- for key, value in pairs(vars.test_after) do
    --     msg[key] = value
    -- end
    local send_can = function(info)
        for k, v in ipairs(info.test_after) do
            local msg = message(protocol[info.test_prot], v)
            async.send(device.main_ctr.conn, helper.creat_main(0x50, info.test_card, pack(msg)))
            delay(500)
        end
    end
    time_id = async.interval(40, 4100, send_can, vars)

end

this.add_err = function (err)
    err_keys = err
    -- table.insert(err_keys, pin)
end

-- 测试结束
this.stop = function (vars, res, need_send_stop)
    if bak_step then
        log.step(bak_step)
    end
    if time_id then
        async.clear(time_id)
        time_id = nil
    end
    if Start_time then
        Start_time = nil
    end
    if Hand_time then
        Hand_time = nil
    end
    if End_time then
        End_time = nil
    end
    if res == 'ok' then
        log.check(vars.test_name .. "检测通过", true)
    elseif res == 'fail' then
        if err_keys then
            log.check('故障位置: ' .. helper.list2str(vars, err_keys), false)
        else
            log.check(vars.test_name .. '检测失败', false)
        end
    end
    helper.do_exit(vars, need_send_stop)
end

-- 普通真值结果判定
this.handle_data = function (vars, main)
    if res ~= 'testing' then
        return nil
    end
    End_time = now("ms")
    if not Start_time then
        Start_time = 0
    end
    if End_time - Start_time > 1000 then
        local msg = unpack(protocol[vars.result_prot], main.BUFFER)
        msgs.set_msg(vars.result_prot, msg)
        rcd.record_recv(vars, msg, vars.result_prot)
        -- record.message.result_data = msg
        local err = {}
        for k, v in pairs(vars.result_data) do
            if msg[k] ~= v then
                print("k =", k, "v =", msg[k], ":", v)
                table.insert(err, k)
            end
        end
        if #err > 0 then
            err_keys = err
            return 'fail'
        end
        return 'ok'
    end
end

-- 自动回复
this.handle_reply = function (vars, main)
    if res ~= 'testing' then
        return nil
    end
    Hand_time = now()
    if not Start_time then
        Start_time = 0
    end
    if Hand_time - Start_time > 1000 then 
        local msg = unpack(protocol[vars.result_prot], main.BUFFER)
        if vars.special then
            for key, value in pairs(vars.special) do
                if value.hook == true then
                    print(vars.special)
                    msg[value.then_1] = 1
                end
            end
        end
        msgs.set_msg(vars.result_prot, msg)
        rcd.record_recv(vars, msg, vars.result_prot)
        local all_ok = true


        -- 自动回复
        local rp = vars.result_reply
        for k, v in pairs(rp.map) do
            if not v.ok then
                -- 收到需要自动回复的标记
                if msg[k] == 1 then
                    -- local reply_msg = message(protocol[rp.prot], v)
                    local reply_msg = msgs.update_msg(rp.prot, v)
                    reply_msg.device_type = nil
                    reply_msg.device_code = nil
                    reply_msg.test_code = vars.test_code
                    reply_msg.test_state = 0x01
                    async.send(device.main_ctr.conn, helper.creat_main(0x30, rp.card, pack(reply_msg)))
                    msgs.set_msg(rp.prot, reply_msg)
                    rcd.record_send(vars, reply_msg, rp.prot)
                    print("已回复给" .. helper.CARDS_NAME[rp.card])
                    v.ok = true
                else
                    all_ok = false
                end
            end
        end

        --真值判定
        local rd = rp.result_data
        local err = {}
        if rd and not rd.ok then
            rd.ok = true
            for k, v in pairs(rd) do
                if k ~= 'ok' then
                    if msg[k] ~= v then

                        rd.ok = false
                        table.insert(err, k)
                    else
                        print('k', k, v, msg[k])
                    end
                end
            end
        end
        if #err > 0 then
            err_keys = err
        end
        if not rd then
            rd = { ok = true }
        end
        if all_ok and rd.ok then
            err_keys = nil
        end
        local res = ((all_ok and rd.ok) and 'ok' or 'fail')
        main.BUFFER = nil
        return res
    end
end

-- 结果变量，用来保存结果验证
-- 这个变量定义在函数体外面
local g_result = {} 

-- 判断预期结果vs和接收到的消息msg是否吻合, 如果全部吻合返回 'ok', 否则返回nil
-- 该函数可以被多次调用
this.handle_result = function (msg, vs)
    for k, v in pairs(vs) do
        if msg[k] == vs[k] then
            g_result[k] = true
        end
    end
    --判断是否所有的预期结果都已经接收过吻合的值，只要有一个不吻合就返回nil
    local err = {}
    for k, v in pairs(vs) do
        if not g_result[k] then
            table.insert(err, k)
            -- return nil
        end
    end
    if #err > 0 then
        err_keys = err
        return nil
    end
    err_keys = nil
    return 'ok'
end

-- 收到0自动回复
this.handle_reply_0 = function (vars, main)
    if res ~= 'testing' then
        return nil
    end
    Hand_time = now()
    if not Start_time then
        Start_time = 0
    end
    if Hand_time - Start_time > 1000 then 
        local msg = unpack(protocol[vars.result_prot], main.BUFFER)
        msgs.set_msg(vars.result_prot, msg)
        rcd.record_recv(vars, msg, vars.result_prot)
        local all_ok = true

        -- 自动回复
        local rp = vars.result_reply
        for k, v in pairs(rp.map) do
            if not v.ok then
                -- 收到需要自动回复的标记
                if msg[k] == 0 then
                    -- local reply_msg = message(protocol[rp.prot], v)
                    local reply_msg = msgs.update_msg(rp.prot, v)
                    print('k = ', k, 'v = ', v, 'reply_msg = ', reply_msg)
                    reply_msg.device_type = nil
                    reply_msg.device_code = nil
                    reply_msg.test_code = vars.test_code
                    reply_msg.test_state = 0x01
                    async.send(device.main_ctr.conn, helper.creat_main(0x30, rp.card, pack(reply_msg)))
                    msgs.set_msg(rp.prot, reply_msg)
                    rcd.record_send(vars, reply_msg, rp.prot)
                    print("已回复给" .. helper.CARDS_NAME[rp.card])
                    v.ok = true
                else
                    all_ok = false
                end
            end
        end
        
        --真值判定
        local rd_ok = true
        if rp.result_data then
            rd_ok = this.handle_result(msg,rp.result_data)
        else
            rd_ok = true
        end
        local res = ((all_ok and rd_ok) and 'ok' or 'fail')
        main.BUFFER = nil
        return res
    end
end

-- 时间结果判定
this.handle_time = function (vars, main)
    if res ~= 'testing' then
        return nil
    end

    local msg = unpack(protocol.recv_time, main.BUFFER)
    rcd.record_recv(vars, msg, 'recv_time')
    local result_recvtime = vars.result_recvtime

    for k, v in pairs(result_recvtime) do
        local t = msg[k]
        if t ~= 0 then
            local ls = vars.labels or {}
            local n = ls[k] or k
            bak_step = vars.test_name
            local diff = t - v.time
            log.step(n .. (diff > 0 and '超时' or '完成'))
            local tip = diff > 0 and (' (超标' .. diff .. 'ms)') or ''
            log.check(t .. ' ms' .. tip, true)
            v.res = (t > v.time and 'fail' or 'ok')
            -- if  t > v.time then
            --     print('t0 =', t, ' t1 =', v.time)
            --     log.check(vars.test_name .. "检测时间超过标准值", false)
            --     v.res = 'fail'
            -- else
            --     v.res = 'ok'
            -- end
        end
    end

    -- 检查结果
    local all_ok = true
    local all = true
    for k, v in pairs(result_recvtime) do
        if not v.res then
            all = false
        end
        if v.res ~= 'ok' then
            all_ok = false
        end
    end

    -- 返回结果
    if all then
        return all_ok and 'ok' or 'fail'
    else
        return 'testing'
    end
end

IU_TICK = 2  -- 电流电压采集周期ms
IU_TIME = 0  -- 时间戳    
this.handle_iu = function (vars, main, opt)
    if res ~= 'testing' then
        return nil
    end

    local msg = unpack(protocol[vars.result_prot],main.BUFFER)

    if opt and opt.is_onlyone then
         local v = msg.data_text[1]
        insert({ time = IU_TIME, I = (v.data_i / 10), U = (v.data_u / 100) })
    else
        for i, v in ipairs(msg.data_text) do
            insert({ time = IU_TIME, I = (v.data_i / 10), U = (v.data_u / 100)  })
            IU_TIME = IU_TIME + IU_TICK
        end
    end
end

-- R结果记录
this.handle_r = function (vars, main)
    if res ~= 'testing' then
        return nil
    end
    local msg = unpack(protocol[vars.result_prot],main.BUFFER)
    -- rcd.record_recv(vars, msg, vars.result_prot)
    print('内阻结果：', msg.state, msg.dianchineizu, msg.dianchi_v);
    if msg.state == 0x02 then
        if msg.dianchineizu >= 5000 then
            record.R1 = string.format('%dmΩ，内阻异常',msg.dianchineizu/100)
        elseif msg.dianchineizu == 0 then
            record.R1 = "线缆连接异常或电池异常"
        else
            record.R1 = msg.dianchineizu/100
            record.R2 = msg.dianchi_v/100
        end
        delay(200)
        helper.do_exit(vars, true)
    elseif msg.state == 0x03 then
        record.R1 = '电池夹连接异常'
        helper.do_exit(vars, true)
    end
end


-- 处理用户判定的测试
this.handle_user = function(vars)
    -- print(res)
    -- if res ~= 'testing' or res ~= 'over' then
    --     print("res",987)
    --     return
    -- end
    if this.timer then
        async.clear(this.timer)
        this.timer = nil
    end

    local result_user = vars.result_user
    local rs = ask("multiswitch", result_user)
    local all_ok = true
    for i, t in ipairs(result_user.items) do
        if t.on then
            if not helper.contains(rs, t.value) then
                print(t.name .. ' 结果错误')
                all_ok = false
                break
            end
        else
            if helper.contains(rs, t.value) then
                print(t.name .. ' 结果错误')
                all_ok = false
                break
            end
        end
    end

    return (all_ok and 'ok' or 'fail')
end

-- res普通结果记录
this.handle_res = function (vars, main)
    if res ~= 'testing' then
        return nil
    end
    local msg = unpack(protocol[vars.result_prot], main.BUFFER)
    rcd.record_recv(vars, msg, vars.result_prot)
end

--设置结束标记
this.handle_over = function ()
    res = 'over'
end

return this


