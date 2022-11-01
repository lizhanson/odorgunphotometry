% [ODORSTIM,WHEEL] = SmellStim_treadmill(PUFF,DELAY)
% controls a 12 channel odor gun-style olfactometer (Burton
% and Wachowiak, Chemical Senses, 2019) via arduino. It takes the inputs of
% puff duration and delay duration in seconds. It will then prompt user to
% choose stim file. Stim files should be in .csv format with numbers from
% 1-12 in one column with one row per stimulation. The program will then
% mount the arduino and subsequently prompt the user to press any key to
% continue when they are ready to start stimulation. This version of the
% program simulatnaously records wheel running via a rotary encoder and
% displays wheel motion in an animatedline figure.
%
% The input variable PUFF sets the duration of stimulation in seconds.
%
% The in put variable DELAY sets the duration of delay between puffs in
% seconds (e.g. for a 20 s total trial duration with a 1 s puff, delay
% would = 19 s)
%
% The output variable ODORSTIM is a matrix of stimulation channels, on
% times, and off times (relative to start time, expressed in seconds) The
% output variable WHEEL is a matrix of times in seconds from start of
% recording and wheel motion position differential (i.e. sample to sample
% motion)
%
% Must only have one mountable arduino connected!



function [OdorStim,Wheel] = SmellStim_treadmill(puff,delay)


a = arduino()

%%% Set up rotary encoder for recording treadmill movement
encoder = rotaryEncoder(a,'D19','D20');
timeall=0;
countall=0;

%%% Make sure channels are attatched to the right pins
for i = 2:13
    pinArray{i-1} = sprintf('D%d',i);
end

%%% load stimulus file
[fn,pth] = uigetfile('~lizhanson/Desktop/*.csv');
stimfile = sprintf('%s%s',pth,fn);
stimCH = csvread(stimfile);

%%% preallocate
OdorStim = zeros([size(stimCH,1) 3]);

%%% prepulse each channel to initialize.
for i = 1:length(pinArray)
    writeDigitalPin(a, pinArray{i}, 1);
    pause(0.01)
    writeDigitalPin(a,pinArray{i},0);
    pause(0.05)
end

%%% Wait for user input to start
sprintf('Press any key to start')
pause
t0 = double(tic);
t=double(tic)-t0;

%%% Initialize treadmill live plot
figure(1)
x0=100;
y0=350;
width=800;
height=200;
set(gcf,'position',[x0,y0,width,height])
h = animatedline;
ax = gca;

%%% Break loop with user input (will progress to file saving option)
button = figure(2);
x0=1000;
y0=400;
width=200;
height=100;
set(gcf,'position',[x0,y0,width,height])
ButtonHandle = uicontrol('Parent',button,...
    'Style', 'PushButton', ...
    'String', 'Stop puffing',...
    'Position',[4 2 192 96],...
    'Callback', 'delete(gcbf)');

%%% Delay start 5 seconds and start treadmill recording
while (t)/10^9 < 5
    [count] = readCount(encoder);
    timeall=cat(1, timeall, t/10^9);
    countall=cat(1, countall, count);
    %Update treadmill plot
    addpoints(h,(t/10^9),count-countall(end-1));
    ax.XLim = [(t/10^9)-5, (t/10^9)+1];
    drawnow
    pause(0.01)
    t = double(tic)-t0;
end

%%% Main control loop
b = 1;
c = 1;
for i=1:length(stimCH)
    
    %%% Allows user to stop puffing mid-prtocol using the gui button while
    %%% maintinaing the option of saving output variables.
    if ~ishandle(ButtonHandle)
        disp('Puffing stopped by user');
        break;
    end
    
    
    t1 = double(tic)-t0;
    for j = length(stimCH(i,:))
     activeCh = stimCH(i,j);
     %Start puff and record puff on time
     OdorStim(b,1) = stimCH(i,j);
     writeDigitalPin(a, pinArray{activeCh}, 1);
 
    
    %Start synchronization pulse
    writeDigitalPin(a, 'D53', 1);
    OdorStim(b,2) = t1/10^9;
    t = double(tic)-t0;
    b=b+1;
    end
    
    while (t-t1)/10^9 < puff
        %%% End with button press
        if ~ishandle(ButtonHandle)
            disp('Puffing stopped by user');
            break;
        end
        %Record treadmill
        [count] = readCount(encoder);
        timeall=cat(1, timeall, t/10^9);
        countall=cat(1, countall, count);
        
        %Update treadmill plot
        addpoints(h,(t/10^9),count-countall(end-1));
        ax.XLim = [(t/10^9)-5, (t/10^9)+1];
        drawnow
        pause(0.01)
        t = double(tic)-t0;
    end
    sprintf('Puffs Complete: %d of %d. Channel %d',i,length(stimCH),activeCh)
    
    %End puff and record off time
    t2 = double(tic)-t0;
    for j = 1:length(stimCH(i,:))
        OdorStim(c,3) = t2/10^9;
        c=c+1;
    end
    for j = 1:length(pinArray)
        writeDigitalPin(a, pinArray{j}, 0);
    end
    
    %End synchronization pulse
    writeDigitalPin(a, 'D53', 0);
    t = double(tic)-t0;
    
    while (t-t2)/10^9 < delay
        %%% End with button press
        if ~ishandle(ButtonHandle)
            disp('Puffing stopped by user');
            break;
        end
        %Record treadmill
        [count] = readCount(encoder);
        timeall=cat(1, timeall, t/10^9);
        countall=cat(1, countall, count);
        %Update treadmill plot
        addpoints(h,(t/10^9),count-countall(end-1));
        ax.XLim = [(t/10^9)-5, (t/10^9)+1];
        drawnow
        pause(0.01)
        t = double(tic)-t0;
    end
    
    clear t t1 t2 activeCh
end

close all

for j = 1:length(pinArray)
    writeDigitalPin(a, pinArray{j}, 0);
end
writeDigitalPin(a,'D53',0);

%%% Only invoked when puffing protocol is stopped mid puff. Records
%%% accurate puff end time.
if OdorStim(end,3) == 0;
    OdorStim(end,3) = (tic-t0)/10^9;
else
end

%%% Calculate treadmill velocity from wheel position
Wheel(:,2) = diff(countall);
Wheel(:,1) = timeall(1:end-1);

%%% Prompt user for file name to save
str = input('Would you like to save output variables? y/n: ','s');
if strcmp(str,'y')
    file = input('Filename: ','s');
    f1 = sprintf('%s_tread.csv',file);
    f2 = sprintf('%s_odortimes.csv',file);
    csvwrite(f1,Wheel);
    csvwrite(f2,OdorStim);
else
end
end