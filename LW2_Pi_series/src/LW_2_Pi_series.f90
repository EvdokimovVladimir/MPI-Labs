
!#define DEBUG

program matrixTranspose

    implicit none
    include "mpif.h"

    integer :: status(MPI_STATUS_SIZE)
    integer :: err, nproc, myID
    integer :: prescPow
    integer(kind = 16) :: i
    double precision :: temp, myPi, presc, Pi

#ifdef DEBUG
    integer(kind = 16) :: iteration
#endif

    ! инициализация MPI
    call MPI_INIT(err)
    call MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, err)
    call MPI_COMM_RANK(MPI_COMM_WORLD, myID, err)

    if (myID == 0) then
        write(*, *) "Enter minus decimal log of precision (10^-n)"
        read(*, *) prescPow
        presc = 10.d0 ** (-prescPow) / 4

#ifdef DEBUG
        write(*, "(a12, es8.1)") "Precision = ", presc
#endif   
    end if

    call MPI_BCAST(presc, 1, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, err)

    temp = huge(temp)
    myPi = 0
    i = myID

    do while(abs(temp) > presc)
        temp = (-1.d0) ** i / (2.d0 * i + 1.d0)
        myPi = myPi + temp

        if (i >= (huge(i) - nproc)) then
            write(*, "(a, i2, a)") "ID:", myID, ", i overflow"
            exit
        end if

        i = i + nproc

#ifdef DEBUG
        iteration = (i - myId) / nproc

        if (mod(iteration, 10000) == 0) then
            write(*, "(a, i2, a, i8, a, es8.1)") "ID:", myID, ", iteration = ", iteration, ", part = ", temp
        end if
#endif     
    end do

#ifdef DEBUG
    write(*, "(a, i2, a, es17.10)") "ID:", myID, ", seqentional Pi =", myPi * 4
#endif
    
    call MPI_REDUCE(myPi, Pi, 1, MPI_DOUBLE_PRECISION, MPI_SUM, 0, MPI_COMM_WORLD, err)
    Pi = Pi * 4

    
    if (myID == 0) then
        write(*, "(a, f0.50)") "Pi = ", Pi
    end if

    call MPI_FINALIZE(err)
    
end program matrixTranspose


