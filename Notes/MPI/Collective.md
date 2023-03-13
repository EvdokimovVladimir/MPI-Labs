# Коллективный обмен сообщениями

## Синхронизация
```fortran
integer :: comm     ! коммуникатор
integer :: err      ! (output) метка ошибки

call MPI_BARRIER(comm, err)
```

## Широкое распространение (один-всем)

```fortran
<type> :: buf               ! буфер, из которого будут отправлены данные
integer :: count            ! количество данных в единицах mpi_datatype
integer :: mpi_datatype     ! тип отправляемых данных
integer :: rootID           ! ID рассылателя
integer :: comm             ! идентификатор коммуникатора
integer :: err              ! (output) метка ошибки

call MPI_BCAST(buf, count, mpi_datatype, rootID, comm, err)
```

## Рассылка фрагментов массива (один-каждому)

Для `MPI_SCATTER`: данные из `bufRecv(ID+1)` будут отправлены процессу `ID`.

Для `MPI_SCATTERV`: данные длиной `counts(ID+1)` из `bufSend(displacements(ID+1))` будут отправлены процессу `ID`.

```fortran
<type> :: bufSend(*)                ! буфер, из которого будут отправлены данные
integer :: countSend                ! количество отправляемых данных в единицах mpi_datatypeSend
integer :: mpi_datatypeSend         ! тип отправляемых данных

integer :: counts(*)                ! массив с количеством отправляемых данных каждому процессу
integer :: displacements(*)         ! массив со смещениями относительно начала bufSend

<type> :: bufRecv                   ! (output) буфер, куда будут приняты данные
integer :: countRecv                ! количество принимаемых данных в единицах mpi_datatypeRecv
integer :: mpi_datatypeRecv         ! тип принимаемых данных

integer :: rootID                   ! ID рассылателя
integer :: comm                     ! идентификатор коммуникатора
integer :: err                      ! (output) метка ошибки

call MPI_SCATTER(bufSend, countSend, mpi_datatypeSend, 
bufRecv, countRecv, mpi_datatypeRecv, 
rootID, comm, err)

call MPI_SCATTERV(bufSend, counts, displacements, mpi_datatypeSend, 
bufRecv, countRecv, mpi_datatypeRecv, 
rootID, comm, err)
```


## Сборка фрагментов массива (каждый-одному)

Для `MPI_GATHER`: данные, отправленные процессом `ID`, будут получены в `bufRecv(ID+1)`.

Для `MPI_GATHERV`: данные длиной `counts(ID+1)`, отправленные процессом `ID`, будут получены в `bufRecv(displacements(ID+1))`.

```fortran
<type> :: bufSend                   ! буфер, из которого будут отправлены данные
integer :: countSend                ! количество отправляемых данных в единицах mpi_datatypeSend
integer :: mpi_datatypeSend         ! тип отправляемых данных

<type> :: bufRecv(*)                ! (output) буфер, куда будут приняты данные
integer :: countRecv                ! количество принимаемых данных в единицах mpi_datatypeRecv
integer :: mpi_datatypeRecv         ! тип принимаемых данных

integer :: counts(*)                ! массив с количеством принимаемых данных от каждого процесса
integer :: displacements(*)         ! массив со смещениями относительно начала bufRecv

integer :: rootID                   ! ID получателя
integer :: comm                     ! идентификатор коммуникатора
integer :: err                      ! (output) метка ошибки

call MPI_GATHER(bufSend, countSend, mpi_datatypeSend, 
bufRecv, countRecv, mpi_datatypeRecv, 
rootID, comm, err)

call MPI_GATHERV(bufSend, countSend, mpi_datatypeSend, 
bufRecv, counts, displacements, mpi_datatypeRecv, 
rootID, comm, err)
```

## Сборка массива с сохранением у каждого (все-каждому)

Условно: `MPI_ALLGATHER = MPI_GATHER + MPI_BCAST`

Для `MPI_ALLGATHER`: данные, отправленные процессом `ID`, будут получены в `bufRecv(ID+1)`.

Для `MPI_ALLGATHERV`: данные длиной `counts(ID+1)`, отправленные процессом `ID`, будут получены в `bufRecv(displacements(ID+1))`.

```fortran
<type> :: bufSend                   ! буфер, из которого будут отправлены данные
integer :: countSend                ! количество отправляемых данных в единицах mpi_datatypeSend
integer :: mpi_datatypeSend         ! тип отправляемых данных

<type> :: bufRecv(*)                ! (output) буфер, куда будут приняты данные
integer :: countRecv                ! количество принимаемых данных в единицах mpi_datatypeRecv
integer :: mpi_datatypeRecv         ! тип принимаемых данных

integer :: counts(*)                ! массив с количеством принимаемых данных от каждого процесса
integer :: displacements(*)         ! массив со смещениями относительно начала bufRecv

integer :: comm                     ! идентификатор коммуникатора
integer :: err                      ! (output) метка ошибки

call MPI_ALLGATHER(bufSend, countSend, mpi_datatypeSend, 
bufRecv, countRecv, mpi_datatypeRecv, 
comm, err)

call MPI_ALLGATHERV(bufSend, countSend, mpi_datatypeSend, 
bufRecv, counts, displacements, mpi_datatypeRecv, 
comm, err)
```

## Обмен

`ID:bufSend(ID2+1) -> ID2:bufRecv(ID+1)`

```fortran
<type> :: bufSend                   ! буфер, из которого будут отправлены данные
integer :: countSend                ! количество отправляемых данных в единицах mpi_datatypeSend
integer :: mpi_datatypeSend         ! тип отправляемых данных

integer :: countsSend(*)            ! массив с количеством отправляемых данных каждому процессу
integer :: displacementsSend(*)     ! массив со смещениями относительно начала bufSend

<type> :: bufRecv(*)                ! (output) буфер, куда будут приняты данные
integer :: countRecv                ! количество принимаемых данных в единицах mpi_datatypeRecv
integer :: mpi_datatypeRecv         ! тип принимаемых данных

integer :: countsRecv(*)            ! массив с количеством получаемых данных от каждого процесса
integer :: displacementsRecv(*)     ! массив со смещениями относительно начала bufRecv

integer :: comm                     ! идентификатор коммуникатора
integer :: err                      ! (output) метка ошибки

call MPI_ALLTOALL(bufSend, countSend, mpi_datatypeSend, 
bufRecv, countRecv, mpi_datatypeRecv, 
comm, err)

call MPI_ALLTOALLV(bufSend, countsSend, displacementsSend, mpi_datatypeSend, 
bufRecv, countsRecv, displacementsRecv, mpi_datatypeRecv, 
comm, err)
```
