
local helper = require 'helper'

local test = {

    serial_send_recv = function()
        local lens = { 1, 10, 100, 1024, 4555 }
        local t1 = 0
        local t2 = 0
        local t3 = 0
        for i, len in ipairs(lens) do
            local buf_a = helper.create_buffer(len)
            local send_len = send(device.dev1.conn1, buf_a)
            assert(send_len == len)
            send_len = send(device.dev2.conn1, buf_a)
            assert(send_len == len)

            t1 = t1 + len
            local buf_b = recv(device.dev2.conn1, nil, 100)
            if buf_b then
                t2 = t2 + #buf_b
            end
        end
        local rbuf = recv(device.dev2.conn1, nil, 100)
        while rbuf do
            t2 = t2 + #rbuf
            rbuf = recv(device.dev2.conn1, nil, 100)
        end
        rbuf = recv(device.dev1.conn1, nil, 100)
        while rbuf do
            t3 = t3 + #rbuf
            rbuf = recv(device.dev1.conn1, nil, 100)
        end
        assert(t2 == t1 and t2 == t3, t1 .. " : " .. t2 .. " : " .. t3)
    end,

    serial_multimsg = function ()
        local lens = { 1, 10, 100, 1024, 4555 }

        local l1 = 0
        local l2 = 0
        local l3 = 0
        local count = 0

        for i, len in ipairs(lens) do
            local buf_a = helper.create_buffer(len)
            send(device.dev1.conn1, buf_a)
            send(device.dev2.conn1, buf_a)
            l1 = l1 + len
        end

        local buf_a, buf_b
        while l2 ~= l1 or l3 ~= l1 do
            if l2 ~= l1 then
                buf_a = recv(device.dev1.conn1, nil, 100)
                l2 = l2 + (buf_a and #buf_a or 0)
            end
            if l3 ~= l1 then
                buf_b = recv(device.dev2.conn1, nil, 100)
                l3 = l3 + (buf_b and #buf_b or 0)
            end
            count = count + 1
            if count > 1000 then
                break;
            end
        end
        
        assert(l1 == l2 and l2 == l3)
    end,

    -- 异步通信测试
    serial_async = function()
        local lens = { 1, 10, 100, 1024, 4555 }
        local count1 = 0
        local count2 = 0
        local count3 = 0

        async.on_recv(device.dev1.conn1, nil,
            function (buf)
                -- print('dev1 recved', #buf)
                count1 = count1 + #buf
            end
        )

        async.on_recv(device.dev2.conn1, nil,
            function (buf)
                -- print('dev2 recved', #buf)
                count2 = count2 + #buf
            end
        )

        for i, len in ipairs(lens) do
            local buf_a = helper.create_buffer(len)
            async.send(device.dev1.conn1, buf_a, nil, function (l) assert(l == len) end)
            async.send(device.dev2.conn1, buf_a, nil, function (l) assert(l == len) end)
            count3 = count3 + len
        end

        -- count2 = #lens

        for i = 1, 2500 do
            delay(10)
            if count1 == count3 and count2 == count3 then
                break
            end
        end
        
        async.off_recv(device.dev1.conn1)
        async.off_recv(device.dev2.conn1)

        -- print(count1, count2, count3)
        assert(count1 == count3 and count2 == count3, count1 .. ':' .. count2 .. ':' .. count3)
    end,

    serial_ioctl = function ()
        local com1 = device.dev1.conn1
        local com2 = device.dev2.conn1
        local cts, dsr, ri,cd
        local bool2str = function (b)
            return b and 'true' or 'false'
        end
        local log_state = function (com)
            cts = ioctl(com, 'GetCTS').result
            dsr = ioctl(com, 'GetDSR').result
            ri = ioctl(com, 'GetRI').result
            cd = ioctl(com, 'GetCD').result
            if DEBUG then
                print('cts=' .. bool2str(cts), 'dsr=' .. bool2str(dsr), 'ri=' .. bool2str(ri) , 'cd=' .. bool2str(cd))
            end
        end
        log_state(com1)
        log_state(com1)
        ioctl(com1, 'SetRTS', {value = true})
        ioctl(com1, 'SetDTR', {value = true})
        log_state(com1)
        log_state(com2)
        ioctl(com1, 'SetRTS', {value = false})
        ioctl(com1, 'SetDTR', {value = false})
        log_state(com2)
    end,

    serial_ioctl_break = function()
        local com1 = device.dev1.conn1
        local com2 = device.dev2.conn1
        local buf
        ioctl(com1, 'SetBreak', {value = true})
        buf = recv(com2, nil, 200)
        assert(string.hex2buff('00') == buf)
        ioctl(com1, 'SetBreak', {value = false})
        buf = recv(com2, nil, 200)
        assert(buf == nil)
    end
}


function entry(vars)
    DEBUG = false
    local filter = "s"

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
