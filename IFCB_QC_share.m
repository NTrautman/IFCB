%{
Nicholas Trautman
UC Davis Bodega Marine Lab
Last Updated: 2023.10.17

Semi-automated quality control for IFCB data.

Download files from the IFCB dashboard before running if you do not already
have them stored on a local machine.

Change the following variables in the USER INPUTS section before running
the script:
- IFCB_id: should match your instrument, e.g., 163 for Bodega Marine Lab
- sample_date: date you want to QC (can only do one day at a time)
- loc: location of IFCB files in local directory
- flag_loc: location to write QC flag data to
- metadata_loc: location to write metadata.csv file to before copying it to
  the IFCB computer

When you are done with QC, copy the metadata.csv file to the appropriate
directory location on the IFCB computer so that it will get uploaded to the
IFCB dashboard the next time rsync is run on the IFCB computer.
%}

clear, clc, close all
%% USER INPUTS
%IFCB ID number
IFCB_id = 163;
%specify date of interest
sample_date = datetime(2023,5,1);

%location of IFCB files in local directory:
loc = '/Users/nicholas/Library/CloudStorage/Box-Box/BOON/Data/IFCB/ifcbdata/CA-IFCB-163/';
%location to write flag structures to:
flag_loc = '/Users/nicholas/Documents/IFCB';
%location to write metadata.csv file to:
metadata_loc = '/Users/nicholas/Documents/IFCB';

%% LOCATE IFCB FILES
%{
The user-defined function 'get_data_IFCB' extracts the adc and hdr files
for a specific date from where they are stored in the local directory.
%}
[sample_path,hdr_files,adc_files] = get_data_IFCB(sample_date,loc);

%% ===================================
% LOOP THROUGH FILES FOR SELECTED DATE
% ====================================
for i = 1:length(hdr_files)


%% LOAD DATA
adc = readtable([sample_path,adc_files{i}],'FileType','text');
s = dir([sample_path,adc_files{i}]);
hdr = readcell([sample_path,hdr_files{i}],'FileType','text','Delimiter','/n');
%extract column names from hdr and add to adc
cols = hdr{end};
cols = strsplit(cols,': ');
cols = strsplit(cols{2},', ');
if s.bytes ~= 0
    adc.Properties.VariableNames = cols;
end
%extract sampleTime, runTime, inhibitTime, temperature, & humidity from hdr
sampleTime = strsplit(hdr{5},': ');
sampleTime = datetime(sampleTime{2},'Format','yyyy-MM-dd''T''HH:mm:SS''Z''');
runTime = strsplit(hdr{139},': ');
runTime = str2double(runTime{2});
inhibitTime = strsplit(hdr{140},': ');
inhibitTime = str2double(inhibitTime{2});
temperature = strsplit(hdr{141},': ');
temperature = str2double(temperature{2});
humidity = strsplit(hdr{142},': ');
humidity = str2double(humidity{2});

%compute volume analyzed
flowrate = 0.25; %milliliters per minute for syringe pump
lookTime = runTime - inhibitTime; %seconds
mL_analyzed = flowrate.*lookTime/60;

%determine the number of triggers and images (if .adc file is not empty)
if s.bytes ~= 0
    %determine number of triggers
    %(unique trigger #s in .adc file)
    triggerCount = max(adc.('trigger#'));

    %determine number of dashboard triggers
    %(this is just the number of rows in the .adc file)
    dashTriggerCount = size(adc,1);

    %determine number of images
    %(ROIx==0 or ROIy==0 means PMT triggered but fluorescence was outside
    %camera's POV)
    imageCount = length(adc.ROIy(adc.ROIy ~= 0));
else
    triggerCount = 0;
    dashTriggerCount = 0;
    imageCount = 0;
    adc.ROIx = NaN;
    adc.ROIy = NaN;
end

%print sample summary
sampleID = char(adc_files{i}(1:end-4));
summary = ['\nFile ',num2str(i),'/',num2str(length(hdr_files)),'\n'...
    sampleID,'\n'...
    hdr{5},'\n'...
    'Instrument: IFCB ',num2str(IFCB_id),'\n'...
    'Triggers: ',num2str(dashTriggerCount),'\n'...
    'Images: ',num2str(imageCount),'\n'...
    'Triggers / s: ',num2str(dashTriggerCount/runTime),'\n'...
    'Volume Analyzed: ',num2str(mL_analyzed),'\n'...
    'ROIs / mL: ',num2str(imageCount/mL_analyzed),'\n'...
    'Runtime [s]: ',num2str(runTime),'\n'...
    'Temperature [degC]: ',num2str(temperature),'\n'...
    'Humidity [RH]: ',num2str(humidity),'\n\n'];
fprintf(summary)

%plot ROIy vs. ROIx
if s.bytes ~= 0
    figure(1)
    plot(adc.ROIx,adc.ROIy,'o');
    grid on
    xlabel('ROIx')
    ylabel('ROIy')
    title(sampleID,'Interpreter','none')
    drawnow
end

%% AUTOMATED QC CHECKS
%skip_flag == 0 if sample is good
skip_flag = 0;

%QC thresholds
TH.sampleVolume = 2.5; %[mL]
TH.runTime = 1000; %[seconds]
TH.images2triggers = 0.9; %[images/trigger]
TH.humidity = 99; %[RH]

%create structure to keep track of which QC checks have flagged bad data
flag = struct('sampleSize',0,'incompleteSample',0,'images2triggers',0,'humidity',0,'noData',0);

%low image to trigger ratio
images2triggers = imageCount/dashTriggerCount;
if images2triggers < TH.images2triggers
    flag.images2triggers = 1;
end

%incomplete sample
if runTime < TH.runTime && mL_analyzed < TH.sampleVolume
    flag.incompleteSample = 1;
end

%high humidity
if humidity > TH.humidity
    flag.humidity = 1;
end

%sample contains no data (zero triggers)
if s.bytes == 0
    flag.noData = 1;
end

%if any of the QC checks return 1, change the value of skip_flag to 1
f = fields(flag);
for j = 1:length(f)
    if flag.(f{j}) == 1
        skip_flag = 1;
    end
end

%if sample is flagged, print the appropriate message to the command window
if skip_flag == 0 && s.bytes ~= 0
    fprintf('Sample data is good!\n\n')
elseif skip_flag == 1
    fprintf('Sample data is bad :(\n')
    if flag.images2triggers == 1
        msg = 'Difference between images and triggers > 10%%';
        fprintf([msg,'\n'])
    end
    if flag.incompleteSample == 1
        msg = 'Incomplete sample';
        fprintf([msg,'\n'])
    end
    if flag.humidity == 1
        msg = 'High humidity';
        fprintf([msg,'\n'])
    end
    if flag.noData == 1
        msg = 'No data in sample';
        fprintf([msg,'\n'])
    end
    fprintf('\n')
end

%% WRITE FLAG STRUCT TO flag.csv FILE
F = struct2table(flag);
sampleID = string(sampleID);
S = table(sampleID);
flagT = [S,F];

if ~exist([flag_loc,'flag.csv'],'file')
    writetable(flagT,[flag_loc,'flag.csv'])
else
    writetable(flagT,[flag_loc,'flag.csv'],'WriteMode','Append',...
        'WriteVariableNames',false)
end

%% WRITE SKIP FLAGS TO metadata.csv FILE
if skip_flag == 1
    skip_flag = "TRUE";
else
    skip_flag = [];
    sampleID = [];
end

T = table(sampleID,skip_flag,'VariableNames',{'bin','skip'});

if ~exist([metadata_loc,'metadata.csv'],'file')
    writetable(T,[metadata_loc,'metadata.csv'])
else
    if ~isempty(skip_flag)
        writetable(T,[metadata_loc,'metadata.csv'],'WriteMode','Append',...
            'WriteVariableNames',false)
    end
end

%% PROMPT FOR NEXT SAMPLE
%don't show prompt on last sample
if i == length(hdr_files)
    disp('All done!')
    return
end

if strcmp(skip_flag,"TRUE")
    prompt = "Next sample? Y/N [Y]: ";
    txt = input(prompt,"s");
    if isempty(txt)
        txt = 'Y';
    end

    if strcmp(txt,'Y')
        clf
        clc
        continue
    else
        return
    end
end


end

%% functions
function [sample_path,hdr_files,adc_files] = get_data_IFCB(sample_date,loc)

[y1,m1,d1] = ymd(sample_date); %extract year, month, and day from start date
%convert to strings
y1 = num2str(y1);
m1 = sprintf('%02d',m1);
d1 = sprintf('%02d',d1);
%generate list of folders in directory where IFCB data is being stored
tmp_path = [loc,y1];
tmp_dir = dir(tmp_path);
ind = startsWith({tmp_dir.name}','D');
tmp_dir = tmp_dir(ind);
folders = {tmp_dir.name}';
%look for folder for start date, otherwise use next one chronologically
uf = ['D',y1,m1,d1];
if any(strcmp(folders,uf))
    tmp_path = [tmp_path,'/',uf];
else
    f = folders;
    f = [f;uf];
    f = sortrows(f);
    idx = find(strcmp(f,uf)==1)+1;
    tmp_path = [tmp_path,'/',f{idx}];
end

%return paths to data files for date of interest
sample_path = [tmp_path,'/'];
hdr_dir = dir([tmp_path,'/*.hdr']);
adc_dir = dir([tmp_path,'/*.adc']);
hdr_files = {hdr_dir.name}';
adc_files = {adc_dir.name}';

end