# Общее описание

В этом репозитории собраны заметки и код лабораторных работ по курсу "Прикладные физико-технические методы исследования".

В ходе курса изучаются:

1. Основы Linux и CLI
2. Программирование на Фортране
3. Библиотека для параллельных вычислений MPI
4. Работа с кластером под управлением SLURM

# Лабораторные работы

1. [Транспонирование квадратной матрицы на 4 процессах][LW1 readme]
2. [Вычисление числа Пи с помощью разложения в ряд Тейлора][LW2 readme]
3. [Вычисление числа Пи с методом Монте-Карло][LW3 readme]
4. [Перемножение матриц ленточным способом][LW4 readme]
5. [Решение СЛАУ методом Якоби][LW5 readme]
6. [Решение уравнения Лапласа методом Якоби][LW6 readme]

Каждая лабораторная работа выделена в отдельную папку. Файлы с исходным кодом собраны в подпапках `src`. Необходимые для работы программы файлы лежат в корне папки лабораторной работы. Также в корне попок лежат Makefile'ы для сборки программ утилитой `make`.

К каждой лабораторной работе написано описание `README.md`. В нём описана задача, требования к программе и даны краткие теоретические сведения. Также приведён псевдокод программы.

[LW1 readme]: /LW1_Matrix_transpose/README.md
[LW2 readme]: /LW2_Pi_series/README.md
[LW3 readme]: /LW3_Pi_Monte_Carlo/README.md
[LW4 readme]: /LW4_Matrix_Multiplication/README.md
[LW5 readme]: /LW5_SLAE_Jacoby/README.md
[LW6 readme]: /LW6_Laplace/README.md

# Дополнительные материалы

1. ["Параллельное программирование с использованием технологии MPI", Антонов А. С.][MPI book] — Хорошая методичка с описанием подпрограмм и примерами кода
2. [Методическое пособие по курсу "Многопроцессорные системы и параллельное программирование", Дацюк В. Н., ...][MPS and PP] — Схожая методичка, но в HTML и с картинками
3. [Параллельное программирование в интерфейсе MPI. Сборник лабораторных работ, Оленев Н. Н.][PP in MPI] — Ещё одна методичка с другими картинками
4. [The GNU Fortran Compiler][gfortran] — Описание компилятора `gfortran` со списком встроенных процедур
5. [Tutorials Point: Fortran][Fortran Tutorial Point] — Хороший туториал по Фортрану, есть все базовые вещи
6. [Fortran Best Practices][Fortran BP] — рекомендации по программированию в Фортране


[MPI book]: https://parallel.ru/sites/default/files/tech/tech_dev/MPI/mpibook.pdf
[MPS and PP]: http://rsusu1.rnd.runnet.ru/tutor/method/index.html
[PP in MPI]: http://www.ccas.ru/mmes/educat/lab04k/
[gfortran]: https://gcc.gnu.org/onlinedocs/gcc-4.8.4/gfortran/index.html#Top
[Fortran Tutorial Point]: https://www.tutorialspoint.com/fortran/index.htm
[Fortran BP]: https://www.fortran90.org/index.html

# Дополнительные программы

Для прикладных целей, связанных с лабораторными работами, написаны дополнительные программы:

1. [Генератор случайных матриц][Random Matrix Generator]


[Random Matrix Generator]: /extra/Random_Martix_Generate/README.md