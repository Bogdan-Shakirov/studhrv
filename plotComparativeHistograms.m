function plotComparativeHistograms(app, ax, beforeData, afterData, binWidth)
    % Построение сравнительных гистограмм до и после нагрузки
    
    cla(ax);
    
    % Объединяем все RR-интервалы для определения общих пределов
    allRR = [];
    for i = 1:length(beforeData)
        if isfield(beforeData(i), 'hrvResults') && isfield(beforeData(i).hrvResults, 'RRintervals')
            allRR = [allRR; beforeData(i).hrvResults.RRintervals(:)];
        end
    end
    for i = 1:length(afterData)
        if isfield(afterData(i), 'hrvResults') && isfield(afterData(i).hrvResults, 'RRintervals')
            allRR = [allRR; afterData(i).hrvResults.RRintervals(:)];
        end
    end
    
    if isempty(allRR)
        return;
    end
    
    % Определяем общие пределы
    minRR = min(allRR);
    maxRR = max(allRR);
    edges = minRR:binWidth:maxRR;
    
    hold(ax, 'on');
    
    % Гистограмма до нагрузки (синий)
    beforeRR = [];
    for i = 1:length(beforeData)
        if isfield(beforeData(i), 'hrvResults') && isfield(beforeData(i).hrvResults, 'RRintervals')
            beforeRR = [beforeRR; beforeData(i).hrvResults.RRintervals(:)];
        end
    end
    
    if ~isempty(beforeRR)
        histogram(ax, beforeRR, edges, ...
            'FaceColor', 'blue', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
    end
    
    % Гистограмма после нагрузки (красный)
    afterRR = [];
    for i = 1:length(afterData)
        if isfield(afterData(i), 'hrvResults') && isfield(afterData(i).hrvResults, 'RRintervals')
            afterRR = [afterRR; afterData(i).hrvResults.RRintervals(:)];
        end
    end
    
    if ~isempty(afterRR)
        histogram(ax, afterRR, edges, ...
            'FaceColor', 'red', 'FaceAlpha', 0.5, 'EdgeColor', 'none');
    end
    
    % Настройка графика
    xlabel(ax, 'RR-интервалы (мс)');
    ylabel(ax, 'Частота');
    title(ax, 'Сравнительные гистограммы до и после нагрузки');
    legend(ax, {'До нагрузки', 'После нагрузки'}, 'Location', 'best');
    grid(ax, 'on');
    
    hold(ax, 'off');
end
