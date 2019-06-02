clear all, close all

totalF = 795;
trainF = 200;
step = 1;
currentFrame = 1;
k = 1;
threshold = 60;
previous_bw = zeros([576 768]);
alfa = 0.02; % Background computation
path = '3DMOT2015/train/PETS09-S2L1/img1/';
str2 = ['%s%.' num2str(6) 'd.%s'];

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


for i = 1 : step : trainF
        img = imread(sprintf('3DMOT2015/train/PETS09-S2L1/img1/%.6d.jpg',i));
        
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

        if num > 0
            for j = 1 : num
                boundingBox = stats(j).BoundingBox;
                t = text(boundingBox(1), boundingBox(2) - 12, 'Person');
                t.Color = [0.0 0.0 1.0];
                t.FontSize = 16;
                color = 'b';
                rectangle('Position', boundingBox, 'EdgeColor',color, 'LineWidth', 2);
            end
        end
        drawnow;
        hold off;
        prev_num =  num;
        k = k + 1;
end


for i = trainF : step : totalF
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