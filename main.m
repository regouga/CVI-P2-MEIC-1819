clear all, close all

totalF = 795;
trainF = 200;
step = 1;
currentFrame = 1;
k = 1;
threshold = 50;
previous_bw = zeros([576 768]);
alfa = 0.01;
path = '3DMOT2015/train/PETS09-S2L1/img1/';
str2 = ['%s%.' num2str(6) 'd.%s'];
T = readtable('3DMOT2015/train/PETS09-S2L1/gt/gt.txt');
disp(T(1,1));
maxObjs = 8;
frameNumb = 1;

vid3D = zeros([576 768 trainF/step]);
bkg = zeros(576, 768);


for i = 1 : step : totalF
        img = imread(sprintf('3DMOT2015/train/PETS09-S2L1/img1/%.6d.jpg',i));
        vid3D(:,:,k) = rgb2gray(img);
        bkg = alfa * double(vid3D(:,:,k)) + (1-alfa) * double(bkg);
        k = k + 1;
        % NOTE1: loop part of code that contributed to removal of people
        % and leaves the background only, useful for trajectory drawing?
        %vid4D(:,:,:,i) = img;
        %imshow(img);
end
%Background only, see NOTE1 above
%bkg = median(vid4D,4);
%figure;imagesc(uint8(bkg));

precisions = []
recalls = []
ious = []

for i = 1 : step : trainF
        TP = 0;
        FP = 0;
        FN = 0;
        img = imread(sprintf('3DMOT2015/train/PETS09-S2L1/img1/%.6d.jpg',i));
        i_table = T(T.Var1 == i, :);
        
        vid3D(:,:,k) = rgb2gray(img);

        bw = (abs(vid3D(:,:,k) - bkg) > threshold);
        bw_final = bwareaopen(bw, 100);
        bw_final = bwmorph(bw_final,'close');
        se = strel('disk', 2);
        bw_final = imdilate(bw_final,se);
        se = strel('disk', 5);
        bw_final = imclose(bw_final,se);
        bw_final = bwareaopen(bw_final, 350);
        bw_image = (bw_final + previous_bw) > 0;
        previous_bw = bw_final; 
        

        [lb, num]= bwlabel(bw_image);
        disp(num)
        stats = regionprops(lb);
        objects = [stats.Area];

        imshow(img); hold on;
        
        truth_boxes = [];
        current_boxes = [];

        if num > 0
            for j = 1 : num
                boundingBox = stats(j).BoundingBox;
                t = text(boundingBox(1), boundingBox(2) - 12, strcat('Person', num2str(j)));
                t.Color = [0.0 0.0 1.0];
                t.FontSize = 10;
                color = 'b';
                current = rectangle('Position', boundingBox, 'EdgeColor',color, 'LineWidth', 2);
                current_boxes = [current_boxes ;[get(current, 'Position')]];
                for z = 1 : size(i_table)
                    truth = rectangle('Position',[i_table.Var3(z) i_table.Var4(z) i_table.Var5(z) i_table.Var6(z)], 'EdgeColor',[1 0 0],'linewidth', 2 );
                    truth_boxes = [truth_boxes ; [get(truth, 'Position')]];
                end
            end
        end
        overlapRatio = bboxOverlapRatio(truth_boxes, current_boxes);
        
        for c = 1: size(overlapRatio, 2)
            if max(overlapRatio(:,c) > 0.5)
                TP = TP + 1;
            else
                FN = FN + 1;
            end    
        end
        
        FP = size(overlapRatio,1) - TP;
        
        current_precision = TP / (TP + FP);
        
        current_recall = TP / (TP + FN);
        
        precisions = [precisions current_precision];
        recalls = [recalls current_recall];
        
        
        ious = [ ious mean(max(overlapRatio)) ];

        drawnow;
        hold off;
        prev_num =  num;
        k = k + 1;
end

figure(3);
scatter(recalls, precisions,'filled'),axis([0 1 0 1]),xlabel('Recall'),ylabel('Precision'),title('Precision - Recall Curve');

th = [0, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.40, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1];
sumt = [];
sum2 = 0;

for b = 1 : length(th)
    sum2 = 0;
    for c = 1 : length(ious)
        if ious(c) > th(b)
            sum2 = sum2 + 1;
        end    
    end
    sumt = [ sumt ; sum2 ];
    disp(sumt);
end

figure(2);
bar(th, (sumt / length(ious))*100),xlabel('Thresholds'),ylabel('Percentage'),title('Success Plot');



for i = trainF : step : totalF
        figure(1);
        img = imread(sprintf(str2,path,i,'jpg'));

        vid3D(:,:,k) = rgb2gray(img);

        bw = (abs(vid3D(:,:,k) - bkg) > threshold);
        bw_final = bwareaopen(bw, 100);
        bw_final = bwmorph(bw_final,'close');
        se = strel('disk', 2);
        bw_final = imdilate(bw_final,se);
        se = strel('disk', 5);
        bw_final = imclose(bw_final,se);
        bw_final = bwareaopen(bw_final, 400);
        bw_image = (bw_final + previous_bw) > 0;
        previous_bw = bw_final; 
        
        [lb, num]= bwlabel(bw_image);
        stats = regionprops(lb);
        objects = [stats.Area];
        
        centroids = zeros(length(objects), 2); % To save (sum of lines, sum of columns) for each label
        for a = 1 : size(lb,1) % For each line
            for j = 1 : size(lb,2) % For each column
                if lb(a,j) ~= 0 % If it's not background
                    centroids(lb(a,j),1) = centroids(lb(a,j),1) + a; % Sum the lines
                    centroids(lb(a,j),2) = centroids(lb(a,j),2) + j; % Sum the columns
                end
            end
        end

        for l = 1 : length(objects) % For each object
            centroids(l,1) = centroids(l,1)/objects(l); % lines' = sum(lines)/area
            centroids(l,2) = centroids(l,2)/objects(l); % columns' = sum(columns)/area
            pathing(1, frameNumb, l) = centroids(l,1);
            pathing(2, frameNumb, l) = centroids(l,2);
        end

        %imshow(img); hold on;
        %takes image and returns a gray version. Colours are then used for
        %trajectory "breadcrumb" trails
        imagesc(uint8(vid3D(:, :, k))); colormap gray; hold on;
        axis off;
        
        %trajectory plotted on the image
        for a = 1 : num
            x_plot = [];
            y_plot = [];
            
            for j = 1 : frameNumb
                if pathing(1, j, a) > 0
                    x_plot = [ x_plot pathing(1, j, a) ];
                else
                    x_plot = [ x_plot nan ];    
                end
                
                if pathing(2, j, a) > 0
                    y_plot = [ y_plot pathing(2, j, a) ];
                else
                    y_plot = [ y_plot nan ];
                end
            end
             

            plot(y_plot, x_plot, '.', 'MarkerSize', 15);
  
            %drawn result
            drawnow;
        end
        hold off;
        frameNumb = frameNumb + 1;
        k = k + 1;
end

numbers = zeros(totalF/step, maxObjs);
centroids = zeros(maxObjs, 2, totalF/step);
index = 1;
for i = trainF : step : totalF
    str1 = sprintf(str2,path,i,'jpg');
    img = imread(str1);
    
    vid3D(:,:,k) = rgb2gray(img);
    
    bw = (abs(vid3D(:,:,k) - bkg) > threshold);
    bw_final = bwareaopen(bw, 100);
    bw_final = bwmorph(bw_final,'close');
    se = strel('disk', 2);
    bw_final = imdilate(bw_final,se);
    se = strel('disk', 5);
    bw_final = imclose(bw_final,se);
    bw_final = bwareaopen(bw_final, 350);
    bw_image = (bw_final + previous_bw) > 0;
    previous_bw = bw_final;
    
    [lb, num]= bwlabel(bw_image);
    stats = regionprops(lb);
    objects = [stats.Area];
    
    for a = 1 : length(objects) % For each object
        centroids(a,1,index) = stats(a).Centroid(1);
        centroids(a,2,index) = stats(a).Centroid(2);
        numbers(index,a) = objects(a);
    end
    
    k = k + 1;
    index = index + 1;
end

    figure('Name','Centroids along time (x/y)','NumberTitle','off');
    subplot(2, 1, 1), hold on;
    for k = 1 : totalF/step
        plot(k, centroids(1,1,k), 'b.',  'LineWidth', 2);
        plot(k, centroids(2,1,k), 'ro', 'LineWidth', 2);
        plot(k, centroids(3,1,k), 'g*', 'LineWidth', 2);
        plot(k, centroids(4,1,k), 'y.', 'LineWidth', 2);
        plot(k, centroids(5,1,k), 'ko', 'LineWidth', 2);
    end
    legend('1','2','3','4','5');
    hold off;
    subplot(2, 1, 2), hold on;
    for k = 1 : totalF/step
        plot(k, centroids(1,2,k), 'b.',  'LineWidth', 2);
        plot(k, centroids(2,2,k), 'ro', 'LineWidth', 2);
        plot(k, centroids(3,2,k), 'g*', 'LineWidth', 2);
        plot(k, centroids(4,2,k), 'y.', 'LineWidth', 2);
        plot(k, centroids(5,2,k), 'ko', 'LineWidth', 2);
    end
    legend('1','2','3','4','5');
    hold off;

    beep;
    figure('Name','Centroids along time','NumberTitle','off'); hold on;
    for k = 1 : totalF/step
        plot(centroids(1,1,k), centroids(1,2,k), 'b.',  'LineWidth', 2);
        plot(centroids(2,1,k), centroids(2,2,k), 'ro', 'LineWidth', 2);
        plot(centroids(3,1,k), centroids(3,2,k), 'g*', 'LineWidth', 2);
        plot(centroids(4,1,k), centroids(4,2,k), 'y.', 'LineWidth', 2);
        plot(centroids(5,1,k), centroids(5,2,k), 'ko', 'LineWidth', 2);
    end
    legend('1','2','3','4','5');
    hold off;