clear all, close all

totalFrames = 795;
step = 1;
currentFrame = 1;
k = 1;
threshold = 40;
previous_bw = zeros([576 768]);
prev_num = 0;


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
        stats = regionprops(lb);
        objects = [stats.Area];

        imshow(img); hold on;

        if num > 0
            for j = 1 : num
                split = false;
                boundingBox = stats(j).BoundingBox;
                if (find(objects(:) > 3400) && num < prev_num)
                    merge = true;
                elseif(merge && num > prev_num)
                    merge = false;
                    split = true;
                    split_count = 15;
                end
                    t = text(boundingBox(1), boundingBox(2) - 12, 'Person');
                    t.Color = [0.0 0.0 1.0];
                    t.FontSize = 16;
                    color = 'b';
%                end
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