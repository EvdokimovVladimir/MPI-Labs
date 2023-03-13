
!#define DEBUG

program PiSeries

    implicit none
    include "mpif.h"

    integer :: err, nproc, myID
    integer :: prescPow
    integer(kind = 16) :: iterations, i
    real(kind = 16) :: temp, myPi
    real(kind = 16), allocatable :: myPis(:)
    double precision :: time
    character(len = 12) :: fmt

#ifdef DEBUG
    integer(kind = 16) :: iteration
#endif

    ! initialization MPI
    call MPI_INIT(err)
    call MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, err)
    call MPI_COMM_RANK(MPI_COMM_WORLD, myID, err)
    allocate(myPis(nproc))

    ! input precision
    if (myID == 0) then
        write(*, *) "Enter decimal log of number of iterations per process"
        write(*, "(a, i3)") "Max: ", floor(log10(1.d0 * huge(iterations)))
        read(*, *) iterations
        iterations = 10 ** iterations
#ifdef DEBUG
        write(*, "(a, i38)") "Iterations: ", iterations
#endif 
        time = MPI_WTIME(err)
    end if

    ! iterations are integer(kind = 16)
    ! there is no native support in MPI for 16 byte integer(
    call MPI_BCAST(iterations, 16, MPI_BYTE, 0, MPI_COMM_WORLD, err)

    ! calculating pi
    myPi = 0

    do i = myID, iterations, nproc
        ! as in Taylor series
        temp = (-1.d0) ** i / (2.d0 * i + 1.d0)
        myPi = myPi + temp

#ifdef DEBUG
        ! debuging every 10 000 iterations
        iteration = (i - myId) / nproc

        if (mod(iteration, 10000) == 0) then
            write(*, "(a, i2, a, i8, a, es8.1)") "ID:", myID, ", iteration = ", i, ", part = ", temp
        end if
#endif     
    end do

#ifdef DEBUG
    write(*, "(a, i2, a, es17.10)") "ID:", myID, ", seqentional Pi =", myPi * 4
#endif
    
    ! collecting data
    ! myPi are integer(kind = 16)
    ! there is no native support in MPI for 16 byte integer(
    call MPI_GATHER(myPi, 16, MPI_BYTE, myPis, 16, MPI_BYTE, 0, MPI_COMM_WORLD, err)

    ! writting the answer
    if (myID == 0) then
        
        ! calculating main sum
        do i = 2, nproc
            myPi = myPi + myPis(i)
        end do

        myPi = 4.d0 * myPi

        write(fmt, "(a, i0, a)") "(a, f0.", int(-log10(abs(temp))), ")"
        write(*, fmt) "Pi = ", myPi

        time = MPI_WTIME(err) - time
        write(*, "(a, f0.9, a, f0.9)") "Time = ", time, " s +- ", MPI_WTICK(err)
    end if

    call MPI_FINALIZE(err)
    
end program PiSeries


