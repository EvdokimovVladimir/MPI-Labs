program matrixTranspose

    implicit none
    include "mpif.h"

    integer :: rows, columns, i, j, status(MPI_STATUS_SIZE)
    real, allocatable :: matrix(:, :)
    integer :: err, nproc, myID

    ! инициализация MPI
    call MPI_INIT(err)
    call MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, err)
    call MPI_COMM_RANK(MPI_COMM_WORLD, myID, err)

    if (nproc /= 4 .AND. myID == 0) then
        write(*, *) "Программа работает только с 4 потоками"
        call MPI_ABORT(MPI_COMM_WORLD, err)
    end if
    
    ! чтение матрицы
    if(myID == 0) then
    
	    open(0, file='A')
        read(0, *) rows
	    read(0, *) columns

        allocate(matrix(rows, columns))

	    do i = 1, rows
	        read(0, *) (matrix(i, j), j = 1, columns)
        end do

	    write(*, *) "Исходная матрица"
        call printMatrix(matrix, rows, columns)

        ! если размеры матрицы не чётные будет лажа)
        rows = rows / 2
        columns = columns / 2
    endif

    ! рассылка размерности матрицы
    call MPI_BCAST(rows,    1, MPI_INTEGER, 0, MPI_COMM_WORLD, err)
    call MPI_BCAST(columns, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, err)
    
    if(myID == 0) then
        ! рассылка фрагментов матрицы
        call MPI_SEND(matrix(1:rows,        columns+1:2*columns), rows*columns, MPI_REAL, 1, 0, MPI_COMM_WORLD, err)
        call MPI_SEND(matrix(rows+1:2*rows, 1:columns),           rows*columns, MPI_REAL, 2, 0, MPI_COMM_WORLD, err)
        call MPI_SEND(matrix(rows+1:2*rows, columns+1:2*columns), rows*columns, MPI_REAL, 3, 0, MPI_COMM_WORLD, err)
	
        ! транспонирование фрагмента матрицы
        call transposeMatrix(matrix(1:rows, 1:columns), rows, columns)

    else
        allocate(matrix(rows,columns))

        ! приём фрагмента матрицы, транспонирование и отправка обратно
        call MPI_RECV(matrix, rows*columns, MPI_REAL, 0, 0, MPI_COMM_WORLD, status, err)
        call transposeMatrix(matrix, rows, columns)
        call MPI_SEND(matrix, rows*columns, MPI_REAL, 0, 0, MPI_COMM_WORLD, err)

        deallocate(matrix)
    endif

    if(myID == 0) then

        ! приём и сборка транспонированной матрицы
        call MPI_RECV(matrix(rows+1:2*rows, 1:columns          ), rows*columns, MPI_REAL, 1, 0, MPI_COMM_WORLD, status, err)
        call MPI_RECV(matrix(1:rows,        columns+1:2*columns), rows*columns, MPI_REAL, 2, 0, MPI_COMM_WORLD, status, err)
        call MPI_RECV(matrix(rows+1:2*rows, columns+1:2*columns), rows*columns, MPI_REAL, 3, 0, MPI_COMM_WORLD, status, err)
        
        write(*, *) "Транспонированная матрица"
        call printMatrix(matrix, 2*rows, 2*columns)

        deallocate(matrix)  
    endif

    call MPI_FINALIZE(err)
    
end program matrixTranspose



subroutine printMatrix(matr, rows, columns)

    implicit none
    integer, intent(in) :: columns, rows
    real, intent(in) :: matr(rows, columns)

    integer :: i, j

    do i = 1, rows
	    write(*,'(100f6.2)')(matr(i, j), j = 1, columns)
    end do

end subroutine printMatrix


subroutine transposeMatrix(matr, rows, columns)

    implicit none
    integer, intent(in) :: rows, columns
    real, intent(inout) :: matr(rows, columns)

    integer :: i, j
    real :: tmp

    do i = 1, rows
        do j = (i + 1), columns
            tmp = matr(i, j)
            matr(i, j) = matr(j, i)
            matr(j, i) = tmp
        end do
    end do

end subroutine transposeMatrix

