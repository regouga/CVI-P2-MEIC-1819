clear all, close all

% Construct a questdlg with three options
    choice = questdlg('Choose your dataset', ...
        'Image', ...
        'Training','Training');
        % 'Training','Testing','Training');
        %   opt1  ,   opt2  , optselected
    % Handle response
    switch choice
        case 'Training'
           path = 'Dataset\TRAINING_CAMERA1_JPEGS\'; frameIdComp = 4; nFrame = 3060;
        %case 'Testing'
           %path = 'Dataset\TESTING_CAMERA1_JPEGS\'; frameIdComp = 4; nFrame = 2688;
    end
    delete(gcf)
    close all
    
%disp(num2str(frameIdComp));
%disp(num2str(nFrame));

str  = ['%s%.' num2str(frameIdComp) 'd.%s'];
step = 6;
vid4D = zeros([576 768 nFrame/step]);

for k = 1 : 1 : nFrame/step
    k
    str1  = sprintf(str,path,k,'jpg');
    img   = imread(str1);
    vid4D(:,:,:,k)=img;
    imshow(img); drawnow
    hold off
    %pause(.2)
end
bkg = median(vid4D,4);
figure;imagesc(uint8(bkg));