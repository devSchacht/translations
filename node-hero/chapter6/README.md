# Модуль Request
*Перевод книги [Node Hero](https://risingstack.com/resources/node-hero) от [RisingStack](https://risingstack.com/). Переведено с разрешения правообладателей.*

В следующей главе вы узнаете основы HTTP и как вы можете получать ресурсы из внешних источников с помощью модуля Node.js `request`.

## Что такое HTTP?

HTTP - это протокол передачи гипертекста. HTTP функционирует как протокол запроса-ответа в модели клиент-сервер.

## Коды состояния HTTP

Прежде чем погрузиться в общение с другими API-интерфейсами, давайте рассмотрим коды состояния HTTP, с которыми мы можем столкнуться во время работы нашего приложения. Они описывают результаты наших запросов и очень важны для обработки ошибок.

* 1xx — Информационный
* 2xx — Успех: Эти коды состояния говорят о том, что наш запрос был получен и обработан правильно. Наиболее распространённые коды успеха - `200 OK`, `201 Created` и `204 No Content`.
* 3xx — Редирект: Эта группа кодов показывает, что клиент должен будет выполнить дополнительные действия для завершения запроса. Наиболее распространёнными кодами перенаправления являются `301 Moved Permanently`, `304 Not Modified`.
* 4xx — Ошибка клиента. Этот класс кодов состояния используется, когда запрос, отправленный клиентом,  содержит какую-то ошибку. Ответ сервера обычно содержит объяснение ошибки. Наиболее распространёнными кодами ошибок клиента являются `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict`.
* 5xx - Ошибка сервера: эти коды отправляются, когда сервер не смог выполнить корректный запрос из-за какой-то ошибки. Причиной может быть ошибка в коде или некоторая временная или постоянная неисправность. Наиболее распространённые коды ошибок сервера: `500 Internal Server Error`, `503 Service Unavailable`.

Если вы хотите узнать больше о кодах состояния HTTP, вы можете найти подробное объяснение [здесь](http://www.restapitutorial.com/httpstatuscodes.html).

## Отправка запросов внешним API

Подключение к внешним API-интерфейсам — простая задача в Node. Вы можете просто подключить базовый [модуль HTTP](https://nodejs.org/api/http.html) и начать отправку запросов.

Конечно, есть способы обращения к внешним API намного лучше. В NPM вы можете найти несколько модулей, которые облегчат вам этот процесс. Например, двумя наиболее популярными являются модули [request](https://www.npmjs.com/package/request) и [superagent](https://www.npmjs.com/package/superagent).

Оба этих модуля имеют интерфейс, построенный на колбеках, который может привести к проблемам (я уверен, вы слышали о *Callback-Hell*), но, к счастью, у нас есть доступ к версиям, обёрнутым в промисы.

## Использование модуля Request

Использование модуля [request-promise](https://www.npmjs.com/package/request-promise) — это очень просто. После установки из NPM вам нужно только подключить его к программе:

```javascript
const request = require('request-promise')
```

Отправка GET-запроса:

```javascript
const options = {
    method: 'GET',
    uri: 'https://risingstack.com'
}

request(options)
    .then(function (response) {
        // Запрос был успешным, используйте объект ответа как хотите
    })
    .catch(function (err) {
        // Произошло что-то плохое, обработка ошибки
    })
```

Если вы вызываете JSON API, вам может потребоваться, чтобы `request-promise` автоматически распарсил ответ. В этом случае просто добавьте это в параметры запроса:

```javascript
json: true
```

POST-запросы работают аналогичным образом:

```javascript
const options = {
    method: 'POST',
    uri: 'https://risingstack.com/login',
    body: {
       foo: 'bar'
    },
    json: true
    // Тело запроса приводится к формату JSON автоматически
}

request(options)
    .then(function (response) {
        // Обработка ответа
    })
    .catch(function (err) {
        // Работа с ошибкой
    })
```

Чтобы добавить параметры строки запроса, вам просто нужно добавить свойство `qs` к объекту `options`:

```javascript
const options = {
    method: 'GET',
    uri: 'https://risingstack.com',
    qs: {
        limit: 10,
        skip: 20,
        sort: 'asc'
    }
}
```

Этот код соберёт следующий URL для запроса: `https://risingstack.com?limit=10&skip=20&sort=asc`. Вы также можете назначить любой заголовок так же, как мы добавили параметры запроса:

```javascript
const options = {
    method: 'GET',
    uri: 'https://risingstack.com',
    headers: {
        'User-Agent': 'Request-Promise',
        'Authorization': 'Basic QWxhZGRpbjpPcGVuU2VzYW1l'
    }
}
```

## Обработка ошибок

Обработка ошибок - это неотъемлемая часть запросов на внешние API, поскольку мы никогда не можем быть уверены в том, что с ними произойдёт. Помимо наших ошибок клиента сервер может ответить с ошибкой или просто отправить данные в неправильном или непоследовательном формате. Помните об этом, когда вы пытаетесь обработать ответ. Кроме того, использование `catch` для каждого запроса - хороший способ избежать сбоя на нашем сервере по вине внешнего сервиса.

## Объединяем всё вместе

Поскольку вы уже узнали, как развернуть HTTP-сервер на Node.js, как отрисовать HTML и как получить данные из внешних API, пришло время собрать эти знания вместе!

В этом примере мы собираемся создать небольшое приложение на Express, отображающее текущие погодные условия на основе названий городов.

(Чтобы получить ключ для API AccuWeather, посетите их [сайт для разработчиков](http://apidev.accuweather.com/developers/samples))

```javascript
const express = require('express')
const rp = require('request-promise')
const exphbs = require('express-handlebars')
const path = require('path')
const app = express()

app.engine('.hbs', exphbs({
    defaultLayout: 'main',
    extname: '.hbs',
    layoutsDir: path.join(__dirname, 'views/layouts')
}))
app.set('view engine', '.hbs')
app.set('views', path.join(__dirname, 'views'))

app.get('/:city', (req, res) => {
    rp({
        uri: 'http://dataservice.accuweather.com/locations/v1/cities/search',
        qs: {
            q: req.params.city,
            apikey: 'api-key'
            // Используйте ваш ключ для accuweather API
                
        },
        json: true
    })
    .then((data) => {
        res.render('home', {
            res: JSON.stringify(data)
        })
    })
    .catch((err) => {
        console.log(err)
        res.render('error')
    })
})

app.listen(3000)
```

Пример выше делает следующее:
* создаёт Express-сервер
* устанавливает handlebars в качестве шаблонизатора
* отправляет запрос к внешнему API
    * если все в порядке, то приложение отображает страницу
    * в противном случае приложение показывает страницу неудачи и регистрирует ошибку

---

В следующей главе Node Hero вы узнаете, какая файловая структура предпочтительней в Node.js проектах.

---

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Глава на Medium](https://medium.com/devschacht/node-hero-chapter-6-83bc7bef89fb)
