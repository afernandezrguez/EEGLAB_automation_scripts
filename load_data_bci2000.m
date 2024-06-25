% Este script es el antiguo 'EEGLAB_loadDAT_script_fullAutomated_dif.m'.

% Hay que pegar en la carpeta del plugin "BCI2000import0.36" el archivo "pop_loadBCI2000_automatedScript.m"

% Automatización total: recorramos dos niveles de subcarpetas dentro de
% "data_IN_DATscript" (sujeto y condición), cargando TODOS los archivos
% .dat existentes

% ------------------------------------------------
clear all;

if (exist('data_IN_DATscript', 'dir') == 0 )
    disp('No existe la carpeta data_IN_DATscript desde la que cargar los archivos de entrada. Cancelando ejecución.')
    return;
end

tempList = dir('data_IN_DATscript');
if (length(tempList) <= 2)
    disp('No hay carpetas de sujetos en data_IN_DATscript. Cancelando ejecución.')
    return;
end

for i_subject = 3:length(tempList)    
    tempList2 = dir(['data_IN_DATscript/' tempList( i_subject ).name]);  
    if (length(tempList2) <= 2)
        disp(['No hay carpetas de condiciones en data_IN_DATscript/' tempList( i_subject ).name '. Cancelando ejecución.'])
        return;
    end
    
    for i_condition = 3:length(tempList2)
        tempList3 = dir(['data_IN_DATscript/' tempList( i_subject ).name '/' tempList2( i_condition ).name '/*.dat'] );  
        if (length(tempList3) < 1)
            disp(['No hay archivos .dat en data_IN_DATscript/' tempList( i_subject ).name '/' tempList2( i_condition ).name '. Cancelando ejecución.'])
            return;
        end
        
        temp_cellArrayOfStrings = {};
        index_cellArray = 1;

        for i_file = 1:length(tempList3)
            temp_cellArrayOfStrings(index_cellArray) = {['data_IN_DATscript/' tempList( i_subject ).name '/' tempList2( i_condition ).name '/' tempList3( i_file ).name]};
            index_cellArray = index_cellArray + 1;
        end
        
        % LLamada a loadBCI2000
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        EEG = pop_loadBCI2000_automatedScript(temp_cellArrayOfStrings);
        indices = strfind(EEG.loadedfilePath,'/');
        newFileName = extractBetween( EEG.loadedfilePath, indices( length(indices)-2 )+1, indices( length(indices) )-1 );
        newFileName(1) = strrep(newFileName(1),'/','_' );

        if (exist('data_OUT_DATscript', 'dir') == 0 )
            mkdir('data_OUT_DATscript');
        end

        newFileName(1) = {['data_OUT_DATscript/' char(newFileName(1))]};

        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off'); 

        EEG = pop_chanedit(EEG, 'lookup','plugins\\dipfit5.4\\standard_BESA\\standard-10-5-cap385.elp');
        
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        
        EEG = eeg_checkset( EEG );
        EEG = pop_epoch( EEG, {  'StimulusBegin'  }, [-0.5         1], 'newname', 'Imported BCI2000 data set epochs', 'epochinfo', 'yes');

        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
        EEG = eeg_checkset( EEG );
        EEG = pop_rmbase( EEG, [-200    0]);
        [ALLEEG EEG CURRENTSET_todos] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 
        EEG = eeg_checkset( EEG );
        EEG = pop_selectevent( EEG, 'latency','0<=0','type',{'StimulusType'},'deleteevents','off','deleteepochs','on','invertepochs','off');
        [ALLEEG EEG CURRENTSET_atendidos] = pop_newset(ALLEEG, EEG, CURRENTSET_todos,'savenew',[char(newFileName) '_attend'],'gui','off'); 
        [ALLEEG EEG CURRENTSET_diferencia] = pop_newset(ALLEEG, EEG, CURRENTSET_todos,'gui','off'); 
        
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'retrieve',CURRENTSET_todos,'study',0); 
        EEG = eeg_checkset( EEG );
        EEG = pop_selectevent( EEG, 'latency','0<=0','type',{'StimulusType'},'deleteevents','off','deleteepochs','on','invertepochs','on');
        [ALLEEG EEG CURRENTSET_ignorados] = pop_newset(ALLEEG, EEG, CURRENTSET_todos,'savenew',[char(newFileName) '_ignore'],'gui','off'); 
        
        dataSetSize = size(ALLEEG(CURRENTSET_atendidos).data);
        for channel = 1:dataSetSize(1);
            for time = 1:dataSetSize(2);
                for stimulus = 1:dataSetSize(3);     % CUIDADO, el número de estímulos difiere entre condiciones, hay que mirar el tamaño del dataset de los target
                    ALLEEG(CURRENTSET_diferencia).data(channel,time,stimulus) = ALLEEG(CURRENTSET_atendidos).data(channel,time,stimulus) - mean(ALLEEG(CURRENTSET_ignorados).data(channel,time,:));
                end
            end
        end
        
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET_diferencia,'saveold',[char(newFileName) '_difference'],'gui','off'); 
        
        close;
    end
end



