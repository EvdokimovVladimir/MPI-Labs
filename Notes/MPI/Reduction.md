## Операции вычисления

|   Функция    |          Описание          | Допустимые типы |
| :----------: | :------------------------: | :-------------: |
|  `MPI_SUM`   |           сумма            |     I, R, C     |
|  `MPI_PROD`  |        произведение        |     I, R, C     |
|  `MPI_MAX`   |          максимум          |     I, R, C     |
|  `MPI_MIN`   |          минимум           |     I, R, C     |
|  `MPI_LAND`  |        логическое и        |        L        |
|  `MPI_LOR`   |       логическое или       |        L        |
|  `MPI_LXOR`  | логическое исключающее или |        L        |
|  `MPI_BAND`  |        побитовое и         |      I, B       |
|  `MPI_BOR`   |       побитовое или        |      I, B       |
|  `MPI_BXOR`  | побитовое исключающее или  |      I, B       |
| `MPI_MAXLOC` |    максимум и положение    |   I, R, C, DP   |
| `MPI_MINLOC` |    минимум и положение     |   I, R, C, DP   |

Типы:
- I - integer
- R - real
- C - complex
- L - logical
- B - byte
- DP - double precision

## Глобальное вычисление с сохранением результата у одного

Вычислит `mpi_operation` для `bufSend` со всех процессов и отправит на `rootID` процесс в `bufRecv`.

```fortran
<type> :: bufSend(*)            ! буфер, откуда будут отправлены данные
<type> :: bufRecv(*)            ! (output) буфер, куда будут приняты данные
integer :: count                ! количество данных в единицах mpi_datatype
integer :: mpi_datatype         ! тип принимаемых данных
integer :: mpi_operation        ! выполняемая операция
integer :: rootID               ! ID получателя
integer :: comm                 ! идентификатор коммуникатора
integer :: err                  ! (output) метка ошибки

call MPI_REDUCE(bufSend, bufRecv, count, mpi_datatype, mpi_operation, rootID, comm, err)
```

## Глобальное вычисление с сохранением результата у всех

Вычислит `mpi_operation` для наборов каждого элемента массива `bufSend` со всех процессов и отправит "сумму" на все процессы в `bufRecv`.

```fortran
<type> :: bufSend(*)            ! буфер, откуда будут отправлены данные
<type> :: bufRecv(*)            ! (output) буфер, куда будут приняты данные
integer :: count                ! количество данных в единицах mpi_datatype
integer :: mpi_datatype         ! тип принимаемых данных
integer :: mpi_operation        ! выполняемая операция
integer :: comm                 ! идентификатор коммуникатора
integer :: err                  ! (output) метка ошибки

call MPI_ALLREDUCE(bufSend, bufRecv, count, mpi_datatype, mpi_operation, comm, err)
```


## Глобальное вычисление с сохранением части результата у каждого
Условно: `MPI_REDUCE_SCATTER = MPI_REDUCE + MPI_SCATTER`

Вычислит `mpi_operation` для наборов каждого элемента массива `bufSend` со всех процессов и отправит "сумму" `i`-ого набора на `(i - 1)` процесс в `bufRecv`.

```fortran
<type> :: bufSend(*)            ! буфер, откуда будут отправлены данные
<type> :: bufRecv(*)            ! (output) буфер, куда будут приняты данные
integer :: counts(*)            ! массив с количеством принимаемых данных от каждого процесса
integer :: mpi_datatype         ! тип принимаемых данных
integer :: mpi_operation        ! выполняемая операция
integer :: comm                 ! идентификатор коммуникатора
integer :: err                  ! (output) метка ошибки

call MPI_REDUCE_SCATTER(bufSend, bufRecv, count, mpi_datatype, mpi_operation, comm, err)
```

## Последовательное вычисление

Последовательно вычислит `mpi_operation` для наборов каждого элемента массива `bufSend` со всех процессов и отправит `i`-ую частную "сумму" на `(i - 1)` процесс в `bufRecv`.

```fortran
<type> :: bufSend(*)            ! буфер, откуда будут отправлены данные
<type> :: bufRecv(*)            ! (output) буфер, куда будут приняты данные
integer :: counts(*)            ! массив с количеством принимаемых данных от каждого процесса
integer :: mpi_datatype         ! тип принимаемых данных
integer :: mpi_operation        ! выполняемая операция
integer :: comm                 ! идентификатор коммуникатора
integer :: err                  ! (output) метка ошибки

call MPI_SCAN(bufSend, bufRecv, count, mpi_datatype, mpi_operation, comm, err)
```
