
-- entry: ETestDev执行用例入口函数 
-- @vars: 输入参数, @option: 自定义选项
local helper = require "Helper"
function entry(vars, option)
    local can_cards = vars.can
	if can_cards then
        print(can_cards)
        local send_can = function(qwe)
            for k, v in ipairs(qwe) do
                v.data = string.hex2buff(v.data)
                local msg = message(protocol.prot_can, v)
                async.send(device.main_ctr.conn, helper.creat_main(0x50, 0x05, pack(msg)))
                msgs.set_msg(v.test_prot, msg)
                rcd.record_send(vars, msg, v.test_prot)
                delay(10)

            end
        end
        time_id = async.interval(4, 50, send_can, can_cards[1].test_data)
    end
end
