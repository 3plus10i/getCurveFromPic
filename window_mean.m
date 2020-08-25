function data2 = window_mean(data, half_width, is_cyclic)
% ���������ݽ��л�������ƽ��
% data����ֵ����
% half_width�����ڰ��
% is_cyclic�����������Ƿ�����βѭ����
%   �����������falseʱ�������ڱ߽�ᱻ��ס
%   ���򴰿��ڱ߽��ѭ������ǰ�봰��Χ��ʹ����β���ݣ����봰��Ȼ

% 2020��8��25��
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