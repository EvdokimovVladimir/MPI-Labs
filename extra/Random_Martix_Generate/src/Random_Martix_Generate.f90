
#define DEBUG

program Random_Martix_Generate

    implicit none
    integer :: rows, columns
    integer :: row, column
    real, allocatable :: tmp(:)

    character(len = 10) :: fmt
    character(len = 20) :: filename
    integer :: fileunit, randomUnit

    ! for random
    integer, allocatable :: seed(:)
    integer :: seedLen

    ! RANDOM INITIALIZATION
    call random_seed(size = seedLen)
    allocate(seed(seedLen))
    open(newunit = randomUnit, file = "/dev/random", access = "stream", &
         status = "old", action = "read", &
         form = "unformatted")
    read(randomUnit) seed
    close(randomUnit)
    call random_seed(put = seed)

    ! READING SIZE AND FILENAME
    write(*, *) "Enter number of rows"
    read(*, *) rows

    if (rows < 1) then
        write(*, *) "Number of rows must be 1 or more"
        call abort()
    end if

    write(*, *) "Enter number of columns"
    read(*, *) columns

    if (columns < 1) then
        write(*, *) "Number of columns must be 1 or more"
        call abort()
    end if

    write(*, *) "Enter filename"
    read(*, *) filename

    ! format for matrix
    write(fmt, "(a, i0, a)") "(", columns, "f5.2)"

    ! WRITING FILE
    open(newunit = fileunit, file = filename, status = "replace")
    
    write(fileunit, "(i0)") rows
    write(fileunit, "(i0)") columns

    allocate(tmp(columns))
    do row = 1, rows
        call random_number(tmp(:))
        write(fileunit, fmt) (tmp(column), column = 1, columns)
    end do
    
    close(fileunit)

end program Random_Martix_Generate

