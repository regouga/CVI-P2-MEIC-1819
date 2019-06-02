clear all, close all

totalFrames = 795;
step = 1;
currentFrame = 1;
k = 1;
threshold = 10;
previous_bw = zeros([576 768]);


vid3D = zeros([576 768 totalFrames/step]);
bkg = zeros(576, 768);

for i = 1 : step : totalFrames
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
        figure;
        imshow(bw_image);
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