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
        path = 'Dataset\TRAINING_CAMERA1_JPEGS\'; nFrame = 3060;
    case 'Testing'
        path = 'Dataset\TESTING_CAMERA1_JPEGS\'; nFrame = 2688;
end
delete(gcf)
close all

frameIdComp = 4;
str  = ['%s%.' num2str(frameIdComp) 'd.%s'];
%step = 6;
step = 12;

vid4D = zeros([576 768 3 nFrame/step]);
max = nFrame-step + 1;
i = 1;

for k = 1 : step : max
    k
    str1  = sprintf(str,path,k,'jpg');
    disp(str1);
    img   = imread(str1);
    vid4D(:,:,:,i)=img;
    i = i + 1;
    imshow(img); drawnow
    hold off
    %pause(.2)
end

bkg = median(vid4D,4);
figure;imagesc(uint8(bkg));

% Turn off this warning "Warning: Image is too big to fit on screen; displaying at 33% "
% To set the warning state, you must first know the message identifier for the one warning you want to enable. 
% Query the last warning to acquire the identifier.  For example: 
warnStruct = warning('query', 'last');
% msgid_integerCat = warnStruct.identifier
% msgid_integerCat =
%    MATLAB:concatenation:integerInteraction
warning('off', 'Images:initSize:adjustingMag');