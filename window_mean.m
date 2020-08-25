function data2 = window_mean(data, half_width, is_cyclic)
% 对向量数据进行滑动窗口平均
% data：数值向量
% half_width：窗口半宽
% is_cyclic：声明数据是否是首尾循环的
%   不给出或给出false时，窗口在边界会被抵住
%   否则窗口在边界会循环：在前半窗范围会使用首尾数据，最后半窗亦然

% 2020年8月25日
if nargin < 3
    is_cyclic = false;
    if nargin < 2
        half_width = 5;
    end
end
hw = half_width;
len = length(data);
idx = @(i)mod( i-1, len) + 1;
if ~is_cyclic
    stir = @(i,hw)max( i-hw, 1 ):min( i+hw, len );
else
    stir = @(i,hw)( 1-hw:1+hw );
end
data2 = zeros(size(data));
for i = 1:len
    data2(idx(i)) = mean( data( idx( stir(i,hw) ) ) );
end
end