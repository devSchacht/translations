# Использование code coverage – нового инструмента Chrome DevTools.

*Перевод заметки [Ben Edelstein](https://blog.logrocket.com/@edelstein): [Using the Chrome devtools new code coverage feature](https://blog.logrocket.com/using-the-chrome-devtools-new-code-coverage-feature-ca96c3dddcaf)*

Code coverage (инструмент анализа покрытия кода) наконец-то вышел из стадии экспериментов и уже появился в [Chrome Canary](https://www.google.com/chrome/browser/canary.html) и скоро будет доступен для всех. Это интересный инструмент, который пригодится как при работе с JavaScript, так и с CSS, поэтому я решил сделать быстрое демо и изучить, какую он может принести пользу.

## Для чего он предназначен?
Code coverage запускает ваше веб-приложение и даёт возможно увидеть для каждого JS/CSS файла, какие строки кода выполнялись, а какие нет.

![](https://cdn-images-1.medium.com/max/800/1*gD8lX40PSemDOZgvT695Mg.png)

Здесь я запустил простую статическую веб-страницу, и Chrome создал эту разбивку файлов CSS и JS, которые на ней подключались. Полосы справа показывают относительный размер каждого файла, красный – неиспользованный код, а зеленый – код, который запускался.

Запись code coverage работает аналогично таймлайнам devtools – вы нажимаете кнопку записи, а затем взаимодействуете с вашим сайтом в обычном режиме. Как только вы закончите, Chrome выполнит некоторые вычисления и сгенерирует данные. Здесь мне было интересно, сколько неиспользованных CSS было на сайте, поэтому я перешёл на различные подстраницы, чтобы убедиться, что я попал в каждую "ветку кода" CSS. Конечно же, здесь есть много возможностей для улучшения, так как 97% css на моем сайте не использовались!

![](https://cdn-images-1.medium.com/max/800/1*1SUTeKlhRee3MyKdxkUGtQ.png)

Chrome также позволяет вам подробно изучить покрытие кода отдельных файлов. Здесь красные и зелёные полосы слева показывают, какие конкретно строки исполнялись, а какие нет. Обратите внимание, что при проверке минифицированных файлов вы можете нажать кнопку в нижнем левом углу файла, чтобы развернуть ваш код в удобночитаемый вид.

## Почему это полезно?
При работе над сложным или долгосрочным проектом легко накапливается мертвый код. Если вы используете webpack или другую систему сборки JS, есть инструменты для предотвращения попадания мёртвого JS кода в продакшен. Но для CSS сделать это несколько сложнее. Наличие инструмента анализа покрытия кода в Chrome – отличный способ получить краткий обзор того, сколько лишнего кода вы отправляете в продакшен, и какие файлы стоит оптимизировать.

## Как его получить?
Загрузите [Chrome Canary](https://www.google.com/chrome/browser/canary.html) или подождите несколько недель, пока он появится в обычном Chrome.

## Стоит почитать
- Более полезные (и менее известные) инструменты в Chrome devtools: [https://blog.logrocket.com/making-the-most-of-the-chrome-developer-tools-8cac9a206979](https://blog.logrocket.com/making-the-most-of-the-chrome-developer-tools-8cac9a206979)

- Визуализация производительности бэкенда в Chrome devtools: https://blog.logrocket.com/visualizing-backend-performance-in-the-chrome-devtools-bb6fd232540

*Примечание переводчика: для тех, кто не может найти этот новый инструмент в Chrome devtools, я в свою очередь подготовил небольшое демо.*

![](https://cdn-images-1.medium.com/max/1440/1*Sh5v8Fsi21CTzuQ3eHRg4A.gif)

- - - -

*Читайте нас на [Медиуме](https://medium.com/devschacht), контрибьютьте на [Гитхабе](https://github.com/devSchacht), общайтесь в [группе Телеграма](https://t.me/devSchacht), следите в [Твиттере](https://twitter.com/DevSchacht) и [канале Телеграма](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht). Скоро подъедет подкаст, не теряйтесь.*

[Статья на Medium](https://medium.com/devschacht/using-the-chrome-devtools-new-code-coverage-feature-6535bc26c97b)
