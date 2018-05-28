# Аутентификация в Node.js с использованием Passport.js
*Перевод книги [Node Hero](https://risingstack.com/resources/node-hero) от [RisingStack](https://risingstack.com/). Переведено с разрешения правообладателей.*

В этой главе вы узнаете, как реализовать стратегию локальной аутентификации в Node.js приложении с использованием Passport.js и Redis.

## Технологии, которые мы будем использовать

Прежде чем перейти к написанию кода, давайте рассмотрим новые технологии, которые мы будем использовать в этой главе.

### Что такое Passport.js?

*Простая ненавязчивая аутентификация для Node.js - [passportjs.org](http://www.passportjs.org/)*

![](NodeHeroEbook-TheComplete-011.png)

Passport.js - это middleware для проверки подлинности. Мы будем исполььзовать её для управления сессиями.

### Что такое Redis?

*Redis это опенсорс (лицензии BSD) хранилище структур данных в оперативной памяти, используемое как база данных, кэш и брокер сообщений — [redis.io](https://redis.io/)*

Мы собираемся хранить информацию о сессии пользователя в Redis, а не в памяти процесса. Таким образом, наше приложение будет намного проще масштабировать.

## Демонстрационное приложение

Для демонстрационных целей создадим приложение, которое умеет только следующее:

* предоставляет форму входа
* предоставляет две защищённые страницы:
    * страницу профиля
    * безопасные заметки

## Структура проекта

Вы уже научились структурировать Node.js-проекты в [предыдущей главе Node Hero](https://medium.com/devschacht/node-hero-chapter-7-4078fa61ece6), поэтому давайте использовать эти знания!

Мы собираемся использовать следующую структуру:

```
├── app
|   ├── authentication
|   ├── note
|   ├── user
|   ├── index.js
|   └── layout.hbs
├── config
|   └── index.js
├── index.js
└── package.json
```

Как вы можете видеть, мы организуем файлы и каталоги вокруг функций. У нас будет страница пользователя, страница заметок и некоторые функции, связанные с проверкой подлинности.

*(Вы можете скачать исходный код по [ссылке](https://github.com/RisingStack/nodehero-authentication))*

## Процесс аутентификации в Node.js

Наша цель - реализовать в нашем приложении следующий процесс аутентификации:

1. Пользователь вводит имя и пароль
2. Приложение проверяет, являются ли они корректными
3. Если имя и пароль корректны, приложение отправляет заголовок `Set-Cookie`, который будет использоваться для аутентификации дальнейших страниц
4. Когда пользователь посещает страницы в том же домене, ранее установленный cookie добавляется ко всем запросам
5. Аутентификация на закрытых страницах происходит с помощью этого файла cookie

Чтобы настроить такую стратегию аутентификации, выполните следующие три действия:

1. Настройте Express
2. Настройте Passport
3. Добавьте защищённые разделы на сайте

## Шаг 1: Настройка Express

Мы будем использовать Express для серверной среды. Вы можете узнать больше на эту тему, перечитав главу [«Ваш первый сервер на Node.js»](https://medium.com/devschacht/node-hero-chapter-4-c2ebcd12565c).

```javascript
// file:app/index.js
const express = require('express')
const passport = require('passport')
const session = require('express-session')
const RedisStore = require('connect-redis')(session)

const app = express()
app.use(session({
    store: new RedisStore({
        url: config.redisStore.url
    }),
    secret: config.redisStore.secret,
    resave: false,
    saveUninitialized: false
}))
app.use(passport.initialize())
app.use(passport.session())
```

Что мы тут делаем?

Прежде всего, нам нужны все зависимости, требующиеся для управления сессией. После этого мы создали новый экземпляр из модуля `express-session`, который будет хранить наши сессии.

Для хранения сессий мы используем Redis, но вы можете использовать любые другие, такие как MySQL или MongoDB.

## Шаг 2: Настройка Passport

Passport.js — отличный пример библиотеки, использующей плагины. В этом уроке мы добавляем модуль `passport-local`, который добавляет простую локальную стратегию аутентификации с использованием имён пользователей и паролей.

Для простоты в этом примере (см. ниже) мы не используем базу данных, вместо неё используется экземпляр объекта пользователя в памяти. В реальных приложениях `findUser` будет искать пользователя в базе данных.

```javascript
file:app/authenticate/init.js
const passport = require('passport')
const LocalStrategy = require('passport-local').Strategy

const user = {
    username: 'test-user',
    password: 'my-password',
    id: 1
}
passport.use(new LocalStrategy(
    function(username, password, done) {
        findUser(username, function (err, user) {
            if (err) {
                return done(err)
            }
            if (!user) {
                return done(null, false)
            }
            if (password !== user.password ) {
                return done(null, false)
            }
            return done(null, user)
        })
    }
))
```

Как только findUser возвращается с нашим объектом пользователя, остаётся только сравнить введённый пользователем и реальный пароли, чтобы увидеть, есть ли совпадение.

Если они совпадают, мы разрешаем пользователю войти (возвращая объект пользователя в `passport` - `return done(null, user)`), если нет — возвращаем ошибку авторизации (путём возврата `null` - `return done(null)`).

*Примечание переводчика: в настоящих приложениях стараются никогда не хранить пароли пользователей в открытом виде. В базу данных записывают хэш пароля и сравнивают его с хэшом значения, введённого пользователем.*

## Шаг 3: Добавляем защищённые разделы на сайте

Чтобы добавить защищенные разделы на сайт, мы используем шаблон middleware Express. Для этого сначала создадим middleware для аутентификации:

```javascript
// file:app/user/init.js
const passport = require('passport')

app.get('/profile', passport.authenticationMiddleware(), renderProfile)
```

Она имеет только одну задачу: если пользователь аутентифицирован (имеет правильные cookie-файлы), она просто вызывает следующую middleware. В противном случае пользователь перенаправляется на страницу, где он может войти в систему.

Использование этой middleware также просто, как добавление любой другой middleware в определение роута.

```javascript
// file:app/authentication/middleware.js
function authenticationMiddleware () {
    return function (req, res, next) {
        if (req.isAuthenticated()) {
            return next()
        }
        res.redirect('/')
    }
}
```

## Резюме

В этом разделе учебника по Node.js вы узнали, как добавить базовую аутентификацию в ваше приложение. Позже вы можете расширить его с помощью различных стратегий аутентификации, таких как Facebook или Twitter. Вы можете найти больше стратегий по адресу [http://passportjs.org/](http://passportjs.org/).

Полный рабочий пример нашего демонстрационного приложения вы можете найти на [GitHub](https://github.com/RisingStack/nodehero-authentication).

---

Следующая глава Node Hero будет посвящена юнит-тестированию Node.js приложений. Вы узнаете такие концепции, как юнит-тестирование, пирамида тестирования, дублёры и многое другое!

---

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Глава на Medium](https://medium.com/devschacht/node-hero-chapter-8-27b74c33a5ce)
