clc;
clear;

%% ����2������ͼ��
left = imread('iml1545.jpg');
right = imread('imr1545.jpg');
sizeI = size(left);

% ��ʾ����ͼ��
zero = zeros(sizeI(1), sizeI(2));
channelRed = left(:,:,1);
channelBlue = right(:,:,3);
composite = cat(3, channelRed, zero, channelBlue);

figure(1);
subplot(2,3,1);
imshow(left);
axis image;
title('��ͼ');

subplot(2,3,2);
imshow(right);
axis image;
title('��ͼ');

subplot(2,3,3);
imshow(composite);
axis image;
title('�ص�ͼ');

%% �����Ŀ�ƥ��

% ͨ�����������صĿ�ƥ������Ӳ�
disp('���л����Ŀ�ƥ��~');

% ������ʱ��
tic();

% ƽ��3����ɫͨ��ֵ��RGBͼ��ת��Ϊ�Ҷ�ͼ��
leftI = mean(left, 3);
rightI = mean(right, 3);


% SHD
%  bitsUint8 = 8;
% leftI = im2uint8(leftI./255.0);
% rightI = im2uint8(rightI./255.0);


% DbasicSubpixel�������ƥ��Ľ����Ԫ��ֵΪ������32λ������
DbasicSubpixel = zeros(size(leftI), 'single');

% ���ͼ���С
[imgHeight, imgWidth] = size(leftI);

% �ӲΧ�������1��ͼ���еĿ�λ�ö�������Զ����������ͼ���е�ƥ��顣
disparityRange = 50;

% �����ƥ��Ŀ��С
halfBlockSize = 5;
blockSize = 2 * halfBlockSize + 1;

% ����ͼ���е�ÿ�У�m������
for (m = 1 : imgHeight)
    	
	% Ϊģ��Ϳ�������С/����߽�
	% ���磺��1�У�minr = 1 �� maxr = 4
    minr = max(1, m - halfBlockSize);
    maxr = min(imgHeight, m + halfBlockSize);
	
    % ����ͼ���е�ÿ�У�n������
    for (n = 1 : imgWidth)
        
        % Ϊģ��������С/���߽�
        % ���磺��1�У�minc = 1 �� maxc = 4
		minc = max(1, n - halfBlockSize);
        maxc = min(imgWidth, n + halfBlockSize);
        
        % ��ģ��λ�ö���Ϊ�����߽磬��������ʹ�䲻�ᳬ��ͼ��߽� 
		% 'mind'Ϊ�ܹ���������ߵ������������'maxd'Ϊ�ܹ��������ұߵ����������
		% �������Ҫ��������������mindΪ0
		% ����Ҫ��˫��������ͼ������mindΪmax(-disparityRange, 1 - minc)
		mind = 0; 
        maxd = min(disparityRange, imgWidth - maxc);

		% ѡ���ұߵ�ͼ�������ģ��
        template = rightI(minr:maxr, minc:maxc);
		
		% ��ñ���������ͼ�����
		numBlocks = maxd - mind + 1;
		
		% ���������������ƫ��
		blockDiffs = zeros(numBlocks, 1);
        
		% ����ģ���ÿ���ƫ��
		for (i = mind : maxd)
		
			%ѡ�����ͼ�����Ϊ'i'���Ŀ�
			block = leftI(minr:maxr, (minc + i):(maxc + i));
		
			% �����Ļ���1�������Ž�'blockDiffs'����
			blockIndex = i - mind + 1;
		    
            %{
            % NCC��Normalized Cross Correlation��
            ncc = 0;
            nccNumerator = 0;
            nccDenominator = 0;
            nccDenominatorRightWindow = 0;
            nccDenominatorLeftWindow = 0;
            %}
            
            % ����ģ��Ϳ���ľ���ֵ�ĺͣ�SAD����Ϊ���
            for (j = minr : maxr)
                for (k = minc : maxc)
                    
                    % SAD��Sum of Absolute Differences��
                    blockDiff = abs(rightI(j, k) - leftI(j, k + i));
                    blockDiffs(blockIndex, 1) = blockDiffs(blockIndex, 1) + blockDiff;
                    
                    
                    %{
                    % NCC
                    nccNumerator = nccNumerator + (rightI(j, k) * leftI(j, k + i));
                    nccDenominatorLeftWindow = nccDenominatorLeftWindow + (leftI(j, k + i) * leftI(j, k + i));
                    nccDenominatorRightWindow = nccDenominatorRightWindow + (rightI(j, k) * rightI(j, k));
                    %}
                end
            end
            
            % SAD
            blockDiffs(blockIndex, 1) = sum(sum(abs(template - block)));
            
            
            %{
            % NCC
            nccDenominator = sqrt(nccDenominatorRightWindow * nccDenominatorLeftWindow);
            ncc = nccNumerator / nccDenominator;
            blockDiffs(blockIndex, 1) = ncc;
            %}
            
            %{
            % SHD��Sum of Hamming Distances��
            blockXOR = bitxor(template, block);
            distance = uint8(zeros(maxr - minr + 1, maxc - minc + 1));
            for (k = 1 : bitsUint8)
                distance = distance + bitget(blockXOR, k);
            end
            blockDiffs(blockIndex, 1) = sum(sum(distance));
            %}
		end
		
		% SADֵ�����ҵ����ƥ�䣨��Сƫ����������Ҫ�����б�

        % SAD/SSD/SHD
        [temp, sortedIndeces] = sort(blockDiffs, 'ascend');

        %{
        % NCC
        [temp, sortedIndeces] = sort(blockDiffs, 'descend');
        %}
        % ������ƥ���Ļ���1������
		bestMatchIndex = sortedIndeces(1, 1);
		
        % ���ÿ����1�������ָ�Ϊƫ����
		% ���ǻ����Ŀ�ƥ������������Ӳ���
		d = bestMatchIndex + mind - 1;
		
        
		% ͨ����������Ӳ�������ع���
		% �����ع���Ҫ�������ұߵĿ�, ����������ƥ������������ı�Ե����Թ���
		if ((bestMatchIndex == 1) || (bestMatchIndex == numBlocks))
			% ���������ع��Ʋ������ʼ�Ӳ�ֵ
			DbasicSubpixel(m, n) = d;
		else
			% ȡ���ƥ��飨C2����SADֵ��������ھӣ�C1��C3��
			C1 = blockDiffs(bestMatchIndex - 1);
			C2 = blockDiffs(bestMatchIndex);
			C3 = blockDiffs(bestMatchIndex + 1);
			
			% �����Ӳ�������ƥ��λ�õ�������λ��
			DbasicSubpixel(m, n) = d - (0.5 * (C3 - C1) / (C1 - (2 * C2) + C3));
        end
        
        %{
        DbasicSubpixel(m, n) = d;
        %}
    end

	% ÿ10�и��¹���
	if (mod(m, 10) == 0)
		fprintf('ͼ���У�%d / %d (%.0f%%)\n', m, imgHeight, (m / imgHeight) * 100);
    end		
end

% ��ʾ����ʱ��
elapsed = toc();
fprintf('�����Ӳ�ͼ���� %.2f min.\n', elapsed / 60.0);

%% ��ʾ�Ӳ�ͼ
fprintf('��ʾ�Ӳ�ͼ~\n');

% �л���ͼ��4
subplot(2,3,4);
% ��2������Ϊ�վ��󣬴Ӷ�����imshow�����ݵ���С/���ֵ������ӳ�����ݷ�Χ����ʾ��ɫ
imshow(DbasicSubpixel, []);
title('�Ӳ�ͼ');

%��ֵ�˲�������ѡ��25*25��Ϊ����
DbasicSubpixel_2 = medfilt2(DbasicSubpixel,[25 25]);
subplot(2,3,5);
imshow(DbasicSubpixel_2,[]);
title('�˲���');

% ȥ����ɫͼ����ʾ�Ҷ��Ӳ�ͼ
% colormap('jet');
% colorbar;



