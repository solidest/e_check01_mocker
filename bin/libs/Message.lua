

-- 报文状态保持
local this = { }
local msgs = { }

this.new_msg = function (prot, data)
    local msg = msgs[prot]
    if not msg then
        msg = message(protocol[prot], data)
        msgs[prot] = msg
    end
    return msg
end

this.get_msg = function (prot)
    return msgs[prot] or {}
end

this.set_msg = function (prot, data)
    msgs[prot] = data
end

this.update_msg = function (prot, data)
    local msg = msgs[prot]
    if not msg then
        msg = message(protocol[prot], data)
        msgs[prot] = msg
        return msg
    else
        for key, value in pairs(data) do
            msg[key] = value
        end
        return msg
    end

end

return this