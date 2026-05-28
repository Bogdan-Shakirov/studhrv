function plotTINNHistogram(ax, results, binWidth)
    % Построение гистограммы TINN с треугольной интерполяцией
    
    cla(ax);
    
    if ~isfield(results, 'RRintervals') || isempty(results.RRintervals)
        return;
    end
    
    RR = results.RRintervals;
    
    histogram(ax, RR, 'BinWidth', binWidth, ...
        'FaceColor', 'blue', 'EdgeColor', 'black', 'FaceAlpha', 0.7);
    
    hold(ax, 'on');
    
    [counts, edges] = histcounts(RR, 'BinWidth', binWidth);
    binCenters = (edges(1:end-1) + edges(2:end)) / 2;
    
    [maxCount, maxIdx] = max(counts);
    modalBin = binCenters(maxIdx);
    
    TINN_value = results.TINN;
    leftBound = modalBin - TINN_value/2;
    rightBound = modalBin + TINN_value/2;
    
    x_triangle = [leftBound, modalBin, rightBound];
    y_triangle = [0, maxCount, 0];
    
    patch(ax, x_triangle, y_triangle, 'r', 'FaceAlpha', 0.3, 'EdgeColor', 'red', 'LineWidth', 2);
    
    text(ax, modalBin, maxCount/2, sprintf('TINN = %.1f мс', TINN_value), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontSize', 10, 'FontWeight', 'bold', 'Color', 'red');
    
    plot(ax, [modalBin, modalBin], [0, maxCount], 'r--', 'LineWidth', 1.5);
    
    hold(ax, 'off');
    
    xlabel(ax, 'RR-интервалы (мс)');
    ylabel(ax, 'Частота');
    title(ax, sprintf('Гистограмма TINN (binWidth = %d мс)', binWidth));
    grid(ax, 'on');
end
