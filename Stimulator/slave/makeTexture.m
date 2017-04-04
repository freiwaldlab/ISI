function makeTexture(modID)
    global comState
    
    stimTime = false;
    makeDone = true;
    switch modID
        case 'PG'  %Periodic Grater
            makeGratingTexture_periodic
        case 'FG'  %Flash Grater
            if getParamVal('FourierBit')
                makeGratingTexture_flash
            else
                makeGratingTexture_flashCartesian
            end
        case 'RD'  %Raindropper
            makeRainTexture
        case 'FN'  %Filtered Noise
            makeNoiseTexture        
        case 'MP'  %Mapper
            %makeMapper  %No need to a make file
        case 'CM'
            makeCohMotion
        case 'IB'
            stimTime = makeImageBlockTexture;
        otherwise
            disp('makeTexture ERROR: Unknown module ID.')
            makeDone = false;
    end
    if makeDone
        if stimTime
            fwrite(comState.serialPortHandle, ...
                strcat('MT;', modID, ';', num2str(stimTime), ';~'))
        else
            fwrite(comState.serialPortHandle, ...
                strcat('MT;', modID, ';-1;~'))
        end
    end