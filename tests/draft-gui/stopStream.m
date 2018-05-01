function stopStream()
if (~isempty(timerfind))
    stop(timerfind);
    delete(timerfind);
end
% cbmex('trialconfig',0); 
cbmex('close');
disp('Data stream closed');