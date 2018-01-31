# Используем axios вместе с Vue.js

*Перевод статьи [Joshua Bemenderfer](https://alligator.io/author/joshua-bemenderfer): [Vue.js REST API Consumption with Axios](https://alligator.io/vuejs/rest-api-axios/)*

Довольно много фреймворков уже имеют свои встроенные модули для работы с API. Во втором Ангуляре это http-модуль, в jquery это $.ajax, и вплоть до версии 2.0, vue так же имел свой модуль для работы с api — vue-resource.

Начиная с версии 2.0 разработчики vue.js посчитали наличие встроенного http модуля избыточным, и теперь считается хорошим тоном использовать сторонние решения.

Таким решением и является Axios

Axios это отличная клиентская библиотека, которая использует промисы по умолчанию, а так же работает как на сервере(что делает его подходящим для получения данных при рендеринге на сервере), так и на клиенте. Axios очень легко начать использовать с vue.
Приступим!

## Установка
```
$ yarn add axios
$ npm i axios -S
```
## Получаем данные с помощью GET запроса

Это считается плохой практикой, однако вы можете использовать axios непосредственно в своих компонентах, в хуках жизненного цикла, из метода либо любым другим способом.
![](https://cdn-images-1.medium.com/max/1000/1*22UtBn0CprqFqiPIRsMyqQ.png)
## Отправляем данные POST запросом
Список запросов которые можно сделать: PUT, DELETE, PATH и POST
![](https://cdn-images-1.medium.com/max/800/1*8J72eWRgsGAdZ91NcdDQlg.png)

## Common Base Instance
Часто забываемая, но очень полезная возможность, предоставляемая axios, — это возможность создать базовый экземпляр, который позволяет вам обмениваться общим базовым URL-адресом и конфигурацией во всех вызовах экземпляра. Это пригодится, если все ваши вызовы относятся к определенному серверу или им необходимо обмениваться заголовками, например заголовком авторизации.

![](https://cdn-images-1.medium.com/max/800/1*WikUlFkZMu0wl53yV8pMbw.png)
Теперь можно использовать http вот так:
![](https://cdn-images-1.medium.com/max/800/1*k6UP8QiVNMsOX4Bi4DlCkA.png)

## Итог:
Мы рассмотрели лишь базовые возможности axios, дополнительная информация и документация на [официальном сайте](https://github.com/mzabriskie/axios).
- - - -

*Читайте нас на [Медиуме](https://medium.com/devschacht), контрибьютьте на [Гитхабе](https://github.com/devSchacht), общайтесь в [группе Телеграма](https://t.me/devSchacht), следите в [Твиттере](https://twitter.com/DevSchacht) и [канале Телеграма](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht). Скоро подъедет подкаст, не теряйтесь.*

[Статья на Medium](https://medium.com/@vik_kod/%D0%B8%D1%81%D0%BF%D0%BE%D0%BB%D1%8C%D0%B7%D1%83%D0%B5%D0%BC-axios-%D0%B2%D0%BC%D0%B5%D1%81%D1%82%D0%B5-%D1%81-vue-js-3bc45464c460)
