-- 打包函数
-- 协议段打包时调用
-- 输入参数 seg_name: 协议段名称、seg_value：协议段值
-- 返回值：返回打包后的string

-- --将浮点数打包成字符串 字符D替换小数点
-- function PackFloat_D(seg_name, seg_value)
--     local str = string.format("%.5f", seg_value)
--     if seg_name=='WD' then  --纬度是最后一个字符串，不需要分割符F
--         return string.gsub(str, "%.", "D")
--     else 
--         return string.gsub(str, "%.", "D")..'F'
--     end
-- end


-- --将浮点数放大10倍后打包成整数字符串
-- function PackFloat_I(seg_name, seg_value, prot_data)
--     return string.format("%.0f", seg_value*10)..'F'
-- end




-- -- 解包函数
-- -- 协议段解包时调用
-- -- 输入参数 seg_name: 协议段名称、prot_buff：报文原始字节、 pos: 当前解析位置
-- -- 返回值：必须返回2个值，第1个为解析得到的值，第2个为解析使用的字节长度


-- --将含D字符的string解包成浮点数
-- function UnpackFloat_D(seg_name, prot_buff, pos)
--     local pos_end = pos
--     local str = ''
--     if seg_name=='WD' then
--         pos_end = string.len(prot_buff)
--         str = string.sub(prot_buff, pos, pos_end)
--     else 
--         pos_end = string.find(prot_buff, 'F', pos)
--         str = string.sub(prot_buff, pos, pos_end-1)
--     end
--     str = string.gsub(str, 'D', '.')
--     return tonumber(str), pos_end-pos+1
-- end


-- --将整数字符串解包成缩小10倍的浮点数
-- function UnpackFloat_I(seg_name, prot_buff, pos)
--     local pos_end = string.find(prot_buff, 'F', pos)
--     local str = string.sub(prot_buff, pos, pos_end-1)
--     return tonumber(str)/10, pos_end-pos+1
-- end

-- -- 校验函数
-- -- 校验函数用于生成原始字节的校验码
-- -- 输入参数 prot_buff: 协议包原始字节、pos_begin：校验开始字节位置、pos_end：校验结束字节位置
-- -- 返回值：返回特定长度字符串

-- -- xor8校验后转字符串
-- function My_xor8(prot_buff, pos_begin, pos_end)
--     local res = 0
--     for i=pos_begin, pos_end do
--         res = res ~ string.byte(prot_buff, i)
--         print(res)
--     end
--     return string.format("%02X", res)
-- end

-- 数据接收过滤器
function Before_recv(b)
    local header = buf.readstr(b, 0, 6, false)
    local len1 = buf.len(b)
    local len2 = buf.readint(b, 6, 2, false, false)
    len2 = (len2<<8 & 0xFF00)|(len2>>8 & 0x00FF)
 
    if header ~= 'TSPD00' or len1 ~= len2 then
        print('ERROR MESSAGE:', header, len2)
        return -1
    else
        return 0
    end
    -- local header = buf.readstr(b, 0, 6, false)
    -- local len1 = buf.len(b)
    -- local len2 = buf.readint(b, 6, 2, false, false)
    -- if header ~= 'TSPD00' or len1 ~= len2 then
    --     print('ERROR MESSAGE:', header, len2)
    --     return -1
    -- else
    --     return 0
    -- end
end
