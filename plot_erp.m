% To use this script, it is required to modify the eeglab's function '\functions\sigprocfunc\plotcurve.m' as follow.
%   Line 304 aprox:
% 	%plot(times, times, 'w'); 
% 	plot(times, times, 'Color', [1 1 1 0.5]);
%   Line 315 aprox:
%   %xlabel(myxlabel);
% 	xlabel('');

function plot_erp(analysis)
    % plot_erp performs statistical analysis of ERP data and displays corresponding plots
    % with statistical significances and standard error.
    %
    % Usage: plot_erp(analysis)
    %
    % Input:
    %    analysis - 'target', 'non-target', or 'difference'

    % Assume the following global variables are already defined:
    % STUDY, ALLEEG, EEG
    global STUDY ALLEEG EEG;

    % Map the analyses to their corresponding numerical values
    switch analysis
        case {'target', 1}
            design = 1;
        case {'non-target', 2}
            design = 2;
        case {'difference', 3}
            design = 3;
        otherwise
            error('Invalid analysis. Use "target", "non-target", or "difference" (or 1, 2, 3, respectively).');
    end

    % Define the number of rows and columns for the large figure
    rows = 2;
    cols = 4;

    % Create a figure for the large plot
    bigFigure = figure;

    % Loop to create 8 individual plots and save them
    for i = 1:8
        % Set the STUDY parameters and get the ERP data for each plot
        STUDY = pop_statparams(STUDY, 'effect', 'marginal', 'condstats', 'on', 'groupstats', 'on', 'method', 'perm', 'mcorrect', 'fdr', 'alpha', 0.05);
        STUDY = pop_erpparams(STUDY, 'plotconditions', 'together', 'timerange', [-200 800]);
        
        % Assuming you have at least 8 channels, adjust the indexing if necessary
        channel_label = EEG(1).chanlocs(i).labels;
        
        [STUDY, erpdata, erptimes, pgroup, pcond, pinter] = std_erpplot(STUDY, ALLEEG, 'channels', {{channel_label}}, 'design', design, 'plotconditions', 'together', 'plotstderr', 'on', 'noplot', 'on');
        
        % Create a subplot in the large figure
        subplot(rows, cols, i, 'Parent', bigFigure);
        
        % Plot the ERP data in the subplot
        std_plotcurve(erptimes, erpdata, ...
            'condstats', pcond, ...
            'threshold', 0.05, ...
            'plotgroups', 'apart', ...
            'plotconditions', 'together', ...
            'plotstderr', 'on', ...
            'ylim', [-10 10], ...
            'legend', 'off', ...
            'figure', 'off');
        
        std_plotcurve(erptimes, erpdata, ...
            'plotstderr', 'on', ...
            'ylim', [-10 10], ...
            'figure', 'off');

        % Customize the subplot
        title(channel_label);
        set(gca, 'xtick', []);
        
        % Remove x and y axis titles
        if i == 5
            xlabel('Time (ms)', 'Position', [300 -14 0]);     
            ylabel('Amplitude (\muV)');
        else
            xlabel('');
            ylabel('');
        end
    end

    % Adjust the overall figure
    set(bigFigure, 'Name', 'Overall ERP Plots', 'NumberTitle', 'off');
end
