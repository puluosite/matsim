function [B] = matrixBlockOperation(A, N, operation)

nBlockRows = size(A,1)/N;
nBlockCols = size(A,2)/N;
for blockRow = 1:nBlockRows
    rows  = (blockRow-1)*N+1:blockRow*N;
    rowsB = (nBlockRows-blockRow)*N+1:(nBlockRows-blockRow+1)*N;
    for blockCol = 1:nBlockCols
        cols  = (blockCol-1)*N+1:blockCol*N;
        colsB = (nBlockCols-blockCol)*N+1:(nBlockCols-blockCol+1)*N;
        switch operation
            case 'transpose_main'
                B(rows, cols) = A(cols, rows);
            case 'transpose_minor'
                B(rows, cols) = A(colsB, rowsB);
            case 'transpose_both'
                B(rows, cols) = A(rowsB, colsB);
            case 'flip_ud'
                B(rows, cols) = A(rowsB, cols);
            case 'flip_lr'
                B(rows, cols) = A(rowsB, cols);
            case 'cyclic_shift_main'
                rowsS = rot(rows, -1, N*nBlockRows);
                colsS = rot(cols, -1, N*nBlockRows);
                B(rows, cols) = A(rowsS, colsS);
        end
    end
end

return
