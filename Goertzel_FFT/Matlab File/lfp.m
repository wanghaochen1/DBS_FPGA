%本文件读取STN-LFP数据并生成可以存储在BRAM里的COE文件
clc; clear; close all
load motortestdata.mat;
lfp_data = Data(:, 1);
lfp_data = lfp_data(1:1024);%选择前1024个数据

%% 生成coe文件
coe_file = 'lfp_data.coe'; % COE文件名
fid = fopen(coe_file, 'w'); % 打开文件
fprintf(fid, 'memory_initialization_radix = 10;\n'); % 写入基数为10进制
fprintf(fid, 'memory_initialization_vector =\n'); % 写入向量头

% 写入10进制有符号数据
for i = 1:length(lfp_data)
    fprintf(fid, '%d', int16(lfp_data(i))); % 写入10进制有符号数据

    if i < length(lfp_data)
        fprintf(fid, ',\n'); % 每行一个数据，逗号分隔
    else
        fprintf(fid, ';\n'); % 最后一个数据以分号结束
    end
end

fclose(fid); % 关闭文件
disp(['10进制有符号COE文件已生成：', coe_file]);