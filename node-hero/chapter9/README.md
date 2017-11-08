# Модульное тестирование
*Перевод книги [Node Hero](https://risingstack.com/resources/node-hero) от [RisingStack](https://risingstack.com/). Переведено с разрешения правообладателей.*

В этой главе вы узнаете, что такое модульное тестирование (*юнит-тестирование*) в Node.js и как правильно тестировать ваши приложения.

## Тестирование Node.js-приложений

Вы можете рассматривать тесты как гарантии надёжности ваших приложений. Они будут запускаться не только на вашей локальной машине, но и на CI-сервисах, чтобы сломанные сборки не попадали в продакшен.

>*«Тесты - это больше, чем просто гарантии, они обеспечивают живую документацию для вашей кодовой базы».*

Вы можете спросить: *что я должен протестировать в своём приложении? Сколько тестов у меня должно быть?*

Ответ варьируется, но, как правило, вы можете следовать рекомендациям, установленным **пирамидой тестирования**.

![](NodeHeroEbook-TheComplete-012.png)

По сути, тестовая пирамида описывает, что вы должны писать **модульные тесты**, **интеграционные тесты** и **e2e тесты**. У вас должно быть больше интеграционных тестов, чем e2e и ещё больше модульных тестов.

Давайте посмотрим, как вы можете добавить модульные тесты для своих приложений!

*Обратите внимание, что здесь мы не собираемся говорить об интеграционных и e2e тестах, поскольку они выходят далеко за рамки этого учебника.*

## Модульное тестирование Node.js-приложений

Мы пишем модульные тесты для того, чтобы проверить, работает ли данный модуль (*юнит*). Все зависимости исключаются, что означает, что мы предоставляем поддельные зависимости (*фейки*) для модуля.

**Вы должны писать тесты для публичных методов, а не для внутренней реализации данного модуля.**

### Анатомия модульного теста

Каждый модульный тест имеет следующую структуру:

1. Настройка теста
2. Вызов тестируемого метода
3. Утверждение

**В каждом модульном тесте должна проверяться только одна проблема.** *(Конечно, это не означает, что вы можете добавить только одно утверждение).*

### Библиотеки, используемые для тестирования в Node.js

Для модульного тестирования мы собираемся использовать следующие библиотеки:
* **запуск тестов**: [mocha](https://www.npmjs.com/package/mocha), альтернативно [tape](https://www.npmjs.com/package/tape)
* **библиотека утверждений**: [chai](http://chaijs.com/), альтернативно [assert](https://www.npmjs.com/package/assert)
* **шпионы, стабы и моки**: [sinon](http://sinonjs.org/) *(для настройки тестов)*.

### Шпионы, стабы и моки - что использовать и когда?

Прежде чем приступить к практике модульного тестирования, давайте разберёмся, что такое шпионы, стабы (*заглушки*) и моки!

### Шпионы

Вы можете использовать шпионов для получения информации о вызовах функций, например, сколько раз они были вызваны или какие аргументы были им переданы.

```javascript
it('calls subscribers on publish', function () {
    var callback = sinon.spy()
    PubSub.subscribe('message', callback)

    PubSub.publishSync('message')
    assertTrue(callback.called)
})
// Пример взят из документации Sinon: http://sinonjs.org/docs/
```

### Стабы

Стабы похожи на шпионов, но они заменяют целевую функцию. Вы можете использовать стабы для управления поведением метода, чтобы форсировать какие-то события в коде (например, выброс ошибки) или предотвратить вызовы внешних ресурсов (таких как HTTP API).

```javascript
it('calls all subscribers, even if there are exceptions', function (){
    var message = 'an example message'
    var error = 'an example error message'
    var stub = sinon.stub().throws()
    var spy1 = sinon.spy()
    var spy2 = sinon.spy()

    PubSub.subscribe(message, stub)
    PubSub.subscribe(message, spy1)
    PubSub.subscribe(message, spy2)

    PubSub.publishSync(message, undefined)

    assert(spy1.called)
    assert(spy2.called)
    assert(stub.calledBefore(spy1))
})
// Пример взят из документации Sinon: http://sinonjs.org/docs/
```

### Моки

Моки — это поддельные методы с заранее запрограммированным поведением и соглашениями.

```javascript
it('calls all subscribers when exceptions happen', function () {
    var myAPI = {
        method: function () {}
    }

    var spy = sinon.spy()
    var mock = sinon.mock(myAPI)
    mock.expects("method").once().throws()

    PubSub.subscribe("message", myAPI.method)
    PubSub.subscribe("message", spy)
    PubSub.publishSync("message", undefined)

    mock.verify()
    assert(spy.calledOnce)
})
// Пример взят из документации Sinon: http://sinonjs.org/docs/
```

Как вы можете видеть, для моков вы должны заранее определить соглашения.

Представьте, что вы хотите протестировать следующий модуль:

```javascript
const fs = require('fs')
const request = require('request')

function saveWebpage (url, filePath) {
    return getWebpage(url,  lePath)
        .then(writeFile)
}

function getWebpage (url) {
    return new Promise (function (resolve, reject) {
        request.get(url, function (err, response, body) {
            if (err) {
                return reject(err)
            }

            resolve(body)
        })
    })
}

function writeFile (fileContent) {
    let  lePath = 'page'
    return new Promise (function (resolve, reject) {
        fs.writeFile(filePath, fileContent, function (err) {
            if (err) {
                return reject(err)
            }
            resolve(filePath)
        })
    })
}

module.exports = {
    saveWebpage
}
```

Этот модуль делает одну вещь: он сохраняет веб-страницу (основываясь на переданном URL) в файл на локальном компьютере. Чтобы протестировать этот модуль, мы должны «застабить» как модуль `fs`, так и модуль `request`.

Прежде чем начинать писать модульные тесты, в RisingStack мы обычно добавляем файл `test-setup.spec.js` для создания базовой настройки тестов, например создания песочниц Sinon. Это избавит вас от написания `sinon.sandbox.create()` и `sinon.sandbox.restore()` после каждого теста.

```javascript
// test-setup.spec.js
const sinon = require('sinon')
const chai = require('chai')

beforeEach(function () {
    this.sandbox = sinon.sandbox.create()
})

afterEach(function () {
    this.sandbox.restore()
})
```

Кроме того, обратите внимание, что мы всегда ставим файлы тестов рядом с реализацией и даём им имя вида `.spec.js`. В нашем `package.json` вы можете найти следующие строки:

```javascript
{
    "test-unit": "NODE_ENV=test mocha '/**/*.spec.js'",
}
```

Как только у нас появились эти настройки, пришло время написать сами тесты!

```javascript
const fs = require('fs')
const request = require('request')

const expect = require('chai').expect

const webpage = require('./webpage')

describe('The webpage module', function () {
    it('saves the content', function * () {
        const url = 'google.com'
        const content = '<h1>title</h1>'
        const writeFileStub = this.sandbox.stub(fs, 'writeFile', function ( filePath, fileContent, cb) {
            cb(null)
        })

        const requestStub = this.sandbox.stub(request, 'get', function (url, cb) {
            cb(null, null, content)
        })

        const result = yield webpage.saveWebpage(url)

        expect(writeFileStub).to.be.calledWith()
        expect(requestStub).to.be.calledWith(url)
        expect(result).to.eql('page')
    })
})
```

Полные исходники примера вы можете найти [здесь](https://github.com/RisingStack/nodehero-testing).

## Покрытие кода

Чтобы лучше понять, насколько хорошо ваша кодовая база покрыта тестами, вы можете сгенерировать отчёт о покрытии.

Этот отчёт будет включать следующие метрики:

* покрытие **строк кода**,
* покрытие **инструкций**,
* покрытие **ветвлений**,
* и покрытие **функций**.

В RisingStack мы используем [istanbul](https://github.com/gotwarlost/istanbul) для анализа покрытия кода. Вы должны добавить следующий скрипт к вашему `package.json`, чтобы использовать `istanbul` с `mocha`:

```
istanbul cover _mocha $(find ./lib -name \"*.spec.js\" -not -path \"./node_modules/*\")
```

Как только вы это сделаете, вы получите что-то вроде:

![](NodeHeroEbook-TheComplete-013.png)

Вы можете кликнуть мышью и на самом деле увидеть, что ваш исходный код аннотирован: какая часть протестирована, а какая — нет.

---

Тестирование может уберечь вас от множества неприятностей. Тем не менее, неизбежно наступает время отладки. В следующей главе Node Hero вы узнаете, **как отлаживать Node.js-приложения**.

---

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Глава на Medium](https://medium.com/devschacht/node-hero-chapter-9-68041507aec)
