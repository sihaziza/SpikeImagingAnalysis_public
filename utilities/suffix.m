classdef suffix
% HELP
% Minimalistic non-handle class to manipulate addind/removing/checking
% suffixes of of file names
% HISTORY
% - 29-Jun-2020 18:25:51 - created by Radek Chrapkiewicz (radekch@stanford.edu)
    properties
        fpath
        hassuffix
        suff
    end
    
    properties (Constant)
        slist={'_res','_reg','_bp','_bpmc','_moco','_umx'};
    end 
    
    properties (Constant, Access=private)
        exm='F:\GEVI_Wave\Raw\Visual\m2\20200613\meas00\7mm-side-visual-updown--BL100-fps116-cG_unmx.h5'; % just for debugging and testing, to be deleted % - 2020-06-29 19:05:31 -   RC 
    end
    
    methods
        function obj = suffix(filepath)
            %SUFFIX Construct an instance of this class
            %   Detailed explanation goes here
            obj.fpath=filepath;
            [obj.hassuffix, obj.suff]=suffix.has(obj.fpath);
        end
        
        function newpath=change(obj,newsuffix)
           % changing suffix of the filename. Function agnostic wheter suffix already exists or not. 
           if suffix.has(obj.fpath)
               newpath=suffix.replace(obj.fpath,newsuffix);
           else
               newpath=suffix.add(obj.fpath,newsuffix);
           end       
        end
    end %%% END OF PUBLIC METHODS
    
    %%% STATIC METHODS
    
    methods (Static)
        function suffixes=list()
            % Outputs list of allowed suffixes in the h5 file naming.
            suffixes=suffix.slist;            
        end  
        
        function issuffix=is(suffixstring)
            % check if string is a valid suffix
            slist=suffix.list;            
            issuffix=false;
            for ii=1:length(slist)
                issuffix=strcmp(slist{ii},suffixstring);
                if issuffix; break; end
            end            
        end
        
        function [hassuffix,suff]=has(fpath)
            %checks if the filename has a suffix 
            [folder,filename,ext]=fileparts(fpath);
            hassuffix=false;
            suff=[];
            for ii=1:length(suffix.list)
                if contains(filename,suffix.slist{ii})
                    hassuffix=true;
                    suff=suffix.slist{ii};
                    break
                end
            end            
        end
        
        function newpath = replace(fpath,newsuff)
            if ~suffix.is(newsuff)
                error('That''s not a valid suffix')
            end
            
            [hassuffix,oldsuff]=suffix.has(fpath);
            if ~hassuffix
                error('No suffix found in the fpath');
            end
            newpath=strrep(fpath,oldsuff,newsuff);       
        end
        
        function newpath = add(fpath,suff,varargin)
%             add(fpath,suff)
%             add(fpath,suff,'f') % forcing adding suffix ignoring the
%             allowed list of ones 
            % adding suffix to the file name if it is not present 
            if nargin>=3
                if strcmp(varargin{1},'f')
                    % ignoting suffix
                else
                    suffcheck();
                end
            else
                suffcheck();
            end
            
            [folder,filename,ext]=fileparts(fpath);
            newpath=fullfile(folder,[filename, suff,ext]);
            % nested function 
            function suffcheck()
                if ~suffix.is(suff)
                    error('That''s not a valid suffix')
                end
                [hassuffix]=suffix.has(fpath);
                if hassuffix
                    error('This file name has already a valid suffix. Conider suffix replacement');
                end
            end
        end
        
        function [path1rep,path2rep]=change2(path1,path2,suff)
            % replace suffixes in two paths
            if ~suffix.is(suff)
                error('%s - is not a valid suffix',suff);
            end
            sobj1=suffix(path1);
            path1rep=sobj1.change(suff);
            sobj2=suffix(path2);
            path2rep=sobj2.change(suff);

        end

    end
end

