import re

def convert_coe(
    input_path, 
    output_path, 
    target_group_size=4,  # 每组4个32位数据（128位）
    padding_value="00000000"  # 不足时填充的32位0值
):
    try:
        # 读取原始COE文件
        with open(input_path, "r") as f:
            coe_content = f.read()

        # 提取数据向量（忽略格式干扰）
        data_match = re.search(
            r"memory_initialization_vector\s*=\s*(.*?);", 
            coe_content, 
            re.DOTALL | re.IGNORECASE
        )
        if not data_match:
            raise ValueError("未找到memory_initialization_vector字段")

        # 清洗数据（去除空白和空值）
        raw_data = [
            d.strip() for d in re.split(r"[,;\s]+", data_match.group(1)) 
            if d.strip()
        ]
        actual_count = len(raw_data)
        print(f"📊 原始数据统计：共{actual_count}个32位数据")

        # 自动填充至4的倍数（确保每组4个数据）
        padding_needed = (target_group_size - (actual_count % target_group_size)) % target_group_size
        if padding_needed > 0:
            print(f"⚠️ 数据不足：填充{padding_needed}个{padding_value}（32位）")
            raw_data += [padding_value] * padding_needed

        # 合并为128位数据（关键修改：逆序拼接每组数据）
        combined_data = []
        for i in range(0, len(raw_data), target_group_size):
            chunk = raw_data[i:i+target_group_size]  # 按顺序取4个数据 [A, B, C, D]
            reversed_chunk = chunk[::-1]  # 反转顺序 → [D, C, B, A]
            combined_data.append("".join(reversed_chunk))  # 拼接为 DCBA（A在最右侧）

        # 生成COE文件内容
        coe_lines = [
            "memory_initialization_radix=16;",
            "memory_initialization_vector=" + ",\n".join(combined_data) + ";"
        ]

        # 写入输出文件
        with open(output_path, "w") as f:
            f.write("\n".join(coe_lines))

        print(f"✅ 转换完成！\n"
              f"合并后数据顺序：原始第1行数据位于128位最低位\n"
              f"输出文件：{output_path}")

    except Exception as e:
        print(f"❌ 转换失败：{str(e)}")

# 执行转换
if __name__ == "__main__":
    # convert_coe(
    #     input_path="code.coe",       # 原始COE路径
    #     output_path="new_code.coe"   # 输出路径
    # )
    convert_coe(
        input_path="irom.coe",       # 原始COE路径
        output_path="irom_128.coe"   # 输出路径
    )
    # convert_coe(
    #     input_path="data.coe",       # 原始COE路径
    #     output_path="new_data.coe"   # 输出路径
    # )
    convert_coe(
        input_path="dram.coe",       # 原始COE路径
        output_path="dram_128.coe"   # 输出路径
    )