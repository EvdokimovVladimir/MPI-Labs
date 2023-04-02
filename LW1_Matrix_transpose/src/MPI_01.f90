program matrixTranspose

    use mpi
    implicit none

    integer :: rows, columns, i, j, status(MPI_STATUS_SIZE)
    real, allocatable :: matrix(:, :)
    integer :: err, nproc, myID

    ! MPI initialization
    call MPI_INIT(err)
    call MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, err)
    call MPI_COMM_RANK(MPI_COMM_WORLD, myID, err)

    if (nproc /= 4 .AND. myID == 0) then
        write(*, *) "This program works only in 4 streams"
        call MPI_ABORT(MPI_COMM_WORLD, 0, err)
    end if
    
    ! matrix reading
    if(myID == 0) then
    
        open(0, file='A')
        read(0, *) rows
        read(0, *) columns

        allocate(matrix(rows, columns))

        do i = 1, rows
            read(0, *) (matrix(i, j), j = 1, columns)
        end do

        write(*, *) "Input matrix"
        call printMatrix(matrix, rows, columns)

        ! it works only with even num of rows and columns)
        rows = rows / 2
        columns = columns / 2
    endif

    ! sending matrix dimensions
    call MPI_BCAST(rows,    1, MPI_INTEGER, 0, MPI_COMM_WORLD, err)
    call MPI_BCAST(columns, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, err)
    
    if(myID == 0) then
        ! sending matrix parts
        call MPI_SEND(matrix(1:rows,        columns+1:2*columns), rows*columns, MPI_REAL, 1, 0, MPI_COMM_WORLD, err)
        call MPI_SEND(matrix(rows+1:2*rows, 1:columns),           rows*columns, MPI_REAL, 2, 0, MPI_COMM_WORLD, err)
        call MPI_SEND(matrix(rows+1:2*rows, columns+1:2*columns), rows*columns, MPI_REAL, 3, 0, MPI_COMM_WORLD, err)
	
        ! tranposing part of matrix
        call transposeMatrix(matrix(1:rows, 1:columns), rows, columns)

    else
        allocate(matrix(rows,columns))

        ! recieving matrix part, transposing and sending back
        call MPI_RECV(matrix, rows*columns, MPI_REAL, 0, 0, MPI_COMM_WORLD, status, err)
        call transposeMatrix(matrix, rows, columns)
        call MPI_SEND(matrix, rows*columns, MPI_REAL, 0, 0, MPI_COMM_WORLD, err)

        deallocate(matrix)
    endif

    if(myID == 0) then

        ! receiving transposed matrix
        call MPI_RECV(matrix(rows+1:2*rows, 1:columns          ), rows*columns, MPI_REAL, 1, 0, MPI_COMM_WORLD, status, err)
        call MPI_RECV(matrix(1:rows,        columns+1:2*columns), rows*columns, MPI_REAL, 2, 0, MPI_COMM_WORLD, status, err)
        call MPI_RECV(matrix(rows+1:2*rows, columns+1:2*columns), rows*columns, MPI_REAL, 3, 0, MPI_COMM_WORLD, status, err)
        
        write(*, *) "Transposed matrix"
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

