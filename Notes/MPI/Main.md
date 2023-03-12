# Заготовка кода
```fortran
program sample
    implicit none
    include "mpif.h"

    ! MPI variables
    integer :: err      ! error signal variable
    integer :: myID		! process ID
    integer :: nprocs	! number of processes
    
    ! initialization of MPI
    call MPI_INIT(err)
    call MPI_COMM_SIZE(MPI_COMM_WORLD, nprocs, err)
    call MPI_COMM_RANK(MPI_COMM_WORLD, myID, err)
    
    write(*,*) "Hello, World! I am process ", myID, "of", nprocs, "process(es)"
    
    ! finalization of MPI
    call MPI_FINALIZE(err)

end program sample
```

# Типы данных

|          MPI           |           Fortran            |
| :--------------------: | :--------------------------: |
|     `MPI_INTEGER`      |          `INTEGER`           |
|       `MPI_REAL`       |            `REAL`            |
| `MPI_DOUBLE_PRECISION` |      `DOUBLE PRECISION`      |
|     `MPI_COMPLEX`      |          `COMPLEX`           |
|     `MPI_LOGICAL`      |          `LOGICAL`           |
|    `MPI_CHARACTER`     |        `CHARACTER(1)`        |
|       `MPI_BYTE`       | 8 бит, для не типизированных |
|      `MPI_PACKED`      |       для упакованных        |


# Процедуры общего назначения

`MPI_COMM_WORLD` —— глобальный коммуникатор

## Инициализация
```fortran
integer :: err  ! (output) метка ошибки

call MPI_INIT(err)
```

## Завершение
```fortran
integer :: err  ! метка ошибки

call MPI_FINALIZE(err)
```

## Время в секундах
```fortran
integer :: err              ! (output) метка ошибки
double precision :: time    ! (output) время

time = MPI_WTIME(err)
```

## Разрешение таймера
```fortran
integer :: err              ! (output) метка ошибки
double precision :: tick    ! (output) разрешение

tick = MPI_WTICK(err)
```

# Получение информации о коммуникаторе
## Количество процессов в коммуникаторе
```fortran
integer :: comm     ! коммуникатор
integer :: nprocs   ! (output) число процессов
integer :: err      ! (output) метка ошибки

call MPI_COMM_SIZE(comm, nprocs, err)
```

## Номер текущего процесса в коммуникаторе
```fortran
integer :: comm     ! коммуникатор
integer :: myID     ! (output) номер процесса
integer :: err      ! (output) метка ошибки

call MPI_COMM_RANK(comm, myID, err)
```

## Имя узла

```fortran
character*(MPI_MAX_PROCESSOR_NAME) name     ! (output) имя узла
integer :: len                              ! (output) записанная длина
integer :: err                              ! (output) метка ошибки

call MPI_GET_PROCESSOR_NAME(name, len, err)
```
