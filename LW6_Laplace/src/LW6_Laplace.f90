!#define DEBUG
#define MAX_ITERATIONS int8(1e10)
#define ITERATION_MESSAGE int8(1e4)

program Laplace

    use mpi
    use utils
    implicit none

    ! MPI
    integer :: err, nproc, myId, status(MPI_STATUS_SIZE)
    double precision :: time
    integer, parameter :: rootId = 0

    ! reading from file
    integer :: fileunit
    integer :: height, width
    double precision :: tempLeftUp, tempLeftDown, tempRightUp, tempRightDown
    double precision :: epsilon

    ! for MPI_SCATTERV
    integer, allocatable :: counts(:), displacements(:)
    integer :: i, count

    ! boundaries conditions
    double precision, allocatable :: boundaryLeft(:), boundaryRight(:), boundaryUp(:), boundaryDown(:)

    ! matrices
    double precision, allocatable :: localMatrix(:, :), mainMatrix(:, :)

    ! iterations
    integer (kind = 8) :: iteration
    integer :: row, column
    double precision, allocatable :: temp(:, :)
    double precision :: error, errorNorm

    ! internal SEND RECV
    integer :: nextId, prevId
    integer :: sendReqest(2), statuses(MPI_STATUS_SIZE * 2)

    ! initialization MPI
    call MPI_INIT(err)
    call MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, err)
    call MPI_COMM_RANK(MPI_COMM_WORLD, myID, err)

    allocate(counts(nproc), displacements(nproc))
    
! ===============================================================
!       READING FROM FILE
! ===============================================================

    if (myID == rootId) then
        open(newunit = fileunit, file = "Laplace", status = "old")
        read(fileunit, *) height
        read(fileunit, *) width
        read(fileunit, *) tempLeftUp, tempRightUp
        read(fileunit, *) tempLeftDown, tempRightDown
        read(fileunit, *) epsilon
        close(fileunit)

        write(*, *) "Length:", height, "Width:", width
        write(*, *) "Boundary conditions:"
        write(*, *) tempLeftUp, tempRightUp
        write(*, *) tempLeftDown, tempRightDown
        write(*, *) "Epsilon: ", epsilon

        ! dividing matrix into processes and preparing for MPI_SCATTERV
        counts = (height - 2) / nproc + 2

        do i = 1, mod(height - 2, nproc)
            counts(i) = counts(i) + 1
        end do

        displacements(1) = 0
        do i = 2, nproc
            displacements(i) = displacements(i - 1) + counts(i - 1) - 2
        end do

#ifdef DEBUG
        write(*, *) "counts"
        call printVector(dble(counts), 0)

        write(*, *) "displacements"
        call printVector(dble(displacements), 0)
#endif

        ! boundaries conditions vectors
        allocate(boundaryLeft(height), boundaryRight(height), boundaryUp(width), boundaryDown(width))
        call interpolateBoundary(boundaryLeft, height, tempLeftUp, tempLeftDown)
        call interpolateBoundary(boundaryRight, height, tempRightUp, tempRightDown)
        call interpolateBoundary(boundaryUp, width, tempLeftUp, tempRightUp)
        call interpolateBoundary(boundaryDown, width, tempLeftDown, tempRightDown)

#ifdef DEBUG
        ! may be ugly
        write(*, *) "boundaryLeft"
        call printVector(boundaryLeft, 1)
        write(*, *) "boundaryRight"
        call printVector(boundaryRight, 1)
        write(*, *) "boundaryUp"
        call printVector(boundaryUp, 1)
        write(*, *) "boundaryDown"
        call printVector(boundaryDown, 1)
#endif
    end if

! ===============================================================
!       SENDING DATA
! ===============================================================

    time = MPI_WTIME()

    ! sizes and epsilon
    call MPI_BCAST(width, 1, MPI_INTEGER, rootId, MPI_COMM_WORLD, err)
    call MPI_BCAST(epsilon, 1, MPI_DOUBLE_PRECISION, rootId, MPI_COMM_WORLD, err)
    call MPI_BCAST(counts, nproc, MPI_INTEGER, rootId, MPI_COMM_WORLD, err)
    call MPI_BCAST(displacements, nproc, MPI_INTEGER, rootId, MPI_COMM_WORLD, err)
    count = counts(myId + 1)

#ifdef DEBUG
    write(*, *) myId, "count = ", count
#endif

    ! scattering boundaries left and right
    allocate(localMatrix(count, width))
    localMatrix = 0
    call MPI_SCATTERV(boundaryLeft, counts, displacements, MPI_DOUBLE_PRECISION, & 
                      localMatrix(:, 1), count, MPI_DOUBLE_PRECISION, rootId, MPI_COMM_WORLD, err)
    call MPI_SCATTERV(boundaryRight, counts, displacements, MPI_DOUBLE_PRECISION, & 
                      localMatrix(:, width), count, MPI_DOUBLE_PRECISION, rootId, MPI_COMM_WORLD, err)

    ! up and down boundaries
    if (myId == rootId) then
        localMatrix(1, :) = boundaryUp
        call MPI_SEND(boundaryDown, width, MPI_DOUBLE_PRECISION, nproc - 1, 0, MPI_COMM_WORLD, err)
    else if (myId == nproc - 1) then
        call MPI_RECV(localMatrix(count, :), width, MPI_DOUBLE_PRECISION, 0, 0, MPI_COMM_WORLD, status, err)
    end if

#ifdef DEBUG
    do i = 0, nproc-1
        call MPI_BARRIER(MPI_COMM_WORLD, err)
        if (myId == i) then
            write(*, *) myId, "Scattered matrix", size(localMatrix, 1), size(localMatrix, 2)
            call printMatrix(localMatrix)
        end if
    end do
#endif

    ! free memory
    if (myId == rootId) then
        deallocate(boundaryLeft, boundaryRight, boundaryUp, boundaryDown)   
    end if
    
! ===============================================================
!       MAIN CALCULATION
! =============================================================== 

    ! for SEND and RECV
    nextId = myId + 1
    prevId = myId - 1
    if (myId == 0) then
        prevId = MPI_PROC_NULL
    end if
    if (myId == nproc - 1) then
        nextId = MPI_PROC_NULL
    end if

    ! temporary variable
    allocate(temp(count - 2, width - 2))
    
    ! Jacoby cycle
    do iteration = 1, MAX_ITERATIONS

        error = 0
        ! main cycle
        do row = 2, count - 1
            do column = 2, width - 1
                temp(row - 1, column - 1) = (localMatrix(row + 1, column) + &
                                            localMatrix(row - 1, column) + &
                                            localMatrix(row, column + 1) + &
                                            localMatrix(row, column - 1)) / 4

                ! local error (new - old)^2
                error = error + (temp(row - 1, column - 1) - localMatrix(row, column)) ** 2
            end do
        end do

        ! rewriting
        localMatrix(2:(count - 1), 2:(width - 1)) = temp        

        ! sending boundaries to next and prev proc
        call MPI_ISEND(temp(count - 2, :), width - 2, MPI_DOUBLE_PRECISION, nextId, &
                        0, MPI_COMM_WORLD, sendReqest(1), err)
        call MPI_ISEND(temp(1, :), width - 2, MPI_DOUBLE_PRECISION, prevId, &
                        0, MPI_COMM_WORLD, sendReqest(2), err)

        ! recieving boundaries from prev and next proc
        call MPI_RECV(localMatrix(1, 2:(width - 1)), width - 2, MPI_DOUBLE_PRECISION, prevId, &
                        0, MPI_COMM_WORLD, status, err)
        call MPI_RECV(localMatrix(count, 2:(width - 1)), width - 2, MPI_DOUBLE_PRECISION, nextId, &
                        0, MPI_COMM_WORLD, status, err)

        ! calculating sum of error
        call MPI_ALLREDUCE(error, errorNorm, 1, MPI_DOUBLE_PRECISION, MPI_SUM, MPI_COMM_WORLD, err)

        ! waiting all recieved
        call MPI_WAITALL(2, sendReqest, statuses, err)

#ifdef DEBUG
        call MPI_BARRIER(MPI_COMM_WORLD, err)
        if (myId == rootId) then
            write(*, *) "errorNorm = ", errorNorm
        end if

        ! you don't need it)
        ! do i = 0, nproc-1
        !     call MPI_BARRIER(MPI_COMM_WORLD, err)
        !     if (myId == i) then
        !         write(*, *) myId, "Iteration", iteration
        !         call printMatrix(localMatrix)
        !     end if
        ! end do
#endif

        ! exit condition
        if ((isnan(errorNorm) .or. errorNorm > huge(errorNorm)) .and. (myId == rootId)) then
            write(*, *) "There is some bad numbers... Error = ", errorNorm
            call MPI_ABORT(MPI_COMM_WORLD, 0, err)
        end if

        if (errorNorm <= epsilon) then
            exit
        end if

        ! output error every ITERATION_MESSAGE
        if ((mod(iteration, ITERATION_MESSAGE) == 0) .and. (myId == rootId)) then
            write(*, *) "Iteration:", iteration, "Error:", errorNorm
        end if
    
    end do ! Jacoby cycle

    ! free memory
    deallocate(temp)

! ===============================================================
!       COLLECTING RESULT ON ROOT
! =============================================================== 

    ! transposing for simplifying sending
    call transposeMatrix(localMatrix)

    ! allocating var for recieving
    if (myId == rootId) then
        allocate(mainMatrix(width, height))
    end if

    ! some magic math for last 2 lines
    if (myId == nproc - 1) then
        count = count + 2
    end if
    counts(nproc) = counts(nproc) + 2

    ! gathering answer
    call MPI_GATHERV(localMatrix(:, 1:(count - 2)), (count - 2) * width, MPI_DOUBLE_PRECISION, &
                    mainMatrix, width * (counts - 2), width * displacements, MPI_DOUBLE_PRECISION, &
                    rootID, MPI_COMM_WORLD, err)

    if (myID == rootId) then
        ! transposing back    
        call transposeMatrix(mainMatrix)
        
        if (iteration >= MAX_ITERATIONS) then
            write(*, *)
            write(*, *) "Iteration overfl`ow!"
        end if
        
        ! writting the answer
        write(*, *) "Answer: "
        call printMatrix(mainMatrix)
        write(*, *) "Error:", errorNorm
        write(*, *) "Iterations:", iteration
        
        ! writting execution time
        time = MPI_WTIME() - time
        write(*, "(a, f0.6, a, f0.6, a)") "Time = ", time, " +- ", MPI_WTICK(), " s"

        ! free memory
        deallocate(mainMatrix)

    end if

    call MPI_FINALIZE(err)

    ! free memory
    deallocate(counts, displacements)
    deallocate(localMatrix)

end program Laplace
