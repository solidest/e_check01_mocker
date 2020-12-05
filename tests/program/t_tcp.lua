
local helper = require 'helper'

local function send_recv (client, server, srv_opt)
    local lens = { 1, 10, 100, 1024, 65507, 65*1024 }

    local l1 = 0
    local l2 = 0
    local l3 = 0

    for i, len in ipairs(lens) do
        l1 = l1 + len
        local buf_a = helper.create_buffer(len)
        local slen = send(device.client[client], buf_a)
        assert(slen == len)

        for i = 1, 100 do
            local buf_b, opt = recv(device.server[server], nil, 100)
            if not buf_b then
                break
            end
            l2 = l2 + #buf_b
            assert(not not opt["client_port"])
        end

        local slen = send(device.server[server], buf_a, srv_opt)
        assert(slen == len)

        for i = 1, 100 do
            local buf_b, opt = recv(device.client[client], nil, 100)
            if not buf_b then
                break
            end
            l3 = l3 + #buf_b
        end
        assert(l2 == l1 and l3 == l1, l1 .. ',' .. l2 .. ',' .. l3)
    end
end

local test = {

    -- 基本通信测试
    tcp_common = function ()
        send_recv('tcp1', 'srva')
        send_recv('tcp4', 'srvd')
    end,

    -- 手动连接
    tcp_conn_disconn = function ()
        local err_fn = function (c)
            send(device.client[c], 'aaa\0')
        end
        local res = pcall(err_fn, 'tcp2')
        assert(not res)

        local opt1 = ioctl(device.client.tcp2, 'Connect', { to = 'server.srvb'})
        local opt2 = ioctl(device.client.tcp3, 'Connect', { to = 'server.srvc'})
        assert(opt1["client_ip"] == opt2["client_ip"])
        send_recv('tcp2', 'srvb', { to = 'client.tcp2' })
        send_recv('tcp3', 'srvc', { to = opt2.client_ip .. ':' .. opt2.client_port })

        ioctl(device.client.tcp2, 'Disconnect')
        res = pcall(err_fn, 'tcp2')
        assert(not res)
        ioctl(device.client.tcp2, 'Connect', { to = 'server.srvb'})
        send_recv('tcp2', 'srvb', { to = 'client.tcp2' })
        ioctl(device.client.tcp2, 'Disconnect')
        res = pcall(err_fn, 'tcp2')
        assert(not res)
        ioctl(device.client.tcp3, 'Disconnect')
    end,

    -- 服务器上的客户端列表
    tcp_listclient = function ()
        delay(10)
        local l1 = ioctl(device.server.srva, 'ListClients')
        assert(#l1.result == 1)
        local l2 = ioctl(device.server.srvb, 'ListClients')
        assert(#l2.result == 0)
        local l3 = ioctl(device.server.srvc, 'ListClients')
        assert(#l3.result == 0)
        local l4 = ioctl(device.server.srvd, 'ListClients')
        assert(#l4.result == 1)
        local l5 = ioctl(device.server.srve, 'ListClients')
        assert(#l5.result == 1)
        local l6 = ioctl(device.server.srvf, 'ListClients')
        assert(#l6.result == 0)
        local l7 = ioctl(device.server.srvg, 'ListClients')
        assert(#l7.result == 0)
        ioctl(device.client.tcp2, 'Connect', { to = 'server.srvb'})
        ioctl(device.client.tcp3, 'Connect', { to = 'server.srvb'})
        l2 = ioctl(device.server.srvb, 'ListClients')
        assert(#l2.result == 2)
        ioctl(device.client.tcp2, 'Disconnect')
        delay(10)
        l2 = ioctl(device.server.srvb, 'ListClients')
        assert(#l2.result == 1)
        ioctl(device.server.srvb, 'Refuse')
        delay(10)
        l2 = ioctl(device.server.srvb, 'ListClients')
        assert(#l2.result == 0)
        ioctl(device.client.tcp3, 'Disconnect')
    end,

    -- 客户端无ip或端口
    tcp_empty_ip_port = function ()
        send_recv('tcp4', 'srvd')
        send_recv('tcp5', 'srve')
        
        local opt1 = ioctl(device.client.tcp6, 'Connect', { to = 'server.srvf'})
        local opt2 = ioctl(device.client.tcp7, 'Connect', { to = 'server.srvg'})
        assert(opt1["client_ip"] == opt2["client_ip"])
        send_recv('tcp6', 'srvf', { to = opt1.client_ip .. ':' .. opt1.client_port })
        send_recv('tcp7', 'srvg', { to = opt2.client_ip .. ':' .. opt2.client_port })
        ioctl(device.client.tcp6, 'Disconnect' )
        ioctl(device.client.tcp7, 'Disconnect' )
    end,

    -- 多报文通信
    tcp_multimsg = function ()
        local lens = { 1, 10, 100, 1024, 65507, 65*1024 }

        local l1 = 0
        local l2 = 0
        local l3 = 0

        for i, len in ipairs(lens) do
            l3 = l3 + len
            local buf_a = helper.create_buffer(len)
            send(device.client.tcp1, buf_a)
            send(device.server.srva, buf_a)
        end

        for i = 1, 100 do
            local buf_a = recv(device.server.srva, nil, 10)
            local buf_b = recv(device.client.tcp1, nil, 10)
            l1 = l1 + (buf_a and #buf_a or 0)
            l2 = l2 + (buf_b and #buf_b or 0)
            if not buf_a and not buf_b then
                break
            end
        end
        assert(l1 == l2 and l2 == l3)
    end,

    tcp_async = function ()
        ioctl(device.client.tcp3, 'Connect', { to = 'server.srvc'})

        local lens = { 1, 10, 100, 1024, 65507, 65*1024 }
        local count_1 = 0
        local count_a = 0
        local count_3 = 0
        local count_c = 0

        async.on_recv(device.client.tcp1, nil,
            function (buf)
                count_1 = count_1 + #buf
            end
        )

        async.on_recv(device.server.srva, nil,
            function (buf)
                count_a = count_a + #buf
            end
        )

        async.on_recv(device.client.tcp3, nil,
            function (buf)
                count_3 = count_3 + #buf
            end
        )

        async.on_recv(device.server.srvc, nil,
            function (buf)
                count_c = count_c + #buf
            end
        )

        local count = 0
        for i, len in ipairs(lens) do
            count = count + len
            local buf_a = helper.create_buffer(len)
            async.send(device.client.tcp1, buf_a)
            async.send(device.client.tcp3, buf_a)
            async.send(device.server.srva, buf_a)
            async.send(device.server.srvc, buf_a)
        end

        for i = 1, 1000 do
            delay(10)
            if count_a == count and count_c == count and count_1 == count and count_3 == count then
                break
            end
        end
        async.off_recv(device.client.tcp1)
        async.off_recv(device.client.tcp3)
        async.off_recv(device.server.srva)
        async.off_recv(device.server.srvc)

        -- print(count_1, count_a, count_c, count_3)
        assert(count_a == count)
        assert(count_c == count)
        assert(count_1 == count)
        assert(count_3 == count)
        ioctl(device.client.tcp3, 'Disconnect')
    end,

    tcp_refuse_stop_start = function ()
        delay(10)
        ioctl(device.server.srvb, 'Stop')
        delay(10)
        ioctl(device.server.srvb, 'Start')
        delay(10)
        ioctl(device.client.tcp2, 'Connect', { to = 'server.srvb'})
        delay(10)
        ioctl(device.server.srvb, 'Refuse')
        delay(10)
        ioctl(device.client.tcp2, 'Disconnect', { to = 'server.srvb'})
    end
}


function entry(vars)

    ioctl(device.client.tcp4, 'Connect')

    local filter = "t"
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
