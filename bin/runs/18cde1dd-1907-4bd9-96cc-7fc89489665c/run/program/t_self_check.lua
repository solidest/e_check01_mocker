
DEBUG = true    -- 开启调试模式
SKIP_TIP = true -- 跳过用户提示

local helper = require "Helper"
local hand = require "Hand_Check"
local init = require "Initial"
local rcd = require "Record"

local is_initial = nil
local vs = nil

function entry(vars, option)  
    vs = vars
    log.step('开始设备自检')
    -- 订阅接收模拟数据
    -- 数据接收处理函数
    local recv_data = function(msg, opt)
        -- 调试模式打印日志
        if DEBUG then
            helper.print_recv(msg, opt)
        end
        -- 收到握手回复
        if msg.CMD == 0x01 then
            hand.handle(vars, msg) 
        end
    end
    -- 订阅数据接收事件
    async.on_recv(device.main_ctr.conn, protocol.RECV_MAIN, recv_data)

    -- 启动握手
    hand.start(vars)
end