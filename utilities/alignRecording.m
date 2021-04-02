function [dataStructure]=alignRecording(ePhys,oPhys)
% align ePhys and oPhys data acquired with different sampling rate and with
% a time lag (one start after the other). Use the function alignSyncTTL
% [ePhys_cal,oPhys_cal]=alignRecording(ePhys,oPhys);
%
% INPUT: structure as follow
%     ePhys.data / ePhys.ttl / ePhys.fps
%     oPhys.data / oPhys.ttl / oPhys.fps
%
% OUTPUT: data structure for each oPhys measurements with the following
% fields:
%     dataStructure(iMeas) .ePhys / .oPhys / .ttl / .fps
    
if ~isstruct(ePhys)||~isstruct(oPhys)
    error('input must be a structure with data to align, syncTTL and fps')
end

field={'data','ttl','fps'};
if sum(isfield(ePhys,field))~=3||sum(isfield(oPhys,field))~=3
    error('you are missing a structure field. Check doc')
end

[parsedData]=parseEPhys(ePhys);

for iMeas=1:numel(parsedData)
    ttlE_temp=parsedData(iMeas).ttl;
    ttlO_temp=oPhys.ttl(:,iMeas);
    
    % should feed all the data...
    [ttlE_temp,ttlO_temp,fps]=equalizeSamplingRate(ttlE_temp,ttlO_temp);
    
    [range_ttlE,range_ttlO]=alignSyncTTL(ttlE_temp,ttlO_temp,fps);
%     
%     dataStructure(iMeas).ePhys=
%     dataStructure(iMeas).oPhys=
%     dataStructure(iMeas).ttl=
%     dataStructure(iMeas).fps=
    
end

end