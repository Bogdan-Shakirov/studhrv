function [amplitude, time] = extractDataColumns(dataArray)
    % Извлечение данных из массива с проверкой различных форматов
    % Входные параметры:
    %   dataArray - числовой массив данных
    % Выходные параметры:
    %   amplitude - первый столбец или вектор амплитуды
    %   time - второй столбец или вектор времени
    
    % Проверка ориентации данных
    [nRows, nCols] = size(dataArray);
    
    % Если данные в строке, транспонируем
    if nRows == 1 && nCols > 1
        dataArray = dataArray';
        [nRows, nCols] = size(dataArray);
    end
    
    % Извлечение данных в зависимости от формата
    if nCols >= 2
        % Стандартный случай: первый столбец - амплитуда, второй - время
        amplitude = dataArray(:, 1);
        time = dataArray(:, 2);
    elseif nCols == 1 && nRows >= 2
        % Если только один столбец, разделяем на две части
        midPoint = floor(nRows/2);
        amplitude = dataArray(1:midPoint, 1);
        time = dataArray(midPoint+1:end, 1);
        
        % Если длины не совпадают, обрезаем до меньшей
        minLength = min(length(amplitude), length(time));
        amplitude = amplitude(1:minLength);
        time = time(1:minLength);
        
        % Нормализуем время, если оно не начинается с 0
        time = time - time(1);
    else
        error('Невозможно извлечь данные: неверный формат массива');
    end
end
