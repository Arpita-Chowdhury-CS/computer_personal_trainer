cam=webcam;
%recordVideoOf_self(cam);
%background_Image=take_screenshot_input(cam);
%background_Image=imread("data/background.png");
demo();
webcam_demo(cam,background_Image);

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
    dim = [.2 .5 .3 .3];
    str = "standing both hand = 0 ";
    str=str+"standing right hand = 0 ";
    str=str+"standing left hand =0 ";
    h_annot=annotation('textbox',dim,'String',str,'FitBoxToText','on');

    I=imread("data/background_1.png");
    v=VideoReader('data/myVideo.avi');
    data=[0 0 0 0 0];
    
    while hasFrame(v)
        frame=readFrame(v);
        data=background_subtraction(frame,I,data,h_annot);
        imshow(frame);
    end
    %captureYellowColor(I);
    %background_subtraction(image,background_Image);
end

function webcam_demo(cam,background_Image)
    data=[0 0 0 0 0]; %left_hand_bool right_hand_bool left_hand_count right_hand_count both_hand_count
    dim = [.2 .5 .3 .3];
    str = "standing both hand = 0 ";
    str=str+"standing right hand = 0 ";
    str=str+"standing left hand =0 ";
    h_annot=annotation('textbox',dim,'String',str,'FitBoxToText','on');
    while true
        image=snapshot(cam);
        imshow(image);
        %captureYellowColor(image,background_Image);
        data=background_subtraction(image,background_Image,data,h_annot);
        
        %pause(0.2);
    end
end

function data=background_subtraction(current_frame,background_Image,data,annotation)
    %captureYellowColor(current_frame);

    current_frame=filter2(fspecial('average',3),rgb2gray(current_frame));
    background_Image=filter2(fspecial('average',3),rgb2gray(background_Image));
    img=medfilt2(current_frame-background_Image)>1;
    
    

    for t=1:-15
        img=medfilt2(current_frame-background_Image)>t;
        imshow(img);
        pause(.2);
    end

    
    data=take_largest_blob(img,data,annotation);
    pause(0.5);
    
end

function data=take_largest_blob(img,data,annotation)
    for i=1:1
        d_bsIm = bwmorph(img, "dilate");
    
    
        [L, ~] = bwlabel(d_bsIm, 8);
        blobMeasurements = regionprops(L, 'area','Centroid');
        allAreas = [blobMeasurements.Area];
        [~, sortIndexes] = sort(allAreas, 'descend');
        biggestBlob = ismember(L, sortIndexes(1:1));
        binaryImage=biggestBlob>0;
        binaryImage=medfilt2(binaryImage);
    
        %changing the centroid point
        [row,col]=size(binaryImage);
        bc=blobMeasurements(sortIndexes(1:1)).Centroid;
        while binaryImage(ceil(bc(2)),ceil(bc(1)))==0
            bc(2)=bc(2)-1;
            if(bc(2)>=row)
                break;
            end
        end
        while binaryImage(ceil(bc(2)),ceil(bc(1)))~=0
            bc(2)=bc(2)+1;
            if(bc(2)>=row)
                break;
            end
        end
    
        bc(2)=bc(2)-150;
        while bc(2)<0
            bc(2)=bc(2)+2;
        end
    end

    data=calculate_workout(binaryImage,bc,data,annotation);
end

function data=calculate_workout(binaryImage,bc,data,h_annot)
    disp("entering calculation: ");
    disp(data);
    disp("after calc");
    [~,col]=size(binaryImage);
    currentleft=0;

    for c=1:ceil(bc(1))-1

        if binaryImage(ceil(bc(2)),c)==0
            %plot(c,bc(2),'-r+'); 
             currentleft=1;
             break;
        end
    end

    if data(1,1)==0 && currentleft==1
        data(1,1)=1;
        data(1,3)=data(1,3)+1;
    elseif data(1,1)==1 && currentleft==0
        data(1,1)=0;
    end

    currentright=0;
    for c=ceil(bc(1))+1:col
        if binaryImage(ceil(bc(2)),c)==0
            %plot(c,bc(2),'-r+')
            currentright=1;
            break;
        end
    end

    if data(1,2)==0 && currentright==1
        data(1,2)=1;
        data(1,4)=data(1,4)+1;
    elseif data(1,1)==1 && currentright==0
        data(1,2)=0;
    end

    if currentleft ==1 && currentright==1
        data(1,4)=data(1,4)-1;
        data(1,3)=data(1,3)-1;
        data(1,5)=data(1,5)+1;
    end
    
    %imshow(binaryImage);
    
    hold on
    
    str = "standing both hand = "+data(1,5);
    str=str+"standing right hand = "+data(1,4);
    str=str+"standing left hand = "+data(1,3);
    set(h_annot,'String',str)
    drawnow;
    %plot(bc(1),bc(2),'-r+');
    hold off
end

function captureYellowColor(data1)
    %afterFilter=background_subtraction(data1,background_Image);

    data=imcomplement(data1);
    diff_im = imsubtract(data(:,:,3), rgb2gray(data));
    diff_im=medfilt2(diff_im,[3 3]);
    diff_im=im2bw(diff_im,0.1);
    diff_im=bwareaopen(diff_im,50);

    [labeledImage, numberOfBlobs] = bwlabel(diff_im,8);
    %bw=bwlabel(diff_im,8);
    stats=regionprops(labeledImage,'BoundingBox','Centroid','Area');
    allAreas=[stats.Area];
    [sortedAreas, sortIndexes] = sort(allAreas, 'descend');


    
    %imshow(afterFilter);
    hold on
    for object=1:length(stats)
        if (stats(object).Area == sortedAreas(1) || stats(object).Area == sortedAreas(2)) && stats(object).Area>1000
            bb=stats(object).BoundingBox;
            bc=stats(object).Centroid;
            %current_dumbell_pos(bc(1),bc(2))=1;
            rectangle('Position',bb,'EdgeColor','Y','LineWidth',2);
            plot(bc(1),bc(2),'-m+');
            text(bc(1)+15,bc(2),"dumbell");
            %set(a, 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 12, 'Color', 'yellow');
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