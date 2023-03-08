# SLURM
[Мануал от авторов](https://slurm.schedmd.com/man_index.html)

## Информация об очередях

```bash
sinfo -s
```

## Информация об узле/разделе/задаче

```bash
scontrol show node hobbit[01]   # информация о ноде
scontrol show hobbits           # информация об очереди
scontrol show job 123456        # информация о задаче
```

## Просмотр очереди задач

```bash
squeue --user=`whoami`   # свои задачи
squeue --states=RUNNING  # задачи в работе
squeue --long            # подробный вывод
```

## Запуск параллельных задачи

```bash
# 4 потока
# очередь hobbits
# исполняемый файл ./a.out
srun -n 4 -p hobbits ./a.out
```

## Удаление задачи

```bash
# удаление задачи с ID = 123
scancel 123

# удаление всех задач пользователя studentmpi
scancel -u studentmpi
```