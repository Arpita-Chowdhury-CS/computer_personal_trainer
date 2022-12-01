clear all;
show_MHI();

function show_MHI()
    Files=dir("data/template/standing_both_hand/");
    for k=1:length(Files)
       FileNames=Files(k).name;
       disp(FileNames);
       image=imread(FileNames);
       imshow(image);
       pause(0.2);
    end
end


function make_MHI()
    j=1;
    for i=0:2:48
        disp(i);
        filename = sprintf('data/template/jumping_jack_3/frame%d.jpg', i); % if starts with 000
        Im(:,:,j) = imrotate(rgb2gray(imread(filename)),180,"bilinear");
        j=j+1;
    end
    
    for t=1:2:16
        afterFilter=medfilt2(Im(:,:,22)-Im(:,:,21))>t;
    end
    
    for i=1:j-1
        if i==1
            afterFilter=medfilt2(Im(:,:,i)-Im(:,:,i))>15;
            baseFileName = sprintf('Image #%d.png', i);
            fullFileName = fullfile("data/template/jumping_jack/", baseFileName);
            imwrite(afterFilter, fullFileName);
        else
            afterFilter=medfilt2(Im(:,:,i)-Im(:,:,i-1))>15;
            baseFileName = sprintf('Image #%d.png', i);
            fullFileName = fullfile("data/template/jumping_jack/", baseFileName);
            imwrite(afterFilter, fullFileName);
        end
    end
end

