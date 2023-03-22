
!#define DEBUG

program PiMonteCarlo

    use mpi
    implicit none

    ! MPI
    integer :: err, nproc, myId
    double precision :: time

    ! calcuating
    integer(kind = 16) :: iterations, i, myPi
    integer(kind = 16), allocatable :: myPis(:)
    double precision :: coord(2)
    double precision :: Pi
    character(len = 12) :: fmt

    ! random
    integer :: istat
    integer, allocatable :: seeds(:), seed(:)
    integer :: seedLen

    ! initialization MPI
    call MPI_INIT(err)
    call MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, err)
    call MPI_COMM_RANK(MPI_COMM_WORLD, myID, err)
    allocate(myPis(nproc))

    ! input number of iterations
    if (myID == 0) then
        write(*, *) "Enter decimal log of number of iterations per process"
        write(*, "(a, i3)") "Max: ", floor(log10(dble(huge(iterations))))
        read(*, *) iterations
        iterations = 10 ** iterations
#ifdef DEBUG
        write(*, "(a, i38)") "Iterations: ", iterations
#endif

        ! seeds for random
        call random_seed(size = seedLen)
        allocate(seeds(seedLen * nproc))

        open(0, file = "/dev/random", access = "stream", &
                status = "old", action = "read", &
                form = "unformatted", iostat = istat)
        if (istat == 0) then
            read(0) seeds
            close(0)
        end if
    end if

    ! iterations are integer(kind = 16)
    ! there is no native support in MPI for 16 byte integer(
    call MPI_BCAST(iterations, 16, MPI_BYTE, 0, MPI_COMM_WORLD, err)

    ! sending of seeds
    call MPI_BCAST(seedLen, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, err)
    allocate(seed(seedLen))
    call MPI_SCATTER(seeds, seedLen, MPI_INTEGER, seed, seedLen, MPI_INTEGER, 0, MPI_COMM_WORLD, err)
    call random_seed(put = seed)

    time = MPI_WTIME()

#ifdef DEBUG
    ! seeds debug
    write(*, "(a, i2, a, 8i12)") "ID: ", myID, ", seed =", seed
#endif

    ! calculating pi by Monte Carlo method
    myPi = 0
    do i = 1, iterations
        call random_number(coord(:))
        if (coord(1)**2 + coord(2)**2 <= 1) then
            myPi = myPi + 1
        end if
    end do

#ifdef DEBUG
    ! local pi debug
    write(*, "(a, i2, a, i38)") "ID: ", myID, ", myPi = ", myPi
#endif

    ! myPi are integer(kind = 16)
    ! there is no native support in MPI for 16 byte integer(
    call MPI_GATHER(myPi, 16, MPI_BYTE, myPis, 16, MPI_BYTE, 0, MPI_COMM_WORLD, err)
    
    if (myID == 0) then       
        ! calculating main sum
        do i = 2, nproc
            myPi = myPi + myPis(i)
        end do

        Pi = 4.d0 * dble(myPi) / dble(iterations) / nproc

        ! writting the answer
        write(fmt, "(a, i0, a)") "(a, f0.", int(log10(dble(iterations)) - 3), ")"
        write(*, fmt) "Pi = ", Pi
        
        time = MPI_WTIME() - time
        write(*, "(a, f0.6, a, f0.6, a)") "Time = ", time, " +- ", MPI_WTICK(), " s"
    end if

    call MPI_FINALIZE(err)
    
end program PiMonteCarlo
