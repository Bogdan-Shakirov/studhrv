function plotSpectrum(ax, data)
    % Спектральный анализ и визуализация
    
    cla(ax);
    
    plot(ax, data.time, data.amplitude, 'g-', 'LineWidth', 0.5);
    
    xlabel(ax, 'Время (с)');
    ylabel(ax, 'Амплитуда');
    title(ax, 'Спектральный анализ (осциллограмма)');
    grid(ax, 'on');
end
