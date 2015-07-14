function value = getElement(matrix, row, col)
    if (row~=0) & (col~=0)
        value = matrix(row, col); 
    else
        value = 0;
    end
return
