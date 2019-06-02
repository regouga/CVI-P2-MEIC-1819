clear all, close all

img = imread('3DMOT2015/train/PETS09-S2L1/img1/000001.jpg');
fid = fopen('3DMOT2015/train/PETS09-S2L1/gt/gt.txt');
tline = fgets(fid);

baseNum = 1;
seqLength = 794;

se = strel('disk',3);

figure;

split = strsplit(tline, ',');
frame_id = split(1,1);
top_left = [str2double(split(1,3)),str2double(split(1,4))];
area = [str2double(split(1,5)),str2double(split(1,6))];
f = str2double(split(1,1));
disp(f);


for i = 1:seqLength
    imgfr = imread(sprintf('3DMOT2015/train/PETS09-S2L1/img1/%.6d.jpg',i));
    imshow(imgfr); hold on;
    while f == i
        
        rectangle('Position',[top_left(1,1) top_left(1,2) area(1,1) area(1,2)], 'EdgeColor',[1 0 0],'linewidth', 2 );
        tline = fgets(fid);
        split = strsplit(tline, ',');
        top_left = [str2double(split(1,3)),str2double(split(1,4))];
        area = [str2double(split(1,5)),str2double(split(1,6))];
        f = str2double(split(1,1));
        disp(f);
    end
    drawnow;
        
    
end


