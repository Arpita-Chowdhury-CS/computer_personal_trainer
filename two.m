clear all;
for i=1:22
    filename = sprintf('data/template/standing_right/Image #%d.png', i); % if starts with 000
    Im(:,:,i) = double(imread(filename));
end
MEI=double(zeros(size(Im(:,:,1))));
MHI=double(zeros(size(Im(:,:,1))));

for i=2:22
    f2=Im(:,:,i);
    f1=Im(:,:,i-1);
    [row,c]=size(f1);

    for r=1:row
        for j=1:c
            if f2(r,j) ~= f1(r,j)
                MEI(r,j)=1;
                MHI(r,j)=i;
            end
        end
    end
end
imagesc(MEI);
colormap("gray");
title("MEI Image");
MHI=max(0, (MHI-1.0)/21.0);
figure;
imagesc(MHI);
colormap("gray");
title("MHI Image");

