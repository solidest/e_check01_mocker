

-- 校验函数
-- 校验函数用于生成原始字节的校验码
-- 输入参数 prot_buff: 协议包原始字节、pos_begin：校验开始字节位置、pos_end：校验结束字节位置
-- 返回值：返回特定长度字符串

-- xor8校验后转字符串
function My_xor8(prot_buff, pos_begin, pos_end)
    local res = 0
    for i=pos_begin, pos_end do
        res = res ~ string.byte(prot_buff, i)
        print(res)
    end
    return string.format("%02X", res)
end