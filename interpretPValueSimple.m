function interpretation = interpretPValueSimple(p)
    % Простая интерпретация p-value
    if isnan(p)
        interpretation = 'Невозможно вычислить';
    elseif p < 0.001
        interpretation = 'p < 0.001 (***)';
    elseif p < 0.01
        interpretation = 'p < 0.01 (**)';
    elseif p < 0.05
        interpretation = 'p < 0.05 (*)';
    else
        interpretation = 'p > 0.05 (не значимо)';
    end
end
