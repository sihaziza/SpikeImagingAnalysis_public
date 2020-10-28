
function changeslice(src,evt,safter,Ftrace,traceX,traceY)
evname = evt.EventName;
    switch(evname)
        case{'SliderValueChanging'}
%             f = sbefore.SliceNumber;
%             safter.SliceNumber = f;
%             disp(['Slider value changed event: ' mat2str(evt.CurrentValue)]);
             safter.SliceNumber = evt.CurrentValue;
             
             drawTrace(Ftrace,traceX, traceY,evt.CurrentValue);
        case{'SliderValueChanged'}
            disp(['Slider value changed event: ' mat2str(evt.CurrentValue)]);
    end

end