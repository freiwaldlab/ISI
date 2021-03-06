function [h] = GrabSaveLoop(h,fname,parport)

global Tens ROIcrop IMGSIZE

% n = 1;
% running = 1;
% h.mildig.Grab;
% while(running && ~get(imagerhandles.masterlink,'BytesAvailable'))
%
%     h.mildig.GrabWait(3);
%     putvalue(parport,1); putvalue(parport,0);
%     h.mildig.Image = h.buf{bitand(n,1)+1};
%     h.mildig.Grab;
%     h.buf{2-bitand(n,1)}.Save([fname '_' sprintf('%08d',n-1) '.raw']);
%     n = n+1;
%
% end


% for n = 1:N
%     h.mildig.Image = h.buf{n};
%     h.mildig.Grab;
%     h.mildig.GrabWait(3);  %% wait...
%     putvalue(parport,1); putvalue(parport,0);
% end




%%%%%%%%
% zz = zeros(ROIcrop(3),ROIcrop(4),'uint16');
% N = length(Tens(1,1,:));
% h.mildig.Grab;
% h.mildig.GrabWait(3);
% 
% for n = 1:N
%     h.mildig.Grab;
%     Tens(:,:,n) = h.milimg.Get(zz,IMGSIZE^2,-1,ROIcrop(1),ROIcrop(2),ROIcrop(3),ROIcrop(4));
%     putvalue(parport,1); putvalue(parport,0);    
%     h.mildig.GrabWait(3);
% end
% 
% %save(fname,'Tens')
% %Use this if you want to save each frame as a variable within the .mat file
% for n = 1:N
%     var = ['f' num2str(n)];    
%     eval([var ' = Tens(:,:,n);' ])
%     if n == 1
%         save(fname,var)
%     else
%         save(fname,var,'-append')
%     end
% end
% 
% Tens = Tens*0;  %So I know for certain if something went wrong
%%%%%%%%%%%%%%%%%%%

zz = zeros(ROIcrop(3),ROIcrop(4),'uint16');
N = length(Tens(1,1,:));
h.mildig.Grab;
h.mildig.GrabWait(3);

for n = 1:N
    
    %Wait for grab to finish before switching the buffers
    h.mildig.GrabWait(3);
    
    %Switch destination, then grab to it (asynchronously)
    h.mildig.Image = h.buf{bitand(n,1)+1};  
    h.mildig.Grab;
    
    %TTL pulse 
    putvalue(parport,1); putvalue(parport,0);
    
    %Pull into Matlab workspace and save to disk
    im = h.buf{2-bitand(n,1)}.Get(zz,IMGSIZE^2,-1,ROIcrop(1),ROIcrop(2),ROIcrop(3),ROIcrop(4));       
    var = ['f' num2str(n)];    
    fnamedum = [fname '_' var];
    save(fnamedum,'im')
    
    
end



%%%%%old loop
% zz = zeros(IMGSIZE,IMGSIZE,'uint16');
% N = length(Tens(1,1,:));
% h.mildig.Grab;
% for n = 1:N
%     h.mildig.GrabWait(3);
%     putvalue(parport,1); putvalue(parport,0);
%     h.mildig.Image = h.buf{bitand(n,1)+1};
%     h.mildig.Grab;
%     Tens(:,:,n) = h.milimg.Get(zz,IMGSIZE^2,-1,0,0,IMGSIZE,IMGSIZE);
%     %h.buf{2-bitand(n,1)}.Save([fname '_' sprintf('%08d',n-1) '.raw']);
% 
% end




%%%%%old loop
% n = 1;
% running = 1;
% h.mildig.Grab;
% while(running & ~get(imagerhandles.masterlink,'BytesAvailable'))
%     h.mildig.GrabWait(3);
%     putvalue(parport,1); putvalue(parport,0);
%     h.mildig.Image = h.buf{bitand(n,1)+1};
%     h.mildig.Grab;
%     h.buf{2-bitand(n,1)}.Save([fname '_' sprintf('%08d',n-1) '.raw']);
%     n = n+1;
% 
% end
% 
