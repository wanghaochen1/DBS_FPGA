% g_dft_testdata.m - 生成具有指定频率的测试数据

% 清空环境
clc; clear; close all;

% 采样频率
Fs = 1024; 
% 信号长度
L = 1024; 
% 时间向量
t = (0:L-1)/Fs;

% 频率成分
f1 = 20; % 第22位
f2 = 29; % 第29位

% 生成基础信号
base_signal = sin(2*pi*f1*t) + sin(2*pi*f2*t);

base_signal = 15+7.5.*base_signal;

% 检查信号范围，确保不超过整数部分表示范围
max_signal = max(abs(base_signal));
fprintf('信号最大值: %.2f\n', max_signal);

if max_signal > 4095
    warning('信号值超过12位整数可表示的范围(4095)，需要减小放大系数');
end

% 计算FFT
Y = fft(base_signal);
f = Fs*(0:(L/2))/L;

% 绘制信号
figure;
subplot(2,1,1);
plot(t, base_signal);
title('时域信号');
xlabel('时间 (秒)');
ylabel('幅值');

% 绘制FFT结果
subplot(2,1,2);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
plot(f, P1);
title('单边幅度谱');
xlabel('频率 (Hz)');
ylabel('幅值');

% 标记第22和29位
hold on;
plot(f1, P1(f1+1), 'ro');
plot(f2, P1(f2+1), 'ro');
hold off;

% 保存生成的数据
Data = base_signal';  % 转置为列向量，与原始lfp.m代码兼容
save('motortestdata.mat', 'Data');

fprintf('已生成测试数据并保存到motortestdata.mat\n');