
% Intersubject Correlation Analysis using automatic analysis (aa)
%
% see: https://github.com/automaticanalysis/automaticanalysis

% -------------------------------------------------------------------------
% INITIALIZATION
% -------------------------------------------------------------------------

clear all;
aa_ver5; 

aap = aarecipe('aa_analysis.xml');       

% -------------------------------------------------------------------------
% DIRECTORY AND DATA OPTIONS
% -------------------------------------------------------------------------

aap.acq_details.root = '/path/to/topleveldir';
aap.directory_conventions.analysisid = 'results_directory_name';

aap.options.NIFTI4D = 1;

toplevelBIDSdir = '/path/to/BIDSdata';
aap.directory_conventions.rawdatadir = toplevelBIDSdir;

% -------------------------------------------------------------------------
% PCT (if available)
% -------------------------------------------------------------------------

% aap.options.wheretoprocess='matlab_pct';
% aap.directory_conventions.poolprofile = 'local';
% aap.options.aaparallel.numberofworkers = 15;

% -------------------------------------------------------------------------
% data selection
% -------------------------------------------------------------------------

aap.acq_details.input.combinemultiple = true;

% ************** select one of the following: *****************************

% analysis 1 -- all subjects (omits 12 subjects w/ SNR < 3)

SID = BIDS_subjectfilter(toplevelBIDSdir,'maxSNR>2.9')
aap = aas_processBIDS(aap,[],[],SID); 

% analysis 2 -- grouped by SNR 
% the 3 SNR cutoffs were determined in a separate review

% analysis 2a - lower tertile SNRn only

% disp('*** LOWER TERTILE ***')
% SID = BIDS_subjectfilter(toplevelBIDSdir,'maxSNR=[3.0 6.0]')
% aap = aas_processBIDS(aap,[],[],SID); 

% analysis 2b - middle tertile SNR

% disp('*** MIDDLE TERTILE ***')
% SID = BIDS_subjectfilter(toplevelBIDSdir,'maxSNR=[6.0 14.5]')
% aap = aas_processBIDS(aap,[],[],SID); 

% analysis 2c - upper tertile SNR

% disp('*** UPPER TERTILE ***')
% SID = BIDS_subjectfilter(toplevelBIDSdir,'maxSNR>14.5')
% aap = aas_processBIDS(aap,[],[],SID); 

% *************************************************************************

% pick single best session for each subject

boldfilter.fieldname = 'meanSNR';
boldfilter.op = 'M';

aap = aas_BIDS_boldfilter(aap, boldfilter);

% -------------------------------------------------------------------------
% module customization 
% -------------------------------------------------------------------------

mask_fname = 'HDDOT_brainmask.nii'; % mask created for this HDDOT array

% aamod_QA options:

aap = aas_renamestream(aap,'aamod_QA_00001','epi','dot'); 

% aamod_intersubject_correlation options:

aap = aas_renamestream(aap,'aamod_intersubject_correlation_00001','epi','dot');
aap.tasksettings.aamod_intersubject_correlation(1).explicit_mask_fname = mask_fname;
aap.tasksettings.aamod_intersubject_correlation(1).outlier_filter = 'none';

aap = aas_renamestream(aap,'aamod_intersubject_correlation_00002','epi','dot');
aap.tasksettings.aamod_intersubject_correlation(2).explicit_mask_fname = mask_fname;
aap.tasksettings.aamod_intersubject_correlation(2).outlier_filter = 'GVTD';
aap.tasksettings.aamod_intersubject_correlation(2).outlier_threshold = 5e-04;

% aamod_render options:

aap = aas_renamestream(aap,'aamod_render_00001','brainmaps','aamod_intersubject_correlation_00001.average_intersubject_correlation_map');
aap.tasksettings.aamod_render(1).renderer = 'neurodot';

aap = aas_renamestream(aap,'aamod_render_00002','brainmaps','aamod_intersubject_correlation_00001.average_intersubject_correlation_map');
aap.tasksettings.aamod_render(2).renderer = 'neurodot';

% -------------------------------------------------------------------------
% run
% -------------------------------------------------------------------------

aa_doprocessing(aap);
