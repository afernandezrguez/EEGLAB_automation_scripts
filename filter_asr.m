% ------------------------------------------------


function filter_asr(experiment_code)

input_folder = ['data_bci2000\', experiment_code];
output_folder = ['data_bci2000\', experiment_code,'_asr'];

if (exist(input_folder, 'dir') == 0)
    disp(['No existe la carpeta "', input_folder, '" desde la que cargar los archivos de entrada. Cancelando ejecución.'])
    return;
end

tempList = dir(input_folder);
if(length(tempList) <= 2)
    disp(['No hay carpetas de sujetos en "', input_folder, '". Cancelando ejecución.'])
    return;
end

if (exist(output_folder, 'dir') == 0)
    mkdir(output_folder);
end

% LLamada a loadBCI2000
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

for i_subject = 3:length(tempList)
    tempList2 = dir([input_folder, '/', tempList(i_subject).name]);
    if(length(tempList2) <= 2)
        disp(['No hay carpetas de condiciones en "', input_folder, '/', tempList(i_subject).name, '". Cancelando ejecución.'])
        return;
    end
    
    for i_condition = 3:length(tempList2)
        tempList3 = dir([input_folder, '/', tempList(i_subject).name, '/', tempList2(i_condition).name, '/*.dat']);
        if(length(tempList3) < 1)
            disp(['No hay archivos .dat en "', input_folder, '/', tempList(i_subject).name, '/', tempList2(i_condition).name, '". Cancelando ejecución.'])
        else
            temp_cellArrayOfStrings = {};
            index_cellArray = 1;
            
            for i_file = 1:length(tempList3)
                temp_cellArrayOfStrings{index_cellArray} = [input_folder, '/', tempList(i_subject).name, '/', tempList2(i_condition).name, '/', tempList3(i_file).name];
                output_dir = [output_folder, '/', tempList(i_subject).name, '/', tempList2(i_condition).name];
                
                if (exist(output_dir, 'dir') == 0)
                    mkdir(output_dir);
                end
                
                EEG = pop_loadBCI2000_automatedScript(temp_cellArrayOfStrings{index_cellArray});
                
                clean = pop_clean_rawdata(EEG, 'FlatlineCriterion', 'off', 'ChannelCriterion', 'off', 'LineNoiseCriterion', 'off', 'Highpass', 'off', 'BurstCriterion', 20, 'WindowCriterion', 'off', 'BurstRejection', 'off', 'Distance', 'Riemannian');
                
                [signal, states, parameters] = load_bcidat(temp_cellArrayOfStrings{index_cellArray});
                
                [~, name, ~] = fileparts(tempList3(i_file).name);  % Obtener el nombre del archivo sin la extensión
                newName = [output_dir, '/', name, '_asr.dat'];  % Crear el nuevo nombre de archivo
                
                signal = clean.data';
                
                save_bcidat(newName, signal, states, parameters);
                
                index_cellArray = index_cellArray + 1;
            end
        end
    end
end
end