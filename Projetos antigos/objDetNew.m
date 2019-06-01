clear all
imgbk = imread('Dataset/img1/000001.jpg');

thr = 40;
minArea = 10;

baseNum = 1;
seqLength = 100;

se = strel('disk',3);

figure;

for i=0:seqLength
    imgfr = imread(sprintf('Dataset/img1/%.6d.jpg',baseNum+i));
    imshow(imgfr);
    
    imgdif = ...
        (abs(double(imgbk(:,:,1))-double(imgfr(:,:,1)))>thr) | ...
        (abs(double(imgbk(:,:,2))-double(imgfr(:,:,2)))>thr) | ...
        (abs(double(imgbk(:,:,3))-double(imgfr(:,:,3)))>thr);
    
    %imshow(imgdif);
    bw = imclose(imgdif,se);
    %imshow(bw);
    %figure(2);
    %subplot(1,2,1); imshow(imgdif);
    %subplot(1,2,2); imshow(bw);
    %pause
    
    [lb num]=bwlabel(bw);
    regionProps = regionprops(lb,'area','FilledImage','Centroid');
    inds = find([regionProps.Area]>minArea);
    
    regnum = length(inds);
    
    
    BW_aux = zeros(size(lb));
    if regnum
        for j=1:regnum
            [lin col]= find(lb == inds(j));
            BW_aux(lin,col) = 1;
            
            upLPoint = min([lin col]);
            dWindow = max([lin col]) - upLPoint + 1;
            
            rectangle('Position', [fliplr(upLPoint) fliplr(dWindow)], 'EdgeColor', [1,1,0],...
               'linewidth',2);
        end
    end
    figure(3);
    subplot(1,2,1); imshow(bw);
    subplot(1,2,2); imshow(BW_aux);
    %pause
    drawnow
end