function varargout=h5load(filename, varargin)
% Load data in an HDF5 file to a MATLAB structure.
%   adapted from the EasyH5 Toolbox: https://github.com/fangq/easyh5
%
% SYNTAX:
% data = h5load(filename)
% data = h5load(filename, dspath)
%
% INPUTS:
% - filename - Name of the h5 file to load data from
% - dspath  - Dataset path to read part of the HDF5 file to load
%
% OUTPUTS:
% - output
%        data: a structure (array) or cell (array)
%
% OPTIONS:
% - 'dspath': the dataset path for storing the variable. If not given, the 
%               actual variable name for the data input will be used as
%               the root object. The value shall not include '/'.
%
% HISTORY
% - 2020-06-02 11:12:20 - created by Jizhou Li (hijizhou@gmail.com)
% - 2020-06-02 18:52:10 - add datatype handling, fixed the image transpose
% issue
%
% ISSUES
% #1 - 
%
% TODO
% *1 - 

if(nargin<1)
    error('you must provide at least the filename');
end

dspath = '';
if(length(varargin)==1)
    dspath=varargin{1};
end

% check the dspath
existing = false;
fileinfo=h5info(filename);
DS = fileinfo.Datasets;
GP = fileinfo.Groups;
for dsi=1:numel(DS)
    if strcmp(dspath, ['/' DS(dsi).Name])
        existing = true;
    end
end
for gpi=1:numel(GP)
    DSi = GP(gpi).Name;
    if startsWith(dspath, DSi)
       existing = true;
    end 
end

if ~existing & ~isempty(dspath) 
    h5info(filename)
    error('The dataset path is not exisiting!');
end

if(isa(filename,'H5ML.id'))
    loc=filename;
else
    loc = H5F.open(filename);
end

opt.rootpath=dspath;
opt.dotranspose = 0;
if(~(isfield(opt,'complexformat') && iscellstr(opt.complexformat) && numel(opt.complexformat)==2))
    opt.complexformat={};
end
   
try
  if(nargin>1 && ~isempty(dspath))
      try
          rootgid=H5G.open(loc,dspath);
          [varargout{1:nargout}]=load_one(rootgid, opt);
          H5G.close(rootgid);
      catch
          [gname,dname]=fileparts(dspath);
          rootgid=H5G.open(loc,gname);
          [status, res]=group_iterate(rootgid,dname,struct('data',struct,'meta',struct,'opt',opt));
          if(nargout>0)
              varargout{1}=res.data;
          elseif(nargout>1)
              varargout{2}=res.meta;
          end
          H5G.close(rootgid);
      end
  else
      [varargout{1:nargout}]=load_one(loc, opt);
  end
  H5F.close(loc);
catch ME
  H5F.close(loc);
  rethrow(ME);
end

% go to the upper level for simplicity
if numel(fieldnames(varargout{1}))==1
    fns =fieldnames(varargout{1});
    varargout{1} = varargout{1}.(fns{1});
end

end

%--------------------------------------------------------------------------
function [data, meta]=load_one(loc, opt)

data = struct();
meta = struct();
inputdata=struct('data',data,'meta',meta,'opt',opt);
order='H5_INDEX_CRT_ORDER';
if(isfield(opt,'order') && strcmpi(opt.order,'alphabet'))
   order='H5_INDEX_NAME';
end

% Load groups and datasets
try
    [status,count,inputdata] = H5L.iterate(loc,order,'H5_ITER_INC',0,@group_iterate,inputdata);
catch
    if(strcmp(order,'H5_INDEX_CRT_ORDER'))
        [status,count,inputdata] = H5L.iterate(loc,'H5_INDEX_NAME','H5_ITER_INC',0,@group_iterate,inputdata);
    end
end

data=inputdata.data;
meta=inputdata.meta;


end

%--------------------------------------------------------------------------
function [status, res]=group_iterate(group_id,objname,inputdata)
status=0;
attr=struct();

encodename=jsonopt('PackHex',1,inputdata.opt);

try
  data=inputdata.data;
  meta=inputdata.meta;

  % objtype index 
  info = H5G.get_objinfo(group_id,objname,0);
  objtype = info.type;
  objtype = objtype+1;
  
  if objtype == 1
    % Group
    name = regexprep(objname, '.*/', '');
  
	group_loc = H5G.open(group_id, name);
	try
	  [sub_data, sub_meta] = load_one(group_loc, inputdata.opt);
	  H5G.close(group_loc);
	catch ME
	  H5G.close(group_loc);
	  rethrow(ME);
	end
	if(encodename)
        name=encodevarname(name);
    else
        name=genvarname(name);
    end
    data.(name) = sub_data;
    meta.(name) = sub_meta;
    
  elseif objtype == 2
    % Dataset
    name = regexprep(objname, '.*/', '');
  
	dataset_loc = H5D.open(group_id, name);
	try
	  sub_data = H5D.read(dataset_loc, ...
	      'H5ML_DEFAULT', 'H5S_ALL','H5S_ALL','H5P_DEFAULT');
          [status, count, attr]=H5A.iterate(dataset_loc, 'H5_INDEX_NAME', 'H5_ITER_INC', 0, @getattribute, attr);
	  H5D.close(dataset_loc);
	catch exc
	  H5D.close(dataset_loc);
	  rethrow(exc);
	end
	
	sub_data = fix_data(sub_data, attr, inputdata.opt);
	if(encodename)
        name=encodevarname(name);
    else
        name=genvarname(name);
    end
    data.(name) = sub_data;
    meta.(name) = attr;
  end
catch ME
    rethrow(ME);
end

res=struct('data',data,'meta',meta,'opt',inputdata.opt);

end
%--------------------------------------------------------------------------
function data=fix_data(data, attr, opt)
% Fix some common types of data to more friendly form.

if isstruct(data)
  fields = fieldnames(data);

  if(length(intersect(fields,{'SparseIndex','Real'}))==2)
    if isnumeric(data.SparseIndex) && isnumeric(data.Real)
      if(nargin>1 && isstruct(attr))
          if(isfield(attr,'SparseArraySize'))
              spd=sparse(1,prod(attr.SparseArraySize));
              if(isfield(data,'Imag'))
                  spd(data.SparseIndex)=complex(data.Real,data.Imag);
              else
                  spd(data.SparseIndex)=data.Real;
              end
              data=reshape(spd,attr.SparseArraySize(:)');
          end
      end
    end
  end

  if(numel(opt.complexformat)==2 && length(intersect(fields,opt.complexformat))==2)
    if isnumeric(data.(opt.complexformat{1})) && isnumeric(data.(opt.complexformat{2}))
        data = data.(opt.complexformat{1}) + 1j*data.(opt.complexformat{2});
    end
  else
    % if complexformat is not specified or not found, try some common complex number storage formats
    if(length(intersect(fields,{'Real','Imag'}))==2)
      if isnumeric(data.Real) && isnumeric(data.Imag)
        data = data.Real + 1j*data.Imag;
      end
    elseif(length(intersect(fields,{'real','imag'}))==2)
      if isnumeric(data.real) && isnumeric(data.imag)
        data = data.real + 1j*data.imag;
      end
    elseif(length(intersect(fields,{'Re','Im'}))==2)
      if isnumeric(data.Re) && isnumeric(data.Im)
        data = data.Re + 1j*data.Im;
      end
    elseif(length(intersect(fields,{'re','im'}))==2)
      if isnumeric(data.re) && isnumeric(data.im)
        data = data.re + 1j*data.im;
      end
    elseif(length(intersect(fields,{'r','i'}))==2)
      if isnumeric(data.r) && isnumeric(data.i)
        data = data.r + 1j*data.i;
      end
    end
  end
  
end

if(isa(data,'uint8') || isa(data,'int8'))
  if(nargin>1 && isstruct(attr))
      if(isfield(attr,'MATLABObjectClass'))
         data=getArrayFromByteStream(data); % use undocumented function
      end
  end
end
end

function val=jsonopt(key,default,varargin)
%
% val=jsonopt(key,default,optstruct)
%
% setting options based on a struct. The struct can be produced
% by varargin2struct from a list of 'param','value' pairs
%
% authors:Qianqian Fang (q.fang <at> neu.edu)
%
% input:
%      key: a string with which one look up a value from a struct
%      default: if the key does not exist, return default
%      optstruct: a struct where each sub-field is a key 
%
% output:
%      val: if key exists, val=optstruct.key; otherwise val=default
%
% license:
%     BSD or GPL version 3, see LICENSE_{BSD,GPLv3}.txt files for details
%
% -- this function is part of JSONLab toolbox (http://iso2mesh.sf.net/cgi-bin/index.cgi?jsonlab)
% 

val=default;
if(nargin<=2)
    return;
end
key0=lower(key);
opt=varargin{1};
if(isstruct(opt))
    if(isfield(opt,key0))
       val=opt.(key0);
    elseif(isfield(opt,key))
       val=opt.(key);
    end
end
end

function str = encodevarname(str,varargin)
%
%    newname = encodevarname(name)
%
%    Encode an invalid variable name using a hex-format for bi-directional
%    conversions. 

%    This function is sensitive to the default charset
%    settings in MATLAB, please call feature('DefaultCharacterSet','utf8')
%    to set the encoding to UTF-8 before calling this function.
%
%    author: Qianqian Fang (q.fang <at> neu.edu)
%
%    input:
%        name: a string, can be either a valid or invalid variable name
%
%    output:
%        newname: a valid variable name by converting the leading non-ascii
%              letter into "x0xHH_" and non-ascii letters into "_0xHH_"
%              format, where HH is the ascii (or Unicode) value of the
%              character.
%
%              if the encoded variable name CAN NOT be longer than 63, i.e. 
%              the maximum variable name specified by namelengthmax, and
%              one uses the output of this function as a struct or variable
%              name, the name will be trucated at 63. Please consider using
%              the name as a containers.Map key, which does not have such
%              limit.
%
%    example:
%        encodevarname('_a')   % returns x0x5F_a
%        encodevarname('a_')   % returns a_ as it is a valid variable name
%        encodevarname('å?˜é‡?')  % returns 'x0xE58F98__0xE9878F_' 
%
%    this file is part of EasyH5 Toolbox: https://github.com/fangq/easyh5
%
%    License: GPLv3 or 3-clause BSD license, see https://github.com/fangq/easyh5 for details
%

    if(~isvarname(str(1)))
        if(exist('unicode2native','builtin'))
            str=regexprep(str,'^([^A-Za-z])','x0x${sprintf(''%X'',unicode2native($1))}_','once');
        else
            str=sprintf('x0x%X_%s',char(str(1))+0,str(2:end));
        end
    end
    if(isvarname(str))
        return;
    end
    if(exist('unicode2native','builtin'))
        str=regexprep(str,'([^0-9A-Za-z_])','_0x${sprintf(''%X'',unicode2native($1))}_');
    else
        cpos=regexp(str,'[^0-9A-Za-z_]');
        if(isempty(cpos))
            return;
        end
        str0=str;
        pos0=[0 cpos(:)' length(str)];
        str='';
        for i=1:length(cpos)
            str=[str str0(pos0(i)+1:cpos(i)-1) sprintf('_0x%X_',str0(cpos(i))+0)];
        end
        if(cpos(end)~=length(str))
            str=[str str0(pos0(end-1)+1:pos0(end))];
        end
    end
end


%--------------------------------------------------------------------------
function [status, dataout]= getattribute(loc_id,attr_name,info,datain)
status=0;
attr_id = H5A.open(loc_id, attr_name, 'H5P_DEFAULT');
datain.(attr_name) = H5A.read(attr_id, 'H5ML_DEFAULT');
H5A.close(attr_id);
dataout=datain;
end