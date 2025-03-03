%Hanming窗函数生成COE文件
%Hanning窗函数的范围是[0,1],将其量化为16位有符号数
%所有系数乘2^15-1(32767)并四舍五入

%数据需要右移15位以恢复原来的大小

% 参数设置
N = 512; % Hanning窗长度
bit_width = 16; % 量化位宽
coe_file = 'hanning_512.coe'; % COE文件名

% 生成Hanning窗系数
hanning_coeff = hanning(N); % 使用hanning函数生成系数

% 量化系数为16位有符号数
max_value = 2 ^ (bit_width - 1) - 1; % 最大值为32767
quantized_coeff = round(hanning_coeff * max_value); % 量化

% 将系数转换为16进制字符串
hex_coeff = dec2hex(quantized_coeff, 4); % 4表示16进制字符串长度为4

% 写入COE文件
fid = fopen(coe_file, 'w'); % 打开文件
fprintf(fid, 'memory_initialization_radix = 16;\n'); % 写入基数
fprintf(fid, 'memory_initialization_vector =\n'); % 写入向量头

% 写入系数
for i = 1:N
    fprintf(fid, '%s', hex_coeff(i, :)); % 写入16进制系数

    if i < N
        fprintf(fid, ',\n'); % 每行一个系数，逗号分隔
    else
        fprintf(fid, ';\n'); % 最后一个系数以分号结束
    end

end

fclose(fid); % 关闭文件
disp(['COE文件已生成：', coe_file]);
