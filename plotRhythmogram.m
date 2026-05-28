function plotRhythmogram(ax, data, results, minPeakHeight)
    % Построение ритмограммы с отмеченными R-пиками
    
    cla(ax);
    
    plot(ax, data.time, data.amplitude, 'b-', 'LineWidth', 0.5);
    hold(ax, 'on');
    
    % Отметка R-пиков
    if isfield(results, 'peakLocations')
        plot(ax, data.time(results.peakLocations), results.peaks, 'r^', ...
            'MarkerSize', 8, 'MarkerFaceColor', 'r');
    end
    
    xlabel(ax, 'Время (с)');
    ylabel(ax, 'Амплитуда');
    title(ax, sprintf('Ритмограмма (minPeakHeight = %.2f)', minPeakHeight));
    grid(ax, 'on');
    legend(ax, {'Сигнал', 'R-пики'}, 'Location', 'best');
    hold(ax, 'off');
end
