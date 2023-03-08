# Передача сообщений точка-точка

## Типы данных

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

## Типы сообщений

| Режим  выполнения            | С блокировкой | Без блокировки |
| ---------------------------- | :-----------: | :------------: |
| Стандартная отправка         |  `MPI_SEND`   |  `MPI_ISEND`   |
| Синхронная отправка          |  `MPI_SSEND`  |  `MPI_ISSEND`  |
| Буферизованная отправка      |  `MPI_BSEND`  |  `MPI_IBSEND`  |
| Отправка по готовности       |  `MPI_RSEND`  |  `MPI_IRSEND`  |
| Получение сообщения          |  `MPI_RECV`   |  `MPI_IRECV`   |
| Получение данных о сообщении |  `MPI_PROBE`  |  `MPI_IPROBE`  |

### Блокирующие и неблокирующие процедуры
Блокирующие процедуры отправки возвращают управление когда все пересылаемые данные помещены в буфер.  
При получении данных —— пока все данные не будут получены из буфера.  
Сразу после блокирующей процедуры можно работать с полученными или отправленными данными. Гарантируется их актуальность.

Неблокирующие процедуры инициируют приём или передачу и сразу возвращают управление. Приём и передача происходит одновременно с основным кодом.  
При работе с полученными или отправленными данными возможны ошибки. Актуальность не гарантируется. Для проверки статуса используются дополнительные процедуры `MPI_WAIT` `MPI_TEST`.

### Стандартная отправка
Сообщение записываются в буфер приёма независимо от инициализации приёма. Факт приёма `MPI_RECV` не проверяется.

Процедура локальная. Не зависит от других процессов.

Если сообщение большое, то стандартная отправка ведёт себя как синхронная (`MPI_SSEND`).

### Синхронная отправка
Процедура ждёт инициализации приёма, после чего отправляет данные. Выполнение завершается при получении данных `MPI_RECV`.

Процедура НЕлокальная. Завершение зависит от получателя.

### Буферизованная отправка
Сообщение записываются в выделенный буфер на стороне отправителя независимо от инициализации приёма `MPI_RECV`. 

Процедура локальная. Не зависит от других процессов.

Необходимо выделить буфер с помощью `MPI_BUFFER_ATTACH`.

### Отправка по готовности
Можно использовать только после инициализации приёма `MPI_RECV`. Отправляет сообщение напрямую. Сокращает протокол взаимодействия между отправителем и получателем.

Процедура НЕлокальная. Завершение зависит от получателя.

Необходимо дополнительно гарантировать предварительную инициализацию приёма, например явно с помощью `MPI_BARRIER` или неявно `MPI_SSEND`.


## Синтаксис процедур отправки

Отправляет содержимое буфера `buf` (может быть простой переменной) типа `mpi_datatype` данные длинны `count` получателю `destID` в коммуникаторе `comm` с тегом `tag`. Метка ошибки записывается в `err`.

Для варианта без блокировки в параметр `request` записывается идентификатор, по которому можно отследить статус отправки с помощью `MPI_TEST` или дождаться отправки с помощью `MPI_WAIT`.

```fortran
<type> buf(*)               ! буфер, из которого будут отправлены данные
integer :: count            ! количество данных в единицах mpi_datatype
integer :: mpi_datatype     ! тип отправляемых данных
integer :: destID           ! ID получателя в коммуникаторе
integer :: tag              ! тег сообщения
integer :: comm             ! идентификатор коммуникатора
integer :: err              ! (output) метка ошибки
integer :: request          ! (output) идентификатор для отслеживания статуса

call MPI_SEND(buf, count, mpi_datatype, destID, tag, comm, err)
call MPI_SSEND(buf, count, mpi_datatype, destID, tag, comm, err)
call MPI_BSEND(buf, count, mpi_datatype, destID, tag, comm, err)
call MPI_RSEND(buf, count, mpi_datatype, destID, tag, comm, err)

call MPI_ISEND(buf, count, mpi_datatype, destID, tag, comm, request, err)
call MPI_ISSEND(buf, count, mpi_datatype, destID, tag, comm, request, err)
call MPI_IBSEND(buf, count, mpi_datatype, destID, tag, comm, request, err)
call MPI_IRSEND(buf, count, mpi_datatype, destID, tag, comm, request, err)
```

## Работа с буфером отправки
Размер буфера должен быть больше максимального размера сообщения не менее чем на `MPI_BSEND_OVERHEAD`.  
Ассоциированный с буфером массив не рекомендуется использовать в программе для других целей.

### Ассоциация массива буферу
```fortran
<type> buf(*)       ! буфер, который будет использоваться при посылке сообщений с буферизацией
integer :: size     ! размер буфера
integer :: err      ! (output) метка ошибки

call MPI_BUFFER_ATTACH(buf, size, err)
```

### Освобождение массива

Процедура блокирующая. Выход произойдет после отправки всех сообщений из буфера.

```fortran
<type> buf(*)       ! буфер, который будет использоваться при посылке сообщений с буферизацией
integer :: size     ! размер буфера
integer :: err      ! (output) метка ошибки

call MPI_BUFFER_DETACH(buf, size, err)
```

## Получение

Получает в буфер `buf` (может быть простой переменной) типа `mpi_datatype` данные длинны `count` от отправителя `srcID` в коммуникаторе `comm` с тегом `tag`. Атрибуты сообщения записываются в `status`, метка ошибки —— в `err`.

Для варианта без блокировки в параметр `request` записывается идентификатор, по которому можно отследить статус приёма с помощью `MPI_TEST` или дождаться приёма с помощью `MPI_WAIT`.

```fortran
<type> buf(*)                       ! (output) буфер, куда будут приняты данные
integer :: count                    ! количество данных в единицах mpi_datatype
integer :: mpi_datatype             ! тип принимаемых данных
integer :: srcID                    ! ID отправителя в коммуникаторе
integer :: tag                      ! тег сообщения
integer :: comm                     ! идентификатор коммуникатора
integer :: status(MPI_STATUS_SIZE)  ! (output) массив атрибутов сообщения
integer :: err                      ! (output) метка ошибки
integer :: request                  ! (output) идентификатор для отслеживания статуса

call MPI_RECV(buf, count, mpi_datatype, srcID, tag, comm, status, err)
call MPI_IRECV(buf, count, mpi_datatype, srcID, tag, comm, status, request, err)
```

### Метки-джокеры

`MPI_ANY_SOURCE` —— получение от любого ID  
`MPI_ANY_TAG` —— получение с любым тегом сообщения

### Атрибуты сообщения

`status(MPI_SOURCE)` —— ID отправителя  
`status(MPI_TAG)` —— тег сообщения  
`status(MPI_ERROR)` —— код ошибки

### Число принятых/принимаемых элементов

По атрибутам сообщения определяет его длину. Работает как с принятыми (после `MPI_RECV`), так и с принимаемыми сообщениями (`MPI_PROBE`).

```fortran
integer :: status(MPI_STATUS_SIZE)  ! массив атрибутов сообщения
integer :: count                    ! (output) количество данных в единицах mpi_datatype
integer :: mpi_datatype             ! тип принимаемых данных
integer :: err                      ! (output) метка ошибки

MPI_GET_COUNT(status, count, mpi_datatype, err)
```

### Получение информации о принимаемом сообщении

Процедура получает не само сообщение, а только данные о нём. После вызова можно узнать число принимаемых элементов с помощью `MPI_GET_COUNT`.

При `canBeReceived == .TRUE.` вариант без блокировки `MPI_IPROBE` не отличается от `MPI_PROBE`.

```fortran
integer :: srcID                    ! ID отправителя в коммуникаторе
integer :: tag                      ! тег сообщения
integer :: comm                     ! идентификатор коммуникатора
integer :: status(MPI_STATUS_SIZE)  ! (output) массив атрибутов сообщения
integer :: err                      ! (output) метка ошибки
logical :: canBeReceived            ! (output) флаг возможности приёма

MPI_PROBE(srcID, tag, comm, status, err)
MPI_IPROBE(srcID, tag, comm, canBeReceived, status, err)
```

## Парная приём-передача

Для предотвращения тупиковых ситуаций можно использовать совместную приём-передачу данных.

### Обмен данными
Отправляет содержимое буфера `bufSend` (может быть простой переменной) типа `mpi_datatypeSend` данные длинны `countSend` получателю `destID` в коммуникаторе `comm` с тегом `tagSend`.

Получает в буфер `bufRecv` (может быть простой переменной) типа `mpi_datatypeRecv` данные длинны `countRecv` от отправителя `srcID` в коммуникаторе `comm` с тегом `tagRecv`. Атрибуты сообщения записываются в `status`. 

Метка ошибки записывается в `err`.

Буферы `bufSend` и `bufRecv` не должны пересекаться.

```fortran
<type> bufSend(*)                   ! буфер, из которого будут отправлены данные
integer :: countSend                ! количество отправляемых данных в единицах mpi_datatypeSend
integer :: mpi_datatypeSend         ! тип отправляемых данных
integer :: destID                   ! ID получателя в коммуникаторе
integer :: tagSend                  ! тег отправляемого сообщения

<type> bufRecv(*)                   ! (output) буфер, куда будут приняты данные
integer :: countRecv                ! количество принимаемых данных в единицах mpi_datatypeRecv
integer :: mpi_datatypeRecv         ! тип принимаемых данных (см. выше)
integer :: srcID                    ! ID отправителя в коммуникаторе
integer :: tagRecv                  ! тег принимаемого сообщения
integer :: comm                     ! идентификатор коммуникатора
integer :: status(MPI_STATUS_SIZE)  ! (output) массив атрибутов сообщения
integer :: err                      ! (output) метка ошибки

call MPI_SENDRECV(bufSend, countSend, mpi_datatypeSend, destID, tagSend, 
bufRecv, countRecv, mpi_datatypeRecv, srcID, tagRecv, 
comm, status, err)
```


### Обмен данными одного типа с замещением посылаемых данных на принимаемые
Отправляет содержимое буфера `buf` (может быть простой переменной) типа `mpi_datatype` данные длинны `countSend` получателю `destID` в коммуникаторе `comm` с тегом `tagSend`.

Получает в буфер `buf` (может быть простой переменной) типа `mpi_datatype` данные длинны не более `countSend` от отправителя `srcID` в коммуникаторе `comm` с тегом `tagRecv`. Атрибуты сообщения записываются в `status`. 

Метка ошибки записывается в `err`.

Принимаемые и отправляемые данные должны быть одного типа `mpi_datatype`. Принимаемые данные должны быть не длиннее отправляемых `countSend`.

```fortran
<type> buf(*)                       ! (output) буфер, из которого будут отправлены и в который будут получены данные
integer :: countSend                ! количество отправляемых данных в единицах mpi_datatype
integer :: mpi_datatype             ! тип отправляемых и получаемых данных
integer :: destID                   ! ID получателя в коммуникаторе
integer :: tagSend                  ! тег отправляемого сообщения

integer :: srcID                    ! ID отправителя в коммуникаторе
integer :: tagRecv                  ! тег принимаемого сообщения
integer :: comm                     ! идентификатор коммуникатора
integer :: status(MPI_STATUS_SIZE)  ! (output) массив атрибутов сообщения
integer :: err                      ! (output) метка ошибки


call MPI_SENDRECV_REPLACE(buf, countSend, mpi_datatype, destID, tagSend, srcID, tagRecv, comm, status, err)
```


## Проверка завершённости неблокирующих процедур

|                     |    Ожидание    |    Проверка    |
| ------------------- | :------------: | :------------: |
| Конкретная операция |   `MPI_WAIT`   |   `MPI_TEST`   |
| Все операции        | `MPI_WAITALL`  | `MPI_TESTALL`  |
| Одна операция       | `MPI_WAITANY`  | `MPI_TESTANY`  |
| Больше одной        | `MPI_WAITSOME` | `MPI_TESTSOME` |


### Ожидание и проверка выполнения конкретной операции

`MPI_WAIT` **ожидает** завершения выполнения неблокирующей процедуры с идентификатором `request`. Для операции неблокирующего приёма заполняется массив атрибутов сообщения `status`.  
После выполнения `request == MPI_REQUEST_NULL`.  
Гарантируется завершение приёма или передачи сообщения.

`MPI_TEST` **проверяет** завершение выполнения неблокирующей процедуры с идентификатором `request`.  
Если операция завершена, поднимается флаг `isCompleted == .TRUE.` и `request == MPI_REQUEST_NULL`, иначе `isCompleted == .FALSE.` и `request` не изменяется.  
Для операции неблокирующего приёма при завершённости заполняется массив атрибутов сообщения `status`.

```fortran
integer :: request                  ! идентификатор операции
integer :: status(MPI_STATUS_SIZE)  ! (output) массив атрибутов сообщения
integer :: err                      ! (output) метка ошибки
logical :: isCompleted              ! (output) флаг завершённости операции

MPI_WAIT(request, status, err)
MPI_TEST(request, isCompleted, status, err)
```

### Ожидание и проверка выполнения всех операций

`MPI_WAITALL` **ожидает** завершения выполнения всех из `count` неблокирующих процедур, идентификаторы которых описаны в массиве `requests`.  
После выполнения все элементы массива `request` заполняются `MPI_REQUEST_NULL`.  
Гарантируется завершение приёма или передачи всех сообщений.  
Для операции неблокирующего приёма при завершённости заполняются элементы массива атрибутов сообщений `statuses`.

`MPI_TESTALL` **проверяет** завершение выполнения всех из `count` неблокирующих процедур, идентификаторы которых описаны в массиве `requests`.  
Если завершены все операции, поднимается флаг `isCompleted == .TRUE.`, все элементы массива `request` заполняются `MPI_REQUEST_NULL`, иначе `isCompleted == .FALSE.`, элементы массива `requests` соответствующие выполненным процедурам заполняются `MPI_REQUEST_NULL`.  
Для операций неблокирующего приёма при завершённости заполняются соответствующие элементы массива атрибутов сообщения `statuses`.

```fortran
integer :: count                            ! число элементов массива requests
integer :: requests(*)                      ! массив идентификаторов операций
integer :: statuses(MPI_STATUS_SIZE,*)      ! (output) массив атрибутов сообщений
integer :: err                              ! (output) метка ошибки
logical :: isCompleted                      ! (output) флаг завершённости операций

MPI_WAITALL(count, requests, statuses, err)
MPI_TESTALL(count, requests, isCompleted, statuses, err)
```

### Ожидание и проверка выполнения одной операции
`MPI_WAITANY` **ожидает** завершения выполнения хотя бы одной из `count` неблокирующих процедур, идентификаторы которых описаны в массиве `requests`.  
После выполнения `requests(index) == MPI_REQUEST_NULL`.  
Если завершилось несколько операций, будет выбрана случайная из них.
Гарантируется завершение приёма или передачи сообщения.  
Для операции неблокирующего приёма при завершённости заполняется массив атрибутов сообщения `status`.

`MPI_TESTANY` **проверяет** завершение выполнения хотя бы одной из `count` неблокирующих процедур, идентификаторы которых описаны в массиве `requests`.  
Если хотя бы одна операция завершена, поднимается флаг `isCompleted == .TRUE.`, в переменную `index` записывается индекс завершённой операции и `requests(index) == MPI_REQUEST_NULL`, иначе `isCompleted == .FALSE.` и `requests` и `index` не изменяются.  
Если завершилось несколько операций, будет выбрана случайная из них.
Для операции неблокирующего приёма при завершённости заполняется массив атрибутов сообщения `status`.

```fortran
integer :: count                    ! число элементов массива requests
integer :: requests(*)              ! массив идентификаторов операций
integer :: index                    ! (output) индекс завершённой операции
integer :: status(MPI_STATUS_SIZE)  ! (output) массив атрибутов сообщения
integer :: err                      ! (output) метка ошибки
logical :: isCompleted              ! (output) флаг завершённости операции

MPI_WAITANY(count, requests, index, isCompleted, status, err)
MPI_TESTANY(count, requests, index, isCompleted, status, err)
```

### Ожидание и проверка выполнения нескольких операции
`MPI_WAITSOME` **ожидает** завершения выполнения хотя бы одной из `count` неблокирующих процедур, идентификаторы которых описаны в массиве `requests`.  
Число завершённых операций записывается в переменную `countFinish`, а индексы завершённых операций в массив `indexes`. После выполнения `requests(indexes(*)) == MPI_REQUEST_NULL`.  
Гарантируется завершение приёма или передачи сообщения.  
Для операции неблокирующего приёма при завершённости заполняется массив атрибутов сообщения `status`.

`MPI_TESTSOME` аналогична `MPI_WAITSOME`, только выход из неё происходит немедленно. Если не завершена ни одна операция, `countFinish == 0`.

```fortran
integer :: count                            ! число элементов массива requests
integer :: requests(*)                      ! массив идентификаторов операций
integer :: countFinish                      ! (output) число завершённых операций
integer :: indexes(*)                       ! (output) массив индексов завершённых операций
integer :: statuses(MPI_STATUS_SIZE,*)      ! (output) массив атрибутов сообщений
integer :: err                              ! (output) метка ошибки

MPI_WAITSOME(count, requests, countFinish, indexes, statuses, err)
MPI_TESTSOME(count, requests, countFinish, indexes, statuses, err)
```