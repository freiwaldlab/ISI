function configurePstate(modID)

switch modID
    case 'PG'
        confPstate_perGrater
    case 'FG'
        confPstate_flashGrater
    case 'RD'
        confPstate_Rain
    case 'FN'
        confPstate_Noise
    case 'MP'
        confPstate_Mapper
    case 'CM'
        confPstate_cohMotion
    case 'IB'
        confPstate_ImageBlock
end     
