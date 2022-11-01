function [output1,output2,output3] = OdorGunPhotometry2()

% ODORGUNPHOT This function imports single channel, isobestic subtracted 
% df/f photometry traces and sorts them by odor presentation. 


% This function promps the user to select the files for the df/f trace 
% (preprocessed), the odor presentation times (an vector where time(t) = 1 
% when any odor channel(s)is open and = 0 when all odor channels are 
% closed), and the list of odors presented. It then sorts the df/f trace 
% by odor presentation, performs statistics, and plots results. 

clear all
close all

% Three different (sequential GUI windows will ask you to selct the files
% you want to import

[fn1,pth1] = uigetfile('*.*'); % Must choose trace file first
[fn2,pth2] = uigetfile('*.*'); % Must choose digital input file second
[fn3,pth3] = uigetfile('*.*'); % Must choose stim file with channel #s third 
%[fn4,pth4] = uigetfile('*.*'); % Must choose wheel file
% Create string variables with paths to correct files (output from GUI) 

tracefn = sprintf('%s%s',pth1,fn1);
% odorpresentationfn = sprintf('%s%s',pth2,fn2);
% odorsfn = sprintf('%s%s',pth3,fn3);
%wheelfn=sprintf('%s%s',pth4,fn4);


% Import the data to matricies (csvread function can take a couple min)

tracedf = csvread(tracefn,1,0);
% 
% odortimes = csvread(odorpresentationfn,1,0);
% odors = csvread(odorsfn);
%wheel = csvread(wheelfn,1,0);
% Downsampling and smoothing out noise from traces

traceds = downsample(tracedf,2);
% odortimesds = downsample(odortimes,50); 

tracetimesm = smooth(traceds(:,1),10);
tracesm410 = smooth(traceds(:,3),10);
tracesm488 = smooth(traceds(:,2),10);

scale=polyfit(tracesm410, tracesm488 , 1);

fTracesm410=(scale(1).*tracesm410)+scale(2);
trace=tracesm488-fTracesm410;

% Plotting trace and digital out together to make sure files were imported
% correctly
figure(1)
subplot(311)
plot(tracetimesm,trace)
axis([0 50 -50 50])
% subplot(312)
% plot(tracetimesm,tracesm488)
% subplot(313)
% plot(tracetimesm,tracesm410)