function str=struct2string(stuct_to_be_formatted)
% EXAMPLE USE WITH ARGUMENTS
% struct2stringstuct_to_be_formatted - use 1
%
% HELP
% This function takes a sturcture or an object and goes transform all the fields into strings in the recursive manner. Fields with big arrays are not processed - instead the size and a type of an array is outputted.
%
% HISTORY
% - 19-09-18 16:40:52 - created by Radek Chrapkiewicz
% - 2020-06-27 21:46:40 RC getting rid of dependencies
%
% ISSUES
% #1 - issue 1
%
% TODO
% *1 - get the first working version of the function!


%% VARIABLE CHECK 


%% CORE
%The core of the function should just go here. 

% try
str=structOrObj2Assignments(stuct_to_be_formatted,'');
% catch 
%     warning('ScanImage function "structOrObj2Assignments" failed while trying to format the structure text. Using "disp" instead');
%     str=evalc('stuct_to_be_formatted');
% end


end  %%% END STRUCT2STRING


function str = structOrObj2Assignments(obj,varname,props,numericPrecision)
%STRUCTOROBJ2ASSIGNMENTS Convert a struct or object to a series of
% assignment statements.
%
% str = structOrObj2Assignments(obj,varname,props)
% obj: (scalar) ML struct or object
% varname: (char) base variable name in assignment statements (see below).
% props: (optional cellstr) list of property names to encode. Defaults to all
% properties of obj. Property names can include dot notation for nested object/structure values.
% numericPrecision: (optional integer) specifies max number of digits to use in output string for numeric assignments. (Default value used otherwise)
%
% str is returned as:
% <varname>.prop1 = value1
% <varname>.prop2 = value2
% <varname>.structProp1 = value3
% <varname>.structProp2 = value4
% ... etc

if nargin < 3 || isempty(props)
    props = fieldnames(obj);
end

if nargin < 4 
    numericPrecision = []; %Use default
end


if ~isscalar(obj)
    str = sprintf('%s = <nonscalar struct/object>\n',varname);
    return;
end

str = [];

if isempty(varname)
    separator = '';
else
    separator = '.';
end

for c = 1:numel(props);
    pname = props{c};        
    
    [base,rem] = strtok(pname,'.');
    
    if isempty(rem)
        val = obj.(pname);
    else
        val = eval(['obj.' pname]);                
    end
        
    qualname = sprintf('%s%s%s',varname,separator,pname);
    if isobject(val) 
        str = lclNestedObjStructHelper(str,val,qualname);
    elseif isstruct(val)
        str = lclNestedObjStructHelper(str,val,qualname);
    else
        str = lclAddPVPair(str,qualname,toString(val,numericPrecision));
    end
end

end

function s = lclAddPVPair(s,pname,strval)
s = [s pname ' = ' strval sprintf('\n')];
end

function str = lclNestedObjStructHelper(str,val,qualname)
if isempty(val)
    str = [str qualname ' = []' sprintf('\n')]; 
elseif numel(val) > 1
    for c = 1:numel(val)
        qualnameidx = sprintf('%s__%d',qualname,c);
        str = [str structOrObj2Assignments(val(c),qualnameidx)]; %#ok<AGROW>
    end
else
    str = [str structOrObj2Assignments(val,qualname)]; 
end
end


function list = structOrObj2List(obj,props)
%STRUCTOROBJ2LIST Convert a struct or object to a string cell array listing all properties/fields
%
% str = structOrObj2List(obj,varname,props)
% obj: (scalar) ML struct or object
% props: (optional cellstr) list of properties to encode. Defaults to all
% properties of obj.
%
% list is returned as:
% {
% prop1
% prop2
% struct.prop1
% struct.prop2
% ... etc
% }

if nargin < 2 || isempty(props)
    props = fieldnames(obj);
end

str = structOrObj2Assignments(obj,'',props);

C = textscan(str,'%s %*[^\n]');

list = C{1};


end %%% end function

function s = array2Str(a)
%ARRAY2STR - Converts an array into a single line string encoding.
%
% Created: Timothy O'Connor 2/25/04
% Copyright: Cold Spring Harbor Laboratories/Howard Hughes Medical Institute 2004
% 
% SYNTAX
%     s = array2Str(a)
%     
% ARGUMENTS
%     a - Any n-dimensional array.
%
% RETURNS
%     s - A single-line string representing the properly shaped array.
%         Scalars are returned as string representations of scalars.
%     
% DESCRIPTION
%  The encoding algorithm works as follows:
%     b = size(a);
%     s = strcat(mat2str(b), '&', mat2str(reshape(a, [1 prod(b)]), 17))
%
%  The encoded string appears as two Matlab style array specifications,
%  such that calling `eval` on them will result in arrays. The two
%  arrays are separated by an ampersand ('&').
%
%  The string may be decoded in the following way: 
%     [bs s] = strtok(s, '&');
%     as = strtok(s, '&');
%     a = reshape(str2num(as), str2num(bs));
%
% EXAMPLES
%     a = zeros(2, 2, 2);
%     a(1, :, :) = magic(2);
%     a(2, :, :) = magic(2);
%     s = ndArray2Str(a)
%     s =
%         [2 2 2]&[1 1 4 4 3 3 2 2]
%
% PROGRAMMER_NOTE
%   Watch out for the 'precision' field on the call to mat2str.
%
%  Changed:
%          3/6/04 Tim O'Connor (TO030604c): Return [] for empty values.
%          3/6/04 Tim O'Connor (TO030504d): Upcast types that aren't supported for stringification.
%           
% See Also NDARRAYFROMSTR, RESHAPE, MAT2STR, STR2NUM

if ~isnumeric(a) && ~islogical(a) 
    error('MATLAB:badopt', 'Input to ndArray2Str must be numeric or logical.');
end

if isempty(a)
    s = '[]';
    return;
end

if numel(a)==1
    s = num2str(a);
    return;
end

b = size(a);

%Encode a string, such that the size preceeds the data, and they're separated by '&'.
%Use 20 digits, since 2^64 ~ 10^19.
%TO102004a - Change the precision to 16 digits, as this is the 'chosen' Matlab precision and lends itself
%to far more manageable strings, with fewer approximations. This may require rethinking, in the future though.
%The string's aesthetic benefits really pay off in GUI edit boxes.
s = strcat(mat2str(b), '&', mat2str(a(:)', 16));

end

function strout = cell2str(cellin)
    strout = cellfun(@(v){imported.scanimage.val2str(v)},cellin);
    strout = [ '{' strjoin(strout,',') '}' ];
end


function s = map2str(m)
%MAP2STR Convert a containers.Map object to a string
% s = map2str(m)
%
% Empty maps are converted to the empty string ''.

keyType = m.KeyType;
keys = m.keys;
Nkey = numel(keys);

s = '';
if Nkey > 0
    for c = 1:Nkey
        ky = keys{c};
        val = m(ky);
        switch keyType
            case 'char'
                keystr = ky;
            otherwise
                keystr = num2str(ky); % currently, ky must be a numeric scalar (see help containers.Map)
        end
        str = sprintf('%s: %s | ',keystr,imported.scanimage.toString(val));
        s = [s str]; %#ok<AGROW>
    end
    s = s(1:end-3); % take off last |
end

end


function s = toString(v,numericPrecision)
%TOSTRING Convert a MATLAB array to a string
% s = toString(v)
%   numericPrecision: <Default=15> Maximum number of digits to encode into string for numeric values
%
% Unsupported inputs v are returned as '<unencodeable value>'. Notably,
% structs are not supported because at the moment structs are processed
% with structOrObj2Assignments.
%
% At moment - only vector cell arrays of uniform type (string, logical, numeric) are encodeable

s = '<unencodeable value>';

if nargin < 2 || isempty(numericPrecision)
    numericPrecision = 6;
end

if iscell(v)
    if isempty(v)
        s = '{}';
    elseif isvector(v)
        if iscellstr(v)
            v = strrep(v,'''','''''');
            if size(v,1) > 1 % col vector
                list = sprintf('''%s'';',v{:});
            else
                list = sprintf('''%s'' ',v{:});
            end
            list = list(1:end-1);
            s = ['{' list '}'];
        elseif all(cellfun(@isnumeric,v(:))) || all(cellfun(@islogical,v(:)))
            strv = cellfun(@(x)mat2str(x,numericPrecision),v,'UniformOutput',false);
            if size(v,1)>1 % col vector
                list = sprintf('%s;',strv{:});
            else
                list = sprintf('%s ',strv{:});
            end
            list = list(1:end-1);
            s = ['{' list '}'];
        else
            s = '{';
            for i = 1:numel(v)
                if isa(v{i}, 'function_handle')
                    s = [s func2str(v{i}) ' '];
                elseif ischar(v{i})
                    s = [s '''' v{i} ''' '];
                elseif isnumeric(v{i}) || islogical(v{i})
                    s = [s imported.scanimage.array2Str(v{i}) ' '];
                elseif iscell(v{i})
                    s = [s imported.scanimage.toString(v{i}) ' '];
                end
            end
            s(end) = '}';
        end
    end
    
elseif ischar(v)
    if strfind(v,'''')
       v =  ['$' strrep(v,'''','''''')];
    end
    s = ['''' v ''''];
elseif isnumeric(v) || islogical(v)
    if ndims(v) > 2
        s = imported.scanimage.array2Str(v);
    else
        s = mat2str(v,numericPrecision);
    end
    
elseif isa(v,'containers.Map')
    s = imported.scanimage.map2str(v);
    
elseif isa(v,'function_handle')
    s = func2str(v);
    if ~strcmpi(s(1),'@');
        s = ['@' s];
    end    
end

end

function str = val2str(val)
    if iscell(val)
        str = imported.scanimage.cell2str(val);
    elseif ischar(val)
        str = ['''' val ''''];
    elseif isnumeric(val)
        str = mat2str(val);
    else
        str = sprintf('''Unknown class %s''',class(val));
        warning('Cannot convert class %s to string',class(val));
    end
end

