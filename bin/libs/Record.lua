

local helper = require "Helper"
local this = {}


-- 发送时状态记录
this.record_send = function (vars, sub_msg, sub_prot)
    if vars.record_send and vars.record_send.prot == sub_prot then
        helper.msg_record('send_', sub_msg, vars.record_send.items)
    elseif vars.record_send2 and vars.record_send2.prot == sub_prot then
        helper.msg_record('send_', sub_msg, vars.record_send2.items)
    end
end

-- 接收时状态记录
this.record_recv = function (vars, sub_msg, sub_prot)
    if vars.record_recv and vars.record_recv.prot == sub_prot then
        helper.msg_record('recv_', sub_msg, vars.record_recv.items)
    elseif vars.record_recv2 and vars.record_recv2.prot == sub_prot then
        helper.msg_record('recv_', sub_msg, vars.record_recv2.items)
    end
end

return this