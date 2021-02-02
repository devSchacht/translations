# 15 полезных однострочных выражений JavaScript

#### Улучшение JavaScript-кода за пару минут - перевод [15 Helpful JavaScript One-Liners](https://medium.com/javascript-in-plain-english/15-helpful-javascript-one-liners-946e1d1a1653)

Новичок ли вы в программировании на JavaScript, или уже более опытный разработчик, но узнать что-то новое - всегда будет не лишним. В этой статье я, [Daan](https://medium.com/@daaaan), покажу вам однострочники JavaScript из моей коллекции, которые, надеюсь, помогут вам быстрее выполнить рутинные JavaScript задачи.

Надеюсь, что сейчас вы узнаете для себя кое-что новое!

----------

### 1. Генерация случайного числа в заданном диапазоне
```
const randomNumberInRange = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
```

В JavaScript получить случайное значение можно с помощью функции ```Math.random()```. Но как насчет случайного числа в определенном диапазоне? JavaScript не предоставил для этого стандартной функции.  
  
``` 
randomNumberInRange(10, 20)  
// Result: 14
```


------

### 2. Переключение логического значения
```
const toggle = (value) => value = !value
```

Переключение логической переменной с одного значения на другое - один из старейших книжных приемов; эту простейшую проблему программирования можно решить множеством разных способов. Вместо использования оператора ```if```  для переопределения логического значения переменной, можно использовать более "чистый", на мой взгляд, способ.

```
toggle(false)
// Result: true

toggle(true)
// Result: false
```
-----
### 3. Сортировка элементов массива в случайном порядке
```
const sortRandom = (arr) => arr.sort(() => Math.random() - 0.5)
```

Отсортировать массив случайным образом сможет функция ```Math.random()``` - очень "чистое" решение элементарной проблемы. Однако такая сортировка не подходит для достижения высокого уровня случайности. Функция ```sort()``` тоже не подходит. Больше информации по этой теме [здесь](https://javascript.info/task/shuffle) (состоянием на 1 февраля 2021)

```
sortRandom([1, 2, 3, 4, 5])
// Result: [4, 2, 5, 3, 1]
```
------
### 4. Заглавная буква в строке
```
const capitalize = (str) => str.charAt(0).toUpperCase() + str.slice(1)
```

В отличие от Python, C# и PHP, JavaScript не имеет стандартной функции, изменяющей регистр первой буквы в строке. Однако это довольно простая функция, которую часто используют. Вы можете использовать одно слово или полное предложение - пока это строка.

```
capitalize("hey, this is pretty cool!")
// Result: "Hey, this is pretty cool!"
```
-----
### 5. Проверка, является ли переменная массивом
```
const isArray = (arr) => Array.isArray(arr)
```

Есть несколько способов проверить, является ли переменная массивом, но я предпочитаю это делать - аккуратно и легко.

```
isArray([1, 2, 3, 4, 5])
// Result: true

isArray({name: 'Ted'})
// Result: false
```
------
### 6. Исключение hostname из URL
Хотя технически эта функция не написана в одну строку, но она все ещё хороша. С её помощью можно определить, является ли представленная ссылка внутренней, или же внешней, что позволит легко и быстро назначать ссылкам специальное поведение или стиль. 

Функция также обслуживает содержащие номер порта или строку запроса URL-адреса:

```
const extractHostname = (url) => {  
  let hostname = (url.indexOf("//") > -1) ? url.split('/')[2] : url.split('/')[0] 
  
  // Remove port number.  
  hostname = hostname.split(':')[0] 
  
  // Remove querystring.  
  hostname = hostname.split('?')[0] 
  
  return hostname  
}
```
-----
### 7. Получение уникальных значений из массива
```
const uniqueValues = (arr) => [...new Set(arr)]
```

Очень простой, но изящный трюк для удаления повторяющихся значений из массива: массив конвертируется в ```Set```, а затем - обратно.

```
uniqueValues([1, 2, 3, 1, 5, 2])
// Result: [1, 2, 3, 5]
```
----
### 8. Проверка, соответствуют ли условию все элементы массива
Метод ```every``` проверяет, все ли элементы в массиве соответствуют определенному условию. Метод принимает обратный вызов в качестве единственного параметра и возвращает логическое значение.   

*Совет: если соответствовать условию должен лишь один элемент массива, то вам нужен метод* ```some()```.
```
const isOldEnough = (age) => age >= 18

const ages = [7, 19, 12, 33, 15, 49]
const olderPeople = [39, 51, 33, 65, 49]

ages.every(isOldEnough)
// Result: false

olderPeople.every(isOldEnough)
// Result: true
```
-----
### 9. Форматирование чисел с плавающей точкой в зависимости от locale
```
const formatFloat = (floatValue, decimals) => parseFloat(floatValue.toFixed(decimals)).toLocaleString("en-US")
```

Форматировать числа с плавающей точкой можно по-разному. Однако, если приложение поддерживает несколько языков, то формат чисел может заметно отличаться:

```
formatFloat(10000.245, 2)
// Result: "10,000.25"

formatFloat(10000.245, 0)
// Result: "10,000"
```
-----
### 10. Обновление строки запроса
```
const searchParams = new URLSearchParams(window.location.search)
```
Обновление строки запроса может пригодиться, например, при работе с фильтрами, а JavaScript ```URLSearchParams``` сделает этот процесс удобным.

```
searchParams.set('key', 'value')

history.replaceState(null, null, '?' + searchParams.toString())

// Results in the querystring being updated to "?key=value"
```
*Обратите внимание*, что ```window.location.search```, переданный в ```URLSearchParams```, хранит текущую строку запроса нетронутой. Значит, в примере, к текущей строке запроса будет добавлено ```key = value```. Если необходимо создать строку запроса с нуля, то не используйте параметр ```window.location.search```.    

-----
### 11. Разрешены только положительные числа
```
const getPositiveNumber = (number) => Math.max(number, 0)
```
Бывает необходимым, чтобы переменная содержала только положительные числа. Вместо использования оператора if для проверки, является ли число отрицательным, можно использовать JavaScript однострочник.

Этот однострочник можно использовать вместо такого кода:

```
let nember = doSomeCalculation()

if (number < 0) {
  number = 0
}
```
Решение через ```Math.max()``` намного "чище", верно?

-------------------
### 12. Показать диалоговое окно печати
```
const copyTextToClipboard = async (text) => {  
  await navigator.clipboard.writeText(text)  
}
```
Вышеописанная строка кода покажет диалоговое окно печати. Может быть полезно, если вы хотите предоставить пользователю удобный способ распечатать определенную страницу на веб-сайте.   

----
### 13. Копирование текста в буфер обмена
```
const copyTextToClipboard = async (text) => {  
  await navigator.clipboard.writeText(text)  
}
```
Копирование текста в буфер обмена - проблема, решаемая разными способами.
Если вы заботитесь только о современных браузерах, вам будет достаточно вышеописанного примера. 

Это довольно "чистое" решение, оно не полагается на элементы DOM.

*Обратите внимание, что эта функция является асинхронной, поскольку функция* ```writeText``` возвращает ```Promise```.   

Однако, если вы хотите поддерживать старые браузеры, такие как Internet Explorer, вам придется использовать следующий подход:

```
// HTML

<input id="input" type="text" value="This is the text that gets copied">
<button id="copy">Copy the text</button>

// JavaScript

const copy = () => {
  const copyText = document.querySelector('#input')
  copyText.select()
  document.execCommand('copy')
}

document.querySelector('#copy').addEventListener('click', copy)
```
Это решение полагается на поле ввода, в отличие от предыдущего решения, основанного на ```Promise```.

```
// HTML

<input id="input" type="text" value="This is the text that gets copied">  
<button id="copy">Copy the text</button>

// JavaScript

const copy = () => {  
  const copyText = document.querySelector('#input')  
  copyText.select()  
  document.execCommand('copy')  
}  
  
document.querySelector('#copy').addEventListener('click', copy)
```

------
### 14. Сведение значений элементов массива к одному типу
```
const arrayToNumbers = (arr) => arr.map(Number)

const arrayToBooleans = (arr) => arr.map(Boolean)
```
Чтобы свести все значения элементов массива к определенному типу, можно использовать функцию ```map```. В этом примере вы увидите, что сначала мы сводим массив строк к массиву чисел. После этого мы преобразуем числовой массив в массив логических значений.

```
const numbers = arrayToNumbers(['0', '1', '2', '3'])
// Result: [0, 1, 2, 3]

const booleans = arrayToBooleans(numbers)
// Result: [false, true, true, true]
```
-----
### 15. Подсчет дней между двумя датами
Вычисление количества дней между двумя датами - одна из тех вещей, которые вы, вероятно, сделаете более одного раза, если вы много программируете на JavaScript. Чтобы избавить вас от необходимости выяснять, как решить эту проблему каждый раз, вы можете использовать эту функцию, которая делает всю тяжелую работу за вас.

Из-за использования ```Math.and()``` порядок аргументов-дат не имеет значения.


```
const daysBetweenDates = (dateA, dateB) => {  
  const timeDifference = Math.abs(dateA.getTime() - dateB.getTime())  
  // Seconds * hours * miliseconds  
  return Math.floor(timeDifference / (3600 * 24 * 1000))
}

daysBetweenDates(new Date('2020/10/21'), new Date('2020/10/29'))  
// Result: 8

daysBetweenDates(new Date('2020/10/21'), new Date('2021/10/29'))  
// Result: 373
```

-----
### Вот и всё
Теперь, когда вы дошли до конца этого списка, я надеюсь, что вы узнали хотя бы немного нового. Надеюсь, вы сможете применить некоторые из приемов на практике. Если вы знаете отличную однострочную версию JavaScript, которой нет в этом списке, сообщите мне. Я был бы рад увидеть еще замечательных однострочников.

Спасибо за чтение!
----
*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*
