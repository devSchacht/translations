# Гонка за скоростью: ускоряем загрузку сайтов в эпоху смартфонов

![](https://cdn-images-1.medium.com/max/800/1*5XLwaxHp9Yk6xUrqr7PCKg.png)

Смартфоны давно стали частью нашей жизни. Мы просыпаемся утром и проверяем социальные сети, читаем почту, открываем ссылки. Мы живём в эпоху смартфонов, начавшуюся в 2007 году, когда Стив Джобс вышел на сцену в Сан-Франциско и показал первый iPhone. Это был телефон, в который тогда мало кто верил, у которого даже не было возможности установки приложений. Однако уже тогда в нём был прекрасный браузер, которым можно было управлять без стилуса и который позволял с относительным удобством читать *обычные* сайты. Через год вышла первая версия Android, впитавшая и переосмыслившая идеи iPhone. И вот тогда, когда простые люди (не гики с КПК и коммуникаторами) отложили в сторону свои устаревшие кнопочные телефоны, тогда и началось победное шествие мобильного Интернета.

Спустя несколько лет это привело к тому, что мобильный трафик превысил десктопный. А вместе с этим событием мобильный Интернет прекратил своё существование. Мобильный Интернет перестал быть подмножеством Большого Интернета, он и есть Самый Настоящий Интернет. Уже не существует Mobile First, перед нами просто разные размеры экранов и разные каналы связи и все они должны обеспечивать одинаково хороший пользовательский опыт.

В этой статье я расскажу о том, какие современные средства существуют для того, чтобы улучшить пользовательский опыт для вашего сайта.

## Метрики

> В 53% случаев пользователи отказываются от дальнейшей загрузки мобильного сайта, если она требует более 3-х секунд ожидания.
>
> Каждый второй пользователь ожидает, что страница загрузится менее чем за 2 секунды.
> [bit.ly/mobile-speed1](bit.ly/mobile-speed1)

Это тайминги, о которых мы должны помнить. Но возникает вопрос, что значит это понятие «Сайт загрузился»? В какой момент времени мы можем так сказать? Существуют три наиболее важные метрики:

1. Первое отображение (First Paint)
2. Первое значимое отображение (First Meaningful Paint)
3. Первая интерактивность (First Interactive)

**Первое отображение** — на вашем сайте что-то появилось. Это уже не пустая белая страница, пользователь понимает, что всё работает.

**Первое значимое отображение** — на вашем сайте появилось что-то полезное, пользователь может начать им пользоваться, например, читать текст.

**Первая интерактивность** — все скрипты проинициализированы и можно начать пользоваться интерактивными элементами. Обычно это можно отследить по падению загрузки процессора.

За этими метриками можно следить в Chrome DevTools, используя вкладку **Performace**. Это достаточно наглядный способ, но предназначен он скорее для отладки, а не для предрелизного и пострелизного аудита.

![](https://cdn-images-1.medium.com/max/1600/1*-sd0XMhxL44yvrnAN-LtTg.png)

В случае ручного снятия метрик всегда нужно помнить о том, что ваши пользователи со смартфонами используют зачастую достаточно ненадёжный и медленный канал, а так же устройства с не самыми быстрыми процессорами. Для эмуляции такого поведения Google Chrome предоставляет инструменты троттлинга канала и процессора:

![](https://cdn-images-1.medium.com/max/2000/1*Sbc8u2rp7SsBQAHaVYE-AA.png)

![](https://cdn-images-1.medium.com/max/2000/1*UOHwhOBYqpHo72KRX9Qe2w.png)

Более удобный подход даёт нам использование [Google Lighthouse](https://developers.google.com/web/tools/lighthouse/) — инструмента для комплексного аудита сайта. Нажимаем одну кнопку, ждём несколько секунд и получаем все метрики.

![](https://developers.google.com/web/tools/lighthouse/images/report.png)

Однако при CI хотелось бы автоматизировать снятие метрик. На помощь могут прийти как сторонние инструменты, такие как [calibreapp.com](calibreapp.com), способные автоматически анализировать заданный сайт и оповещать в случае превышения заданного бюджета для каждой из метрик, так и собственные решения, построенные на [Navigation Timing API](https://developer.mozilla.org/ru/docs/Web/API/Navigation_timing_API). Второй вариант наиболее интересен, так как отражает реальные проблемы реальных пользователей вашего сайта.

## Этапы получения веб-страницы

Получение и отрисовка страницы на сайте происходит в несколько этапов.

### Запрос данных с сервера

![](https://cdn-images-1.medium.com/max/1600/1*6RTdXK1VhUfl6jhwfdU_uA.png)

Смартфон устанавливает сетевое соединение с сервером и получает HTML.

### Получение ресурсов из HTML

![](https://cdn-images-1.medium.com/max/2000/1*Y91UODRMM3s69STy_-Lu_Q.gif)

Браузер анализирует HTML в потоковом режиме и ставит обнаруженные ресурсы в очередь. Все ресурсы получают приоритеты загрузки в зависимости от своего типа: **Lowest**, **Low**, **Medium**, **High** и **Highest**. Подробнее о приоритетах загрузки ресурсов можно прочитать в [статье Бена Шварца «Критический запрос»](https://medium.com/devschacht/the-critical-request-ac20b5267e4a).

### Разбор JavaScript и CSS

* JavaScript - парсинг и компиляция
* CSS - наложение стилей, рендер

> Даже если ваш CSS-файл ссылается на шрифт @font-face, он не будет запрашиваться до тех пор, пока этот шрифт не будет использован в селекторе, а этот селектор будет соответствовать элементу на странице.
> [«Критический запрос»](https://medium.com/devschacht/the-critical-request-ac20b5267e4a)

## Начинаем ускорять: оптимизация порядка доставки ресурсов

![](https://cdn-images-1.medium.com/max/1600/1*N8ZwYztJimjfSmdlctaZsQ.png)

Если мы посмотрим на график загрузки ресурсов, то увидим, что он хаотичен и ресурсы, необходимые в первую очередь (например, шрифты) могут быть расположены на таймлайне весьма далеко от начала запроса. К счастью, у нас есть замечательный способ для управления порядком загрузки ресурсов — `<link rel="preload">`. Мы можем с помощью тега `<link>` передать браузеру список необходимых ресурсов, которые нам **понадобятся позднее**. Таким образом, мы можем указать наш загружаемый шрифт и браузер добавит его в очередь загрузки ещё до того, как начнёт анализировать css.

```html
<link rel="preload" href="//yastatic.net/islands/_/GEumJGdz6PuI2jZ6GhSq0paPvho.woff2" as="font" type="font/woff2" crossorigin>
```

С помощью атрибута `as="font"` мы подсказываем браузеру, что это шрифт и его необходимо загружать с высшим приоритетом.

![](https://cdn-images-1.medium.com/max/800/1*torQAocGkw_Gjn9Sm3LNHQ.png)

Можно заметить, что шрифт начинает загружаться сразу после загрузки HTML. Инициировать предварительную загрузку ресурсов можно не только внутри HTML, но и с помощью HTTP-заголовков.

```
Link: <//yastatic.net/islands/_/GEumJGdz6PuI2jZ6GhSq0paPvho.woff2>; rel=preload; as=font
```

### font-display

Однако у нас всё равно остаётся момент, когда браузер отображает страницу без текста, ожидая загрузки шрифта. К счастью, современные браузеры [начали внедрение](http://caniuse.com/#search=font-display) замечательного CSS-правила **font-display**.

Наиболее полезно для нас его значение `font-display: swap`, которое говорит браузеру, что необходимо сначала показать текст имеющимся шрифтом, а после того как загрузится нужный — подменить на него. `font-display: fallback` работает ещё более хитро — это правило командует браузеру подождать небольшой период времени (100мс для Google Chrome) и если шрифт не загрузился, отобразить текст имеющимся в системе шрифтом, без подмены на загруженный позднее.

## Протокол прикладного уровня

Как бы мы не старались оптимизировать приоритеты загрузки, мы всё равно можем заметить, что ресурсы начинают загружаться в разное время, даже если имеют одинаковый приоритет и встали в очередь одновременно.

![](https://cdn-images-1.medium.com/max/1000/1*RVVOv85QtAq2K0V4exwhFw.png)

Это связано с тем, что браузеры имеют ограничение по количеству параллельных запросов на один домен (в среднем около шести параллельных запросов). Раньше это ограничение обходили, разнося статику по нескольким доменам третьего уровня или вынося её в CDN, что, очевидно, не всегда удобно и доступно (хотя и очень эффективно).

Однако с 2015 года у нас есть протокол HTTP/2, пришедший на смену устаревшему HTTP1.1, который не обновлялся с 1999 года. Протокол [HTTP/2](https://ru.wikipedia.org/wiki/HTTP/2) основан на представленном Google в 2012 году протоколе [SPDY](https://ru.wikipedia.org/wiki/SPDY), разработка и поддержка которого на данный момент [прекращены](http://web.archive.org/web/20150310025724/http://blog.chromium.org/2015/02/hello-http2-goodbye-spdy-http-is_9.html). Наиболее интересно для нас сейчас то, что протокол является бинарным и поддерживает мультиплексирование запросов и ответов — иначе говоря параллельную передачу нескольких запросов в одном TCP-соединении.

![](https://cdn-images-1.medium.com/max/800/1*2f7kJCYLFVJiMUCevh2bgw.png)

### Node.js 8.4.0 ❤️ HTTP/2

Не так давно вышла Node.js версии 8.4.0, включающая в себя экспериментальную поддержку HTTP/2. Это позволяет нам поэкспериментировать с новым протоколом, не подключая никаких дополнительных пакетов. Попробуем написать небольшой сервер, используя новые возможности и новое API.

```javascript
const http2 = require('http2');
const fs = require('fs');
const url = require('url');
const path = require('path');

const options = {
	key: fs.readFileSync('key.pem'),
	cert: fs.readFileSync('cert.pem')
};

const mimeType = {
	'.ico': 'image/x-icon',
	'.html': 'text/html',
	'.js': 'text/javascript',
	'.json': 'application/json',
	'.css': 'text/css',
	'.png': 'image/png',
	'.jpg': 'image/jpeg',
	'.wav': 'audio/wav',
	'.mp3': 'audio/mpeg',
	'.svg': 'image/svg+xml',
	'.pdf': 'application/pdf',
	'.doc': 'application/msword',
	'.eot': 'appliaction/vnd.ms-fontobject',
	'.ttf': 'aplication/font-sfnt'
};

const server = http2.createSecureServer(options);

server.on('stream', (stream, headers) => {

  console.log(`${headers[':method']} ${headers[':path']}`);
  // parse URL
  const parsedUrl = url.parse(headers[':path']);
  // extract URL path
  let pathname = `.${parsedUrl.pathname}`;
  const ext = path.parse(pathname).ext;
  // maps file extention to MIME types
  fs.exists(pathname, function(exist) {
		if (!exist) {
			// if the file is not found, return 404
			stream.respond({':status': 404});
			stream.end(`File ${pathname} not found!`);
			return;
		}

		// if is a directory, then look for index.html
		if (fs.statSync(pathname).isDirectory()) {
			pathname += '/index.html';
		}

		const indexPath = path.join(__dirname, pathname);
		const readStream = fs.createReadStream(indexPath);
		readStream.on('open', function () {
			stream.respond({'content-type': mimeType[ext] || 'text/plain', ':status': 200});
			readStream.pipe(stream);
		});

		readStream.on('error', function(err) {
			stream.respond({':status': 500});
			stream.end(`Error getting the file: ${err}.`);
		});
	 });
});

server.listen(8800);
```

Запускаем наш сервер с ключом `--expose-http2`:

```
node --expose-http2 server.js
```

И видим совершенно другие результаты, ресурсы загружаются параллельно!

![](https://cdn-images-1.medium.com/max/800/1*wy8XexXbh0BFSb9_RllDDw.png)

Обратите внимание, все ресурсы (кроме внешних) имеют один Connection ID.

### Push me!

Другая интересная технология, появившаяся в HTTP/2 — это Server Push. Как видно на графике, мы всё равно продолжаем ожидать окончания загрузки html, чтобы перейти к стадии загрузки ресурсов. Технология Server Push позволяет начать загрузку необходимых ресурсов **одновременно** с загрузкой html.

![](https://cdn-images-1.medium.com/max/800/1*k7MDRXk_HOHHwIopjBRqWw.png)

Давайте научим наш сервер отдавать `common.css` через Server Push.

```javascript
const server = http2.createSecureServer(options);
const commonCSS = fs.readFileSync('common.css');

server.on('stream', (stream, headers) => {

  console.log(`${headers[':method']} ${headers[':path']}`);
  const parsedUrl = url.parse(headers[':path']);

  let pathname = `.${parsedUrl.pathname}`;
  const ext = path.parse(pathname).ext;
  if (headers[':path'] === '/index.html') {
	stream.pushStream({ ':path': 'common.css' }, (pushStream) => {
		pushStream.respond({ ':status': 200, 'content-type': 'text/css'});
		pushStream.end(commonCSS, () => {
		});

	});
	const indexPath = path.join(__dirname, pathname);
	const readStream = fs.createReadStream(indexPath);
	readStream.on('open', function () {
		stream.respond({'content-type': mimeType[ext] || 'text/plain', ':status': 200});
		readStream.pipe(stream);
	});
  } else {
	  // остальная статика
	}
});

server.listen(8800);
```

Что здесь происходит? В тот момент, когда пользователь запрашивает `index.html`, сервер одновременно начинает отдавать ему `common.css`, и когда браузер начнёт анализировать HTML и дойдёт до необходимости загрузки css, файл уже будет частично (или даже полностью) загружен!

### Подводные камни Server Push

Джейк Арчибальд написал замечательную статью [«HTTP/2 Server Push не так прост, как я думал»](https://habrahabr.ru/company/badoo/blog/331216/), в которой рассматривает множество проблем, имеющихся у Server Push на текущий момент. Наиболее важный для нас вопрос — это вопрос кэширования ресурсов. Действительно, в приведённой выше реализации сервера получается, что мы получаем `common.css` каждый раз, когда запрашиваем `index.html`, даже если `common.css` уже есть в кеше браузера. Для обхода этого ограничения есть несколько техник.

### Печеньки!

Удивительно простое решение, которое поддерживается готовыми HTTP/2 серверами, такими как [H2O](https://h2o.examp1e.net/). После первичной загруски, клиент ставит сookie, в которой записывает факт загрузки и кэширования ресурсов текущей версии. Основываясь на этой cookie, сервер принимает решение о том, необходим ли Server Push.

### Server Push ❤️ Service Worker

Более интересное решение доступно владельцам Android (а в скором времени и iOS) — это технология [сервис-воркеров](https://medium.com/high-technologies-center/кто-ты-такой-service-worker-9bce3b1201b6).

Давайте напишем небольшой сервис-воркер, который будет жить в браузере мобильного телефона и держать в себе кэш всех необходимых ресурсов.

![](https://cdn-images-1.medium.com/max/800/1*MLT0qPGJ1JqTyC_mwmXNfQ.png)

Этот сервис-воркер имеет довольно простой код:

```javascript
const cacheName = 'v1';

this.addEventListener('install', function(event) {
  event.waitUntil(
    caches.open(cacheName).then(function(cache) {
      return cache.addAll([
        'index.html',
        'common.css'
      ].map(u => new Request(u, { credentials: 'include' })))
    }).then(()=> console.log('done'))
  );
  this.skipWaiting();
});

this.addEventListener('fetch', function(event) {
  console.log('SW Fetching... ')
  let response;
  event.respondWith(async function() {
    const cachedResponse = await caches.match(event.request);
    if (cachedResponse) return cachedResponse;
    response = await fetch(event.request);
    caches.open(cacheName).then(function(cache) {
      cache.put(event.request, response);
    });
    return response.clone();
  }());
});
```

При первом заходе на сайт пользователь получает код сервис-воркера, который кэширует полученные через Server Push ресурсы и начинает слушать событие `fetch`. Как только браузер запрашивает какой-то ресурс, сервис-воркер проверяет, нет ли у него в кэше этого ресурса и отдаёт его при наличии (либо кэширует при отсутствии). Что наиболее интересно, при следующем заходе на страницу браузер уже не будет запрашивать с сервера `index.html` — он возьмёт его из своего кэша. А значит не будет инициирован Server Push и, что ещё более интересно, вам вообще не понадобится сетевое соединение, чтобы посмотреть последнюю загруженную версию сайта!

Как можно заметить из приведённого кода, в случае загрузки сервис-воркера с новым `cacheName` мы получим полный сброс кэшей. Это не очень хорошая стратегия и реальной жизни лучше подумать над инкрементальным обновлением.

Посмотрим на графики загрузки:

![](https://cdn-images-1.medium.com/max/800/1*CbtotmwtPQMJPlDFyPzbUA.png)

Выглядит просто отлично!

## Оптимизация JavaScript

Не вдаваясь в подробности оптимизации парсинга JavaScript кода (такие, как например, [принудительный обход ленивого парсинга](https://medium.com/devschacht/lazy-javascript-parsing-in-v8-99b5c3a6cbba)), можно дать один важный совет — уменьшайте размер вашего JavaScript-бандла. Это важно не только для скорости его загрузки, но и для уменьшения времени парсинга.

![](https://cdn-images-1.medium.com/max/800/1*2rOxJHggNE9JJLEJGqI8cA.png)

Почему размер бандла так важен? Ответ в том, что не все пользователи ходят с последними моделями телефонов.

![](https://cdn-images-1.medium.com/max/800/1*aVyTLq7bPe4cimVOz4jqdg.png)

[https://docs.google.com/spreadsheets/d/1wHcNNQea28LhwQ_amFamT33d5woVrJfJy53Z1k6V090/edit#gid=1882596388](https://docs.google.com/spreadsheets/d/1wHcNNQea28LhwQ_amFamT33d5woVrJfJy53Z1k6V090/edit#gid=1882596388)

Используйте такие утилиты, как [webpack-bundle-analyzer](https://www.npmjs.com/package/webpack-bundle-analyzer) для того, чтобы разобраться, что же делает ваш бандл таким большим.

![](https://cloud.githubusercontent.com/assets/302213/20628702/93f72404-b338-11e6-92d4-9a365550a701.gif)

Разбивайте ваш код на несколько бандлов и подгружайте их по мере необходимости.

## Выводы

* Используйте preload и font-display:swap
* Используйте HTTP/2
* Попробуйте Server Push и Service Workers
* Уменьшайте ваши бандлы
* Тестируйте на реальных устройствах в реальной сети

---

На написание этой статьи меня сподвиг замечательный доклад [@samccone](https://twitter.com/samccone) : [Planning for Performance](https://www.youtube.com/watch?v=RWLzUnESylc)

Использованы некоторые слайды из моего доклада на [Frontend Mix](https://events.yandex.ru/events/meetings/29-august-2017/).

Большое спасибо @maksugr[https://github.com/maksugr] за редактуру всех моих текстов.

---

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Статья на Medium](https://medium.com/devschacht/speeding-up-loading-in-the-era-of-smartphones-f9fa0f6ac672)
