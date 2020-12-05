
local this = {}

this.create_bufstr = function (len)
    local s = ''
    for i = 0, len-1 do
        s = s .. (i%256<16 and '0' or '') .. string.format(i==len-1 and '%X' or '%X ', i%256)
    end
    return s
end

this.create_buffer = function (len)
    local t = {}
    for i = 1, len do
        t[i] = (i-1)%256
    end
    return string.arr2buff(t)
end


this.trim_error_info = function (info)
    local pos1, pos2 = string.find(info, "/run/", 1)
    if pos2 then
        return string.sub(info, pos2+1)
    end
    return info
end

return this