# Исчерпывающее руководство по написанию Dockerfile для веб-приложений на Node.js

*Перевод статьи [Praveen Durairaj](http://twitter.com/PraveenWeb): [An Exhaustive Guide to Writing Dockerfiles for Node.js Web Apps](https://blog.hasura.io/an-exhaustive-guide-to-writing-dockerfiles-for-node-js-web-apps-bbee6bd2f3c4). Опубликовано с разрешения автора.*

![](https://cdn-images-1.medium.com/max/800/1*4KhmpXFJ_Etczs6awRnAbg.png)

## TL;DR

Данный пост состоит из нескольких примеров, начиная от простого Dockerfile до многоэтапных продакшен-сборок для веб-приложений Node.js. Краткое описание того, что охватывает данное руководство:

- Использование соответствующего базового образа (carbon для разработки, alpine для продакшена).
- Использование nodemon для горячей перезагрузки во время разработки.
- Оптимизация для уровней кеша Docker — размещение команд в правильном порядке, так что `npm install` выполняется только при необходимости.
- Обслуживание статических файлов (бандлов, созданных React/Vue/Angular), используя пакет `serve`.
- Использование многоэтапной сборки `alpine` для уменьшения окончательной продакшен-сборки.
- Советы профи: 1) Использование COPY вместо ADD 2) Обработка сигналов ядра (kernel signals) при нажатии CTRL-C при помощи флага `init`

Если вы сразу хотите перейти к коду, посмотрите [репозиторий на GitHub](https://github.com/praveenweb/node-docker).

## Оглавление 

1. [Простой Dockerfile и .dockerignore](#1-%D0%9F%D1%80%D0%BE%D1%81%D1%82%D0%BE%D0%B9-%D0%BF%D1%80%D0%B8%D0%BC%D0%B5%D1%80-dockerfile)
2. [Горячая перезагрузка с nodemon](#2-%D0%93%D0%BE%D1%80%D1%8F%D1%87%D0%B0%D1%8F-%D0%BF%D0%B5%D1%80%D0%B5%D0%B7%D0%B0%D0%B3%D1%80%D1%83%D0%B7%D0%BA%D0%B0-%D1%81-nodemon)
3. [Оптимизации](#3-%D0%9E%D0%BF%D1%82%D0%B8%D0%BC%D0%B8%D0%B7%D0%B0%D1%86%D0%B8%D0%B8)
4. [Обслуживание статических файлов](#4-%D0%9E%D0%B1%D1%81%D0%BB%D1%83%D0%B6%D0%B8%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5-%D1%81%D1%82%D0%B0%D1%82%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%B8%D1%85-%D1%84%D0%B0%D0%B9%D0%BB%D0%BE%D0%B2)
5. [Одноэтапная продакшен-сборка](#5-%D0%9E%D0%B4%D0%BD%D0%BE%D1%8D%D1%82%D0%B0%D0%BF%D0%BD%D0%B0%D1%8F-%D0%BF%D1%80%D0%BE%D0%B4%D0%B0%D0%BA%D1%88%D0%B5%D0%BD-%D1%81%D0%B1%D0%BE%D1%80%D0%BA%D0%B0)
6. [Многоэтапная продакшен-сборка](#6-%D0%9C%D0%BD%D0%BE%D0%B3%D0%BE%D1%8D%D1%82%D0%B0%D0%BF%D0%BD%D0%B0%D1%8F-%D0%BF%D1%80%D0%BE%D0%B4%D0%B0%D0%BA%D1%88%D0%B5%D0%BD-%D1%81%D0%B1%D0%BE%D1%80%D0%BA%D0%B0)

Давайте представим простую структуру каталогов. Наше приложение будет называться `node-app`. В каталоге верхнего уровня есть два файла: `Dockerfile` и `package.json`. Исходный код node-приложения будет находятся в каталоге `src`. Для краткости предположим, что файл `server.js` содержит код Express-сервера, запущенного на порте `8080`.

```
node-app
├── Dockerfile
├── package.json
└── src
    └── server.js
```

## 1. Простой пример Dockerfile

<script src="https://gist.github.com/lex111/90acdd955201189677b9364d024c1327.js"></script>

Для базового образа мы использовали последнюю LST-версию `node:carbon`.

Во время сборки образа Docker берёт все файлы в директории приложения. Для увеличения производительности сборки Docker, исключим файлы и директории, добавив файл `.dockerignore`.

Как правило, ваш файл `.dockerignore` должен быть таким:

```
.git
node_modules
npm-debug
```

Соберём и запустим этот образ:

```sh
$ cd node-docker
$ docker build -t node-docker-dev .
$ docker run --rm -it -p 8080:8080 node-docker-dev
```

Приложение будет доступно по URL http://localhost:8080. Используйте `Ctrl+C` для завершения сервера.

Теперь предположим, что вы хотите, чтобы сборка пересобиралась при каждом изменении кода, то есть во время разработки. Тогда вы должны примонтировать файлы исходного кода в контейнер при запуске и остановки node-сервера.

```sh
$ docker run --rm -it -p 8080:8080 -v $(pwd):/app \
             node-docker-dev bash
root@id:/app# node src/server.js
```

## 2. Горячая перезагрузка с Nodemon

[nodemon](https://www.npmjs.com/package/nodemon) — популярный пакет, который будет отслеживать файлы в каталоге, в котором он был запущен. Если какие-нибудь файлы будут изменены, то nodemon автоматически перезагрузит ваше приложение.

<script src="https://gist.github.com/lex111/f05fcce2c9e8b1dcd17cd923c955cb6b.js"></script>

Мы соберём образ и запустим nodemon, чтобы код приложения обновлялся всякий раз, когда в директории `app` происходят изменения.

```sh
$ cd node-docker
$ docker build -t node-hot-reload-docker .
$ docker run --rm -it -p 8080:8080 -v $(pwd):/app \
             node-hot-reload-docker bash
root@id:/app# nodemon src/server.js
```

Все изменения в папке `app` будут вызывать пересборку приложения, и изменения будут доступны в режиме реального времени по URL `http://localhost:8080`. Обратите внимание, что мы примонтировали файлы приложения в контейнер, чтобы nodemon мог работать.

## 3. Оптимизации

В вашем Dockerfile предпочитайте COPY вместо использования ADD, если вы не пытаетесь добавить tar-файлы для автоматической распаковки, следуя [лучшим практикам Docker](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#add-or-copy).

Откажитесь от использования команды `start` в файле `package.json` и выполняйте её непосредственно. Поэтому вместо этого:

```
$ CMD ["npm", "start"]
```

Вы можете использовать это в вашем Dockerfile:

```
$ CMD ["node", "server.js"]
```

Это уменьшает количество запущенных процессов внутри контейнера, а также вызывает сигналы выхода, такие как `SIGTERM` и `SIGINT`, которые должны быть получены процессом Node.js вместо npm, подавляя их. (см. подробнее — [лучшие практики Docker и Node.js](https://github.com/nodejs/docker-node/blob/master/docs/BestPractices.md#cmd))

Вы также можете использовать флаг `--init` для оборачивания вашего процесса Node.js в [лёгкую систему инициализации](https://github.com/krallin/tini), которая будет реагировать на сигналы ядра, такие как `SIGTERM` (`CTRL-C`) и т.д. Например, вы можете сделать так:

```sh
$ docker run --rm -it --init -p 8080:8080 -v $(pwd):/app \
             node-docker-dev bash
```

## 4. Обслуживание статических файлов

В приведённом выше Dockerfile предполагается, что вы используете API-сервер на Node.js. Допустим, вы хотите обслуживать приложение на React.js/Vue.js/Angular, используя Node.js.

<script src="https://gist.github.com/lex111/e8e50c64a67664e2a7d653517cd384ae.js"></script>

Как вы можете увидеть выше, мы используем пакет [serve](https://www.npmjs.com/package/serve) для обслуживания статических файлов. Предполагая, что вы создаёте UI-приложение с помощью React/Vue/Angular, вы в идеале собираете окончательный бандл, используя `npm run build`, который будет создавать минифицированные JS и CSS-файлы.

Другой альтернативой является либо: 1) собирать файлы локально и использовать nginx docker для обслуживания этих статических файлов или 2) использовать конвейер (pipeline) CI/CD.

## 5. Одноэтапная продакшен-сборка

<script src="https://gist.github.com/lex111/e66a33435c0576d1feab13f3a7c99e61.js"></script>

Соберите и запустите образ "всё в одном":

```sh
$ cd node-docker
$ docker build -t node-docker-prod .
$ docker run --rm -it -p 8080:8080 node-docker-prod
```

Созданный образ будет весит приблизительно 700 Мб (в зависимости от вашей кодовой базы) из-за основного слоя Debian. Давайте посмотрим, как мы можем уменьшить размер.


## 6. Многоэтапная продакшен-сборка

С многоэтапной сборкой вы используете несколько выражений `FROM` в своём Dockerfile, но окончательный этап сборки будет использовать только одно из них, и в идеале это будет крошечный продакшен-образ с точно указанными зависимостями, требуемыми в продакшен-сервере.

<script src="https://gist.github.com/lex111/e6309d5588ccaeb44ca15c81ff691dd1.js"></script>

В вышеприведённом сниппете образ, собранный с Alpine, занимает около 70 Мб, тем самым уменьшая размер в 10 раз. Вариант с использованием `alpine` обычно является очень безопасным выбором для уменьшения размеров образов.

Есть предложения по улучшению руководства? Или другие варианты использования, которые вы хотели бы видеть? Дайте мне знать в комментариях.

Присоединяйтесь к дискуссии на [Reddit](https://www.reddit.com/r/node/comments/7vw6gj/an_exhaustive_guide_to_writing_dockerfiles_for/) или [HackerNews](https://news.ycombinator.com/item?id=16330793) :)

- - -

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*
