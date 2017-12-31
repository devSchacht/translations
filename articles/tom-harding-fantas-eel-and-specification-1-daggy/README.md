# Спецификация волшебного мира 1: Daggy

*Перевод статьи [Tom Harding](http://www.tomharding.me): [Fantas, Eel, and Specification 1: Daggy](http://www.tomharding.me/2017/03/03/fantas-eel-and-specification/). Опубликовано с разрешения автора.*

Ещё раз привет, Интернет! Как фанатик функционального программирования\* и JavaScript разработчик†, я провожу **много** времени бредя об их скрещивании. В этой серии мы будем смотреть на спецификацию [Fantasy Land](https://medium.com/p/спецификация-fantasy-land-bf81121b58cb) в её полном объёме и пройдемся по примерам, как мы можем использовать типы классов в ней. Однако, прежде чем мы пойдем дальше, нам нужно поговорить о `daggy`.

Daggy — это крошечная библиотека для создания **суммы типов** для функционального программирования. Не беспокойтесь слишком много о том, что это означает, и сосредоточьтесь на двух функциях, которые экспортирует библиотека: `tagged` и `taggedSum`.

## `daggy.tagged(... fields)`

Это очень простой способ для создания типов с одним конструктором. Другими словами, думайте о нем, как о способе для хранения  данных с жёсткой структурой (например, моделей):

```js
//- Координата в 3D пространстве.
//+ Coord :: (Int, Int, Int) -> Coord
const Coord = daggy.tagged('x', 'y', 'z')

//- Линия между двумя координатами.
//+ Line :: (Coord, Coord) -> Line
const Line = daggy.tagged('from', 'to')
```

Результирующая структура довольно понятна:

```js
// Мы можем добавить методы...
Coord.prototype.translate =
  function (x, y, z) {
    // Именованные свойства!
    return Coord(
      this.x + x,
      this.y + y,
      this.z + z
    )
  }

// Автоматически заполнить именованные свойства
const origin = Coord(0, 0, 0)

const myLine = Line(
  origin,
  origin.translate(2, 4, 6)
)
```

В этом нет ничего страшного, если вы до этого использовали систему объектов в JavaScript: всё что на самом деле даёт функция `tagged` — заполняет именованные свойства в объекте. **Это всё.** Маленькая утилита для создания конструкторов с именованными свойствами.

## ```daggy.taggedSum(constructors)```

Теперь для заинтересованных. Подумайте о булевом типе: у него есть два значения: `True` и `False`. Для того, чтобы представлять такую структуру как `Bool`, нам нужно сделать тип с несколькими конструкторами (то, что мы называем **сумма типов**):

```js
const Bool = daggy.taggedSum({
  True: [], False: []
})
```

Мы вызываем разные формы типов через **конструктор типов**: в данном случае, это `True` и `False`, и они не имеют никаких аргументов. Что если мы возьмём наш код из примера `tagged` и создадим более сложный тип?

```js
const Shape = daggy.taggedSum({
  // Square :: (Coord, Coord) -> Shape
  Square: ['topleft', 'bottomright'],

  // Circle :: (Coord, Number) -> Shape
  Circle: ['centre', 'radius']
})
```

В отличии от логических значений, наши конструкторы здесь имеет значения. Они принимают *различные* значения, в зависимости от используемого конструктора, но мы знаем что `Square` и `Circle` наверняка оба конструкторы типа `Shape`. Как это поможет нам?

```js
Shape.prototype.translate =
  function (x, y, z) {
    return this.cata({
      Square: (topleft, bottomright) =>
        Shape.Square(
          topleft.translate(x, y, z),
          bottomright.translate(x, y, z)
        ),

      Circle: (centre, radius) =>
        Shape.Circle(
          centre.translate(x, y, z),
          radius
        )
    })
  }

Square(Coord(2, 2, 0), Coord(3, 3, 0))
.translate(3, 3, 3)
// Square(Coord(5, 5, 3), Coord(6, 6, 3))

Circle(Coord(1, 2, 3), 8)
.translate(6, 5, 4)
// Circle(Coord(7, 7, 7), 8)
```

Как и прежде, мы определяем методы на прототипе `Shape`. Однако `Shape` не *конструктор*, это *тип*: `Shape.Square` и `Shape.Circle` конструкторы.

Это означает, что когда мы пишем метод, мы должны писать то, что будет работать для *всех* форм типа `Shape` и `this.cata` — это киллер фича Daggy. *Кстати, cata сокращение для [catamorphism](http://www.tomharding.me/2017/02/24/reductio-and-abstract-em/)!*

Все что мы делаем, это пробрасываем объект `{ constructor: handler }` в функцию `cata` и соответсвующий конструктор будет вызван, когда метод выполнится. Как мы можем видеть выше, теперь у нас есть метод `translate`, который будет работать для обоих типов `Shape`!

Мы можем даже определить метод для нашего типа `Bool`:

```js
const { True, False } = Bool

// Меняем местами логические значения.
Bool.prototype.invert = function () {
  return this.cata({
    False: () => True,
    True: () => False
  })
}

// Сокращение для Bool.prototype.cata?
Bool.prototype.thenElse =
  function (then, or) {
    return this.cata({
      True: then,
      False: or
    })
  }
```

Как видите, для конструкторов без аргументов, мы используем обработчики без аргументов. Также обратите внимание, что различные конструкторы одной суммы типов могут иметь **совершенно разное число и типы аргументов.** Это будет очень важно, когда мы перейдем к примерам структур из Fantasy Land.

Это все, что нужно знать о `taggedSum`: она позволяет нам создавать типы с несколькими конструкторами и удобно писать методы для них.

## `List`, но не меньший…

Как последний пример `taggedSum` (потому что я *надеюсь*, что с `tagged` всё ясно и понятно), вот связанный список и пара полезных функций:

```js
const List = daggy.taggedSum({
  Cons: ['head', 'tail'], Nil: []
})

List.prototype.map = function (f) {
  return this.cata({
    Cons: (head, tail) => List.Cons(
      f(head), tail.map(f)
    ),

    Nil: () => List.Nil
  })
}

// "Статичный" метод для удобства.
List.from = function (xs) {
  return xs.reduceRight(
    (acc, x) => List.Cons(x, acc),
    List.Nil
  )
}

// И обратное преобразование для удобства!
List.prototype.toArray = function () {
  return this.cata({
    Cons: (x, acc) => [
      x, ... acc.toArray()
    ],

    Nil: () => []
  })
}

// [3, 4, 5]
console.log(
  List.from([1, 2, 3])
  .map(x => x + 2)
  .toArray())
```

Конечно, мы можем создать список с двумя конструкторами, `Cons` и `Nil` (как мы сделали с `[x, ... xs]` и `[]` в [моем последнем посте](http://www.tomharding.me/2017/02/24/reductio-and-abstract-em/)), и каждый объект списка будет иметь соответствующий объект массива‡. Например, `[1, 2, 3]` станет `Cons(1, Cons(2, Cons(3, Nil)))`, так что это довольно очевидно, как *любой* список может быть переведён!

- - - -

Это все, что нужно знать о `daggy`, чтобы понять Fantasy Land! Если вы хотите закрепить ваше понимание, почему бы не попробовать добавить ещё пару функций массива к типу `List`, таких как `filter` или `reduce`?

В противном случае, у нас есть ещё одна вещь, о которой стоит поговорить, до того как мы приступим к структурам: [описание типа](http://www.tomharding.me/2017/03/08/fantas-eel-and-specification-2/)!

А пока, берегите себя! ♥

- - - -

*\* Моё (дословно) представление [Дэном](https://twitter.com/MrDanack) членам основной команды разработки PHP.*

*† Даже если только формально.*

*‡ Мы называем этот изоморфизм!*

- - - -

*Читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [Github](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht). Скоро подъедет подкаст, не теряйтесь.*

[Статья на Medium](https://medium.com/devschacht/cпецификация-волшебного-мира-1-daggy-ef332ae68dd8)

- - - -

*В оригинальном названии статьи используется непереводимая игра слов, основанная на схожести звучания названия спецификации Fantasy Land*
