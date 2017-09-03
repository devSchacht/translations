# Ленивый синтаксический анализ JavaScript в V8
*Перевод статьи [Matt Zeunert](http://www.mattzeunert.com): [Lazy JavaScript Parsing in V8](http://www.mattzeunert.com/2017/01/30/lazy-javascript-parsing-in-v8.html). Опубликовано с разрешения автора.*

![](https://cdn-images-1.medium.com/max/800/1*3YvmAm2_2hRw23m1hQYmtw.jpeg)

В движках JavaScript для ускорения выполнения кода используется механизм, называемый ленивым синтаксическим анализом (lazy parsing).

В этой статье вы узнаете: что такое ленивый синтаксический анализ, чем он полезен и каковы потенциальные проблемы при его использовании.

## Исходные данные

V8 — это JavaScript-движок, который используется в Chrome и Node. Хотя эта статья посвящена V8, это не единственный JavaScript-движок, использующий ленивый синтаксический анализ.

Перед запуском JavaScript его необходимо преобразовать в машинный код. Это то, что делает V8.

Сначала код преобразуется в список токенов, затем токены преобразуются в синтаксическое дерево, а затем из этого дерева генерируется машинный код.

Синтаксический анализ — это второй шаг, преобразование токенов в абстрактное синтаксическое дерево (AST). Вот пример исходного кода с соответствующим ему AST:

![](http://www.mattzeunert.com/img/blog/lazy-parsing-ast.png)

Если вы хотите попробовать поиграть с синтаксическими деревьями JavaScript, попробуйте [AST Explorer](https://astexplorer.net/).

## Предварительный и полный синтаксический анализ

Для синтаксического анализа требуется время, поэтому JavaScript-движки стараются избегать глубокого разбора файла.

Это возможно, потому что большинство функций в файле JavaScript никогда не вызываются или, например, не будут вызваны до тех пор, пока пользователь не начнёт взаимодействовать с пользовательским интерфейсом.

Поэтому вместо анализа каждой функции, большинство функций подвергаются предварительному анализу. Предварительный анализ обнаруживает синтаксические ошибки, но не разрешает область видимости переменных, используемых в функции, и не генерирует для неё AST.

Благодаря менее интенсивному анализу, предварительный синтаксический анализ примерно в [два раза быстрее](https://docs.google.com/document/d/1dev8h3FtP-BDjcwQosanV9wGy3NyOOpQe3tAIDr7hXc/edit), чем полный.

Однако, когда вы вызываете функцию, которая еще не была полностью проанализирована, вам нужно выполнить полный анализ во время её вызова.

## Пример с использованием V8

Давайте посмотрим на пример такого поведения.

Node имеет специальный аргумент `--trace_parse`, при запуске с которым вам будет видно, как происходит синтаксический анализ скриптов или функции. Тем не менее, вывод может быть довольно большим из-за различного внутреннего кода, который Node запускает для начальной загрузки вашей программы. Поэтому вместо Node я буду использовать оболочку V8 под названием d8.

В отличие от Node, d8 не имеет функции `console.log`, поэтому я использую функцию с именем `print`:

```javascript
function sayHi(name){
    var message = "Hi " + name + "!"
    print(message)
}

function add(a, b){
    return a + b;
}

sayHi("Sparkle")
```

Здесь у меня две функции `sayHi` и `add`, причём `add` никогда не вызывается.

```
$ d8 --trace_parse test.js

[parsing script: native datetime-format-to-parts.js - took 0.361 ms]
[parsing function: ImportNow - took 0.014 ms]
[parsing function: InstallFunctions - took 0.044 ms]
[parsing function: SetFunctionName - took 0.015 ms]
[parsing script: native icu-case-mapping.js - took 0.031 ms]
[parsing function: OverrideFunction - took 0.029 ms]
[parsing function: PostExperimentals - took 0.028 ms]
[parsing script: test.js - took 0.058 ms]
[parsing function: sayHi - took 0.009 ms]
Hi Sparkle!
```

Всё еще присутствует избыточный вывод, связанный с `d8`, но гораздо меньший, чем если бы мы использовали Node (*при использовании d8 из последней сборки v8 избыточный вывод отсутствует, - прим. пер.*). Важны три последние строчки.

Когда `test.js` первоначально анализируется, функции `sayHi` и `add` обрабатываются только *предварительно*, что ускоряет анализ исходного кода.

Тогда же, когда мы вызываем `sayHi`, функция анализируется полностью.

Важно: `add` никогда не анализируется полностью. Это позволяет экономить время синтаксического анализатора и уменьшает потребление памяти V8.

Если мы добавим `add(1, 2)` к нашему JavaScript-коду, функция `add` будет проанализирована во время вызова:

```
[parsing script: /Users/mattzeunert/test.js - took 0.608 ms]
[parsing function: sayHi - took 0.011 ms]
Hi Sparkle!
[parsing function: add - took 0.007 ms]
```

## В чём проблема с ленивым синтаксическим разбором?

Давайте уберём неиспользуемую функцию `add` из кода ниже.

```javascript
function sayHi(name){
    var message = "Hi " + name + "!"
    print(message)
}

sayHi("Sparkle")
```

Вывод `d8 --trace_parse test.js`:

```
// ...
[parsing script: /Users/mattzeunert/test.js - took 0.599 ms]
[parsing function: sayHi - took 0.011 ms]
Hi Sparkle!
```

Сначала V8 предварительно обрабатывает `sayHi`, после чего следует полный синтаксический анализ. Тогда предварительный анализ не нужен и наша программа работает быстрее без попыток оптимизации V8!

В идеале, функции, вызываемые прямо при загрузке JavaScript-файла, всегда должны быть полностью проанализированы, в то время как для других функций достаточно выполнить предварительный парсинг.

В V8 фактически есть эвристика, где функции, заключенные в круглые скобки, всегда анализируются полностью. Например, это относится к немедленно вызываемым функциональным выражениям (IIFE):

```javascript
var constants = (function constants(){
    return {pi: 3.14}
})()
```

```
$ d8 --trace-parse test.js

[parsing script: test.js - took 0.024 ms]
```

Обратите внимание: здесь нет `parsing function: constants`.

## Микрооптимизации JavaScript-кода

Теперь предположим, что мы хотим, чтобы наш пример `sayHi` работал быстрее. Что мы можем сделать?

Во-первых, давайте сохраним `sayHi` как переменную вместо использования объявления функции:

```javascript
var sayHi = function sayHi(name){
    var message = "Hi " + name + "!"
    print(message)
}

sayHi("Sparkle");
```

V8 по-прежнему выполняет предварительный парсинг `sayHi`, но мы можем предотвратить это, завернув выражение функции в круглые скобки.

```javascript
var sayHi = (function sayHi(name){
    var message = "Hi " + name + "!"
    print(message)
})

sayHi("Sparkle");
```

Хотя это и не IIFE V8 будет использовать эвристику и сделает полный анализ с самого начала:

```
[parsing script: /Users/mattzeunert/test.js - took 0.029 ms]
Hi Sparkle!
```

## Optimize-JS

Вместо того, чтобы вручную делать эти оптимизации и превращать наш код в трудно читаемый, мы можем использовать инструмент [optimize-js](https://github.com/nolanlawson/optimize-js).

На практике общей причиной ненужных предварительных анализов является то, что минификатор UglifyJS удаляет круглые скобки из IIFE для сохранения байтов:

```javascript
(function(){
    console.log("hi")
})()
```

Превращается в:

```javascript
!function(){console.log("hi")}();
```

Это не меняет поведение кода, но нарушает эвристику Chrome.

Если вы запустите `optimize-js` на уменьшенном коде выше, скобки будут восстановлены:

```javascript
!(function(){console.log("hi")})();
```

Кстати, [readme optimise-js](https://github.com/nolanlawson/optimize-js/blob/master/README.md) уточняет, что Chakra, движок JavaScript, используемый в Edge, способен правильно определять синтаксис `!Function (){}()` IIFE и предотвращать предварительный анализ.

Этот факт также указывает на одно ограничение этих оптимизаций: они зависят от реализации движка JavaScript. Вы можете ожидать, что их эффективность будет снижаться по мере того, как движки JavaScript становятся более изощренными при принятии решения о том, в каких случаях предварительный парсинг является хорошей идеей.

## Стоят ли эти оптимизации потраченных усилий?

В документации `optimize-js` есть результаты несколько тестов производительности, показывающие впечатляющие ускорения - около 20%. Однако в Chrome на моем ноутбуке фактическое улучшение для образца приложения на React составляет всего 6 мс (время загрузки кода уменьшилось с 24мс до 18мс).

Ускорение будет заметнее на более медленных устройствах. Но не на iPhone: движок Safari, JavaScriptCore, не показывает улучшения для оптимизированного кода.

Скорее всего, есть более эффективные вещи, которые вы можете сделать для повышения производительности своих сайтов. Но если у вас закончились идеи, стоит попробовать `optimize-js` и измерить, есть ли какое-то значимое улучшение.

---

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Статья на Medium](https://medium.com/devschacht/lazy-javascript-parsing-in-v8-99b5c3a6cbba)