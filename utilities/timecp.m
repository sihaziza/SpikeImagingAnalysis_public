function timecp()
% Copy time stamp to a clipboard, for pasting comments inside functions.
% SYNTAX
%[output_arg1,summary]= timmecp() - use 1 if no arguments are allowed
%
% HISTORY
% - 27-Jun-2020 00:33:34 - created by Radek Chrapkiewicz (radekch@stanford.edu)
% - 2020-06-27 00:41:18 Radek - adapted for VIA


ADD_initials=true; % 2019-06-07 11:53:54 RC

initials=getenv('username');
switch initials
    case 'Radek'
        initials='RC';
    case 'Simon'
        initials='SH';
end
        
if ADD_initials
    now_formatted=sprintf('%% - %s -   %s',datetime('now','Format','yyyy-MM-dd HH:mm:ss'),initials); % 2019-06-07 11:53:27 RC
else
    now_formatted=datetime('now','Format','yyyy-MM-dd HH:mm:ss');
end
fprintf('%s\n',now_formatted)
clipboard('copy',now_formatted)
