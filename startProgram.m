cam=webcam;
global calorie

recordVideoOf_self(cam);
background_Image=take_screenshot_input(cam);
background_Image=imread("data/background.png");
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
    dim = [.2 .5 .3 .3];
    str = "standing both hand = 0 ";
    str=str+"standing right hand = 0 ";
    str=str+"standing left hand =0 ";
    h_annot=annotation('textbox',dim,'String',str,'FitBoxToText','on');

    I=imread("data/background_1.png");
    v=VideoReader('data/myVideo.avi');
    data=[0 0 0 0 0 0 0 0];
    old_frame= read(v,1);
    while hasFrame(v)
        frame=readFrame(v);
        data=background_subtraction(old_frame,frame,I,data,h_annot);
        imshow(frame);
        old_frame=frame;
    end
end

function webcam_demo(cam,background_Image)
    data=[0 0 0 0 0 0 0 0]; %left_hand_bool right_hand_bool left_hand_count right_hand_count both_hand_count
    dim = [.2 .5 .3 .3];
    str = "standing both hand = 0 ";
    str=str+"standing right hand = 0 ";
    str=str+"standing left hand =0 ";
    h_annot=annotation('textbox',dim,'String',str,'FitBoxToText','on');
    old_frame=background_Image;
    while true
        image=snapshot(cam);
        %imshow(image);
        %captureYellowColor(image,background_Image);
        data=background_subtraction(old_frame,image,background_Image,data,h_annot);
        old_frame=image;
        
        %pause(0.2);
    end
end

function data=background_subtraction(old_frame,current_frame_rgb,background_Image,data,annotation)
    number=captureYellowColor(current_frame_rgb);

    current_frame=filter2(fspecial('average',3),rgb2gray(current_frame_rgb));
    background_Image=filter2(fspecial('average',3),rgb2gray(background_Image));
    img=medfilt2(current_frame-background_Image)>1;
    
    

    for t=1:-15
        img=medfilt2(current_frame-background_Image)>t;
        imshow(img);
        pause(.2);
    end

    
    data=take_largest_blob(old_frame,img,data,annotation,current_frame_rgb,number);
    pause(0.5);
    
end

function data=take_largest_blob(old_frame,img,data,annotation,current_frame,dumbell_num)
    
    for i=1:2
        d_bsIm = bwmorph(img, "dilate");
    
    
        [L, ~] = bwlabel(d_bsIm, 8);
        blobMeasurements = regionprops(L, 'area','Centroid');
        allAreas = [blobMeasurements.Area];
        [~, sortIndexes] = sort(allAreas, 'descend');
        biggestBlob = ismember(L, sortIndexes(1:1));
        binaryImage=biggestBlob>0;
        binaryImage=medfilt2(binaryImage);
    end
            %changing the centroid point
        [row,col]=size(binaryImage);
        bc=blobMeasurements(sortIndexes(1:1)).Centroid;
        
        %track(old_frame,current_frame,bc);

        while binaryImage(ceil(bc(2)),ceil(bc(1)))==0
            bc(2)=bc(2)-1;
            if(bc(2)>=row-1)
                break;
            end
        end
        while binaryImage(ceil(bc(2)),ceil(bc(1)))~=0
            bc(2)=bc(2)+1;
            if(bc(2)>=row-1)
                break;
            end
        end
    
        bc(2)=bc(2)-150;
        while bc(2)<0
            bc(2)=bc(2)+2;
        end

    
    data=calculate_workout(binaryImage,bc,data,annotation,dumbell_num);
end

function track(old_img, new_img,bc)
    disp(size(new_img));
    im1=old_img;
    im2=new_img;
    
    X=circularNeighbours(im1,floor(bc(1)),floor(bc(2)),25);
    disp(size(X));
    q_model=colorHistogram(X,16,150.0,175.0,25);
    x0=floor(bc(1));
    y0=floor(bc(2));
    bins=16;
    
    for i=1:3
        Y=circularNeighbours(im2,x0,y0,25);
        p_test=colorHistogram(Y,bins,x0,y0,25);
        w=meanshiftWeights(Y,q_model,p_test,bins);
        x1=calculateBestLoc(w(:,1),Y(:,1))/sum(w,"all");
        y1=calculateBestLoc(w(:,1),Y(:,2))/sum(w,"all");
        x0=x1;
        y0=y1;
    end
end

function data=calculate_workout(binaryImage,bc,data,h_annot,dumbell_num)
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
        if dumbell_num==1
                data(1,6)=data(1,6)+1;
        end
        if currentleft ==1 && currentright==1
            if dumbell_num==2
                data(1,8)=data(1,8)+1;
            end
            data(1,4)=data(1,4)-1;
            data(1,3)=data(1,3)-1;
            data(1,5)=data(1,5)+1;
        end
    elseif data(1,2)==1 && currentright==0
        data(1,2)=0;
    end
    
    imshow(binaryImage);
    
    hold on
    
    str = "standing both hand = "+data(1,5);
    str=str+"standing right hand = "+data(1,4);
    str=str+"standing left hand = "+data(1,3);
    %str=str+"with dumbell = "+ dumbell_num;
    calories=data(1,5)*2 + data(1,4)+ data(1,3) + data(1,8)*4+data(1,6)*3;
    str=str+ "calories = "+calories;

    set(h_annot,'String',str)
    drawnow;
    %plot(bc(1),bc(2),'-r+');
    hold off
end

function count=captureYellowColor(data1)
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
    count=0;
    hold on
    for object=1:length(stats)
        if (stats(object).Area == sortedAreas(1) || stats(object).Area == sortedAreas(2)) && stats(object).Area>1000
            count=count+1;
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
    image=snapshot(cam);
    closePreview(cam);
    imwrite(image,"data/background.png");
end

function x=calculateBestLoc(w,Y)
    x=w.*Y;
    x=sum(x,1);
    %disp(x);
end

function w=meanshiftWeights(X, q_model, p_test, bins)
    range=1:255;
    [~,edges,~] = histcounts(range,bins);
    [~,~,bin]=histcounts(X,edges);

    [rows,~]=size(X);
    w=zeros(rows,1);

    for i=1:bins
        for j=1:bins
            for k=1:bins
                 %calculate bin for each pixel in X
                for r=1:rows
                    if bin(r,3)==i && bin(r,4)==j && bin(r,5)==k
                        w(r,1)=w(r,1)+sqrt(q_model(i,j,k)/p_test(bin(r,3),bin(r,4),bin(r,5)));
                    end
                end
            end
        end
    end

end

function hist=colorHistogram(X,bins,x,y,h)
    hist=zeros(bins,bins,bins);

    range=1:255;
    [~,edges,~] = histcounts(range,bins);
    [~,~,bin]=histcounts(X,edges);

    [rows,~]=size(X);
    for i=1:rows
        %calculate r
        r=(sqrt((x-X(i,1)^2)+(y-X(i,2)^2))/h)^2;
        if r < 1
            hist(bin(i,3),bin(i,4),bin(i,5))=hist(bin(i,3),bin(i,4),bin(i,5))+1-r;
        end
    end

    C=sum(hist,"all");
    hist=hist/C;
end
  

function X=circularNeighbours(img,x,y,radius)
    i=1;
    [rows,columns]=size(img);
    X=zeros(rows*columns,5);

    for x1=1:columns
        for y1=1:rows
            dist=sqrt((y-y1)^2+(x-x1)^2);
            if(dist<radius)
                X(i,1)=x1;
                X(i,2)=y1;
                X(i,3)=img(y1,x1,1);
                X(i,4)=img(y1,x1,2);
                X(i,5)=img(y1,x1,3);
                i=i+1;
                img(y1,x1)=255;
            end
        end
    end
    i=i-1;
    X=X(1:i,:);
    %figure;
    imshow(img);
    pause(1);
end