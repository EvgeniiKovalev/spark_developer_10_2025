package ru.otus.scala.developer
import scala.io.StdIn._
import java.util.Scanner

@main
def main(): Unit = {
  val scanner = new Scanner(System.in)

  // 1.Напишите программу на Scala, которая принимает имя пользователя с клавиатуры
  //    и выводит приветственное сообщение.
  val name = readLine("Введите имя: ")
  println(s"Привет \"$name\"")

  // 2.Напишите функцию, которая принимает два целых числа и возвращает их сумму.
  def sum(a : Int, b : Int) : Int = {a + b}



  // 3.Создайте список из нескольких чисел (например, List(1, 2, 3, 4, 5))
  val l: List[Int] = List(1, 2, 3, 4, 5)

  // и примените к нему функцию, которая увеличивает каждое число на 1.
  val newl = l.map(sum(1,_))

  // Выведите получившийся список на экран.
  // вариант 1
  newl.foreach(print)


  println()
  // вариант 2
  for (i <- newl) {print(i)}


  println()
  // 4.Напишите программу, которая принимает число с клавиатуры и выводит
  // , является ли оно четным или нечетным.
  val num: Int = scanner.nextInt()
  val res = if (num %2 == 0) "чётное" else "нечетное"
  println(res)


  // 5.Создайте программу, которая принимает строку и выводит её длину.
  print("Введите строку:")
  val s = scanner.next()
  println(s"длина введеной строки = ${s.length}")


  //  6.Напишите функцию
  //  , которая принимает список строк и возвращает новую строку
  //  , состоящую из всех строк списка
  //  , разделенных пробелами.
  val list_string: List[String] = List("1", "2")

  //вариант 1
  def agg_list1(l: List[String]): String = {
    var res = ""
    for (s <- l) {
       res = res + (if (res.length > 0) " " else "") + s
    }
    return res
  }

  println(agg_list1(list_string))

  //вариант 2, с mkString аналогом  String.join(" ", list) в java 8+
  def agg_list2(l: List[String]): String = l.mkString(" ")
  println(agg_list2(list_string))
}


