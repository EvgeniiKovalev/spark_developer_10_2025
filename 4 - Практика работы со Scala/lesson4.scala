package ru.otus.scala.developer
import scala.io.StdIn._
import java.util.Scanner

@main
def lesson4(): Unit = {
  val scanner = new Scanner(System.in)

  // 1. Создайте переменные следующих типов :
  //  Целое число (Int) для хранения возраста.
  //  Дробное число (Double) для хранения веса.
  //  Строку(String) для хранения имени.
  //  Логическое значение (Boolean) для хранения статуса (студент или не студент).
  var age: Int = 10;
  val weight: Double = 40.02
  var name: String = "Иван"
  var isStudent: Boolean = false

  // 2. Выведите значения всех переменных на экран с помощью функции println.
  println(f"age=$age%d; weight=$weight%5.2f; name=$name%s; isStudent=$isStudent%s")

  // 3. Напишите функцию, которая принимает два целых числа и возвращает их сумму
  def sum(a: Int, b: Int): Int = {a + b}

  // 3.1. Вызовите эту функцию с любыми двумя числами и выведите результат на экран.
  println(sum(1,2))

  // 4.0. Напишите функцию, которая принимает возраст и возвращает строку "Молодой",
  // если возраст меньше 30, и "Взрослый", если возраст 30 или больше.
  def age_young(age: Int) : String = {
    if (age < 30) "Молодой" else "Взрослый"
  }

  // 4.1. Вызовите эту функцию с вашей переменной возраста и выведите результат на экран.
  println(age_young(age))

  // 5.0. Напишите цикл, который выводит на экран числа от 1 до 10
  for (i <- 1 to 10) { print(i + (if (i < 10) " " else "\n"))}

  // 5.1. Создайте список имен студентов и выведите каждое имя на экран с помощью цикла.
  for (i <- 1 to 10) { print("student" + i + (if (i < 10) " " else ""))}

  println()
  // 6.1 Напишите программу, которая выполняет следующие действия :
  // Запрашивает у пользователя ввод имени, возраста и статуса(студент или нет).
  // Использует написанные выше функции и выводит на экран информацию о пользователе и его возрастную категорию.\
  name = readLine("Введите имя: ")
  print("Введите возраст: ")
  age = scanner.nextInt()
  print("Студент (true/false)?: ")
  isStudent = scanner.nextBoolean()
  println(f"age=${age_young(age)}%s; name=$name%s; isStudent=$isStudent%s")

  println()
  // Создан список чисел от 1 до 10.
  val range = 1 to 10
  // Использован for comprehension для создания списка квадратов чисел.
  println("Квадраты чисел: ")
  val sqNum = for i <- range yield i*i
  sqNum.foreach(println)

  println()
  // Использован for comprehension для создания списка, содержащего только чётные числа.
  val sqEvenNum = for i <- range if (i % 2 == 0) yield i
  println("Чётные: ")
  sqEvenNum.foreach(println)
}