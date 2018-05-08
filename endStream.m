function endStream()
if (~isempty(timerfind))
    stop(timerfind);
    delete(timerfind);
    disp('Timer(s) deleted');
end

try
    cbmex('close');
catch
    % CBMEX can sometimes cause problems trying to run close methods like
    % this if the stream isn't running properly
end