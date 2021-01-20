
local helper = require "Helper"
local this = { }
local res = nil


-- 开始握手
this.start = function(vars)

    if this.timer then
        async.clear(this.timer)
        this.timer = nil
    end

    res = 'waiting'

    -- 发送握手
    local send_count = 0
    local send_hand = function()
        send_count = send_count + 1
        if send_count>3 then
            async.clear(this.timer)
            this.timer = nil
            local cards = vars.cards
            -- 检查cards中的每一块板卡，输出握手失败的板卡
            for i, v in ipairs(cards) do
                if not v.hand_ok then
                    log.check(helper.CARDS_NAME[v.card] .. "握手响应超时", false)
                end
            end
            helper.do_exit(vars, false)
        else
            -- 发送握手指令
            local msg = message(protocol.send_hand)
            msg.device_type = vars.device_type
            msg.device_code = vars.device_code
            async.send(device.main_ctr.conn, helper.creat_main(0x01, 0xFF, pack(msg)))
        end
    end

    this.timer = async.interval(0, vars.timeout_hand, send_hand)

end

-- 处理握手回复
this.handle = function(vars, main)
    if res ~= 'waiting' then
        return nil
    end

    local cards = vars.cards
    local band_data = unpack(protocol.recv_hand, main.BUFFER)
    if band_data.result == 1 then
        local all_ok = true
        for i, v in ipairs(cards) do
            if v.card == main.SA then
                v.hand_ok = true
            end
            if not v.hand_ok then
                all_ok = false
            end
        end
        if all_ok then
            -- 握手成功
            log.check("检测设备自检成功", true)
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
                log.check(helper.CARDS_NAME[v.card] .. "自检失败", false)
                helper.do_exit(vars, false)
            end
        end
    end

    return res
end

return this