function create_study(experiment_code, participant_code)
    % create_study creates the study design
    %
    % Usage: create_study(experiment_code, participant_code)
    %
    % Inputs:
    %    experiment_code - Code for the experiment (e.g., 'rsvp_trans_e2')
    %    participant_code - Code for the participant (e.g., 'BU')

    % Assume the following global variables are already defined:
    % STUDY, ALLEEG, EEG
    global STUDY ALLEEG EEG;
    
    % Initialize EEGLAB
    eeglab;

    % Get the folder path containing the experiment data
    folderPath = ['data_eeglab\' experiment_code]; % Replace this with your folder path

    % Get the list of all .set files in the specified folder
    files = dir(fullfile(folderPath, '*.set'));

    % Sort the file names
    fileNames = {files.name};
    fileNames = sort(fileNames);

    % Initialize a cell to store the commands
    commands = {};

    % Initialize sets of conditions and participants
    conditions = {};
    participants = {};

    % Loop through the entire list of files
    for i = 1:length(fileNames)
        currentFile = fileNames{i};

        % Assign value to 'stimulus_type' based on the file name content
        if contains(currentFile, 'attend', 'IgnoreCase', true)
            stimulus_type = 'attend';
        elseif contains(currentFile, 'ignore', 'IgnoreCase', true)
            stimulus_type = 'ignore';
        elseif contains(currentFile, 'difference', 'IgnoreCase', true)
            stimulus_type = 'difference';
        else
            stimulus_type = 'unknown'; % Default value if no condition matches
        end

        % Assign value to 'condition' based on the file name content
        if contains(currentFile, '001', 'IgnoreCase', true)
            condition = 'C1';
        elseif contains(currentFile, '002', 'IgnoreCase', true)
            condition = 'C2';
        elseif contains(currentFile, '003', 'IgnoreCase', true)
            condition = 'C3';
        elseif contains(currentFile, '004', 'IgnoreCase', true)
            condition = 'C4';
        else
            condition = 'unknown'; % Default value if no condition matches
        end

        % Add the condition to the list if not already included
        if ~ismember(condition, conditions)
            conditions{end+1} = condition;
        end

        % Update the value of 'participant_code' based on the file name
        tuIndex = regexp(currentFile, [participant_code '\d{2}'], 'match');
        if ~isempty(tuIndex)
            participant_id = tuIndex{1};
        else
            participant_id = 'unknown'; % Default value if no participant code found
        end

        % Add the participant to the list if not already included
        if ~ismember(participant_id, participants)
            participants{end+1} = participant_id;
        end

        % Accumulate the commands in the cell
        commands{end+1} = {'index', i, 'load', fullfile(folderPath, currentFile)};
        commands{end+1} = {'index', i, 'subject', participant_id};
        commands{end+1} = {'index', i, 'condition', condition};
        commands{end+1} = {'index', i, 'group', stimulus_type};
    end

    % Call std_editset once with all accumulated commands
    [STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'name', experiment_code, 'commands', commands, 'updatedat', 'off');

    % Update the current dataset and check the study
    CURRENTSTUDY = 1; 
    EEG = ALLEEG;
    CURRENTSET = [1:length(EEG)];
    [STUDY, ALLEEG] = std_checkset(STUDY, ALLEEG);

    % Create and select study designs based on the detected conditions and participants
    STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name', 'target', 'delfiles', 'off', 'defaultdesign', 'off', 'variable1', 'condition', 'values1', conditions, 'vartype1', 'categorical', 'variable2', 'group', 'values2', {'attend'}, 'vartype2', 'categorical', 'subjselect', participants);
    STUDY = std_makedesign(STUDY, ALLEEG, 2, 'name', 'non-target', 'delfiles', 'off', 'defaultdesign', 'off', 'variable1', 'condition', 'values1', conditions, 'vartype1', 'categorical', 'variable2', 'group', 'values2', {'ignore'}, 'vartype2', 'categorical', 'subjselect', participants);
    STUDY = std_makedesign(STUDY, ALLEEG, 3, 'name', 'difference', 'delfiles', 'off', 'defaultdesign', 'off', 'variable1', 'condition', 'values1', conditions, 'vartype1', 'categorical', 'variable2', 'group', 'values2', {'difference'}, 'vartype2', 'categorical', 'subjselect', participants);

    STUDY = std_selectdesign(STUDY, ALLEEG, 1);

    % Precompute the study
    [STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, {}, 'savetrials', 'on', 'interp', 'on', 'recompute', 'on', 'erp', 'on', 'erpparams', {'rmbase', [-200 0]});
    
    % Save the study
    [STUDY, EEG] = pop_savestudy( STUDY, EEG, 'filename', [experiment_code, '.study'],'filepath',[cd, '\studies_eeglab\']);

    % Redraw EEGLAB
    eeglab redraw;
end