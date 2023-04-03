!#define DEBUG
!#define MATRIX_B_CUT

program MatrixMultiplication

    use mpi
    use utils
    implicit none

    ! MPI
    integer :: err, nproc, myId
    double precision :: time
    integer :: status(MPI_STATUS_SIZE)
    integer, parameter :: rootId = 0

    ! pointer for MPI_ISEND
    integer :: sendReqest
    ! numbers of columns or rows per process
    integer, allocatable :: countsA(:), countsB(:)
    ! displacements for MPI_SCATTERV
    integer, allocatable :: displacementsA(:), displacementsB(:), displacementsC(:)

    ! main matrixes
    real, allocatable :: matrixA(:, :), matrixB(:, :), matrixC(:, :)
    ! temporary matrix 
    real, allocatable :: temp(:, :)

    ! dimensions of main matrixes
    integer :: rowsA, rowsB, columnsA, columnsB
    ! for iterations
    integer :: i, partOfB, columnPrefix, column, row
    ! local number of columns or rows
    integer :: countA, countB
    ! internal size of matrxes
    integer :: internalSize
    ! local parts of main matrixes
    real, allocatable :: localA(:, :), localB(:, :), localC(:, :)
    ! temporary
    real :: tmp
    

    ! initialization MPI
    call MPI_INIT(err)
    call MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, err)
    call MPI_COMM_RANK(MPI_COMM_WORLD, myID, err)
    
    ! for MPI_SCATTERV
    allocate(countsA(nproc), countsB(nproc))
    allocate(displacementsA(nproc), displacementsB(nproc), displacementsC(nproc))

! ===============================================================
!       READING MATRIXES FROM FILE
! ===============================================================

    if (myID == rootId) then
        
        call readMatrix(matrixA, "A")
        
        write(*, *) "Matrix A:"
        call printMatrix(matrixA)
        rowsA = size(matrixA, 1)
        columnsA = size(matrixA, 2)

        ! transposing for sending and optimization
        call transposeMatrix(matrixA)
        
#ifdef DEBUG
        write(*, *) "Matrix A transposed"
        call printMatrix(matrixA)
#endif

        call readMatrix(matrixB, "B")  
        write(*, *) "Matrix B:"
        call printMatrix(matrixB)

#ifdef MATRIX_B_CUT
        ! deleting last column
        allocate(temp(size(matrixB, 1), size(matrixB, 2)-1))
        temp = matrixB(:, :(size(matrixB, 2)-1))
        deallocate(matrixB)
        allocate(matrixB(size(temp, 1), size(temp, 2)))
        matrixB = temp
        deallocate(temp)

#ifdef DEBUG
        write(*, *) "Matrix B cut"
        call printMatrix(matrixB)
#endif
#endif
        rowsB = size(matrixB, 1)
        columnsB = size(matrixB, 2)

#ifdef DEBUG
        write(*, *) "size matrixA", rowsA, columnsA
        write(*, *) "size matrixB", rowsB, columnsB
#endif
        !  impossible multiplication
        if (columnsA /= rowsB) then
            write(*, *) "# of colunms of A should be equal # of rows of B"
            write(*, *) "# of columns of A:", columnsA, ", # of rows of B:", rowsB
            call MPI_ABORT(MPI_COMM_WORLD, 0, err)
        end if

        ! dividing matrix into processes and preparing for MPI_SCATTERV
        countsA = rowsA / nproc
        countsB = columnsB / nproc

        do i = 1, mod(rowsA, nproc)
            countsA(i) = countsA(i) + 1
        end do

        do i = 1, mod(columnsB, nproc)
            countsB(i) = countsB(i) + 1
        end do

#ifdef DEBUG
        write(*, *) "countsA = ", countsA
        write(*, *) "countsB = ", countsB
#endif

        internalSize = columnsA

        displacementsA(1) = 0
        displacementsB(1) = 0
        displacementsC(1) = 0
        do i = 2, nproc
            displacementsA(i) = displacementsA(i-1) + internalSize * countsA(i-1)
            displacementsB(i) = displacementsB(i-1) + internalSize * countsB(i-1)
            displacementsC(i) = displacementsC(i-1) + columnsB * countsA(i-1)
        end do
        
#ifdef DEBUG
        write(*, *) "displacementsA = ", displacementsA
        write(*, *) "displacementsB = ", displacementsB
#endif
        allocate(matrixC(columnsB, rowsA))
    end if

! ===============================================================
!       SENDING DATA
! ===============================================================

    time = MPI_WTIME()

    ! sending internal size of A*B
    call MPI_BCAST(internalSize, 1, MPI_INTEGER, rootId, MPI_COMM_WORLD, err)
    
    ! sending for MPI_SCATTERV
    call MPI_BCAST(countsA, nproc, MPI_INTEGER, rootId, MPI_COMM_WORLD, err)
    call MPI_BCAST(displacementsA, nproc, MPI_INTEGER, rootId, MPI_COMM_WORLD, err)
    countA = countsA(myId + 1)
    
#ifdef DEBUG
    call MPI_BARRIER(MPI_COMM_WORLD, err)
    if (myId == rootId) then
        write(*, *) "Casted m"
        write(*, *) "Scattered countsA"
    end if
    write(*, *) myId, "countA = ", countA
#endif

    ! sending parts of A
    allocate(localA(internalSize, countA))
    call MPI_SCATTERV(matrixA, internalSize * countsA, displacementsA, MPI_REAL, & 
                    localA, size(localA), MPI_REAL, rootId, MPI_COMM_WORLD, err)

#ifdef DEBUG
    call MPI_BARRIER(MPI_COMM_WORLD, err)
    if (myId == rootId) then
        write(*, *) "Scattered matrixA"
    end if
#endif

    ! sending # of columns of B
    call MPI_BCAST(countsB, nproc, MPI_INTEGER, rootId, MPI_COMM_WORLD, err)
    call MPI_BCAST(columnsB, 1, MPI_INTEGER, rootId, MPI_COMM_WORLD, err)
#ifdef DEBUG
    call MPI_BARRIER(MPI_COMM_WORLD, err)
    if (myId == rootId) then
        write(*, *) "Casted countsB and columnsB", columnsB
    end if    
#endif

    ! sending parts of B
    countB = countsB(myId + 1)
    allocate(localB(internalSize, countB))
    call MPI_SCATTERV(matrixB, internalSize * countsB, displacementsB, MPI_REAL, & 
                    localB, size(localB), MPI_REAL, rootId, MPI_COMM_WORLD, err)
#ifdef DEBUG
    do i = 0, nproc-1
        call MPI_BARRIER(MPI_COMM_WORLD, err)
        if (myId == i) then
            write(*, *) myId, "Scattered matrixB", size(localB)
            call printMatrix(localB)
            write(*, *) myId, "countA, countB", countA, countB
        end if
    end do
#endif  


    allocate(localC(columnsB, countA))
    localC = 0
        
! ===============================================================
!       MAIN CALCULATION
! =============================================================== 

    ! parts of B
    do partOfB = 1, nproc

        ! column perfix
        columnPrefix = 0
        do i = 1, mod(myId+partOfB-1, nproc)
            columnPrefix = columnPrefix + countsB(i)
        end do

#ifdef DEBUG
        do i = 0, nproc-1
            call MPI_BARRIER(MPI_COMM_WORLD, err)
            if (myId == i) then
                write(*, *) myId, "partOfB = ", partOfB, "columnPrefix = ", columnPrefix
            end if
        end do   
        call MPI_BARRIER(MPI_COMM_WORLD, err)      
#endif  

        ! calculating part of C
        ! THIS IS MATRIX MULTIPLICATION
        do row = 1, countA
            do column = 1, countB
                tmp = 0
                do i = 1, internalSize
                    tmp = tmp + localA(i, row) * localB(i, column)
                end do
                localC(columnPrefix + column, row) = tmp
            end do 
        end do


#ifdef DEBUG
        do i = 0, nproc-1
            call MPI_BARRIER(MPI_COMM_WORLD, err)
            if (myId == i) then
                write(*, *) myId, "localC"
                call printMatrix(localC)
            end if
        end do
#endif 
        
        ! sending to the left process
        ! mod for cycling
        call MPI_ISEND(localB, internalSize * countB, MPI_REAL, mod(nproc + myId - 1, nproc), &
                        0, MPI_COMM_WORLD, sendReqest, err)
! #ifdef DEBUG
!         do i = 0, nproc-1
!             call MPI_BARRIER(MPI_COMM_WORLD, err)
!             if (myId == i) then
!                 write(*, *) myId, "localB to ", mod(nproc + myId - 1, nproc), ", reals: ", internalSize * countB
!             end if
!         end do
! #endif
        
        ! temporary matrix for recieving next part of B
        countB = countsB(mod(nproc + myId + partOfB, nproc) + 1)
        allocate(temp(internalSize, countB))

! #ifdef DEBUG
!         do i = 0, nproc-1
!             call MPI_BARRIER(MPI_COMM_WORLD, err)
!             if (myId == i) then
!                 write(*, *) myId, "readind from ", mod(myId + 1, nproc), ", reals: ", internalSize * countB
!             end if
!         end do
! #endif
        ! recieving next part of B
        call MPI_RECV(temp, internalSize * countB, MPI_REAL, mod(myId + 1, nproc), &
                        0, MPI_COMM_WORLD, status, err)
        
        ! waiting for releasing localB
        call MPI_WAIT(sendReqest, status, err)
        
        ! and putting recieved part of B into localB
        deallocate(localB)
        allocate(localB(internalSize, countB))
        localB = temp
        deallocate(temp)

    end do  

! ===============================================================
!       COLLECTING RESULT ON ROOT
! =============================================================== 

    ! gathering result on root
    call MPI_GATHERV(localC, countA * columnsB, MPI_REAL, &
                    matrixC, countsA * columnsB, displacementsC, MPI_REAL, &
                    rootId, MPI_COMM_WORLD, err)

    ! free memory
    deallocate(localA, localB, localC)

    if (myID == rootId) then       
        ! writting the answer
        call transposeMatrix(matrixC)
        write(*, *) "C = A * B ="
        call printMatrix(matrixC)
        call writeMatrixToFile(matrixC, "C")
        
        ! writting execution time
        time = MPI_WTIME() - time
        write(*, "(a, f0.6, a, f0.6, a)") "Time = ", time, " +- ", MPI_WTICK(), " s"

        deallocate(matrixC)
    end if

    ! free memory
    deallocate(countsB, countsA)
    deallocate(displacementsA, displacementsB, displacementsC)

    call MPI_FINALIZE(err)
    
end program MatrixMultiplication

