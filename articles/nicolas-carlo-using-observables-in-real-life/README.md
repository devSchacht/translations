# Использование Observables в реальной жизни

*Перевод статьи [Nicolas Carlo](https://hackernoon.com/@nicoespeon): [Using Observables in real life](https://hackernoon.com/using-observables-to-make-our-app-work-with-barcode-scanners-e8a673fba625)*

В этой статье я приведу пример практической ситуации, в которой Observables способны сделать наш код чище и удобнее.

## Как создать сканер штрих-кода?!
Да, это специфичный пример, но он отлично иллюстрирует проблемы, способные побудить вас к использованию Observables.

Сканер штрих-кода всего лишь эмулирует клавиатуру. Он воспроизводит сканируемый код на основе событий клавиш клавиатуры после нажатия клавиши «Enter» (код клавиши - 13).

Предположим, мы разрабатываем приложение, позволяющее пользователям искать продукты по кодовой ссылке, состоящей из 16 символов. Вместо того, чтобы вводить их вручную, пользователи должны иметь возможность использовать сканер штрих-кода для запуска поиска.

> «Просто позвольте пользователю сфокусироваться на вводе данных для поиска, сканируйте, и все готово!»

Задумано именно так.

Но функция поиска содержится внутри всплывающего окна, которое можно открыть с помощью кнопки. И нам заказали, что приложение должно быть супер эргономичным! Всякий раз, когда пользователь сканирует штрих-код, мы должны открыть всплывающее окно и заполнить его сканируемым кодом.

Теперь проблема заключается в том, как мы отличим сканирование кода от других событий нажатия клавиш? Допустим, пользователь нажимает клавишу перед сканированием кода: мы не хотим, чтобы этот ключ был частью сканируемого кода!

## Решим проблему императивно
Нам, конечно, нужно слушать события нажатия клавиш... Затем мы должны... запоминать коды клавиш, возможно, используя буфер! Если код нажатой клавиши - код клавиши «Enter», заполнить поле ввода и очистить буфер. В противном случае добавить код клавиши в буфер!

Давайте предпринем первую попытку:

```js
const ENTER_KEY_CODE = 13
let keyCodesBuffer = []

document.addEventListener("keypress", (event) => {
  const keyCode = event.keyCode

  if(keyCode === ENTER_KEY_CODE) {
    fillInputWithKeyCodesBuffer()
    cleanBuffer()
  } else {
    addToBuffer(keyCode)
  }
})

function fillInputWithKeyCodesBuffer() {
  // …
}

function cleanBuffer() {
  keyCodesBuffer = []
}

function addToBuffer(keyCode) {
  keyCodesBuffer.push(keyCode)
}
```

Хорошо.

Но этого недостаточно: он не отличает сканирование кода от обычных нажатий клавиш!

Мы знаем, что если через ~50 миллисекунд не происходит новое нажатие клавиши, то это не сканирование кода и мы можем очистить буфер.

```js
const ENTER_KEY_CODE = 13
const MAX_INTERVAL_BETWEEN_EVENTS_IN_MS = 50
let keyCodesBuffer = []

document.addEventListener("keypress", (event) => {
  const keyCode = event.keyCode

  if(keyCode === ENTER_KEY_CODE) {
    fillInputWithKeyCodesBuffer()
    cleanBuffer()
  } else {
    addToBuffer(keyCode)
    cleanBufferAfter(MAX_INTERVAL_BETWEEN_EVENTS_IN_MS)
  }
})

function fillInputWithKeyCodesBuffer() {
  // …
}

function cleanBuffer() {
  keyCodesBuffer = []
}

function addToBuffer(keyCode) {
  keyCodesBuffer.push(keyCode)
}

function cleanBufferAfter(timeout) {
  setTimeout(cleanBuffer, timeout)
}
```

Хм... неплохо. Но здесь есть узкое место: если код потребует более 50 миллисекунд на сканирование, он начнёт с начала...

На самом деле, если новое нажатие клавиши происходит в течение 50 миллисекунд, мы должны очистить тайм-аут.

```js
const ENTER_KEY_CODE = 13
const MAX_INTERVAL_BETWEEN_EVENTS_IN_MS = 50
let keyCodesBuffer = []
let cleanBufferTimeout

document.addEventListener("keypress", (event) => {
  const keyCode = event.keyCode

  stopCleanBufferTimeout()
  if(keyCode === ENTER_KEY_CODE) {
    fillInputWithKeyCodesBuffer()
    cleanBuffer()
  } else {
    addToBuffer(keyCode)
    cleanBufferAfter(MAX_INTERVAL_BETWEEN_EVENTS_IN_MS)
  }
})

function fillInputWithKeyCodesBuffer() {
  // …
}

function cleanBuffer() {
  keyCodesBuffer = []
}

function addToBuffer(keyCode) {
  keyCodesBuffer.push(keyCode)
}

function cleanBufferAfter(timeout) {
  cleanBufferTimeout = setTimeout(cleanBuffer, timeout)
}

function stopCleanBufferTimeout() {
  clearTimeout(cleanBufferTimeout)
}
```

Теперь у нас есть кое-что работающее.

Давайте сделаем шаг назад и подумаем: если бы у нас была полная история событий нажатия клавиш, смогли бы мы вычленить из неё последовательность событий сканирования кода? Будет ли код проще? Давайте выясним это...

## Решаем проблему при помощи Observables
Я уверен, для такого рода случаев, Observables являются мощной абстракцией для представления наших данных.

> Observables - это неизменяемые коллекции асинхронных событий, которыми вы можете управлять с помощью операторов.

Если для работы с массивами мы используем *map* и *filter*, значит мы уже знакомы с подобным образом мышления.

> Если Observables все ещё покрыты завесой тайны для вас, я предлагаю вам прочитать [отличное введение в реактивное программирование](https://gist.github.com/staltz/868e7e9bc2a7b8c1f754) от Андре Стальца.

Так что, вместо того, чтобы отвечать на каждое событие отдельно, давайте соберём все события в один обрабатываемый поток.

```js
const keyCode$ = Rx.Observable.fromEvent(document, "keypress")
  // ---(ev)--(ev)--------(ev)--->
  .pluck('keyCode')
  // ---(43)--(51)--------(13)--->
```

> Знак `$` в конце имени переменной означает «Поток». Это соглашение, которое я использую, чтобы узнать, что переменная, которой я манипулирую, является Observable в нетипизированных языках, точно так же, как я называю `elements` массив **элементов**, или `$header` - jQuery представление заголовка.

Теперь у нас есть поток кодов клавиш. Каждый раз, когда происходит событие нажатия клавиши, генерируется новое событие, значение которого соответствует соответствующему коду клавиши.

В конце процесса мы хотели бы иметь поток, на который могли бы подписаться. Каждое событие потока должно представлять сканируемый код. Поэтому нам нужно сделать партию кодов клавиш таким образом, чтобы изолировать сканируемый код от нежелательных нажатий клавиш.

Чтобы реализовать это, мы можем **буферизовать** наш поток, используя стратегию задержки (**debounce**): когда происходит событие, ждём следующего события 50 миллисекунд. Если следующее событие происходит в течение этого временного интервала, ждём ещё 50 миллисекунд. Если в течение этого временного интервала не происходит никаких других событий, создаём партию произошедших событий.

![](https://cdn-images-1.medium.com/max/800/1*m382rBb8PLofAu6_rZ4mRA.png)

*Это то, чего мы хотим добиться с помощью [оператора буфера](http://reactivex.io/documentation/operators/buffer.html)*

```js
const MAX_INTERVAL_BETWEEN_EVENTS_IN_MS = 50

const keyCode$ = Rx.Observable.fromEvent(document, "keypress")
  .pluck('keyCode')

const keyCodesBuffer$ = keyCode$
  // --(43)-(64)----(32)-----(65)-(77)-(13)--->
  .buffer(keyCode$.debounce(MAX_INTERVAL_BETWEEN_EVENTS_IN_MS))
  // --([43,64])----([32])-----([65,77,13])--->
```

Пока что все идёт хорошо!

Теперь все, что нам нужно сделать, - это отфильтровать партии, которые не похожи на сканируемый код. А мы знаем, что сканируемый код - последовательность, заканчивающаяся клавишей «Enter».

```js
const ENTER_KEY_CODE = 13
const MAX_INTERVAL_BETWEEN_EVENTS_IN_MS = 50

const keyCode$ = Rx.Observable.fromEvent(document, "keypress")
  .pluck('keyCode')

const keyCodesBuffer$ = keyCode$
  .buffer(keyCode$.debounce(MAX_INTERVAL_BETWEEN_EVENTS_IN_MS))
  .filter(isFromScan)

function isFromScan(keyCodes) {
  return keyCodes.length > 1 && keyCodes[keyCodes.length - 1] === ENTER_KEY_CODE
}
```

Наконец, давайте подпишемся на созданный нами поток и выполним обратный вызов на каждое новое событие.

> Ничего не произойдет, пока мы не подпишемся на Observable, так как они ленивы.

```js
const ENTER_KEY_CODE = 13
const MAX_INTERVAL_BETWEEN_EVENTS_IN_MS = 50

const keyCode$ = Rx.Observable.fromEvent(document, "keypress")
  .pluck('keyCode')

const keyCodesBuffer$ = keyCode$
  .buffer(keyCode$.debounce(MAX_INTERVAL_BETWEEN_EVENTS_IN_MS))
  .filter(isFromScan)

function isFromScan(keyCodes) {
  return keyCodes.length > 1 && keyCodes[keyCodes.length - 1] === ENTER_KEY_CODE
}

function fillInputWith(keyCodes) {
  // …
}

keyCodesBuffer$.subscribe(fillInputWith)
```

## Что мы здесь делали
Это наглядная иллюстрация того, что мы сделали, чтобы перейти от `keyCodes$`, которая была создана из событий нажатия клавиш, к `keyCodesBuffer$`, на которые мы подписались:

![](https://cdn-images-1.medium.com/max/800/1*D72UTQdF5w7dx0AsfvEN3Q.gif)

*Преобразование потока кодов клавиш в поток сканируемых кодов*

Есть несколько замечаний для нашего финального кода:

* Нам не нужно вручную управлять таймаутом и буфером
* Следовательно, код короче и **ориентирован на конкретную работу**
* `fillInputWith()` не полагается на глобальный буфер, что **лучше для тестирования и переиспользования** - на самом деле, мы в нескольких небольших шагах, чтобы сделать всю логику чисто функциональной
* Мы манипулируем только `const`, ничего не переопределяем, такой код **проще понимать**
* Созданные потоки можно использовать повторно, чтобы делать другие вещи; Мы можем **добавлять функции, не боясь** что-нибудь сломать
* Если это понадобится, мы можем, например, легко устранить проблемы в этом коде, добавить операторы в каналы создания потоков. Мы, вероятно, отфильтровали бы неинтересные коды клавиш из `keyCodes$` просто вот так: `.filter (isValidKeyCode)`

На мой взгляд, сложность только в том, чтобы мыслить потоками, и понимать, как решить задачу с заданными операторами.

Но я считаю, что это приходит с практикой.

- - - -

*Читайте нас на [Медиуме](https://medium.com/devschacht), контрибьютьте на [Гитхабе](https://github.com/devSchacht), общайтесь в [группе Телеграма](https://t.me/devSchacht), следите в [Твиттере](https://twitter.com/DevSchacht) и [канале Телеграма](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht). Скоро подъедет подкаст, не теряйтесь.*

[Статья на Medium](https://medium.com/devschacht/nicolas-carlo-using-observables-in-real-life-750bb4e83cd9)
