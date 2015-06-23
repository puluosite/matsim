function matrix = addElement(matrix, row, col, value)
%     if (row~=0) & (col~=0)
%         matrix(row, col) = matrix(row, col) + value; 
%     end
try
   matrix(row, col) = matrix(row, col) + value; 
end
return
