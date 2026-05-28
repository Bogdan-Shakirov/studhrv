function [dataStruct, isValid, errorMessage] = validateData(loadedData)
    % Валидация входных данных из .mat файла
    
    dataStruct = struct();
    isValid = true;
    errorMessage = '';
    
    try
        % Получение списка полей из загруженной структуры
        fieldNames = fieldnames(loadedData);
        
        if isempty(fieldNames)
            isValid = false;
            errorMessage = 'Файл не содержит данных';
            return;
        end
        
        % Извлечение первого поля (предполагаем, что это массив данных)
        firstField = fieldNames{1};
        dataArray = loadedData.(firstField);
        
        % Проверка, что это числовой массив
        if ~isnumeric(dataArray)
            isValid = false;
            errorMessage = 'Данные должны быть числовыми';
            return;
        end
        
        % Проверка размерности
        if ndims(dataArray) > 2
            isValid = false;
            errorMessage = 'Данные должны быть двумерным массивом';
            return;
        end
        
        % Проверка количества столбцов
        if size(dataArray, 2) < 2
            isValid = false;
            errorMessage = 'Данные должны содержать как минимум 2 столбца (амплитуда и время)';
            return;
        end
        
        % Извлечение первого и второго столбцов
        amplitude = dataArray(:, 1);
        time = dataArray(:, 2);
        
        % Проверка на пустые данные
        if isempty(amplitude) || isempty(time)
            isValid = false;
            errorMessage = 'Столбцы данных не должны быть пустыми';
            return;
        end
        
        % Проверка одинаковой длины
        if length(amplitude) ~= length(time)
            isValid = false;
            errorMessage = 'Столбцы амплитуды и времени должны иметь одинаковую длину';
            return;
        end
        
        % Проверка на NaN и Inf
        if any(isnan(amplitude)) || any(isinf(amplitude)) || ...
           any(isnan(time)) || any(isinf(time))
            isValid = false;
            errorMessage = 'Данные содержат недопустимые значения (NaN или Inf)';
            return;
        end
        
        % Создание структуры с полями amplitude и time
        dataStruct.amplitude = amplitude;
        dataStruct.time = time;
        dataStruct.originalData = dataArray;
        
    catch ME
        isValid = false;
        errorMessage = sprintf('Ошибка при валидации данных: %s', ME.message);
    end
end
