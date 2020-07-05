function f = getCurveFromPic2(picfile)
% ��ͼ��ʶ�������ߣ��޽�����
% �����˶Կ�ֵ�Ͷ�ֵ�ĳ����Զ�������
% �����˶Խ�ͼ���ҵĲü�������Ϊ��ֵ��
% ���¶����˹�һ���������Խ�ͼ���µĲü�����
% �Խ�����ź͵������ͼ��Ч���ή�͡�
% yjy@2020-7-3

%% ��ȡ����ͼ��
pic = imread(picfile);
pic = rgb2gray(pic);
pic = pic<(255/2); % �����ֵ�� 1 = white; 0 == black 
% pic��1ָʾ����������

%% ��ͼ��ת��Ϊ��ֵɢ��
% Խ�磨��ֵ�������+�����ԣ���ֵ
% �ױߣ���ֵ��������+���� ���������������ġ���

% ��һ�жԽ���ױ��������Ҫ����һ�б��뵥ֵ
% ��Ҫ��̫ǿ�ˣ���һЩ�ڵ�һ���и��ŵ��������
perfectFirstColumn = false;
while ~perfectFirstColumn
    % ���������ǱȽ�ϸ��
    if sum(pic(:,1)) > 0.5*size(pic,1)
        pic(:,1) = [];
        continue
    end
    idx = find(pic(:,1));
    % ��ο�ֵҲ���У�Ӧ���ǽ�ͼ�ش��ˣ�
    if isempty(idx)
        pic(:,1) = [];
        continue
    end
    % ͨ�������㷨��鱾���Ƿ���ͨ
    % neighbor�ڽ�״̬Ϊ��ʶ�������������߽�
    neighbor = [idx(1),idx(1)]; % ����һ�����
    while  neighbor(1)>=1 && pic(neighbor(1),1)
        neighbor(1) = neighbor(1) - 1;
    end
    while  neighbor(2)<=size(pic,1) && pic(neighbor(2),1)
        neighbor(2) = neighbor(2) + 1;
    end
    % neighbor���ŵ������Ե
    if neighbor(2)-neighbor(1) - 1  >= length(idx) % ���ŵ������е�
        perfectFirstColumn = true;
    else
        pic(:,1) = []; % ���ǲ���̫�ֱ��ˣ�
    end
end
% ������ֵ���м�¼����f
f = zeros(size(pic,2),1);
nRows = size(pic,1);
nColumns = size(pic,2);
waitForInterpolation = false;
lastValid = 0;
for ii=1:nColumns
    % Ѱ��3���ھ��������ص㣨���ǣ�
    neighbor = myExpand(neighbor,3,nRows);
    idx = find(pic(neighbor(1):neighbor(2),ii));
    idx = neighbor(1)-1 + idx; % �ָ�Ϊpic������
    % ��ֵ���
    if isempty(idx)
        waitForInterpolation = true;
%         neighbor = [1,nRows]; % ������������ȫ��
        neighbor = myExpand(neighbor,3,nRows); % ��������������
        continue
    end
    % ���idx�İ����к��д���0����Ӧ���������˶�ֵ
    if length(idx) / ( idx(end) - idx(1) ) < 0.75
        % ��ʱӦ�ôӾ�����һ�У������Ч�У�����ĵ㿪ʼ������������
        % �������̫��Ŀ������̫ϸ�������м�ϣ������������������ȥ
        core = nearest(idx,f(lastValid-1));
        %  ʹ�������㷨
        neighbor = [idx(core),idx(core)]; % ����һ�����
        while  neighbor(1)>=1 && any(neighbor(1) == idx)
            neighbor(1) = neighbor(1) - 1;
        end
        while  neighbor(2)<=nColumns && any(neighbor(2) == idx)
            neighbor(2) = neighbor(2) + 1;
        end
%         idx = idx(neighbor(1)+1:neighbor(2)-1);
        idx = idx( find(idx==neighbor(1)+1):find(idx==neighbor(2)-1) );
    end
    % ��ȡȫ���ھ��������ص���ͨ�������ţ�
    % neighbor�������ŵ����Ե(�������)
    if idx(1)==neighbor(1) % �б�Ҫ��������
        neighbor(1) = neighbor(1) - 1;
        while  neighbor(1)>=1 && pic(neighbor(1),ii)
            neighbor(1) = neighbor(1) - 1;
        end
%         idx = [(neighbor(1)+1:idx(1)-1)'; idx];
    else % �����Ҫ��������Ҫ�ֶ��ս�
        neighbor(1) = idx(1)-1;
    end
    if idx(end)==neighbor(2) % �б�Ҫ��������
        neighbor(2) = neighbor(2) + 1;
        while  neighbor(2)<=nRows && pic(neighbor(2),ii)
            neighbor(2) = neighbor(2) + 1;
        end
%         idx = [idx; (idx(end)+1:neighbor(2)-1)'];
    else % �����Ҫ��������Ҫ�ֶ��ս�
        neighbor(2) = idx(end)+1;
    end
    idx = [(neighbor(1)+1:idx(1)-1)'; idx; (idx(end)+1:neighbor(2)-1)'];
    
    % ȡ��ֵ
    f(ii) = mean(idx);
    % һ���뿪��ֵ���䣬�������Բ�ֵ���ؿ�ֵ
    if waitForInterpolation
        tmp = linspace(f(lastValid), f(ii),...
            ii-lastValid+1);
        f(lastValid+1:ii-1) = tmp(2:end-1)';
        waitForInterpolation = false;
    end
    lastValid = ii;
end
% ��������һ�ο�ֵ��Ӧ���ǽ�ͼ�ش��ˣ�
if waitForInterpolation
    f(lastValid:end) = [];
end

f = nRows-f+1;
f = f - min(f(:));
f = f / max(f(:)); % ����ֵ��+��һ��
% f(f<0.001) = 0.001;

%% test
subplot(2,1,1)
imshow(picfile)
subplot(2,1,2)
plot(f)

end

%%
function interval = myExpand(interval,n,max)
% ����������interval����n���������������е��������
% ��������˵�Ϊ������
% ��������˵�С���Ͻ�max
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
% ������a���ҳ���ӽ�t���Ǹ�Ԫ�ص�λ��
[~,core] = min( abs(a-t) );
end