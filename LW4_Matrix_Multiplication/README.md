# Лабораторная работа №4 "Перемножение матриц ленточным способом"

## Необходимо

Умножить матрицу, сохранённую в файле `A`, на матрицу, сохранённую в файле `B`.

Дополнительно:
1. вывести время выполнения программы в терминал
2. сохранить матрицу С в файл
3. разбить матрицу В на вертикальные ленты, которые в процессе расчёта сдвигать по процессорам

## Матричное умножение

1. Правило: строка на столбец.
2. Число столбцов в первой матрице должно быть равно числу строк во второй матрице.

$$ C_{ \{ m,k \} } = A_{ \{ m,n \} } \cdot B_{ \{ n,k \} } $$

$$ c_{i,j} = \displaystyle\sum_{k=1}^{n} a_{i,k} \cdot b_{k,j} $$

## Псевдокод
```
если (процесс == 0) {
    прочитать матрицу А из файла
    прочитать матрицу В из файла

    рассчитать число строк в ленте для каждого процесса
}

разослать размеры лент матрицы А на каждый процесс
разослать ленты матрицы А на каждый процесс

разослать размерность матрицы В на все процессы
разослать матрицу В на все процессы

рассчитать фрагмент матрицы С

собрать фрагменты матрицы С на 0 процессе

если (процесс == 0) {
    вывести в терминал собранную матрицу С
}
```

## Изучаемые элементы

- `MPI_SCATTERV` — рассылка разных данных разной длины всем процессам
- `MPI_GATHERV` — сборка разных данных разной длины со всех процессов