function snirf2bids(filename)
snirfname = [filename, '.snirf'];
snf = loadsnirf(snirfname);


%% Populate *_nirs.json file
nirs = struct;

if isfield(snf.nirs.metaDataTags, 'tag')
    nirs.TaskName = snf.nirs.metaDataTags.tag;
else
    nirs.TaskName = 'n/a';
end

if isfield(snf.nirs.data, 'time')
    nirs.SamplingFrequency =round(mean(diff(snf.nirs.data.time)),3); % calculate from slope of datatimeseries
    nirs.SamplingFrequency = snf.original_header.system.framerate;
else
    nirs.SamplingFrequency = 'n/a';
    nirs.SamplingFrequency = snf.original_header.system.framerate;
end

if isfield(snf.nirs.data, 'dataTimeSeries')
    nirs.NIRSChannelCount = length(snf.nirs.data.dataTimeSeries(1,:));
end

if isfield(snf.nirs.probe, 'sourcePos3D')
    nirs.NIRSSourceOptodeCount = length(snf.nirs.probe.sourcePos3D);
else
    nirs.NIRSSourceOptodeCount = length(snf.nirs.probe.sourcePos2D);
end

if isfield(snf.nirs.probe, 'detectorPos3D')
    nirs.NIRSDetectorOptodeCount = length(snf.nirs.probe.detectorPos3D);
else
    nirs.NIRSDetectorOptodeCount = length(snf.nirs.probe.detectorPos2D);
end

if isfield(snf.nirs.metaDataTags, 'MeasurementTime')
    tArray = split(snf.nirs.metaDataTags.MeasurementTime,':');
    nirs.RecordingDuration = ((str2num(tArray{1})*60*10) + (str2num(tArray{2})*10) + str2num(tArray{3}))/10;
else
    nirs.RecordingDuration = 'n/a';
end

bids.util.jsonwrite([filename, '_nirs.json'], nirs)
%% Populate *_channels.tsv file  
% probe has wavelengths ex: [750;850]

% Construct Wavelength list 
if isfield(snf.nirs.data.measurementList, 'wavelengthIndex')
    WlIdx1 = find(snf.nirs.data.measurementList.wavelengthIndex == 1);
    WlIdx2 = find(snf.nirs.data.measurementList.wavelengthIndex == 2);
    WLtemp = zeros(length(snf.nirs.data.measurementList.wavelengthIndex),1);

    if isfield(snf.nirs.probe, 'wavelengths')
        WLtemp(WlIdx1) = snf.nirs.probe.wavelengths(1);
        WLtemp(WlIdx2) = snf.nirs.probe.wavelengths(2);
        wllist = WLtemp;
    end
end

col_1 = [];
col_2 = [];
col_3 = [];
col_4 = [];
col_5 = [];
col_6 = [];
col_7 = [];
if isfield(snf.nirs.data, 'measurementList')
    channels = struct;
    for j =  1:length(snf.nirs.data.measurementList.sourceIndex)
        source = snf.nirs.data.measurementList.sourceIndex(:,j);
        col_3 = [col_3; source];
        detector = snf.nirs.data.measurementList.detectorIndex(:,j);
        col_4 = [col_4; detector]; 
        name = ['S', num2str(source), '-D', num2str(detector)];
        col_1 = [col_1; {name}];    
        type = 'NIRSCWAMPLITUDE';
        col_2 = [col_2; type];    
        wavelength_nominal = num2str(wllist(j)); % look in snirf measurement list for wavelengths
        col_5 = [col_5; wavelength_nominal];    
        units = 'n/a'; 
        col_6 = [col_6; units];    
        sampling_frequency = snf.original_header.system.framerate;
        col_7 = [col_7; sampling_frequency];
    end
        channels.name = col_1;
        channels.type = col_2;
        channels.source = col_3;
        channels.detector = col_4;
        channels.wavelength_nominal = col_5;
        channels.units = col_6;
        channels.sampling_frequency = col_7;
        channels = struct2table(channels);

        bids.util.tsvwrite([filename,'_channels.tsv'], channels);
end

%% Populate *_optodes.tsv file
nChannels = length(snf.nirs.probe.sourcePos3D) + length(snf.nirs.probe.detectorPos3D);
optodes = struct;
for j = 1:length(snf.nirs.probe.sourcePos3D)
    optodes.name{j} = {['S', num2str(j)]};
    optodes.type{j} = 'source';
    optodes.x(j) = snf.nirs.probe.sourcePos3D(j,1);
    optodes.y(j) = snf.nirs.probe.sourcePos3D(j,2);
    optodes.z(j) = snf.nirs.probe.sourcePos3D(j,3);
end

for k = 1:length(snf.nirs.probe.detectorPos3D)
    optodes.name{j+k} = {['D', num2str(k)]};
    optodes.type{j+k} = 'detector';
    optodes.x(j+k) = snf.nirs.probe.detectorPos3D(k,1);
    optodes.y(j+k) = snf.nirs.probe.detectorPos3D(k,2);
    optodes.z(j+k) = snf.nirs.probe.detectorPos3D(k,3);
end
optodes.name = optodes.name';
optodes.type = optodes.type';
optodes.x = optodes.x';
optodes.y = optodes.y';
optodes.z = optodes.z';

optodes = struct2table(optodes);
bids.util.tsvwrite([filename,'_optodes.tsv'], optodes); 

%% Populate *_coordsystem.json file
coordsystem = struct;
 
coordsystem.NIRSCoordinateSystem = 'Talairach'; % include mapping to either Talairach or MNI
if isfield(snf.nirs.metaDataTags, 'LengthUnit')
    coordsystem.NIRSCoordinateUnits = snf.nirs.metaDataTags.LengthUnit;
else
    coordsystem.NIRSCoordinateUnits = 'Unknown';
end
% coordsystem.NIRSCoordinateSystemDescription
bids.util.jsonwrite([filename,'_coordsystem.json'], coordsystem)

%write to .json file using bids-matlab

%% Populate *_events.tsv file
events = struct;
totalLength = 0;
events.onset = [];
events.duration = [];
for jj = 1:length(snf.nirs.stim)
    pulse = snf.nirs.stim(jj).data;
    for ii = 1:size(pulse,1)
        events.onset = [events.onset, pulse(ii)/snf.nirs.metaDataTags.framerate];
        events.duration = [events.duration; 'n/a'];
    end
end

events.onset = events.onset';
events.duration = events.duration;

bids.util.tsvwrite([filename,'_events.tsv'], events);
end