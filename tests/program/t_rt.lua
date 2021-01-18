
local helper = require 'helper'

local test = {

    rt_udp = function ()
        local len = 0
        local max_recv_diff = 0
        local max_send_diff = 0
        local t1, t2, t3, t4
        local buff = string.hex2buff('aa bb cc 00 ff ef ff 11 aa bb cc 00 ff ef ff 11 aa bb cc 00 ff ef ff 11')

        async.on_recv(device.udp2_.conn1, nil,
            function (buf)
                -- assert(buf == buff)
                if t3 == nil then
                    t3 = now('us')
                else
                    t4 = now('us')
                    local diff = (t4 - t3) - len*1000
                    record.recv_diff = diff
                    if math.abs(diff) > max_recv_diff then
                        max_recv_diff = math.abs(diff)
                    end
                    record.len = len
                    t3 = now('us')
                end
            end
        )

        local ticker = function (buff)
            send(device.udp1_.conn1, buff)
            if t1 == nil then
                t1 = now('us')
            else
                t2 = now('us')
                local diff = (t2 - t1) - len*1000
                record.send_diff = diff
                if math.abs(diff) > max_send_diff then
                    max_send_diff = math.abs(diff)
                end
                record.len = len
                t1 = now('us')
            end

        end


        local lens = { 1, 10, 100, 200, 300 }
        for i, l in ipairs(lens) do
            len = l
            t1 = nil
            t3 = nil
            local timer = async.interval(l, l, ticker, buff)
            delay(l * 10)
            async.clear(timer)
            delay(400)
        end

        print('发送调度最大误差 =', max_send_diff .. 'us')
        print('接收事件最大误差 =', max_recv_diff .. 'us')

    end,

    rt_serial = function ()
        local b_break = true
        local count = 0
        local send = 0
        local max_diff = 0
        local t1

        async.on_recv(device.dev2_.conn1, nil,
            function (buf)
                count = count + #buf
            end
        )

        -- local ticker = function ()
        --     if t1 == nil then
        --         t1 = now('us')
        --     else 
        --         local t2 = now('us')
        --         local diff = math.abs(t2-t1-1000)
        --         if diff > max_diff then
        --             max_diff = diff
        --         end
        --         t1 = t2
        --     end
        --     ioctl(device.dev1_.conn1, 'SetBreak', {value = b_break})
        --     if b_break then
        --         send = send + 1
        --     end
        --     b_break = not b_break
        -- end

        local buf = string.hex2buff('11 22 33 44 55 66 77 88')
        local ticker = function ()
            if t1 == nil then
                t1 = now('us')
            else 
                local t2 = now('us')
                local diff = math.abs(t2-t1-1000)
                if diff > max_diff then
                    max_diff = diff
                end
                t1 = t2
            end
            async.send(device.dev1_.conn1, buf)
            send = send + #buf
        end

        local timer = async.interval(10, 1, ticker)
        delay(20000)
        async.clear(timer)
        delay(300)
        print('发送周期 1 ms')
        print('共发送', send, '字节')
        print('共接收', count, '字节')
        print('最大误差 =', max_diff, 'us')
    end
}


function entry(vars)

    local filter = "r"

    for k, t in pairs(test) do
        if string.sub(k, 1, 1) == filter then
            print('【' .. k .. '】测试开始...')
            local t1 = now()
            local ok, res = pcall(t, vars)
            local t2 = now()
            if ok then
                log.info('【' .. k .. '】测试通过(' .. (t2-t1) .. 'ms)')
            else
                record.test_case = k
                record.test_result = res
                log.error('【' .. k .. '】测试失败, ' .. helper.trim_error_info(res))
            end
        end
    end

    exit()
end
