-- DEBUG = false    -- 开启调试模式
-- SKIP_TIP = true -- 跳过用户提示

local tester = require "Electric_tester"
local helper = require "Helper"
local vs = nil
local _this = {}

function entry(vars)
    tester.do_stop(vars, false)
    vs = vars
    log.step(vars.test_name)
    async.on_recv(device.main_ctr.conn, protocol.RECV_MAIN, _this.do_recv_all)
    tester.send_init(vars)
end

function Stop()
    tester.do_stop(vs,true)
end

function Send_b1553(cmd)
    -- print('Send_b1553', cmd)
    local msg = message(protocol.start_electric)
    msg.device_type = vs.device_type
    msg.function_type = vs.function_type
    msg.test_code = 5   -- 1553B测试
    msg.test_code_child = 1    -- 测试子项
    msg.other = cmd.switch  -- 开关 1 开； 2 关
    async.send(device.main_ctr.conn, helper.creat_main(vs.result_cmd, 0x07, pack(msg)))
    _this.set_result(vs.result_user.items_b1553, cmd.switch==1, 'b1553')
end

function Send_b15531(cmd)
    -- print('Send_b1553', cmd)
    local msg = message(protocol.start_electric)
    msg.device_type = vs.device_type
    msg.function_type = vs.function_type
    msg.test_code = 5   -- 1553B测试
    msg.test_code_child = 2    -- 测试子项
    msg.other = cmd.switch  -- 开关 1 开； 2 关
    async.send(device.main_ctr.conn, helper.creat_main(vs.result_cmd, 0x07, pack(msg)))
    _this.set_result(vs.result_user.items_b15531, cmd.switch==1, 'b15531')
end
function Send_lan(cmd)
    _this.clear_timer();
    local ip_addr = ask('text', vs.lan_config)
    local ip_data = String_split(ip_addr, ".")
    print("ip_data", ip_data)
    local msg = message(protocol.start_electric_ip)
    msg.device_type = vs.device_type
    msg.function_type = vs.function_type
    msg.test_code = 4   -- lan测试
    msg.test_code_child = 1    -- 测试子项
    msg.other = cmd.switch  -- 开关 1 开； 2 关
    msg.ip1 = tonumber(ip_data[1])
    msg.ip2 = tonumber(ip_data[2])
    msg.ip3 = tonumber(ip_data[3])
    msg.ip4 = tonumber(ip_data[4])
    local tout = function()
        _this.clear_timer()
        record.open_lan = {result='error', text='测试执行超时'}
    end
    _this.timer = async.timeout(vs.timeout_lan, tout)
    print('SEND IP', string.buff2hex(pack(msg)))
    async.send(device.main_ctr.conn, helper.creat_main(vs.result_cmd, vs.card, pack(msg)))
    _this.state = 'waiting_lan'
end

function String_split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function Send_can(cmd)
    local msg = message(protocol.start_electric)
    msg.device_type = vs.device_type
    msg.function_type = vs.function_type
    msg.test_code = 2   -- can测试
    msg.test_code_child = 1    -- 测试子项
    msg.other = cmd.switch  -- 开关 1 开； 2 关
    async.send(device.main_ctr.conn, helper.creat_main(vs.result_cmd, 0x07, pack(msg)))
    _this.set_result(vs.result_user.items_can, cmd.switch==1, 'can')
end

function Send_uart()
    _this.clear_timer();
    _this.uart_count = ask('integer', vs.uart_config)

    local msg = message(protocol.start_electric)
    msg.device_type = vs.device_type
    msg.function_type = vs.function_type
    msg.test_code = 3   -- 串口测试
    msg.test_code_child = 1    -- 测试子项
    msg.other = 1  -- 开关 1 开； 2 关

    local tout = function()
        _this.clear_timer()
        record.open_uart = {result='error', text='测试执行超时'}
    end
    _this.timer = async.timeout(vs.timeout_uart, tout)
    print('SEND UART', string.buff2hex(pack(msg)))
    async.send(device.main_ctr.conn, helper.creat_main(vs.result_cmd, vs.card, pack(msg)))
    _this.state = 'waiting_uart'
end

function Send_mic_dlc(cmd)
     local msg = message(protocol.start_electric)
    msg.device_type = vs.device_type
    msg.function_type = vs.function_type
    msg.test_code = 1   -- MIC测试
    msg.test_code_child = 1    -- MIC动力舱
    msg.other = cmd.switch  -- 开关 1 开； 2 关
    print(string.buff2hex(pack(msg)))
    async.send(device.main_ctr.conn, helper.creat_main(vs.result_cmd, 0x07, pack(msg)))
    _this.set_result(vs.result_user.items_mic_dlc, cmd.switch==1, 'mic_dlc')
end

function Send_mic_cyc(cmd)
     local msg = message(protocol.start_electric)
    msg.device_type = vs.device_type
    msg.function_type = vs.function_type
    msg.test_code = 1   -- MIC测试
    msg.test_code_child = 2    -- MIC乘员舱
    msg.other = cmd.switch  -- 开关 1 开； 2 关
    async.send(device.main_ctr.conn, helper.creat_main(vs.result_cmd, 0x07, pack(msg)))
    _this.set_result(vs.result_user.items_mic_cyc, cmd.switch==1, 'mic_cyc')
end

function Send_mic_jsy(cmd)
    local msg = message(protocol.start_electric)
    msg.device_type = vs.device_type
    msg.function_type = vs.function_type
    msg.test_code = 1   -- MIC测试
    msg.test_code_child = 3    -- MIC驾驶员
    msg.other = cmd.switch  -- 开关 1 开； 2 关
    async.send(device.main_ctr.conn, helper.creat_main(vs.result_cmd, 0x07, pack(msg)))
    _this.set_result(vs.result_user.items_mic_jsy, cmd.switch==1, 'mic_jsy')
end
-- 集中处理上报信息
_this.do_recv_all = function(msg)
    if msg.CMD ~= vs.result_cmd and msg.SA ~= vs.card then
        return
    end
    local submsg, subtype, state
    submsg, subtype = tester.parse_sub(msg.BUFFER)
    if subtype == 'tick_reply' then
        state = tester.handle_tick(vs, submsg)
        if state == 'tick_ok' then
            tester.send_init(vs)
        end
    elseif subtype == 'init_reply' then
        state = tester.handle_init(vs, submsg)
        if state == 'init_ok' then
            record.init_state = 'ok'
        end
    elseif subtype == 'uart_reply' then
        _this.do_uart_reply(submsg)
    elseif subtype == "lan_reply" then
        _this.do_lan_reply(submsg)
    end
end

_this.includes = function(items, value)
    for i, v in ipairs(items) do
        if v==value then
             return true
        end
    end
    return false
end

_this.set_result = function(items, is_open, comm_id)
    local opt = {title=vs.result_user.title, msg = vs.result_user.msg, items=items, color=vs.result_user.color}
    for i, v in ipairs(items) do
        v.on = is_open
    end
    local res = ask("multiswitch", opt)
    if is_open then --打开判断
        if #items == #res then
            record['open_'..comm_id] = {result='ok', text='测试通过'}
        else
            local text = ''
            for i, v in ipairs(opt.items) do
                if not _this.includes(res, v.value) then
                    text = text..' '..v.name
                end
            end
            record['open_'..comm_id] = {result='error', text='以下节点测试失败:'..text}
        end
    else --关闭判断
        if #res == 0 then
            record['close_'..comm_id] = {result='ok', text='测试通过'}
        else
            local text = ''
            for i, v in ipairs(res) do
                for ii, vv in ipairs(items) do
                    if vv.value==v then
                        text = text..' '..vv.name
                        break
                    end
                end
            end
            record['close_'..comm_id] = {result='error', text='以下节点测试失败:'..text}
        end
    end
end

_this.clear_timer = function()
    if _this.timer then
        async.clear(_this.timer)
        _this.timer = nil
    end
end

_this.do_uart_reply = function (submsg)
    if _this.state ~= 'waiting_uart' then
        return
    end
    _this.clear_timer()
    if tonumber(_this.uart_count) == tonumber(submsg.usart) then
        local answer = ask('yesno',  {title = "提示", msg = '请查看驾驶员任务终端是否显示“综合保障刷卡器确认信息，发送数据成功”'})
        if answer then
            record.open_uart = {result='ok', text='测试通过, 电启动次数'.. submsg.usart}
        else
            record.open_uart = {result='error', text='测试失败'}
        end
    else
        record.open_uart = {result='error', text='测试失败'}
    end
end

_this.do_lan_reply = function (submsg)
    if _this.state ~= 'waiting_lan' then
        return
    end
    _this.clear_timer()
    if submsg.other == 1 then
        log.check("执行测试通过", true)
        record.open_lan = {result='ok', text='测试通过'}
    else
        log.check("执行测试失败", false)
        record.open_lan = {result='error', text='测试失败'}
    end
end

print(not not entry or Send_b1553 or Send_can or Send_uart or Send_lan)