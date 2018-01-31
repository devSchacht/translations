# Функциональный JavaScript: развязка методов из их объектов

*Перевод статьи [Joel Thoms](https://hackernoon.com/@joelthoms): [Functional JavaScript: Decoupling methods from their objects](https://hackernoon.com/functional-javascript-decoupling-methods-from-their-objects-aa3ca13d7ae8)*

![](https://cdn-images-1.medium.com/max/800/1*OkWOLixnGyTmjucx-9PVRQ.jpeg)

В своих проектах я всегда делаю одну вещь: развязку (*decoupling*) методов из их объектов. `map`, `filter` и `reduce` - не единственные, но, безусловно, одни из первых, кому дается свобода.

> Развязка метода освобождает его от ограничений, накладываемых родительским объектом, а также даёт нам больше свободы в способах написания кода.

## Так как же это выглядит?
Чтобы все было проще, давайте ограничимся развязкой `map` из массива. К счастью, прототипное наследование JavaScript облегчает нашу задачу, поскольку желаемая функция *сидит* на `Array.prototype.map`. Одно замечательное свойство JavaScript заключается в том, что мы можем вызвать этот метод напрямую. Нам просто нужно использовать `.call`, потому что `map` ожидает параметр `this`.

Приправьте сюда немного каррирования (будущая статья), и окажется, что нам был нужен всего лишь небольшой однострочник...

```js
const map = f => x => Array.prototype.map.call(x, f)

```

Теперь мы можем вызывать нашу функцию `map` вне массива!

## Альтернативные способы вызова `map`
Существует много разных способов вызова `map`, но из-за оптимизации движком V8 сколько-нибудь реальной разницы в производительности нет.

![](https://cdn-images-1.medium.com/max/800/1*i8mZiUCkRGxTFsvwyrU4hw.gif)

Любая разница в производительности не является существенной, и эти числа будут меняться постоянно. Можно считать производительность этих вызовов равной.

## Как развязка методов делает мою жизнь лучше?
Вот это отличный вопрос! Возможно, лучший вопрос. Я думаю, что это лучше всего объяснить кодом, а не словами, так что давайте просто окунемся в него.

`document.querySelectorAll` (и аналогичные методы) не возвращают Array, они возвращают NodeList, а NodeList не содержит метода `map`. Есть некоторые фокусы, которые вы можете сделать, чтобы преобразовать NodeList в массив, но преобразование не требуется, поскольку наша `map` может перебирать NodeList так, как если бы это был массив.

```js
const items = document.querySelectorAll('div')

items.map(doSomething)
// => Uncaught TypeError: items.map is not a function

map(doSomething)(items)
// => [<div/>, ..., <div/>]
```

Мы можем даже осуществлять `map` по строке без необходимости сначала преобразовывать её в массив символов.

```js
const value = 'Kitty Cat'

value.map(doSomething)
// => Uncaught TypeError: items.map is not a function

map(doSomething)(value)
// => ['K', 'i', 't', 't', 'y', ' ', 'C', 'a', 't']
```

Развязка позволяет нам легко превратить сопоставление по объекту в сопоставление по списку:

```js
const getFullName = ({ first, last }) => `${first} ${last}`

getFullName({ first: 'Max', last: 'Power' })
// => 'Max Power'

map(getFullName)([
  { first: 'Max', last: 'Power' },
  { first: 'Disco', last: 'Stu' },
  { first: 'Joe', last: 'Kickass' }
])
// => ['Max Power', 'Disco Stu', 'Joe Kickass']
```

Мы можем даже осуществлять `map` по объектам.

```js
const obj = {
  0: 4,
  1: 5,
  2: 6,
  length: 3
}

map(increase)(obj)
// => [5, 6, 7]
```

Развязка позволяет нам составлять функции:

```js
const mapDoStuff = map(doStuff)
const mapDoSomething = map(doSomething)

// composing 2 mappings
const mapDoSomethingThenStuff =
  compose(mapDoStuff, mapDoSomething)
```

Развязка (вместе с каррированием) позволяет частично применять аргументы функции и создавать новые функции.

```js
const increaseOne = x => x + 1

// partially applied map increase
const increaseMany = map(increaseOne)

increaseMany([1, 2, 3])
// => [2, 3, 4]
```

Попрощайтесь с `this`!!!

```js
const cat = {
  sound: 'meow',
  speak: function() {
    console.log(this.sound)
  }
}

const catSpeak = cat.speak

cat.speak()
// => 'meow'

catSpeak()
// => Uncaught TypeError: Cannot read property 'sound' of undefined
```

В этом примере работает `cat.speak`, но `catSpeak` не работает, потому что контекст `this` изменился. Какой ужас! Вместо этого мы можем развязать метод `speak` и **никогда больше не беспокоиться о `this`**!

```js
const cat = {sound: 'meow'}
const speak = ({sound}) => console.log (sound)

speak(cat)
// => 'meow'
```

Затем мы можем создавать новые функции, использующие наши развязанные функции.

```js
const cat = { sound: 'meow' }
const speak = ({ sound }) => console.log(sound)
const speakLoudly = obj =>
  speak({ ...obj, sound: obj.sound.toUpperCase() + '!' })

speak(cat)
// => 'meow'

speakLoudly(cat)
// => 'MEOW!'
```

## Итог
Сегодня мы узнали много преимуществ развязки методов и их извлечения из их объектов. Развязка позволяет использовать функцию в большем количестве мест и с различными типами объектов, а также открывать её для компоновки с другими функциями. Мы также исключаем все ссылки к контексту `this` - одного этого для меня уже достаточно!

Я знаю, что это мелочь, но это делает мой день, когда я получаю уведомления, что кто-то подписался на меня в Medium или Twitter ([@joelnet](https://twitter.com/joelnet)). Или, если вы думаете, что я несу чушь, скажите это мне в комментариях ниже *(прим. пер.: соответствующим образом, дорогой читатель, вы можете поступить и относительно этого или [любого другого](https://medium.com/devschacht) перевода)*.

Увидимся!

## Связанные статьи
* [Functional JavaScript: Function Composition For Every Day Use](https://hackernoon.com/javascript-functional-composition-for-every-day-use-22421ef65a10)
* [Rethinking JavaScript: Death of the For Loop](https://hackernoon.com/rethinking-javascript-death-of-the-for-loop-c431564c84a8)
* [Rethinking JavaScript: The if statement](https://hackernoon.com/rethinking-javascript-the-if-statement-b158a61cd6cb)

- - - -

*Читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht). Скоро подъедет подкаст, не теряйтесь.*

[Статья на Medium](https://medium.com/devschacht/joel-thoms-functional-javascript-decoupling-methods-from-their-objects-9a2686096418)
