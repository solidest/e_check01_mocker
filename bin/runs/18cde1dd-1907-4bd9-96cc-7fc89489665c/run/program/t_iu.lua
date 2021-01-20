DEBUG = true    -- 开启调试模式
SKIP_TIP = true -- 跳过用户提示

local helper = require "Helper"
local hand = require "Hand"
local init = require "Initial"
local tester = require "Tester"
local vs = nil
-- 电流电压测试 2-1-1
function entry(vars, option)
    vs = vars
    log.step(vars.test_name)

    -- 数据接收处理函数
    local recv_data = function(msg, opt)
        -- 调试模式打印日志
        if DEBUG then
            helper.print_recv(msg, opt)
        end

        -- 收到握手回复
        if msg.CMD == 0x01 then
            if hand.handle(vars, msg) == 'ok' then
                init.start(vars)
            end

        -- 收到初始化回复
        elseif msg.CMD == 0x02 then 
            if init.handle(vars, msg) == 'ok' then
                tester.start_normal(vars)
            end
            -- 收到测试结果回复
        elseif msg.CMD == vars.result_cmd and msg.SA == vars.result_card then
           tester.handle_iu(vars, msg, option)
        end
    end

    -- 订阅数据接收事件
    async.on_recv(device.main_ctr.conn, protocol.RECV_MAIN, recv_data)

    -- 启动握手
    hand.start(vars)

end


function Stop()
    helper.do_exit(vs,true)
end

