function f = getCurveFromPic2(picfile)
% 从图像识别函数曲线（无交互）
% 增加了对空值和多值的初步自动处理方法
% 增加了对截图左右的裁剪处理（归为空值）
% 重新定义了归一化方法（对截图上下的裁剪处理）
% 对交叉干扰和低信噪比图像，效果会降低。
% yjy@2020-7-3

%% 获取随意图像
pic = imread(picfile);
pic = rgb2gray(pic);
pic = pic<(255/2); % 中央二值化 1 = white; 0 == black 
% pic用1指示了线条像素

%% 将图像转化为数值散点
% 越界（空值）：检查+（线性）插值
% 白边（多值）：覆盖+扩张 （“曲线是连续的”）

% 第一列对解决白边问题很重要，第一列必须单值
% 这要求太强了，对一些在第一列有干扰的情况很糟
perfectFirstColumn = false;
while ~perfectFirstColumn
    % 首先线条是比较细的
    if sum(pic(:,1)) > 0.5*size(pic,1)
        pic(:,1) = [];
        continue
    end
    idx = find(pic(:,1));
    % 其次空值也不行（应该是截图截大了）
    if isempty(idx)
        pic(:,1) = [];
        continue
    end
    % 通过扩张算法检查本列是否单联通
    % neighbor在紧状态为所识别连续区间的外边界
    neighbor = [idx(1),idx(1)]; % 从任一点出发
    while  neighbor(1)>=1 && pic(neighbor(1),1)
        neighbor(1) = neighbor(1) - 1;
    end
    while  neighbor(2)<=size(pic,1) && pic(neighbor(2),1)
        neighbor(2) = neighbor(2) + 1;
    end
    % neighbor扩张到了外边缘
    if neighbor(2)-neighbor(1) - 1  >= length(idx) % 扩张到了所有点
        perfectFirstColumn = true;
    else
        pic(:,1) = []; % 这是不是太粗暴了？
    end
end
% 建立数值点列记录变量f
f = zeros(size(pic,2),1);
nRows = size(pic,1);
nColumns = size(pic,2);
waitForInterpolation = false;
lastValid = 0;
for ii=1:nColumns
    % 寻找3倍邻居区域像素点（覆盖）
    neighbor = myExpand(neighbor,3,nRows);
    idx = find(pic(neighbor(1):neighbor(2),ii));
    idx = neighbor(1)-1 + idx; % 恢复为pic的索引
    % 空值检查
    if isempty(idx)
        waitForInterpolation = true;
%         neighbor = [1,nRows]; % 搜索区域扩大到全部
        neighbor = myExpand(neighbor,3,nRows); % 搜索区域再扩大
        continue
    end
    % 如果idx的包络中含有大量0，则应该是遇到了多值
    if length(idx) / ( idx(end) - idx(1) ) < 0.75
        % 此时应该从距离上一列（最后有效列）最近的点开始进行连续扩张
        % 如果干扰太大，目标线条太细（甚至有间断），则可能跳到干扰上去
        core = nearest(idx,f(lastValid-1));
        %  使用扩张算法
        neighbor = [idx(core),idx(core)]; % 从任一点出发
        while  neighbor(1)>=1 && any(neighbor(1) == idx)
            neighbor(1) = neighbor(1) - 1;
        end
        while  neighbor(2)<=nColumns && any(neighbor(2) == idx)
            neighbor(2) = neighbor(2) + 1;
        end
%         idx = idx(neighbor(1)+1:neighbor(2)-1);
        idx = idx( find(idx==neighbor(1)+1):find(idx==neighbor(2)-1) );
    end
    % 获取全部邻居区域像素点联通区域（扩张）
    % neighbor可能扩张到外边缘(可能溢出)
    if idx(1)==neighbor(1) % 有必要向上扩张
        neighbor(1) = neighbor(1) - 1;
        while  neighbor(1)>=1 && pic(neighbor(1),ii)
            neighbor(1) = neighbor(1) - 1;
        end
%         idx = [(neighbor(1)+1:idx(1)-1)'; idx];
    else % 如果不要扩张则需要手动收紧
        neighbor(1) = idx(1)-1;
    end
    if idx(end)==neighbor(2) % 有必要向下扩张
        neighbor(2) = neighbor(2) + 1;
        while  neighbor(2)<=nRows && pic(neighbor(2),ii)
            neighbor(2) = neighbor(2) + 1;
        end
%         idx = [idx; (idx(end)+1:neighbor(2)-1)'];
    else % 如果不要扩张则需要手动收紧
        neighbor(2) = idx(end)+1;
    end
    idx = [(neighbor(1)+1:idx(1)-1)'; idx; (idx(end)+1:neighbor(2)-1)'];
    
    % 取均值
    f(ii) = mean(idx);
    % 一旦离开空值区间，就做线性插值补回空值
    if waitForInterpolation
        tmp = linspace(f(lastValid), f(ii),...
            ii-lastValid+1);
        f(lastValid+1:ii-1) = tmp(2:end-1)';
        waitForInterpolation = false;
    end
    lastValid = ii;
end
% 如果最后有一段空值（应该是截图截大了）
if waitForInterpolation
    f(lastValid:end) = [];
end

f = nRows-f+1;
f = f - min(f(:));
f = f / max(f(:)); % 充满值域+归一化
% f(f<0.001) = 0.001;

%% test
subplot(2,1,1)
imshow(picfile)
subplot(2,1,2)
plot(f)

end

%%
function interval = myExpand(interval,n,max)
% 将整数区间interval扩张n倍，并保持区间中点基本不变
% 保持区间端点为正整数
% 限制区间端点小于上界max
len = abs(diff(interval));
% interval(1) = round( mid - n/2*len );
% interval(2) = round( mid + n/2*len );
if ~isrow(interval)
    interval = interval';
end
interval = interval + [-1,1]*len/2*(n-1);
interval(interval<1) = 1;
interval(interval>max) = floor(max);
end


function core = nearest(a,t)
% 从向量a中找出最接近t的那个元素的位置
[~,core] = min( abs(a-t) );
end