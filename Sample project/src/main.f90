program sample
    implicit none
    include "mpif.h"

    ! MPI variables
    integer :: err      ! error signal variable. Standard Value = 0
	integer :: myID		! process ID (pid) / Number
	integer :: nprocs	! number of processes
    
    ! initialization of MPI
    call MPI_INIT(err)
    call MPI_COMM_SIZE(MPI_COMM_WORLD, nprocs, err)
    call MPI_COMM_RANK(MPI_COMM_WORLD, myID, err)
    
    write(*,*) "Hello, World! I am process ", myID, "of", nprocs, "process(es)"
    
    ! finalization of MPI
    call MPI_FINALIZE(err)

end program sample
