# Разбираемся в проверке JavaScript-типов с помощью typeof

*Перевод статьи [Glad Chinda](https://blog.logrocket.com/@gladchinda): [JavaScript typeof](https://blog.logrocket.com/javascript-typeof-2511d53a1a62).*

![](https://cdn-images-1.medium.com/max/2000/1*j6B7Q6KRIhgNZQuSkVkP_w.jpeg)

Очень важным аспектом любого языка программирования — это его система типов и типы данных в нем. Для строго типизированных языков программирования, например для таких как Java, переменные определяются конкретными типами, которые в свою очередь ограничивают значения переменных.

> Несмотря на то, что JavaScript — это динамически типизированный язык программирования, существуют расширения над языком, которые поддерживают строгую типизацию, например [TypeScript](https://www.typescriptlang.org/).

В JavaScript возможно иметь переменную, которая была определена как содержащая значение типа `string`, а несколько позже на пути своего жизненного цикла она становится ссылкой на значение типа  `object`. Также случается, что JavaScript-движок неявно занимается приведением типов во время выполнения сценария. Проверка типов очень важна для написания предсказуемых JavaScript-программ.

> Для проверки типов в JavaScript присутствует довольно простой оператор [typeof](https://developer.mozilla.org/ru/docs/Web/JavaScript/Reference/Operators/typeof)

Однако позже мы с вами увидим, что использование этого оператора может ввести в заблуждение, об этом мы поговорим ниже.

## Типы данных в JavaScript

Перед тем как начать рассматривать проверку типов с помощью оператора `typeof` важно взглянуть на существующие типы данных в JavaScript. Хотя в этой статье не рассматриваются подробные сведения о типах данных JavaScript, вы все равно сможете что-то почерпнуть по мере чтения статьи.

До ES6 в JavaScript присутствовало 6 типов данных. Но с появлением ES6-спецификации был добавлен тип данных `Symbol`. Ниже приведен список всех существующих типов данных:

1. String
2. Number
3. Boolean (значения true and false)
4. null (значение null)
5. undefined (значение undefined)
6. Symbol
7. Object

Первые шесть типов данных относятся к **примитивным типам**. Все другие типы данных помимо вышеуказанных шести являются *объектами* и относятся к **ссылочному типу**. *Объект* — это нечто иное, как коллекция свойств, представленная в виде пар ключ и значение.

Обратите внимание, что в указанном списке типов данных, `null` и `undefined` — это примитивные типы в JavaScript, которые содержат ровно одно значение.

Вы уже наверно начали задаваться вопросом, а как же массивы, функции, регулярные выражения и прочие вещи? Все это специальные виды объектов.

- `array` — специальный вид объектов, который представляет собой упорядоченную коллекцию пронумерованных значений со специальным синтаксисом и характеристиками, что отличает работу с ним от работы с другими объектами
- `function` — специальный вид объектов, содержащий исполняемый сценарий, который выполняется при вызове функции. Этот вид объектов также имеет специальный синтаксис и характеристики, отличающие работу с ним от работы с другими  объектами

JavaScript содержит несколько конструкторов для создания и других различных объектов, например, таких как:

- `Date` — для создания объектов даты
- `RegExp` — для создания регулярных выражений
- `Error` — для создания JavaScript ошибок

## Проверка типов с использованием typeof

### Синтаксис

Оператор `typeof` в JavaScript является унарным оператором (принимает только один операнд), который возвращает строковое значение типа операнда. Как и другие унарные операторы, он помещается перед его операндом, разделенный пробелом:

```js
typeof 53; // *"number"*
```

Однако существует альтернативный синтаксис, который позволяет использовать `typeof` похожим на вызов функции, через оборачивание операнда в круглые скобки. Это очень полезно при проверке типов возвращаемого значения из JavaScript-выражения:

```js
typeof(typeof 53); // "string"
```

### Защита от ошибок

До спецификации ES6 оператор `typeof` всегда возвращал строку независимо от операнда, который использовал.

> Для необъявленных идентификаторов функция typeof вернет "undefined" вместо того, чтобы выбросить исключение ReferenceError.


```js
console.log(undeclaredVariable === undefined); // ReferenceError
console.log(typeof undeclaredVariable === 'undefined'); // true
```
https://gist.github.com/ufocoder/047c44e201456b9121ec93f1eb0db4ad#file-undeclared_typeof-js

Однако в ES6, переменные объявленные c блочной областью видимости с помощью `let` и `const` будут возвращать `ReferenceError` , если они использовались с оператором `typeof` до того как были инициализированы. А все потому что:


> Переменные, имеющие блочную область видимости остаются во [временной мертвой зоне](https://developer.mozilla.org/ru/docs/Web/JavaScript/Reference/Statements/let#Temporal_Dead_Zone) до момента инициализации:


```js
// Использование typeof для идентификатора
// объявленного с блочной областью видимости
// создаст `ReferenceError` ошибку
console.log(typeof tdzVariable === 'undefined'); // ReferenceError
const tdzVariable = 'I am initialized.';
```
https://gist.github.com/ufocoder/1e7169b111990ec17d3c2c4a5c8cec57#file-tdz_typeof-js

### Проверка типов

Следующий фрагмент кода демонстрирует проверку типов c использованием оператора `typeof`:

```js
console.log(typeof ""); // "string"
console.log(typeof "hello"); // "string"
console.log(typeof String("hello")); // "string"
console.log(typeof new String("hello")); // "object"

console.log(typeof 0); // "number"
console.log(typeof -0); // "number"
console.log(typeof 0xff); // "number"
console.log(typeof -3.142); // "number"
console.log(typeof Infinity); // "number"
console.log(typeof -Infinity); // "number"
console.log(typeof NaN); // "number"
console.log(typeof Number(53)); // "number"
console.log(typeof new Number(53)); // "object"

console.log(typeof true); // "boolean"
console.log(typeof false); // "boolean"
console.log(typeof new Boolean(true)); // "object"

console.log(typeof undefined); // "undefined"

console.log(typeof null); // "object"

console.log(typeof Symbol()); // "symbol"

console.log(typeof []); // "object"
console.log(typeof Array(5)); // "object"

console.log(typeof function() {}); // "function"
console.log(typeof new Function); // "function"

console.log(typeof new Date); // "object"

console.log(typeof /^(.+)$/); // "object"
console.log(typeof new RegExp("^(.+)$")); // "object"

console.log(typeof {}); // "object"
console.log(typeof new Object); // "object"
```
https://gist.github.com/ufocoder/a6915234ce2af220276e5f3c59153e81#file-typechecks-with-typeof-js


Обратите внимание на то, что все значения созданные с помощью ключевого слова `new` всегда имеют тип `“object”`. Исключением из этого является только конструктор `Function`.

**Ниже представлена сводка результатов проверок типов:**

```
| значение | typeof |
| ----- | ------ |
| `undefined` | `"undefined"` |
| `null` | `"object"` |
| `true` or `false` | `"boolean"` |
| all numbers or `NaN` | `"number"` |
| all strings | `"string"` |
| all symbols | `"symbol"` |
| all functions | `"function"` |
| all arrays | `"object"` |
| native objects | `"object"` |
| host objects | зависит от реализации |
| other objects | `"object"` |
```
https://gist.github.com/ufocoder/05b1692e336542e5d8a8db7eadf34ff5#file-typeof_summary-md

## Улучшенная проверка типов

Результаты определения типов в предыдущем разделе показали, что некоторые значения требуют дополнительных проверок. Например, оба значения `null` и `[]` будут иметь тип `"object"`,  когда проверка типа сделана с помощью `typeof` оператора.

Дополнительные проверки могут быть сделаны при использовании некоторых других характеристик, например:

- использование оператора `instanceof`
- проверка свойства `constructor` для объекта
- проверка класса с помощью метода объекта `toString()`

### Проверка на null

Использование оператора `typeof` для проверки значения `"null"`, как вы уже заметили, не лучшая идея. Лучший способ проверить на значение `"null"` — это выполнить строгое сравнение с `null`, как показано в следующем фрагменте кода:

```js
function isNull(value) {
  return value === null;
}
```
https://gist.github.com/ufocoder/37c8865b81c91b39133fa8884ac0cb9a#file-isnull-js

Очень важным здесь является использование оператора строгого сравнения. Следующий фрагмент кода иллюстрирует использования значения `undefined`:

```js
console.log(undefined == null); // true
console.log(undefined === null); // false
```
https://gist.github.com/ufocoder/402773140e1bde90bffe00f026b9cada#file-undeclared_typeof-js

### Проверка на NaN

`NaN` является специальным значением получаемым в результате арифметических операций, когда нет определения как можно представить результат. Например `(0 / 0) => NaN`. Также когда совершена попытка преобразования нечислового значения, у которого отсутствует возможное численного представление, результатом преобразования будет `NaN`.

> Любая арифметическая операция, включающая в выражение NaN, всегда определяется как NaN.

Если вы действительно хотите применить произвольное значения для любой арифметической операции, тогда убедитесь, что это значение не NaN.


Использование оператора `typeof` для проверки типа для `NaN` вернет значение `“number”`. Для проверки же на значение `NaN` вы можете использовать глобальную функцию `isNaN()` или даже предпочтительней будет использовать функцию `Number.isNaN()`, добавленную в ES6:

```js
console.log(isNaN(NaN)); // true
console.log(isNaN(null)); // false
console.log(isNaN(undefined)); // true
console.log(isNaN(Infinity)); // false

console.log(Number.isNaN(NaN)); // true
console.log(Number.isNaN(null)); // false
console.log(Number.isNaN(undefined)); // false
console.log(Number.isNaN(Infinity)); // false
```
https://gist.github.com/ufocoder/8bc0105501d1049d0a85599656af7551#file-nan_check-js

> Значение NaN в JavaScript имеет отличительную особенность. Это единственное значение в JavaScript, которое при сравнении с каким-либо другим значением, включая NaN, не будет ему эквивалентно

```js
var x = NaN;

console.log(x == NaN); // false
console.log(x === NaN); // false
```
https://gist.github.com/ufocoder/22f876430c23c66d1e8e7875ca0567bb#file-nan_equality-js

Вы можете проверить на значение `NaN` следующим образом

```js
function isNan(value) {
  return value !== value;
}
```
https://gist.github.com/ufocoder/5f1f14c03853dc32381aa2b66fbf77bb#file-isnan-js

Функция выше очень похожа на реализацию функции `Number.isNaN()`, добавленную в ES6, и следовательно, ее можно использовать в качестве полифила для сред выполнения, отличных от ES6, следующим образом:

```js
Number.isNaN = Number.isNaN || (function(value) {
  return value !== value;
})
```
https://gist.github.com/ufocoder/65c011cae47e164a78c0afda1d3eee1d#file-polyfill-isnan-js

В заключение вы можете усилить проверку с помощью `Object.is()`, добавленную в ES6 для проверки на значение `NaN`. Функция `Object.is()` позволяет проверить, что два переданных в нее значения это одно и то же значение:

```js
function isNan(value) {
  return Object.is(value, Number.NaN);
}
```
https://gist.github.com/ufocoder/135c5207148a3da2c56158414286331d#file-isnan_object_is-js

### Проверка для массивов

Использование проверки с помощью `typeof` для массива вернет `“object”`. Существует несколько путей для того, чтобы проверить является ли значение массивом, как показано в нижнем фрагменте кода:

```js
// Метод #1: свойство constructor
// Ненадежный метод
function isArray(value) {
  return typeof value == 'object' && value.constructor === Array;
}

// Метод #2: instanceof
// Ненадежный метод в связи с возможностью изменения прототипа объекта
// Непредвиденные результаты при работе с `iframe`
function isArray(value) {
  return value instanceof Array;
}

// Метод #3: Object.prototype.toString()
// Улучшенная проверка плюс очень похода на функцию ES6 Array.isArray()
function isArray(value) {
  return Object.prototype.toString.call(value) === '[object Array]';
}

// Метод #4: ES6 Array.isArray()
function isArray(value) {
  return Array.isArray(value);
}
```
https://gist.github.com/ufocoder/ea352b1cee49f77ca189ce57c3dda2bf#file-array_check-js

Очень важным здесь является использование оператора строгого сравнения. Следующий фрагмент кода иллюстрирует использования значения `undefined`:


## Общий подход к проверки типов

Как вы видели на примере массивов, метод `Object.prototype.toString()` может быть полезным при проверки типов объектов для любого значения в JavaScript.

Когда вызывается этот метод с помощью `call()` или `apply()`, он возвращает тип объекта в формате: `**[object Type]**`, где `Type` является типом объекта.

Рассмотрим следующий фрагмент кода:

```js
function type(value) {
  var regex = /^\[object (\S+?)\]$/;
  var matches = Object.prototype.toString.call(value).match(regex) || [];

  return (matches[1] || 'undefined').toLowerCase();
}
```
https://gist.github.com/ufocoder/7df39101a36b1784b853513e15d134c6#file-type-js

Фрагмент кода ниже демонстрирует результаты проверки типов с использованием созданной функции `type()`:

```js
console.log(type('')); // "string"
console.log(type('hello')); // "string"
console.log(type(String('hello'))); // "string"
console.log(type(new String('hello'))); // "string"

console.log(type(0)); // "number"
console.log(type(-0)); // "number"
console.log(type(0xff)); // "number"
console.log(type(-3.142)); // "number"
console.log(type(Infinity)); // "number"
console.log(type(-Infinity)); // "number"
console.log(type(NaN)); // "number"
console.log(type(Number(53))); // "number"
console.log(type(new Number(53))); // "number"

console.log(type(true)); // "boolean"
console.log(type(false)); // "boolean"
console.log(type(new Boolean(true))); // "boolean"

console.log(type(undefined)); // "undefined"

console.log(type(null)); // "null"

console.log(type(Symbol())); // "symbol"
console.log(type(Symbol.species)); // "symbol"

console.log(type([])); // "array"
console.log(type(Array(5))); // "array"

console.log((function() { return type(arguments) })()); // "arguments"

console.log(type(function() {})); // "function"
console.log(type(new Function)); // "function"

console.log(type(class {})); // "function"

console.log(type({})); // "object"
console.log(type(new Object)); // "object"

console.log(type(/^(.+)$/)); // "regexp"
console.log(type(new RegExp("^(.+)$"))); // "regexp"

console.log(type(new Date)); // "date"
console.log(type(new Set)); // "set"
console.log(type(new Map)); // "map"
console.log(type(new WeakSet)); // "weakset"
console.log(type(new WeakMap)); // "weakmap"
```
https://gist.github.com/ufocoder/01e934a691810d84aa0cc49b1dd0ae6e#file-checks_with_type-js

## Бонус: не все является объектами

Очень вероятно, что в какой-то момент вы могли столкнуться с этим утверждением:

> "Все сущности в JavaScript являются объектами." - (Неправда)

Это ошибочное утверждение и на самом деле это неправда. Не все в JavaScript является объектами. Примитивы не являются объектами.

Вы можете начать задаваться вопросом — почему же мы можем делать следующие операции над примитивами, если они не являются объектами?

- `**("Hello World!").length**` — получить свойство `length` для строк
- `**("Another String")[8]**` — получить символ строки по индексу 8
- `**(53.12345).toFixed(2)**` — выполнить `Number.prototype.toFixed()` метод над числом

Причина, по которой мы можем достичь всего этого над примитивами, заключается в том, что JavaScript-движок неявно создает соответствующий **объект-обертку** для примитива и затем вызывает указанный метод или обращается к указанному свойству.

Когда значение было возвращено, объект-обертка отбрасывается и удаляется из памяти. Для операций, перечисленных ранее, JavaScript-движок неявно выполняет следующие действия:

```js
// объект-обертка: new String("Hello World!")
(new String("Hello World!")).toLowerCase();

// объект-обертка: new String("Another String")
(new String("Another String"))[8];

// объект-обертка: new Number(53.12345)
(new Number(53.12345)).toFixed(2);
```
https://gist.github.com/ufocoder/ca9e9c61f78ff712c0f41c79c155a891#file-wrapper_objects-js

## Заключение

В этой статье вы получили крупицу того, что является системой типов в JavaScript и типами данных, а также то, как проверка типов может быть выполнена с помощью оператора `typeof`.

Также вы видели, как проверка типов с помощью оператора `typeof` может ввести в заблуждение. И, наконец, вы видели несколько способов реализации предсказуемой проверки типов для некоторых типов данных.

Если вы заинтересованы в получении дополнительной информации об операторе `typeof` в JavaScript, обратитесь к [этой статье](https://developer.mozilla.org/ru/docs/Web/JavaScript/Reference/Operators/typeof).

- - - -

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*
