

-- 数据接收过滤器
function Before_recv(b)
    local header = buf.readstr(b, 0, 6, false)
    local len1 = buf.len(b)
    local len2 = buf.readint(b, 6, 2, false, false)
    if header ~= 'TSPD00' or len1 ~= len2 then
        print('ERROR MESSAGE:', header, len2)
        return -1
    else
        return 0
    end
end
