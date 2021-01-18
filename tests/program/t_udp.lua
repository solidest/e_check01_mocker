
local helper = require 'helper'

local test = {

    -- 超长报文
    e_udp_msg_too_long = function ()
        local len = 65508
        local buf_a = helper.create_buffer(len)
        send(device.udp1.conn1, buf_a, nil)
    end,

    -- 基本通信测试
    udp_common = function()
        local lens = { 1, 10, 100, 1024, 65507 }

        for i, len in ipairs(lens) do
            local buf_a = helper.create_buffer(len)
            send(device.udp1.conn1, buf_a)
            local buf_b = recv(device.udp2.conn1, nil, 3000)
            assert(buf_a == buf_b, i .. "," .. #buf_a .. ',' .. #buf_b)
        end
    end,

    -- 多报文通信
    udp_multimsg = function ()
        local lens = { 1, 10, 100, 1024, 65507 }

        for i, len in ipairs(lens) do
            local buf_a = helper.create_buffer(len)
            send(device.udp1.conn1, buf_a)
        end
        for i, len in ipairs(lens) do
            local buf_a = helper.create_buffer(len)
            local buf_b = recv(device.udp2.conn1, nil, 3000)
            assert(buf_a == buf_b, #buf_a .. '~=' .. #buf_b)
        end
    end,

    -- 动态目标
    udp_target = function ()
        local lens = { 1, 10, 100, 1024, 65507 }
        for i, len in ipairs(lens) do
            local buf_a = helper.create_buffer(len)
            send(device.udp1.conn2, buf_a, { to = 'udp2.conn2'})
        end
        for i, len in ipairs(lens) do
            local buf_a = helper.create_buffer(len)
            local buf_b = recv(device.udp2.conn2, nil, 3000)
            assert(buf_a == buf_b, #buf_a .. '~=' .. #buf_b)
        end
        local buf_c = recv(device.udp2.conn3, nil)
        assert(buf_c == nil)
    end,


    -- 广播报文测试
    udp_broadcast = function ()
        local lens = { 1, 10, 100, 1024 }
        for i, len in ipairs(lens) do
            local buf_a = helper.create_buffer(len)
            send(device.udp1.conn2, buf_a, { to_port = 8000 })
        end
        for i, len in ipairs(lens) do
            local buf_a = helper.create_buffer(len)
            local buf_b = recv(device.udp2.conn4, nil, 3000)
            assert(buf_a == buf_b, #buf_a .. '~=' .. #buf_b)
        end
        local buf_c = recv(device.udp2.conn3, nil)
        assert(buf_c == nil)
    end,

    -- 异步通信测试
    udp_async = function()
        local lens = { 1, 10, 100, 1024, 65507 }
        local count1 = 0
        local count2 = 0
        local count3 = 0

        async.on_recv(device.udp2.conn1, nil,
            function (buf)
                count1 = count1 + 1
                local len = #buf
                assert(buf == helper.create_buffer(len))
            end
        )

        async.on_recv(device.udp2.conn2, nil,
            function (buf)
                count2 = count2 + 1
                local len = #buf
                assert(buf == helper.create_buffer(len))
            end
        )

        async.on_recv(device.udp2.conn4, nil,
            function (buf)
                count3 = count3 + 1
                local len = #buf
                assert(buf == helper.create_buffer(len))
            end
        )

        for i, len in ipairs(lens) do
            local buf_a = helper.create_buffer(len)
            async.send(device.udp1.conn1, buf_a)
            async.send(device.udp1.conn2, buf_a, { to = 'udp2.conn2'})
            async.send(device.udp1.conn2, buf_a, { to_port = 8000 })
        end

        -- count2 = #lens

        for i = 1, 1000 do
            delay(10)
            local l = #lens
            if count1 == l and count2 == l and count3 == l then
                break
            end
        end
        async.off_recv(device.udp2.conn1)
        async.off_recv(device.udp2.conn2)
        async.off_recv(device.udp2.conn4)

        -- print(count1, count2, count3)
        assert(count1 == #lens)
        assert(count2 == #lens)
        assert(count3 == #lens)
    end,

}


function entry(vars)

    -- ioctl(device.udp1.conn1, "JoinGroup", {group = "244.0.2.2"})
    -- ioctl(device.udp1.conn1, "LeaveGroup", {group = "244.0.2.2"})

    local filter = "u"

    for k, t in pairs(test) do
        if string.sub(k, 1, 1) == filter then
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
