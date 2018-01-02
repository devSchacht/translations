# Иллюстрированное объяснение работы async_hooks в Node.js

*Перевод статьи [Ирины Шестак](https://medium.com/@_lrlna?source=post_header_lockup):[async_hooks in node.js, illustrated](https://medium.com/the-node-js-collection/async-hooks-in-node-js-illustrated-b7ce1344111f). Опубликовано с разрешения автора.*

Несколько недель назад я обратила внимание на [async_hooks](http://devdocs.io/node/async_hooks), новое и все ещё экспериментальное API, которое вышло с node 8, и я решила немного разобраться, чем оно может мне помочь.

![](https://cdn-images-1.medium.com/max/2000/1*WvQ_cZPu8DaHTx2StbpPTA.jpeg)

*async_hooks API в кратком изложении*

*async_hooks* API существенно упрощает отслеживание ваших ресурсов (прощай, dtrace?). Вы начинаете с инициализации его объектом колбэков: `init`, `before`, `after` и `destroy`.

```javascript
var asyncHooks = require('async_hooks')
var hooks = {
  init: init,
  before: before, 
  after: after,
  destroy: destroy
}
var asyncHook = asyncHooks.createHook(hooks)
```

*async_hooks* основаны на концепции ресурсов. `resource` запускает колбэки *async_hooks*, описанные в вышепреведённом коде, и может быть чем угодно: от `TTYWRAP` и `SSLCONNECTION` до тех, которые вы определили сами, используя [Embedder API](https://nodejs.org/api/async_hooks.html#async_hooks_javascript_embedder_api)(подробнее об этом позже). Если вы должны написать сервер с `http.createServer()`, запустите *async_hooks* API и посмотрите, `init` колбэки каких ресурсов вызываются в этом случае. Пример такого кода:

```javascript
var http = require('http')
// asyncHook был описан в примере кода выше
asyncHook.enable()

http.createServer(function (req, res) {
  res.end('hello qts')
}).listen(8079)

function init(asyncId, type, triggerId) {
  fs.writeSync(1, `${type} \n`)
}
```

![](https://cdn-images-1.medium.com/max/2000/1*ObGpUcFpGwbTR3naPODtqg.gif)
*Примеры ресурсов для GET-запроса*


## function init(asyncId, type, triggerId) {}

![](https://cdn-images-1.medium.com/max/2000/1*RpvWsEE-O7_8BgEA6ezIdA.jpeg)
*`init` колбэк async_hooks*

Этот колбэк `init`, вероятно, самый интересный — он позволяет вам получить доступ к текущему ресурсу и посмотреть, что вызвало его запуск. Это означает, что в конечном итоге вы сможете создать хорошую структуру логов, чтобы понять, что действительно происходит в вашем приложении.

![](https://cdn-images-1.medium.com/max/1200/1*5wZTATIQvOXIebSR9MPRAg.jpeg)
*Запускаем отслеживание на `init`, и группируем временные интервалы по их `triggerId`*

Я подумала, что это хороший вход в трассировку исполнения программы — получаем `asyncId` и `triggerId` на `init`, запускаем таймер, чтобы отслеживать время исполнения вашей операции и в конце уничтожаем его в колбэке `destroy`. С этой идеей я написала [`on-async-hook`](https://github.com/lrlna/on-async-hook), простой эмиттер трассировки с использованием *async_hook*.

`on-async-hook` создает трассировку, когда *async_hooks* вызывает колбэк init и группирует ресурсы на основе их `triggerId`. Я хотела измерять время исполнения операций, поэтому структура вывода трассировки `on-async-hook` также включает время начала и время окончания, которое фиксирует, когда ресурс был добавлен на `init` и когда удалён в `destroy`. Простой *hello world* сервер в конечном итоге получит такую трассировку:

![](https://cdn-images-1.medium.com/max/1600/1*NaukfvJ4LfQD-7_sJjXJdg.gif)
*трассировка ‘hello world’ с помощью on-async-hook*

## Embedder API

Если вы работаете с нативными биндингами на C++, вы можете определить свои собственные ресурсы. Вы можете легко это сделать с помощью интерфейса Embedder API. Вот пример, использующий [utp-native](https://github.com/mafintosh/utp-native) библиотеку [mafintosh](https://twitter.com/mafintosh):

```javascript
var AsyncResource = require('async_hooks').AsyncResource
var utp = require('utp-native')
var resource = new AsyncResource('UTPNative')
var server = utp.createServer(function (socket) {
  socket.pipe(socket)
})
server.listen(1337, function () {
  var socket = utp.connect(1337)
  resource.emitBefore()
  socket.write('hello qts')
  resource.emitAfter()
  socket.on('data', function (data) {
    console.log('resourceId', resource.asyncId())
    console.log('triggerAsyncId', resource.triggerAsyncId())
    console.log('this is my data ', data)
  })
})
server.on('close', function () {
  resource.emitDestroy()
})
```

## Что дальше?

*async_hooks* все ещё довольно экспериментальны — все сломано™, и API, возможно, все ещё меняется (например, `async_hooks.executionAsyncId()` используется как `async_hooks.currentId()`), но так приятно видеть, что node объединяет вместе новые способы для мониторинга наших приложений.

## Дополнительная информация:

* Performance Timing API. [@jasnell](https://twitter.com/jasnell) добавил его поддержку в Node.js [на прошлой неделе](https://medium.com/the-node-js-collection/async-hooks-in-node-js-illustrated-b7ce1344111f). Это довольно интересная новость для тех, кто хочет мониторить производительность приложений на Node.js, и я бы определенно посоветовала изучить её.
* Если вы уже используете *async_hooks* в продакшене, есть [ишью](https://github.com/nodejs/node/issues/14794), открытое для сбора отзывов.
* Поскольку *async_hooks* доступен только для node 8, я также предложила бы изучить [async-tracer](http://github.com/davidmarkclements/async-tracer) от  [davidmarkclem](https://twitter.com/davidmarkclem) - он поддерживает предыдущие версии node.

---

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Статья на Medium](https://medium.com/devschacht/async-hooks-in-node-js-illustrated-e8ddcfcffac9)
