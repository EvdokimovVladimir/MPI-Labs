program hello

    implicit none
    include "mpif.h"
    integer :: n, m, i, j, stat(MPI_STATUS_SIZE)
    real, allocatable :: matr(:,:), temp(:,:)
    
    integer :: err, nproc, myID
    call MPI_INIT(err)
    call MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, err)
    call MPI_COMM_RANK(MPI_COMM_WORLD, myID, err)
    
    if(myID == 0) then
	open(0,file='A')
        read(0,*)n
	read(0,*)m

        allocate(matr(n,m))

	do i = 1,n
	    read(0,*)(matr(i,j), j = 1,m)
        end do

	write(*,*)"Initial matrix"
	call printmatr(matr, n, m, myID)

	n = n / 2
	m = m / 2
    endif

    call MPI_BCAST(n, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, err)
    call MPI_BCAST(m, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, err)

    if(myID == 0) then
	
	call MPI_SEND(matr(1:n, m+1:2*m), n*m, MPI_REAL, 1, 0, MPI_COMM_WORLD, err)
	call MPI_SEND(matr(n+1:2*n, 1:m), n*m, MPI_REAL, 2, 0, MPI_COMM_WORLD, err)
	call MPI_SEND(matr(n+1:2*n, m+1:2*m), n*m, MPI_REAL, 3, 0, MPI_COMM_WORLD, err)
	
    elseif(myID <= 3) then
	allocate(matr(n,m))

	call MPI_RECV(matr, n*m, MPI_REAL, 0, 0, MPI_COMM_WORLD, stat, err)
	call transpose(matr, n, m)
    endif

    if(myID == 0) then
	call MPI_RECV(matr(n+1:2*n, 1:m), n*m, MPI_REAL, 1, 0, MPI_COMM_WORLD, stat,  err)
	call MPI_RECV(matr(1:n, m+1:2*m), m*m, MPI_REAL, 2, 0, MPI_COMM_WORLD, stat, err)
	call MPI_RECV(matr(n+1:2*n, m+1:2*m), n*m, MPI_REAL, 3, 0, MPI_COMM_WORLD, stat, err)
	
	allocate(temp(n, m))
	temp = matr(1:n, 1:m)
	call transpose(temp, n, m)
	matr(1:n, 1:m) = temp
	
	write(*,*)"Transposed matrix"
	call printmatr(matr, 2*n, 2*m, myID)
    else if (myID <= 3) then
	call MPI_SEND(matr, m*m, MPI_REAL, 0, 0, MPI_COMM_WORLD, err)
    endif
    
    
    deallocate(matr)
end program hello

subroutine printmatr(matr, n, m, myID)
    implicit none
    integer :: n, m, i, j, myID
    real :: matr(n, m)

    do i = 1,n
	write(*,'(a,i4,100f6.2)')'myID=', myID, (matr(i,j), j = 1,m)
    end do

end subroutine printmatr

subroutine transpose(matr, n, m)
    implicit none
    integer :: n, m, i, j
    real :: matr(n, m)
    real :: tmp

    do i = 1,n
	do j = i+1,m
	    tmp = matr(i, j)
	    matr(i, j) = matr(j, i)
	    matr(j, i) = tmp
	
	end do
    end do

end subroutine transpose






