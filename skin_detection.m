cam=webcam;
while true
    image=snapshot(cam);
    detect_skin(image);
    pause(2); 
end
take_screenshot_input(cam);



function take_screenshot_input(cam)
    showWebcam(cam);
    fig=uifigure;
    set(fig,'position',[0,350,380,180])
    selection = uiconfirm(fig,'Click when you have background without you','Confirm Close');
    disp(selection);
    if(selection=='OK')
        close(fig);
        clickPhotoFromWebcam(cam);
    end
end
function showWebcam(cam)
    preview(cam);
end

function clickPhotoFromWebcam(cam)
    image=snapshot(cam);
    closePreview(cam);
    imwrite(image,"data/background.png");
end


function detect_skin(file)
    %Read the image, and capture the dimensions
    img_orig=file;
    %img_orig = imread("data/template/cross_squat_1/frame4.jpg");
    height = size(img_orig,1);
    width = size(img_orig,2);
    
    out = img_orig;
    bin = zeros(height,width);
    
    img = grayworld(img_orig);    

    img_ycbcr = rgb2ycbcr(img);
    Cb = img_ycbcr(:,:,2);
    Cr = img_ycbcr(:,:,3);
    

    [r,c,v] = find(Cb>=77 & Cb<=127 & Cr>=133 & Cr<=173);
    numind = size(r,1);
    

    for i=1:numind
        out(r(i),c(i),:) = [0 0 255];
        bin(r(i),c(i)) = 1;
    end
    imshow(img_orig);
    figure; imshow(out);
    figure; imshow(bin);
end

function out = grayworld(I)
    out = uint8(zeros(size(I,1), size(I,2), size(I,3)));
    
    %R,G,B components of the input image
    R = I(:,:,1);
    G = I(:,:,2);
    B = I(:,:,3);
    %Inverse of the Avg values of the R,G,B
    mR = 1/(mean(mean(R)));
    mG = 1/(mean(mean(G)));
    mB = 1/(mean(mean(B)));
    
    %Smallest Avg Value (MAX because we are dealing with the inverses)
    maxRGB = max(max(mR, mG), mB);
    
    %Calculate the scaling factors
    mR = mR/maxRGB;
    mG = mG/maxRGB;
    mB = mB/maxRGB;
   
    %Scale the values
     out(:,:,1) = R*mR;
     out(:,:,2) = G*mG;
     out(:,:,3) = B*mB;
end