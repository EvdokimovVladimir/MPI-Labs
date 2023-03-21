
module utils
    implicit none
    
contains
    
subroutine readMatrix(matrix, filename)

    real, allocatable, intent(out) :: matrix(:, :)
    character(*), intent(in) :: filename
    integer :: fileunit, rows, columns, i, j

    open(newunit = fileunit, file = filename, status = "old")
    
    read(fileunit, *) rows
    read(fileunit, *) columns

    allocate(matrix(rows, columns))

    do i = 1, rows
        read(fileunit, *) (matrix(i, j), j = 1, columns)
    end do
    
    close(fileunit)
    
end subroutine readMatrix

subroutine printMatrix(matrix)

    implicit none
    real, intent(in) :: matrix(:, :)
    integer :: rows, columns
    integer :: i, j
    character(len = 10) :: fmt

    rows = size(matrix, 1)
    columns = size(matrix, 2)

    write(fmt, "(a, i0, a)") "(", columns, "f8.2)"

    do i = 1, rows
        write(*, fmt)(matrix(i, j), j = 1, columns)
    end do

end subroutine printMatrix

subroutine writeMatrixToFile(matrix, filename)

    implicit none
    real, intent(in) :: matrix(:, :)
    character(*), intent(in) :: filename
    integer :: rows, columns
    integer :: i, j
    integer :: fileunit
    character(len = 10) :: fmt

    rows = size(matrix, 1)
    columns = size(matrix, 2)
    write(fmt, "(a, i0, a)") "(", columns, "f8.2)"

    open(newunit = fileunit, file = filename, status = "replace")
    
    write(fileunit, "(i0)") rows
    write(fileunit, "(i0)") columns

    do i = 1, rows
        write(fileunit, fmt) (matrix(i, j), j = 1, columns)
    end do
    
    close(fileunit)
end subroutine writeMatrixToFile

subroutine transposeMatrix(matrix)
    real, allocatable, intent(inout) :: matrix(:, :)
    real, allocatable :: temp(:, :)

    allocate(temp(size(matrix, 2), size(matrix, 1)))
    temp = transpose(matrix)
    deallocate(matrix)
    allocate(matrix(size(temp, 1), size(temp, 2)))
    matrix = temp
    deallocate(temp)
    
end subroutine transposeMatrix

end module utils

