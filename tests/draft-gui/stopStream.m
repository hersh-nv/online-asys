function stopStream()
if (~isempty(timerfind))
    stop(timerfind);
    delete(timerfind);
end
cbmex('close');
disp('Data stream closed');