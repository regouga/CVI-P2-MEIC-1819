clear all, close all

    % Construct a questdlg with three options
    choice = questdlg('Choose your dataset', ...
        'Image', ...
        'Training','Testing','Training');
        %   opt1  ,   opt2  , optselected
    % Handle response
    switch choice
        case 'Training'
           path = ['Dataset' filesep 'img1' filesep]; 
           nFrame = 795;
           videoSelected = 'CVI - Project 2 (Training Camera 1)';
        case 'Testing'
           path = ['Dataset' filesep 'img1' filesep]; 
           nFrame = 795;
           videoSelected = 'CVI - Project 2 (Testing Camera 1)';
    end
    delete(gcf)
    close all

    frameIdComp = 6;     
    str  = ['%s%.' num2str(frameIdComp) 'd.%s'];
    step = 1;
    %step = 12;
    max = nFrame-step + 1;
    i = 1;
    th = 35;
    
    merge = false;
    split = false;
    swarning = false;
    mwarning = false;
    prev_num = 0;

    % Construct a questdlg with three options
    choice = questdlg('Choose your background detection', ...
        'Image', ...
        'Median','Equation','Equation');
        %   opt1  ,   opt2  , optselected

    bar = waitbar(0, 'Calculating background...','Name','CVI - Project 2', 'Color', 'w');    
    % Handle response
    switch choice
        case 'Median'
           vid4D = zeros([576 768 3 nFrame/step]);
           for k = 1 : step : max
                str1  = sprintf(str,path,k,'jpg');
                img   = imread(str1);
                vid4D(:,:,:,i)=rgb2gray(img);
                i = i + 1; 
                waitbar(k/max,bar);
           end
           bkg = median(vid4D,4);
           figure;imagesc(uint8(bkg));
        case 'Equation'
           str1  = sprintf(str,path,1,'jpg');
           img   = imread(str1);
           bkg = zeros(size(img));
           alfa = 0.01;  %experimentar para v?rios valores de alfa
           for i = 1 : step : nFrame
               str1  = sprintf(str,path,i,'jpg');
               img   = imread(str1);
               Y     = img;
               bkg   = alfa * double(Y) + (1-alfa) * double(bkg);
               waitbar(i/nFrame,bar);
           end
    end

    close(bar);
    
    figure('Name',videoSelected,'NumberTitle','off', 'units','normalized', 'outerposition',[0 0 1 1])

    for k = 1 : step : max
                str1 = sprintf(str,path,k,'jpg');
                img  = imread(str1);
                diff = (abs(double(bkg(:,:,1)) - double(img(:,:,1))) > th) |...
                       (abs(double(bkg(:,:,2)) - double(img(:,:,2))) > th) |...
                       (abs(double(bkg(:,:,3)) - double(img(:,:,3))) > th);

                %--------------------------------------------------------------------------------------
                diff = bwareaopen(diff, 100);
                
                se1 = strel('disk',2); 
                diff = imerode(diff, se1);
                
                se2 = strel('disk',8);                
                diff = imdilate(diff, se2);
                
                diff = bwconvhull(diff, 'objects');
                
                [lb, num]= bwlabel(diff);
                props = regionprops(lb, 'BoundingBox', 'Area');
                objects = [props.Area];
                
                subplot(1,2,1),imshow(diff);
                title('Subplot 1: Regions Detected');
                text(10, 550, strcat('Total Objects: ' , int2str(num)), 'color', 'k', 'backgroundcolor', 'w');
                
                subplot(1,2,2),imshow(img);
                title('Subplot 2: Bounding Boxes');
                t = text(10, 550, strcat('Frame: ' ,int2str(k)), 'color', 'w', 'backgroundcolor', 'k');

                if num > 0
                    for j = 1 : num
                        split = false;            

                        if (find(objects(:) > 3400) & num < prev_num)
                            merge = true;
                            
                        elseif(merge && num > prev_num)
                            merge = false;
                            split = true;
                        end
                        
                        if(not(mwarning) && merge)
                            mergeTxt = text(10, 500,' MERGE ', 'color', 'k', 'backgroundcolor', 'g');
                            mwarning = true;
                        end
                        
                        if(not(swarning) && (split > 0))
                            splitTxt = text(10, 450,' SPLIT ', 'color', 'k', 'backgroundcolor', 'g');
                            split = false;
                            swarning = true;
                        end
                    end
                    swarning = false;
                    mwarning = false;
                end      

                if k==1
                   propsPrev = props; 
                end
                matrix = zeros(length(props),length(propsPrev));
                
        for index=1 : length(props)
            for index2=1 : length(propsPrev)
                
                       x = props(index).BoundingBox(1) -  propsPrev(index2).BoundingBox(1);
                       y = props(index).BoundingBox(2) -  propsPrev(index2).BoundingBox(2);

                       distance = sqrt(x*x + y*y);

                       if distance > 2 && distance < 50 
                            matrix(index,index2) = 1;
                       end
  
                if matrix(index,index2) == 1
                    if props(index).Area > 150
                        if props(index).BoundingBox(3) / props(index).BoundingBox(4) > 1.1
                            rectangle('Position', [props(index).BoundingBox(1),props(index).BoundingBox(2),props(index).BoundingBox(3),props(index).BoundingBox(4)], 'EdgeColor', 'r', 'LineWidth', 3);
                            text(props(index).BoundingBox(1),props(index).BoundingBox(2)-10,'Car','color', 'w', 'backgroundcolor', 'r');

                        elseif (abs(props(index).BoundingBox(3) / props(index).BoundingBox(4) - 1) < 0.3)
                            rectangle('Position', [props(index).BoundingBox(1),props(index).BoundingBox(2),props(index).BoundingBox(3),props(index).BoundingBox(4)], 'EdgeColor', 'y', 'LineWidth', 3);
                            text(props(index).BoundingBox(1),props(index).BoundingBox(2) - 10,'Other','color', 'black','backgroundcolor', 'y');

                        else
                            rectangle('Position', [props(index).BoundingBox(1),props(index).BoundingBox(2),props(index).BoundingBox(3),props(index).BoundingBox(4)], 'EdgeColor', 'b', 'LineWidth', 3);
                            text(props(index).BoundingBox(1),props(index).BoundingBox(2) - 10,'Person','color', 'w','backgroundcolor', 'b');
                        end
                    end
                end
                
            end
        end

        propsPrev = props;
        drawnow
        hold off;
        prev_num =  num;

    end

delete(gcf)
close all