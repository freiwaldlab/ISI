
%%create

milapp = actxcontrol('MIL.Application');
milsys = actxcontrol('MIL.System');
mildisp = actxcontrol('MIL.Display',[10 10 800 800]);
mildig = actxcontrol('MIL.Digitizer');
milimg = actxcontrol('MIL.Image');

%%allocate

milsys.Allocate;

mildisp.set('OwnerSystem',milsys,'DisplayType','dispActiveMILWindow');
mildisp.Allocate

mildig.set('OwnerSystem',milsys);
mildig.Allocate

milimg.set('CanGrab',1,'CanDisplay',1,'CanProcess',0, ...
    'SizeX',1024,'SizeY',1024,'DataDepth',16,'NumberOfBands',1,'OwnerSystem',milsys);

milimg.Allocate;

mildig.set('Image',milimg);
%%mildisp.set('Image',milimg,'ViewMode','dispAutoScale');
mildisp.set('Image',milimg,'ViewMode','dispBitShift','ViewBitShift',4);

IMGSIZE = mildig.get('SizeX');
%% Grab the image

mildig.Grab;

%% write  (this works)

milimg.set('FileFormat','imBMP')
milimg.Save('kuku.bmp')


%% This works!!!!

IMGSIZE = 512;

zz  = zeros(IMGSIZE,IMGSIZE,'uint8');
q = milimg.Get(zz,IMGSIZE^2,-1,0,0,IMGSIZE,IMGSIZE);

Free(mildisp)
Free(milimg)
Free(mildig)
Free(milsys)
