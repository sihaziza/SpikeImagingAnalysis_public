classdef MovieSpecs < handle
    %MovieSpecs stores .h5 movie file universal content (besides the movie)
    % and provides simple operations for history manipulations
    
    properties (Constant = true)
        history_sep = ';'; %separator of the history string
    end
    
    properties (SetAccess = protected)
        history; % string that contains the history of data processing steps
        fps;
        scale_factor; % spatial downsampling factor \in [0,1]
        frame_range; % range of frames stored [firts_frame, last_frame] 
    end
    
    methods
        function obj = MovieSpecs(history,fps,scale_factor,frame_range)
            obj.CheckInputs(history,fps,scale_factor,frame_range);
            
            obj.history = string(history);
            obj.fps = fps;
            obj.scale_factor = scale_factor;
            obj.frame_range = frame_range;
        end
        
        function history_array = AddToHistory(obj,new_entry)
            if(~isstring(new_entry)&& ~ischar(new_entry))
                error("new_entry for history shoud be string or char")
            end
            if(contains(new_entry, obj.history_sep))
                error("new_entry for history shoud not contain the separator")
            end
            
            obj.history  = obj.history + obj.history_sep + new_entry;
            history_array = obj.GetHistory();
        end
        
        function history_array = GetHistory(obj)
            history_array = strsplit(obj.history, obj.history_sep);
            history_array(history_array == "") = [];
        end
        
        function [specs_cells, specs_names] = GetAllSpecs(obj)
            %GetAllSpecs - returs all required specs as two array - cell
            % array of actual specs and sting array of names. For data
            % saving convenience.
            specs_cells = {obj.history, obj.fps, obj.scale_factor, obj.frame_range};
            specs_names = ["history", "fps", "scale_factor", "frame_range"];
        end
    end
    
    methods(Access = protected)
        function CheckInputs(obj,history,fps,scale_factor,frame_range)
            if(~ischar(history) && ~isstring(history))
                error("history shoud be string or char")
            end
            
            if(~isnumeric(fps) || fps <= 0)
                error("fps should be a number > 0")
            end
            
            if(~isnumeric(scale_factor) || scale_factor > 1 || scale_factor < 0)
                error("scale_factor should be a number in [0,1]")
            end
            
            if(length(frame_range) ~= 2 || any(frame_range < 0) || ...
               any( floor(frame_range) ~= frame_range) )
                error("frame_range should be an array of two round numbers > 0")
            end
        end
    end
end

