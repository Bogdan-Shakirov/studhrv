% calculateHRV.m
function results = calculateHRV(data, minPeakHeight, binWidth)
    % Расчёт параметров вариабельности сердечного ритма с анализом аритмии
    
    results = struct();
    
    try
        % Извлечение данных
        amplitude = data.amplitude;
        time = data.time;
        
        % Проверка ориентации данных
        if isrow(amplitude)
            amplitude = amplitude';
        end
        if isrow(time)
            time = time';
        end
        
        % Детектирование R-пиков
        [peaks, locations] = findpeaks(amplitude, 'MinPeakHeight', minPeakHeight);
        
        % Проверка, что найдено достаточно пиков
        if length(locations) < 2
            error('Обнаружено менее 2 R-пиков. Уменьшите минимальную высоту пика.');
        end
        
        % Расчёт времени между пиками
        timeBetweenPeaks = diff(time(locations));
        
        % Определение единиц измерения времени
        % Если среднее время между пиками меньше 5, считаем что время в секундах и переводим в миллисекунды
        meanTimeBetweenPeaks = mean(timeBetweenPeaks);
        if meanTimeBetweenPeaks < 5
            % Время в секундах, переводим в миллисекунды
            RRintervals = timeBetweenPeaks * 1000;
        else
            % Время уже в миллисекундах
            RRintervals = timeBetweenPeaks;
        end
        
        % Сохранение RR-интервалов
        results.RRintervals = RRintervals;
        results.peaks = peaks;
        results.peakLocations = locations;
        
        % Базовые параметры ВСР
        results.meanRR = mean(RRintervals);
        results.SDNN = std(RRintervals);
        
        % RMSSD - квадратный корень из среднего квадрата разностей
        diffRR = diff(RRintervals);
        results.RMSSD = sqrt(mean(diffRR.^2));
        
        % NN50 и pNN50
        diffRR = abs(diffRR);
        results.NN50 = sum(diffRR > 50);
        if length(RRintervals) > 1
            results.pNN50 = (results.NN50 / (length(RRintervals) - 1)) * 100;
        else
            results.pNN50 = 0;
        end
        
        % Расчёт TINN через гистограмму
        [counts, edges] = histcounts(RRintervals, 'BinWidth', binWidth);
        binCenters = (edges(1:end-1) + edges(2:end)) / 2;
        
        % Нахождение моды (бина с максимальной частотой)
        [maxCount, maxIdx] = max(counts);
        modalBin = binCenters(maxIdx);
        
        % Порог для TINN (5% от максимальной высоты)
        threshold = maxCount * 0.05;
        
        % Поиск левой границы
        leftIdx = maxIdx;
        while leftIdx > 1 && counts(leftIdx) > threshold
            leftIdx = leftIdx - 1;
        end
        leftBound = binCenters(max(1, leftIdx));
        
        % Поиск правой границы
        rightIdx = maxIdx;
        while rightIdx < length(counts) && counts(rightIdx) > threshold
            rightIdx = rightIdx + 1;
        end
        rightBound = binCenters(min(length(counts), rightIdx));
        
        % TINN - ширина основания треугольника
        results.TINN = rightBound - leftBound;
        
        % Спектральный анализ
        [LF, HF, LFHFratio] = spectralAnalysis(RRintervals);
        results.LF = LF;
        results.HF = HF;
        results.LFHFratio = LFHFratio;
        
        % Анализ аритмии
        results.arrhythmiaAnalysis = analyzeArrhythmia(RRintervals, binWidth);
        
        % Дополнительные параметры для диагностики
        results.CV = std(RRintervals) / mean(RRintervals) * 100; % Коэффициент вариации
        results.skewnessRR = skewness(RRintervals);
        results.kurtosisRR = kurtosis(RRintervals);
        
        % Определение типа ритма на основе анализа
        if results.arrhythmiaAnalysis.nPeaks >= 2
            if results.CV > 15
                results.rhythmType = 'Выраженная синусовая аритмия';
            elseif results.CV > 5
                results.rhythmType = 'Умеренная синусовая аритмия';
            else
                results.rhythmType = 'Возможная экстрасистолия';
            end
        else
            results.rhythmType = 'Регулярный синусовый ритм';
        end
        
    catch ME
        error('Ошибка при расчёте параметров ВСР: %s', ME.message);
    end
end

function TINN_val = calculateSimpleTINN(data, minPeakHeight, binWidth)
    % Простой расчёт TINN для пакетного анализа
    amplitude = data.amplitude;
    time = data.time;
    
    % Проверка ориентации
    if isrow(amplitude), amplitude = amplitude'; end
    if isrow(time), time = time'; end
    
    % Детекция пиков
    [~, locations] = findpeaks(amplitude, 'MinPeakHeight', minPeakHeight);
    
    if length(locations) < 2
        TINN_val = NaN;
        return;
    end
    
    % Расчёт RR-интервалов
    RRintervals = diff(time(locations)) * 1000; % в миллисекундах
    
    % Простая гистограмма
    [counts, edges] = histcounts(RRintervals, 'BinWidth', binWidth);
    binCenters = (edges(1:end-1) + edges(2:end)) / 2;
    
    % Находим максимум
    [maxCount, maxIdx] = max(counts);
    modalBin = binCenters(maxIdx);
    
    % Простой расчёт TINN
    threshold = maxCount * 0.05;
    
    % Левая граница
    leftIdx = maxIdx;
    while leftIdx > 1 && counts(leftIdx) > threshold
        leftIdx = leftIdx - 1;
    end
    leftBound = binCenters(max(1, leftIdx));
    
    % Правая граница
    rightIdx = maxIdx;
    while rightIdx < length(counts) && counts(rightIdx) > threshold
        rightIdx = rightIdx + 1;
    end
    rightBound = binCenters(min(length(counts), rightIdx));
    
    TINN_val = rightBound - leftBound;
end

function [LF, HF, LFHFratio] = spectralAnalysis(RRintervals)
    % Спектральный анализ RR-интервалов
    
    % Если недостаточно данных, возвращаем нули
    if length(RRintervals) < 10
        LF = 0;
        HF = 0;
        LFHFratio = 0;
        return;
    end
    
    try
        % Детрендирование
        RR_detrended = detrend(RRintervals);
        
        % Параметры спектрального анализа
        N = length(RR_detrended);
        
        % Применение окна Ханна
        window = hann(N);
        RR_windowed = RR_detrended .* window;
        
        % Быстрое преобразование Фурье
        Y = fft(RR_windowed);
        
        % Односторонний спектр
        P2 = abs(Y/N);
        P1 = P2(1:floor(N/2)+1);
        P1(2:end-1) = 2*P1(2:end-1);
        
        % Частотная ось
        fs = 4; % Частота дискретизации 4 Гц для RR-интервалов
        f = fs*(0:(N/2))/N;
        
        % Индексы для LF (0.04-0.15 Гц) и HF (0.15-0.4 Гц)
        LF_idx = f >= 0.04 & f <= 0.15;
        HF_idx = f >= 0.15 & f <= 0.4;
        
        % Интеграция мощностей
        if any(LF_idx)
            LF = trapz(f(LF_idx), P1(LF_idx));
        else
            LF = 0;
        end
        
        if any(HF_idx)
            HF = trapz(f(HF_idx), P1(HF_idx));
        else
            HF = 0;
        end
        
        % Отношение LF/HF
        if HF > 0
            LFHFratio = LF / HF;
        else
            LFHFratio = 0;
        end
        
    catch
        % В случае ошибки возвращаем нули
        LF = 0;
        HF = 0;
        LFHFratio = 0;
    end
end

function arrhythmiaResults = analyzeArrhythmia(RRintervals, binWidth)
    % Детальный анализ аритмии по распределению RR-интервалов
    % Входные параметры:
    %   RRintervals - массив RR-интервалов (мс)
    %   binWidth - ширина бина гистограммы
    % Выходные параметры:
    %   arrhythmiaResults - структура с результатами анализа
    
    arrhythmiaResults = struct();
    
    % Построение гистограммы
    [counts, edges] = histcounts(RRintervals, 'BinWidth', binWidth);
    binCenters = (edges(1:end-1) + edges(2:end)) / 2;
    
    % Поиск всех значимых пиков
    minPeakHeight = max(counts) * 0.05; % 5% от максимальной высоты
    minPeakProminence = max(counts) * 0.1; % 10% от максимальной высоты
    
    [peaks, peakLocs, peakWidths, peakProminences] = findpeaks(counts, ...
        'MinPeakHeight', minPeakHeight, ...
        'MinPeakProminence', minPeakProminence);
    
    % Основные метрики
    arrhythmiaResults.nPeaks = length(peaks);
    arrhythmiaResults.peakHeights = peaks;
    arrhythmiaResults.peakPositions = binCenters(peakLocs);
    arrhythmiaResults.peakWidths = peakWidths;
    arrhythmiaResults.peakProminences = peakProminences;
    
    % Классификация распределения
    if arrhythmiaResults.nPeaks == 1
        arrhythmiaResults.distributionType = 'Унимодальное (норма)';
        arrhythmiaResults.arrhythmiaSeverity = 'Нет аритмии';
        arrhythmiaResults.severityLevel = 0;
    elseif arrhythmiaResults.nPeaks == 2
        arrhythmiaResults.distributionType = 'Бимодальное (лёгкая аритмия)';
        arrhythmiaResults.arrhythmiaSeverity = 'Лёгкая аритмия';
        arrhythmiaResults.severityLevel = 1;
    else
        arrhythmiaResults.distributionType = 'Мультимодальное (выраженная аритмия)';
        arrhythmiaResults.arrhythmiaSeverity = 'Выраженная аритмия';
        arrhythmiaResults.severityLevel = 2;
    end
    
    % Расчёт индексов аритмии
    if arrhythmiaResults.nPeaks >= 2
        % Индекс аритмии 1: отношение высоты второго пика к первому
        [sortedPeaks, sortIdx] = sort(peaks, 'descend');
        arrhythmiaResults.arrhythmiaIndex1 = sortedPeaks(2) / sortedPeaks(1);
        
        % Индекс аритмии 2: сумма относительных высот всех пиков кроме основного
        arrhythmiaResults.arrhythmiaIndex2 = sum(sortedPeaks(2:end)) / sortedPeaks(1);
        
        % Расстояние между пиками (в мс и в % от среднего RR)
        meanRR = mean(RRintervals);
        peakDistances = diff(sort(binCenters(peakLocs)));
        arrhythmiaResults.meanPeakDistance = mean(peakDistances);
        arrhythmiaResults.relativePeakDistance = arrhythmiaResults.meanPeakDistance / meanRR * 100;
    else
        arrhythmiaResults.arrhythmiaIndex1 = 0;
        arrhythmiaResults.arrhythmiaIndex2 = 0;
        arrhythmiaResults.meanPeakDistance = 0;
        arrhythmiaResults.relativePeakDistance = 0;
    end
    
    % Статистика RR-интервалов для дополнительной диагностики
    arrhythmiaResults.CV = std(RRintervals) / mean(RRintervals) * 100; % Коэффициент вариации
    arrhythmiaResults.skewness = skewness(RRintervals); % Асимметрия
    arrhythmiaResults.kurtosis = kurtosis(RRintervals); % Эксцесс
    
    % Интерпретация результатов
    if arrhythmiaResults.nPeaks >= 2 && arrhythmiaResults.CV > 10
        arrhythmiaResults.interpretation = 'Выраженная дыхательная аритмия или синусовая аритмия';
    elseif arrhythmiaResults.nPeaks >= 2 && arrhythmiaResults.CV <= 10
        arrhythmiaResults.interpretation = 'Возможна экстрасистолия или другие нарушения ритма';
    else
        arrhythmiaResults.interpretation = 'Регулярный синусовый ритм';
    end
end
