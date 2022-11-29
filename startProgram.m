cam=webcam;
%recordVideoOf_self(cam);
%background_Image=take_screenshot_input(cam);
%background_Image=imread("data/background.png");
demo();
%webcam_demo(cam,background_Image);

function recordVideoOf_self(cam)
  aviObject = VideoWriter('data/myVideo.avi');   % Create a new AVI file 
  open(aviObject);
  for i=1:100
    image=snapshot(cam);
    imshow(image);
    pause(0.5);                   
    writeVideo(aviObject,image);
  end
   close(aviObject);         % Close the AVI file
end

function demo()
    I=imread("data/background.png");
    v=VideoReader('data/myVideo.avi');
    while hasFrame(v)
        frame=readFrame(v);
        background_subtraction(frame,I);
        %imshow(frame);
    end
    %captureYellowColor(I);
    %background_subtraction(image,background_Image);
end

function webcam_demo(cam,background_Image)
    while true
        image=snapshot(cam);
        %captureYellowColor(image,background_Image);
        background_subtraction(image,background_Image);
        %pause(0.2);
    end
end

function result=background_subtraction(current_frame,background_Image)

    current_frame=filter2(fspecial('average',3),rgb2gray(current_frame));
    background_Image=filter2(fspecial('average',3),rgb2gray(background_Image));
    img=medfilt2(current_frame-background_Image)>1;
    
    

    for t=1:-15
        img=medfilt2(current_frame-background_Image)>t;
        imshow(img);
        pause(.52);
    end


    result=take_largest_blob(img);
    %point_largest_blob(img);
    result=take_largest_blob(result);
    %imshow(result);
    pause(0.5);
    
end

function binaryImage=take_largest_blob(img)
     d_bsIm = bwmorph(img, "dilate");
    %d_bsIm = bwmorph(d_bsIm, "erode");


    [L, ~] = bwlabel(d_bsIm, 8);
    blobMeasurements = regionprops(L, 'area','Centroid');
    allAreas = [blobMeasurements.Area];
    [~, sortIndexes] = sort(allAreas, 'descend');
    biggestBlob = ismember(L, sortIndexes(1:1));
    binaryImage=biggestBlob>0;
    binaryImage=medfilt2(binaryImage);
   
    imshow(binaryImage);
    hold on
    bc=blobMeasurements(sortIndexes(1:1)).Centroid;
    plot(bc(1),bc(2),'-m+');
    hold off
end


function captureYellowColor(data1,background_Image)
    afterFilter=background_subtraction(data1,background_Image);

    data=imcomplement(data1);
    diff_im = imsubtract(data(:,:,3), rg2gray(data));
    diff_im=medfilt2(diff_im,[3 3]);
    diff_im=im2bw(diff_im,0.1);
    diff_im=bwareaopen(diff_im,50);

    [labeledImage, numberOfBlobs] = bwlabel(diff_im,8);
    %bw=bwlabel(diff_im,8);
    stats=regionprops(labeledImage,'BoundingBox','Centroid','Area');
    allAreas=[stats.Area];
    [sortedAreas, sortIndexes] = sort(allAreas, 'descend');


    
    imshow(afterFilter);
    hold on
    for object=1:length(stats)
        if (stats(object).Area == sortedAreas(1) || stats(object).Area == sortedAreas(2)) && stats(object).Area>100
            bb=stats(object).BoundingBox;
            bc=stats(object).Centroid;
            %current_dumbell_pos(bc(1),bc(2))=1;
            rectangle('Position',bb,'EdgeColor','Y','LineWidth',2);
            plot(bc(1),bc(2),'-m+');
            a=text(bc(1)+15,bc(2), strcat('X:', num2str(round(bc(1))), 'Y:', num2str(round(bc(2)))));
            set(a, 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 12, 'Color', 'yellow');
        end 
     end
     hold off
end


function image=take_screenshot_input(cam)
    showWebcam(cam);
    fig=uifigure;
    set(fig,'position',[0,350,380,180])
    selection = uiconfirm(fig,'Click when you have background without you','Confirm Close');
    %disp(selection);
    if(selection=='OK')
        close(fig);
        image=clickPhotoFromWebcam(cam);
    end
end
function showWebcam(cam)
    preview(cam);
end

function image=clickPhotoFromWebcam(cam)
    image=snapshot(cam);
    closePreview(cam);
    imwrite(image,"data/background.png");
end