
!#define DEBUG
#define MAX_ITERATIONS (10e6)
#define EPS (1d-100)

program SLAE_Jacoby

    use mpi
    use utils
    implicit none

    ! MPI
    integer :: err, nproc, myId
    double precision :: time
    integer, parameter :: rootId = 0

    ! numbers of columns or rows per process
    integer, allocatable :: countsX(:)
    ! displacements for MPI_SCATTERV
    integer, allocatable :: displacementsX(:)

    ! main matrixes
    double precision, allocatable :: matrixA(:, :), vectorB(:), vectorX(:)
    ! temporary matrix 
    double precision, allocatable :: temp(:, :)

    ! dimensions of main matrixes
    integer :: lengthA, countX
    ! for iterations
    integer :: i, row, column, iteration
    ! local parts of main matrixes
    double precision, allocatable :: localA(:, :), localB(:), localX(:)
    ! for calculating norm
    double precision :: errorNorm, tmp    

    ! initialization MPI
    call MPI_INIT(err)
    call MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, err)
    call MPI_COMM_RANK(MPI_COMM_WORLD, myID, err)
    
    ! for MPI_SCATTERV
    allocate(countsX(nproc), displacementsX(nproc))

! ===============================================================
!       READING MATRIXES FROM FILE
! ===============================================================

    if (myID == rootId) then
        
        call readMatrix(matrixA, "B")
        
        write(*, *) "Matrix A:"
        call printMatrix(matrixA)

        !  impossible
        if (size(matrixA, 1) /= (size(matrixA, 2) - 1)) then
            write(*, *) "# of colunms of A should be equal # of rows of A"
            write(*, *) "# of columns of A:", size(matrixA, 2), ", # of rows of A:", size(matrixA, 1)
            call MPI_ABORT(MPI_COMM_WORLD, 0, err)
        end if

        lengthA = size(matrixA, 1)

        ! B = -D^(-1) * (A - D)
        ! D - diagonal part of A
        ! D^(-1)_ii = 1 / D_ii
        do row = 1, lengthA
            tmp = matrixA(row, row)
            matrixA(row, row) = 0

            if (tmp == 0) then
                write(*, *) "There is 0 on A_ii. i = ", row
                call MPI_ABORT(MPI_COMM_WORLD, 0, err)
            end if

            do column = 1, (lengthA+1)
                matrixA(row, column) = -1. * matrixA(row, column) / tmp
            end do
        end do

#ifdef DEBUG
        write(*, *) "Matrix A modified"
        call printMatrix(matrixA)
#endif

        ! deleting last column
        allocate(temp(lengthA, lengthA))
        allocate(vectorB(lengthA))
        temp = matrixA(:, :lengthA)
        vectorB = matrixA(:, lengthA + 1)
        deallocate(matrixA)
        allocate(matrixA(lengthA, lengthA))
        matrixA = temp
        deallocate(temp)

        ! transposing for sending and optimization
        call transposeMatrix(matrixA)
        
#ifdef DEBUG
        write(*, *) "Matrix A transposed"
        call printMatrix(matrixA)
#endif

        ! dividing matrix into processes and preparing for MPI_SCATTERV
        countsX = lengthA / nproc

        do i = 1, mod(lengthA, nproc)
            countsX(i) = countsX(i) + 1
        end do

        displacementsX(1) = 0
        do i = 2, nproc
            displacementsX(i) = displacementsX(i-1) + countsX(i-1)
        end do
        
#ifdef DEBUG
        write(*, *) "countsX"
        call printVector(dble(countsX))

        write(*, *) "displacementsX"
        call printVector(dble(displacementsX))
#endif
    end if

! ===============================================================
!       SENDING DATA
! ===============================================================

    time = MPI_WTIME()

    ! sending parameters for MPI_SCATTERV
    call MPI_BCAST(lengthA, 1, MPI_INTEGER, rootId, MPI_COMM_WORLD, err)
    call MPI_BCAST(countsX, nproc, MPI_INTEGER, rootId, MPI_COMM_WORLD, err)
    call MPI_BCAST(displacementsX, nproc, MPI_INTEGER, rootId, MPI_COMM_WORLD, err)
    countX = countsX(myId + 1)
    allocate(vectorX(lengthA))

#ifdef DEBUG
    call MPI_BARRIER(MPI_COMM_WORLD, err)
    if (myId == rootId) then
        write(*, *) "Scattered countsX"
    end if
    write(*, *) myId, "countX = ", countX
#endif

    ! sending parts of A
    allocate(localA(lengthA, countX))
    call MPI_SCATTERV(matrixA, lengthA * countsX, lengthA * displacementsX, MPI_DOUBLE_PRECISION, & 
                    localA, size(localA), MPI_DOUBLE_PRECISION, rootId, MPI_COMM_WORLD, err)

#ifdef DEBUG
    do i = 0, nproc-1
        call MPI_BARRIER(MPI_COMM_WORLD, err)
        if (myId == i) then
            write(*, *) myId, "Scattered matrixA", size(localA)
            call printMatrix(localA)
        end if
    end do
#endif

    ! sending parts of B
    allocate(localB(countX))
    call MPI_SCATTERV(vectorB, countsX, displacementsX, MPI_DOUBLE_PRECISION, & 
                    localB, size(localB), MPI_DOUBLE_PRECISION, rootId, MPI_COMM_WORLD, err)

#ifdef DEBUG
    do i = 0, nproc-1
        call MPI_BARRIER(MPI_COMM_WORLD, err)
        if (myId == i) then
            write(*, *) myId, "Scattered matrixB", size(localB)
            call printVector(localB)
        end if
    end do
#endif
        
    ! free memory
    if (myId == 0) then
        deallocate(matrixA, vectorB)
    end if
    
! ===============================================================
!       MAIN CALCULATION
! =============================================================== 

    allocate(localX(countX))
    
    ! initial values = 0
    localX = 0
    vectorX = 0

    iteration = 0
    ! Jacoby cycle
    do
        ! calculating new X's
        do row = 1, countX

            tmp = 0
            ! main sum row(A)*X
            do i = 1, lengthA
                tmp = tmp + vectorX(i) * localA(i, row)
            end do

            localX(row) = tmp - localB(row)
            
        end do

        tmp = 0
        ! calculating local part of error
        do row = 1, countX
            tmp = tmp + (localX(row) - vectorX(displacementsX(myId + 1) + row)) ** 2
        end do

        ! sending X
        call MPI_ALLGATHERV(localX, countX, MPI_DOUBLE_PRECISION, &
                            vectorX, countsX, displacementsX, MPI_DOUBLE_PRECISION, &
                            MPI_COMM_WORLD, err)

        ! calculating sum of error
        call MPI_ALLREDUCE(tmp, errorNorm, 1, MPI_DOUBLE_PRECISION, MPI_SUM, MPI_COMM_WORLD, err)


#ifdef DEBUG
        call MPI_BARRIER(MPI_COMM_WORLD, err)
        if (myId == rootId) then
            write(*, *) "errorNorm = ", errorNorm
            call printVector(vectorX)
        end if
#endif

        ! exit condition
        iteration = iteration + 1
        if ((isnan(errorNorm) .or. errorNorm > huge(errorNorm)) .and. (myId == rootId)) then
            write(*, *) "There is some bad numbers... Error = ", errorNorm
            call MPI_ABORT(MPI_COMM_WORLD, 0, err)
        end if

        if (errorNorm <= EPS .or. iteration >= MAX_ITERATIONS) then
            exit
        end if
    
    end do ! Jacoby cycle

    ! free memory
    deallocate(localA, localB, localX)

! ===============================================================
!       COLLECTING RESULT ON ROOT
! =============================================================== 


    if (myID == rootId) then       
        if (iteration >= MAX_ITERATIONS) then
            write(*, *)
            write(*, *) "Iteration overflow!"
        end if
        
        ! writting the answer
        write(*, *) "Answer: "
        call printVector(vectorX)
        write(*, *) "Error:", errorNorm
        write(*, *) "Iterations:", iteration
        
        ! writting execution time
        time = MPI_WTIME() - time
        write(*, "(a, f0.6, a, f0.6, a)") "Time = ", time, " +- ", MPI_WTICK(), " s"

    end if

    ! free memory
    deallocate(countsX, displacementsX, vectorX)

    call MPI_FINALIZE(err)
    
end program SLAE_Jacoby

