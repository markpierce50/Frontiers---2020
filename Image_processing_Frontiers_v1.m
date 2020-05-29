% SWIR image processing for Frontiers manuscript (Jay V. Shah, Rutgers University)
% Developed in Matlab 2018a, including Image Processing toolbox
% (c) Mark C. Pierce (Rutgers University), mark.pierce@rutgers.edu, 5-29-20
% Not for use without acknowledgment of the authors

clearvars; close all; clc;

WL_Pre_filename = 'WL_Pre.tif';         % Enter filenames for four images (white light (WL) and SWIR images, pre/post injection)
SWIR_Pre_filename = 'SWIR_Pre.tif';
WL_Post_filename = 'WL_Post.tif';
SWIR_Post_filename = 'SWIR_Post.tif';

WL_Pre = imread(WL_Pre_filename);
SWIR_Pre = imread(SWIR_Pre_filename);
WL_Post = imread(WL_Post_filename);
SWIR_Post = imread(SWIR_Post_filename);

WL_Pre = uint8((WL_Pre-2^15)/128);
WL_Post = uint8((WL_Post-2^15)/128);

WL_max_disp = 128;                      % Maximum pixel value displayed in white light image
Num_ROI = 2;                            % Number of ROIs to be used (2 for left/right lungs)
s = size(WL_Pre);

response1 = msgbox('Select ROIs on Pre-Inject Image'); uiwait(response1);          % User selects ROIs in pre-inject WL image
for i = 1:Num_ROI       
    response2 = msgbox(['ROI #',num2str(i)]); uiwait(response2);         
    figure; imshow(WL_Pre,[0 WL_max_disp]);
    [mask,xi,yi] = roipoly; close(gcf);                             
    
    Pre_ROI_mean(i) = mean(SWIR_Pre(mask));         % (DOUBLE) Store the mean pixel value within each pre-inject ROI 
    
    A = regionprops(mask,'Area');
    Pre_ROI_area(i) = A.Area;
end

response3 = msgbox('Select ROIs on Post-Inject Image'); uiwait(response3);          % User selects ROIs in post-inject WL image
for i = 1:Num_ROI       
    response4 = msgbox(['ROI #',num2str(i)]); uiwait(response4);
    figure; imshow(WL_Post,[0 WL_max_disp]);
    [mask,xi,yi] = roipoly; close(gcf);                                

    Not_mask(:,:,i) = ~mask;          
    SWIR_inj_ROI = zeros(s) + Pre_ROI_mean(i);      % Create an array (DOUBLE) containing only the mean background level for the ROI
    Post_ROI_mask(:,:,i) = SWIR_inj_ROI.*mask;      % (DOUBLE)  Set elements outside the mask to 0, retain background level values within ROI
    Post_ROI_mean(i) = mean(SWIR_Post(mask));       % Store the mean pixel value within the POST SWIR ROI
    Post_ROI_max(i) = max(SWIR_Post(mask(:)));      % Store the max pixel value within the ROI
    
    A = regionprops(mask,'Area');
    Post_ROI_area(i) = A.Area;
end

Final_ROI_mask = max(Post_ROI_mask,[],3);                       % (DOUBLE) Merge all ROI masks into a single 2-D array
Back_sub = imsubtract(double(SWIR_Post), Final_ROI_mask);       % (DOUBLE) Subtract the PRE inject ROI mean values from from ROIs in the POST image                        
Min_Not_mask = min(Not_mask,[],3);                              % (LOGICAL) Merge the masks of inverted image into a single 2-D array storing minimum values to keep zeros within ROI. 
Invert = uint16(Min_Not_mask).*SWIR_Post;                       % (UINT16) Multiply SWIR_Post with the inverted mask image to yield zeros inside ROIs and SWIR_Post values outside. 
I = imsubtract(Back_sub,double(Invert));                        % (DOUBLE) Subtract original background subtraction image from inverted mask image. 
SWIR_Corrected = uint16(I);                                     % SWIR_Corrected is the background-corrected SWIR emission image


% Show corrected SWIR image overlaid on post-inject white light image:
figure; imshow(WL_Post,[0 WL_max_disp]); hold on;
originalSize = get(gca,'Position');
ax2 = axes;
set(ax2,'Position',originalSize);
set(findobj(gcf, 'type','ax2'), 'Visible','off');
hImg = imshow(SWIR_Corrected);
set(ax2,'Color','none');
set(hImg,'CDataMapping','scaled');
colormap(ax2,jet(256));
colorbar('location','east','YColor','w');
caxis(ax2,[0 100]);
set(hImg,'AlphaData',5*uint8(SWIR_Corrected));  
alim([1 2]); hold off; 

% Save ROI pixel data to Excel file:
FileName = 'OutputData';  
Param_list1 = {'Filename:', FileName; 'Processed on:', datestr(clock)};      
xlswrite(FileName, Param_list1,'metrics','A1');                  
xlswrite(FileName, {'ROI #:'},'metrics','A4');
xlswrite(FileName, (1:Num_ROI)','metrics','A5'); 
xlswrite(FileName, {'Post ROI Area (# Pixels):'},'metrics','B4');          
xlswrite(FileName, Post_ROI_area', 'metrics','B5');         
xlswrite(FileName, {'Pre ROI Area (# Pixels):'},'metrics','C4');      
xlswrite(FileName, Pre_ROI_area', 'metrics','C5');
xlswrite(FileName, {'Mean Post ROI Values:'},'metrics','D4');          
xlswrite(FileName, Post_ROI_mean', 'metrics','D5');         
xlswrite(FileName, {'Mean Pre ROI Values:'},'metrics','E4');      
xlswrite(FileName, Pre_ROI_mean', 'metrics','E5');
xlswrite(FileName, {'Mean Corrected ROI Values:'}, 'metrics','F4');   
xlswrite(FileName, (Post_ROI_mean-Pre_ROI_mean)', 'metrics','F5');
xlswrite(FileName, {'Max pixel values:'}, 'metrics','G4');       
xlswrite(FileName, Post_ROI_max', 'metrics','G5');

