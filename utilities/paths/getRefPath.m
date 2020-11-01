function refPath=getRefPath(voltagePath)
% 2020-06-27 04:22:40 RC
refPath=strrep(voltagePath,'cG','cR');
if ~isfile(refPath)
    error('Reference file has not been found')
end
end