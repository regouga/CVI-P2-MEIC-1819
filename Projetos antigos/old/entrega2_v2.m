clear all, close all

% -------------------------------- INICIAL MENU --------------------------------
% Construct a questdlg with three options
    choice = questdlg('Choose your dataset', ...
        'Image', ...
        'Training','Testing','Training');
        %   opt1  ,   opt2  , optselected
    % Handle response
    switch choice
        case 'Training'
           path = ['Dataset' filesep 'TRAINING_CAMERA1_JPEGS' filesep]; 
           nFrame = 3064;
        case 'Testing'
           path = ['Dataset' filesep 'TESTING_CAMERA1_JPEGS' filesep];
           nFrame = 2688;
    end
    delete(gcf)
    close all

frameIdComp = 4;     
str  = ['%s%.' num2str(frameIdComp) 'd.%s'];
step = 4;
max = nFrame-step + 1;
i = 1;
th = 35;

% -------------------------------- MENU TO CHOOSE MEDIAN OR EQUATION --------------------------------
% Construct a questdlg with three options
    choice = questdlg('Choose your background detection', ...
        'Image', ...
        'Median','Equation','Equation');
        %   opt1  ,   opt2  , optselected
    % Handle response
    switch choice
        case 'Median'
           disp('Running Median...');
           vid4D = zeros([576 768 3 nFrame/step]);
           for k = 1 : step : max
                str1  = sprintf(str,path,k,'jpg');
                img   = imread(str1);
                vid4D(:,:,:,i)=img;
                i = i + 1; 
           end
           bkg = median(vid4D,4);
           figure;imagesc(uint8(bkg));
        case 'Equation'
           disp('Running Equation...');
           str1  = sprintf(str,path,1,'jpg');
           img   = imread(str1);
           bkg = zeros(size(img));
           alfa = 0.01;  %experimentar para v?rios valores de alfa
           for i = 1 : step : nFrame
               str1  = sprintf(str,path,i,'jpg');
               img   = imread(str1);
               Y     = img;
               bkg   = alfa * double(Y) + (1-alfa) * double(bkg);
           end
    end

    % -------------------------------- MENU TO CHOOSE RGB OR BLACK&WHITE --------------------------------
    % Construct a questdlg with three options
    choice = questdlg('Choose your option', ...
        'Image', ...
        'RGB','B&W','RGB');
        %   opt1  ,   opt2  , optselected
    % Handle response
    switch choice
        % ------------------------------------------------------ RGB ----------------------------------------------------------------
        case 'RGB'
            disp('Running Active Pixels RGB...');
            % Create push button
            % btn = uicontrol('Style', 'pushbutton', 'String', 'Clear',...
            %           'Position', [20 20 50 20],...
            %           'Callback', 'cla');  
                
            mytxt = uicontrol('Style','text','String','Close');
            mytxt.Enable = 'Inactive';
            mytxt.ButtonDownFcn = 'disp(''Text was clicked'')';
            
            for k = 1 : step : max
                str1 = sprintf(str,path,k,'jpg');
                img  = imread(str1);
                diff = (abs(double(bkg(:,:,1)) - double(img(:,:,1))) > th) |...
                       (abs(double(bkg(:,:,2)) - double(img(:,:,2))) > th) |...
                       (abs(double(bkg(:,:,3)) - double(img(:,:,3))) > th);
                
                % SE = strel('disk',R,N) creates a disk-shaped structuring element, where R specifies the radius. 
                % N specifies the number of line structuring elements used to approximate the disk shape. 
                % N must be 0, 4, 6, or 8.
                se1 = strel('disk',4);   
                   
                %IM2 = imerode(IM,SE) erodes the grayscale, binary, or packed binary image IM, returning the eroded 
                %image IM2. The argument SE is a structuring element object or array of structuring element objects 
                %returned by the strel or offsetstrel functions.    
                diff = imerode(diff, se1);
                
                % SE = strel('disk',R,N) creates a disk-shaped structuring element, where R specifies the radius. 
                % N specifies the number of line structuring elements used to approximate the disk shape. 
                % N must be 0, 4, 6, or 8.
                se2 = strel('disk',8);  
                
                %IM2 = imdilate(IM,SE) dilates the grayscale, binary, or packed binary image IM, returning the dilated 
                %image, IM2. The argument SE is a structuring element object, or array of structuring element objects, 
                %returned by the strel or offsetstrel function.
                diff = imdilate(diff, se2);
                
                %Generate convex hull image from binary image
                %CH = bwconvhull(BW, method) specifies the desired method for computing the convex hull image.
                %'objects': Compute the convex hull of each connected component of BW individually. 
                %CH contains the convex hulls of each connected component.
                diff = bwconvhull(diff, 'objects');
                
                %BW2 = bwmorph(BW,operation) applies a specific morphological operation to the binary image BW.
                diff = bwmorph(diff,'fill');
                
                [lb, num] = bwlabel(diff);
                props = regionprops(lb,'BoundingBox', 'Area');
                              
                if k==1
                   propsPrev = props; 
                end
                matrix = zeros(length(props),length(propsPrev));

                for index=1 : length(props)
                    for index2=1 : length(propsPrev)
                       x = props(index).BoundingBox(1) -  propsPrev(index2).BoundingBox(1);
                       y = props(index).BoundingBox(2) -  propsPrev(index2).BoundingBox(2);

                       distance = sqrt(x*x + y*y);

                       if distance > 1 && distance < 40 
                            matrix(index,index2) = 1;
                       end
                    end
                end

               for index=1 : length(props)
                   for index2=1 : length(propsPrev)
                       if matrix(index,index2) == 1
                         rectangle('Position', [props(index).BoundingBox(1),props(index).BoundingBox(2),props(index).BoundingBox(3),props(index).BoundingBox(4)], 'EdgeColor', 'r', 'LineWidth', 2);
                       end
                   end
               end

               propsPrev = props;
                subplot(1,2,1),imshow(img); drawnow 
                subplot(1,2,2),imshow(diff, [])
            end
        % ------------------------------------------------------ B&W ----------------------------------------------------------------
        case 'B&W'
            disp('Running Active Pixels Black&White...');
            
            mytxt = uicontrol('Style','text','String','Close');
            mytxt.Enable = 'Inactive';
            mytxt.ButtonDownFcn = 'disp(''Text was clicked'')';
            
            for k = 1 : step : max
                str1 = sprintf(str,path,k,'jpg');
                img  = imread(str1);
                
                imgg = rgb2gray(img);
                level = graythresh(imgg);
                imgbw = im2bw(imgg, level);

                % SE = strel('disk',R,N) creates a disk-shaped structuring element, where R specifies the radius. 
                % N specifies the number of line structuring elements used to approximate the disk shape. 
                % N must be 0, 4, 6, or 8.
                se1 = strel('disk',4);   
                   
                %IM2 = imerode(IM,SE) erodes the grayscale, binary, or packed binary image IM, returning the eroded 
                %image IM2. The argument SE is a structuring element object or array of structuring element objects 
                %returned by the strel or offsetstrel functions.    
                imgbw = imerode(imgbw, se1);
                
                % SE = strel('disk',R,N) creates a disk-shaped structuring element, where R specifies the radius. 
                % N specifies the number of line structuring elements used to approximate the disk shape. 
                % N must be 0, 4, 6, or 8.
                se2 = strel('disk',8);  
                
                %IM2 = imdilate(IM,SE) dilates the grayscale, binary, or packed binary image IM, returning the dilated 
                %image, IM2. The argument SE is a structuring element object, or array of structuring element objects, 
                %returned by the strel or offsetstrel function.
                imgbw = imdilate(imgbw, se2);
                
                %Generate convex hull image from binary image
                %CH = bwconvhull(BW, method) specifies the desired method for computing the convex hull image.
                %'objects': Compute the convex hull of each connected component of BW individually. 
                %CH contains the convex hulls of each connected component.
                imgbw = bwconvhull(imgbw, 'objects');
                
                %BW2 = bwmorph(BW,operation) applies a specific morphological operation to the binary image BW.
                imgbw = bwmorph(imgbw,'fill');

                subplot(1,2,1),imshow(img); drawnow 
                subplot(1,2,2),imshow(imgbw, [])
            end
    end
    delete(gcf)
    close all

delete(gcf)
close all