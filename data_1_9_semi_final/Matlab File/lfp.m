%本文件读取STN-LFP数据并生成可以存储在BRAM里的COE文件
clc; clear; close all
load motortestdata.mat;
lfp_data = Data(:, 1);
lfp_data = lfp_data(1:512);%选择前1024个数据
%% 进制转换——4位小数，12位整数，共16位。去除了小数点（移位4，扩大2^4倍）
% 将数据拆分为整数和小数部分
lfp_int_part = floor(lfp_data);  % 整数部分
lfp_frac_part = lfp_data - lfp_int_part;  % 小数部分

% 将整数部分转换为11位二进制(不包括符号位)
lfp_int_bin = arrayfun(@(x) dec2bin(abs(x), 12), lfp_int_part, 'UniformOutput', false);
%将小数部分转换为2进制，取这些二进制小数的前4位
lfp_frac_bin = arrayfun(@(x) dec2bin(abs(x), 4), lfp_frac_part, 'UniformOutput', false);

% 将整数和小数部分合并
lfp_data_bin = cellfun(@(x, y) [x, y], lfp_int_bin, lfp_frac_bin, 'UniformOutput', false);
%% 生成coe文件
coe_file = 'lfp_data.coe'; % COE文件名
fid = fopen(coe_file, 'w'); % 打开文件
fprintf(fid, 'memory_initialization_radix = 16;\n'); % 写入基数
fprintf(fid, 'memory_initialization_vector =\n'); % 写入向量头

% 将二进制数据转换为16进制数据
lfp_data_hex = cellfun(@(x) dec2hex(bin2dec(x), 4), lfp_data_bin, 'UniformOutput', false);

% 写入16进制数据
for i = 1:length(lfp_data_hex)
    fprintf(fid, '%s', lfp_data_hex{i}); % 写入16进制数据

    if i < length(lfp_data_hex)
        fprintf(fid, ',\n'); % 每行一个数据，逗号分隔
    else
        fprintf(fid, ';\n'); % 最后一个数据以分号结束
    end
end

fclose(fid); % 关闭文件
disp(['COE文件已生成：', coe_file]);
