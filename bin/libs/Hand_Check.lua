
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

    -- 发送握手指令
    local msg = message(protocol.send_hand)
    local main = helper.creat_main(0x01, 0xFF, pack(msg))
    print('SendCheckSelf')
    async.send(device.main_ctr.conn, main)


    -- 握手超时处理函数
    local tout = function()
        local cards = vars.cards

        -- 检查cards中的每一块板卡，输出握手失败的板卡
        for i, v in ipairs(cards) do
            if not v.hand_ok then
                log.check(helper.CARDS_NAME[v.card] .. "握手响应超时", false)
            end
        end
        helper.do_exit(vars, false)
    end

    -- 启动超时定时器
    this.timer = async.timeout(vars.timeout_hand, tout)

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
                if v.card == 2 then
                    record.nobus = 1
                elseif v.card == 3 then
                    record.fanghu1 = 1
                elseif v.card == 4  then
                    record.fanghu2 = 1
                elseif v.card == 5 then
                    record.tongxun1 = 1
                elseif v.card == 6 then
                    record.tongxun2 = 1
                elseif v.card == 7 then
                    record.zongdian = 1
                end
                v.hand_ok = true

            end

            if not v.hand_ok then
                all_ok = false
            end
        end
        if all_ok then
            -- 握手成功
            log.check("检测设备自检成功", true)
            exit()
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