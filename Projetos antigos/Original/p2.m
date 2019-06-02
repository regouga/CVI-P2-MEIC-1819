% Clear workspace
clc;
close all;
clear;

% Enable sound
beep on;

% Show bar
prompt = {'Enter source type (video or picture):','Enter mode (box, path or plot):'};
dlg_title = 'Input';
num_lines = 1;
defaultans = {'video','box'};
answer = inputdlg(prompt,dlg_title,num_lines,defaultans);

type = answer(1);
mode = answer(2);

% Variables
k = 1; % Differences index
alfa = 0.05; % Background computation
ths = 29; % Threshold for difference
n_train = 300; % Amount of train frames
ahead = 0; % Start in frame %d

nFrame = 795;
step = 1;

nF = 1;
nOD = 0;
merge = false;
split = false;
split_warning = false;
merge_warning = false;
split_count = 0;

prev_num = 0;

maxObjs = 10;

pathing = zeros(2, nFrame, 5);
d = zeros([576 768 nFrame/step]);
previous_bw = zeros([576 768]);

if(strcmp(type,'picture')) % If the user wants picture type
    path = ['Dataset' filesep 'img1' filesep]; 
    frameIdComp = 6;
    str2 = ['%s%.' num2str(frameIdComp) 'd.%s'];
    vid3D = zeros([576 768 nFrame/step]);
    bkg = zeros(576, 768);
elseif(strcmp(type,'video')) % If the user wants movie type
    path = ['Dataset' filesep 'img1' filesep]; 
    file = 'camera1.mp4';
    str1 = strcat(path, file);
    vid = VideoReader(str1);
    vid3D = zeros([vid.Height vid.Width nFrame/step]);
    bkg = zeros(vid.Height, vid.Width);
else
    errordlg('Invalid type','Type Error');
end


h = waitbar(0, 'Getting the background, please wait...');

if(strcmp(type,'picture')) % If the user wants picture type
   for i = 1 : step : n_train
        str1 = sprintf(str2,path,i,'jpg');
        img = imread(str1);
        vid3D(:,:,k) = rgb2gray(img);
        bkg = alfa * double(vid3D(:,:,k)) + (1-alfa) * double(bkg);
        waitbar(i/n_train, h); 
        k = k + 1;
    end
else
    for i = 1 : step : n_train
        img = read(vid,i);
        vid3D(:,:,k) = rgb2gray(img);
        bkg = alfa * double(vid3D(:,:,k)) + (1-alfa) * double(bkg);
        waitbar(i/n_train, h); 
        k = k + 1;
    end
end

close(h);
beep;

if(strcmp(mode,'box'))
    figure('Name','Applying algorithm with box mode','NumberTitle','off'), hold on;
    for i = n_train + ahead : step : nFrame
        if(strcmp(type,'picture'))
            str1 = sprintf(str2,path,i,'jpg');
            img = imread(str1);
        else
            img = read(vid,i);
        end

        vid3D(:,:,k) = rgb2gray(img);

        bw = (abs(vid3D(:,:,k) - bkg) > ths);
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

        imshow(img); hold on;

        if num > 0
            for j = 1 : num
                split = false;
                boundingBox = stats(j).BoundingBox;
                if (find(objects(:) > 3400) & num < prev_num)
                    merge = true;
                elseif(merge && num > prev_num)
                    merge = false;
                    split = true;
                    split_count = 15;
                end
                if (boundingBox(3)/boundingBox(4) > 1.1) %boundingBox(3) = width; boundingBox(4) = height. When width > height, it is a car
                    t = text(boundingBox(1), boundingBox(2) - 12, 'Car');
                    t.Color = [1.0 0.0 0.0];
                    t.FontSize = 16;
                    color = 'r';
                elseif (abs(boundingBox(3)/boundingBox(4) - 1) < 0.3)
                    t = text(boundingBox(1), boundingBox(2) - 12, 'Other');
                    t.Color = [0.0 1.0 0.0];
                    t.FontSize = 16;
                    color = 'g';
                else
                    t = text(boundingBox(1), boundingBox(2) - 12, 'Person');
                    t.Color = [0.0 0.0 1.0];
                    t.FontSize = 16;
                    color = 'b';
                end
                rectangle('Position', boundingBox, 'EdgeColor',color, 'LineWidth', 2);
                if(not(merge_warning) && merge)
                    str = 'MERGE';
                    t = text(0, 500,str);
                    s = t.Color;
                    t.Color = [1.0 1.0 0.0];
                    s = t.FontSize;
                    t.FontSize = 25;
                    merge_warning = true;
                end
                if(not(split_warning) && (split || split_count > 0))
                    str = 'SPLIT';
                    t = text(0, 420,str);
                    t.Color = [0.0 1.0 1.0];
                    t.FontSize = 25;
                    split_count = split_count - 1;
                    split = false;
                    split_warning = true;
                end
            end
            split_warning = false;
            merge_warning = false;
        end
        drawnow;
        hold off;
        prev_num =  num;
        k = k + 1;
    end
elseif(strcmp(mode,'path'))
    figure('Name','Applying algorithm with path mode','NumberTitle','off');
    %figure;
    for i = n_train : step : nFrame
        if(strcmp(type,'picture'))
            str1 = sprintf(str2,path,i,'jpg');
            img = imread(str1);
        else
            img = read(vid,i);
        end

        vid3D(:,:,k) = rgb2gray(img);

        bw = (abs(vid3D(:,:,k) - bkg) > ths);
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
        
        nOD = max(nOD, length(objects));
        
        centroids = zeros(length(objects), 2); % To save (sum of lines, sum of columns) for each label
        for a = 1 : size(lb,1) % For each lines
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
            pathing(1, nF, l) = centroids(l,1);
            pathing(2, nF, l) = centroids(l,2);
        end

        %imshow(img); hold on;
        imagesc(uint8(vid3D(:, :, k))); colormap gray; hold on;
        axis off;

        for a = 1 : num
            x_plot = [];
            y_plot = [];
            for j = 1 : nF
                x_plot = [ x_plot pathing(1, j, a) ];
                y_plot = [ y_plot pathing(2, j, a) ];
            end
            if(stats(a).BoundingBox(3) / stats(a).BoundingBox(4) > 1)
                plot(y_plot, x_plot, 'r.', 'MarkerSize', 5);
            else
                plot(y_plot, x_plot, 'b.', 'MarkerSize', 5);
            end
            drawnow;
        end
        hold off;
        nF = nF + 1;
        k = k + 1;
    end
elseif(strcmp(mode,'plot'))
    numbers = zeros(nFrame/step, maxObjs);
    centroids = zeros(maxObjs, 2, nFrame/step);
    h = waitbar(0, 'Getting the values, please wait...');
    index = 1;
    for i = n_train : step : nFrame
        if(strcmp(type,'picture'))
            str1 = sprintf(str2,path,i,'jpg');
            img = imread(str1);
        else
            img = read(vid,i);
        end

        vid3D(:,:,k) = rgb2gray(img);

        bw = (abs(vid3D(:,:,k) - bkg) > ths);
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
        waitbar((i - n_train)/(nFrame - n_train), h);
    end
    close(h);
    beep;
    
    figure('Name','Areas along time','NumberTitle','off');
    hold on;
    plot(numbers(:,1),'y-');
    plot(numbers(:,2),'r--');
    plot(numbers(:,3),'g:');
    plot(numbers(:,4),'b--o');
    plot(numbers(:,5),'k-*');
    legend('1','2','3','4','5');
    hold off;
    beep;
    figure('Name','Centroids along time (x/y)','NumberTitle','off');
    h = waitbar(0, 'Ploting x, please wait...');
    subplot(2, 1, 1), hold on;
    for k = 1 : nFrame/step
        plot(k, centroids(1,1,k), 'b.',  'LineWidth', 2);
        plot(k, centroids(2,1,k), 'ro', 'LineWidth', 2);
        plot(k, centroids(3,1,k), 'g*', 'LineWidth', 2);
        plot(k, centroids(4,1,k), 'y.', 'LineWidth', 2);
        plot(k, centroids(5,1,k), 'ko', 'LineWidth', 2);
        waitbar(k/(nFrame/step), h);
    end
    legend('1','2','3','4','5');
    hold off;
    close(h);
    beep;
    subplot(2, 1, 2), hold on;
    h = waitbar(0, 'Ploting y, please wait...');
    for k = 1 : nFrame/step
        plot(k, centroids(1,2,k), 'b.',  'LineWidth', 2);
        plot(k, centroids(2,2,k), 'ro', 'LineWidth', 2);
        plot(k, centroids(3,2,k), 'g*', 'LineWidth', 2);
        plot(k, centroids(4,2,k), 'y.', 'LineWidth', 2);
        plot(k, centroids(5,2,k), 'ko', 'LineWidth', 2);
        waitbar(k/(nFrame/step), h);
    end
    legend('1','2','3','4','5');
    hold off;
    close(h);
    beep;
    figure('Name','Centroids along time','NumberTitle','off'); hold on;
    h = waitbar(0, 'Plotting the centroids (x,y), please wait...');
    for k = 1 : nFrame/step
        plot(centroids(1,1,k), centroids(1,2,k), 'b.',  'LineWidth', 2);
        plot(centroids(2,1,k), centroids(2,2,k), 'ro', 'LineWidth', 2);
        plot(centroids(3,1,k), centroids(3,2,k), 'g*', 'LineWidth', 2);
        plot(centroids(4,1,k), centroids(4,2,k), 'y.', 'LineWidth', 2);
        plot(centroids(5,1,k), centroids(5,2,k), 'ko', 'LineWidth', 2);
        waitbar(k/(nFrame/step), h);
    end
    legend('1','2','3','4','5');
    hold off;
    close(h);
else
    errordlg('Invalid mode','Mode Error');
end
beep;