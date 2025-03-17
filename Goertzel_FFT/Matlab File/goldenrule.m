% 读取COE文件
filename = 'lfp_data.coe';
fileID = fopen(filename, 'r');
data = textscan(fileID, '%s', 'Delimiter', '\n');
fclose(fileID);

% 提取数据部分
data = data{1};
data = data(3:end); % 跳过前两行

% 去掉每行末尾的逗号
data = strrep(data, ',', '');

% 打印数据以检查格式
disp('Data before conversion:');
disp(data(1:10)); % 只显示前10个数据，避免输出过多

% 将字符串转换为数值
numData = zeros(length(data), 1);
for i = 1:length(data)
    numData(i) = str2double(data{i});
end

% 打印转换后的数据
disp('Data after conversion:');
disp(numData(1:10)); % 只显示前10个数据，避免输出过多

% 如果数据长度不足1024点，进行零填充
if length(numData) < 1024
    numData = [numData; zeros(1024 - length(numData), 1)];
elseif length(numData) > 1024
    numData = numData(1:1024);
end

% Goertzel算法部分
N = length(numData);
k_values = 21:27; % 感兴趣的频点

% 初始化结果数组
goertzel_results = zeros(1, length(k_values));

% 对每个频点执行Goertzel算法
for k_idx = 1:length(k_values)
    k = k_values(k_idx);
    
    % Goertzel算法参数
    w = 2 * pi * k / N;
    cosine = cos(w);
    coeff = 2 * cosine;
    
    % 初始化Goertzel状态变量
    s0 = 0;
    s1 = 0;
    s2 = 0;
    
    % 处理每个样本
    for n = 1:N
        % Goertzel算法核心计算
        s0 = numData(n) + coeff * s1 - s2;
        s2 = s1;
        s1 = s0;
        
        % 每10个样本输出一次中间变量
        if n<=500
            fprintf('频点k=%d, 样本n=%d: s0=%.4f, s1=%.4f, s2=%.4f\n', ...
                k, n, s0, s1, s2);
        end
    end
    
    % 计算最终幅值平方
    real_part = s1 - s2 * cosine;
    imag_part = s2 * sin(w);
    magnitude_squared = real_part^2 + imag_part^2;
    
    goertzel_results(k_idx) = magnitude_squared;
end

% 打印最终结果
disp('频点21-27的能量:');
for k_idx = 1:length(k_values)
    fprintf('频点%d: %.4f\n', k_values(k_idx), goertzel_results(k_idx));
end

% 与FFT结果比较
fft_result = fft(numData, N);
fft_mag = zeros(size(k_values));
for i = 1:length(k_values)
    k_mod = mod(k_values(i), N);
    if k_mod == 0
        k_mod = N;
    end
    fft_mag(i) = abs(fft_result(k_mod))^2;
end

disp('FFT计算的能量:');
for k_idx = 1:length(k_values)
    fprintf('频点%d: %.4f\n', k_values(k_idx), fft_mag(k_idx));
end

% 打印二者误差
disp('Goertzel与FFT结果的相对误差:');
for k_idx = 1:length(k_values)
    rel_error = abs(goertzel_results(k_idx) - fft_mag(k_idx)) / fft_mag(k_idx) * 100;
    fprintf('频点%d: %.6f%%\n', k_values(k_idx), rel_error);
end