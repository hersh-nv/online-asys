function endStream(src,callbackdata)
if (~isempty(timerfind))
    stop(timerfind);
    delete(timerfind);
    disp('Timer(s) deleted');
end
cbmex('close');