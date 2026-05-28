function result = interpretTestResultSimple(p)
    % Простая интерпретация результата теста
    if isnan(p)
        result = 'Ошибка в расчёте';
    elseif p < 0.05
        result = 'Есть статистически значимые различия';
    else
        result = 'Нет статистически значимых различий';
    end
end
