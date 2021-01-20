
local rcd = require "Record"
local helper = require "Helper"
local this = { }
local res = nil


-- 开始初始化
this.start = function(vars)

    if this.timer then
        async.clear(this.timer)
        this.timer = nil
    end
    res = 'waiting'
    local send_count = 0
    local send_init = function()
        send_count = send_count + 1
        if send_count>3 then
            async.clear(this.timer)
            this.timer = nil
            local cards = vars.cards
            -- 检查cards中的每一块板卡，输出握手失败的板卡
            for i, v in ipairs(cards) do
                if not v.init_ok then
                    log.check(helper.CARDS_NAME[v.card] .. "初始化响应超时", false)
                end
            end
            helper.do_exit(vars, false)
        else
            -- 发送初始化指令
            local cards = vars.cards
            for k, v in ipairs(cards) do
                if not v.init_ok then
                    local msg = message(protocol[v.init_prot], v.init_data)
                    msg.device_type = vars.device_type
                    msg.device_code = vars.device_code
                    msg.test_code = vars.test_code
                    async.send(device.main_ctr.conn, helper.creat_main(0x02, v.card, pack(msg))) 
                    rcd.record_send(vars, msg, v.test_prot)
                    -- 如果引脚置高，直接设置对应接收信号为高
                    if vars.special then
                        for key, value in pairs(vars.special) do
                            if msg[key] == value.when then
                                record['recv_' .. value.then_1] = 1
                                value.hook = true
                            end
                        end
                    end
                    delay(40)
                end
            end
        end
    end
    this.timer = async.interval(0, vars.timeout_init, send_init)
end


-- 处理测试初始化
this.handle = function(vars, main)
    if res ~= 'waiting' then
        return nil
    end

    local cards = vars.cards
    local band_data = unpack(protocol.recv_init, main.BUFFER)
    if band_data.result == 1 then
        local all_ok = true
        for i, v in ipairs(cards) do
            if v.card == main.SA then
                v.init_ok = true
            end
            if not v.init_ok then
                all_ok = false
            end
        end
        if all_ok then
            log.check("被测设备初始化成功", true)
            if this.timer then
                async.clear(this.timer)
                this.timer = nil
            end
            res = 'ok'
        end
    else
        for i, v in ipairs(cards) do
            if v.card == main.SA then
                res = 'fail'
                log.check(helper.CARDS_NAME[v.card] .. "初始化失败", false)
                helper.do_exit(vars, false)
                -- 同测试初始化超时一致
            end
        end
    end
    return res
end

-- 初始化配置CAN波特率
this.can_init = function(vars)
    -- 发送一帧配置波特率的CAN帧
    if vars.can_init then
        for k,v in pairs(vars.can_init) do
            local msg_can = message(protocol[v.init_prot], v.init_data)
            print(msg_can, v)
            async.send(device.main_ctr.conn, helper.creat_main(0x50, v.card, pack(msg_can)))
            delay(40)
        end
    end
end

return this