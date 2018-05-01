function stopCBMEX()
if (~isempty(timerfind))
    stop(timerfind);
    delete(timerfind);
end
cbmex('close');
disp('CBMEX closed');