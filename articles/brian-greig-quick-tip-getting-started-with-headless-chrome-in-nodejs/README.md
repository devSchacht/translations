# Быстрый старт: начало работы с безголовым Chrome в Node.js

*Перевод статьи [Brian Greig](https://twitter.com/IgnoreIntuition): [Quick Tip: Getting Started with Headless Chrome in Node.js](https://www.sitepoint.com/headless-chrome-node-js/).*

![](headless.png)

Часто в ходе нашей работы мы сталкиваемся с необходимостью снова и снова повторять действия пользователя, чтобы убедиться, что по мере внесения изменений на наш сайт ничего не сломалось. Для систематического и удобного решения этой задачи критически важными являются библиотеки, позволяющие создавать такие тесты. Познакомьтесь с безголовыми браузерами! Это инструменты командной строки, предоставляющие возможность программно создавать сценарии взаимодействия пользователя на сайте с последующей фиксацией их результатов для использования в тестах.

Многие из нас годами пользуются [PhantomJS](http://phantomjs.org/), [CasperJS](http://casperjs.org/) и другими инструментами. Но, как часто бывает с любовью, наши сердца могут быть завещаны другому. Начиная с Chrome 59 (60 для пользователей Windows), Chrome поставляется с собственным безголовым браузером. И хотя в настоящее время он не имеет поддержки для Selenium, он использует Chromium и движок Blink, то есть имитирует актуальный пользовательский интерфейс в Chrome.

Как всегда, код этой статьи можно найти в [репозитории GitHub](https://github.com/sitepoint-editors/ChromeHeadless).

## Запуск безголового Chrome из командной строки

Запуск безголового Chrome из командной строки относительно прост. На Mac вы можете установить алиас для Chrome и выполнить его с помощью параметра командной строки `--headless`:

```
alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome”
chrome --headless --disable-gpu --remote-debugging-port=9090 https://www.sitepoint.com/
```

На Linux всё ещё проще:

```bash
google-chrome --headless --disable-gpu --remote-debugging-port=9090 https://www.sitepoint.com/
```

* `--headless`: запуск без пользовательского интерфейса
* `--disable-gpu`: отключение аппаратного ускорения графического процессора (сейчас это временно необходимо)
* `--remote-debugging-port`: добавление возможности удаленной отладки по HTTP на указанном порту

Вы также можете взаимодействовать с запрашиваемой страницей, например, для вывода `document.body.innerHTML` в stdout:

```bash
google-chrome --headless --disable-gpu --dump-dom http://endless.horse/
```

Если вас интересно большее количество возможностей, [полный список параметров можно найти здесь](https://peter.sh/experiments/chromium-command-line-switches/).

## Запуск безголового Chrome в Node.js

Однако данная статья не о запуске безголового Chrome в командной строке, а об его запуске в Node.js. Для этого нам понадобятся следующие модули:

* chrome-remote-interface: JavaScript API, обеспечивающее простую абстракцию для команд и уведомлений
* chrome-launcher: позволяет нам запускать Chrome из Node.js кроссплатформенно

Затем мы можем настроить нашу среду. Предполагается, что на вашем компьютере установлены Node.js и npm. Если это не так, [ознакомьтесь с нашим учебным пособием](https://www.sitepoint.com/quick-tip-multiple-versions-node-nvm/).

```bash
mkdir headless
cd headless
npm init -y
npm install chrome-remote-interface --save
npm install chrome-launcher --save
```

После этого мы хотим создать сессию безголового Chrome. Начнем с создания файла `index.js` в нашей папке проекта:

```js
const chromeLauncher = require('chrome-launcher');
const CDP = require('chrome-remote-interface');

(async function() {
  async function launchChrome() {
    return await chromeLauncher.launch({
      chromeFlags: [
        '--disable-gpu',
        '--headless'
      ]
    });
  }
  const chrome = await launchChrome();
  const protocol = await CDP({
    port: chrome.port
  });

  // ЗДЕСЬ ВСЕ ПОСЛЕДУЮЩИЕ ПРИМЕРЫ КОДА

})();
```

Во-первых, мы подключаем наши зависимости, а затем создаём самовызывающуюся функцию, которая будет порождать экземпляр сессии Chrome. Обратите внимание, что флаг `--disable-gpu` требуется на момент написания этой статьи, но может оказаться не нужен, когда вы будете читать это, поскольку это всего лишь обходной путь ([в соответствии с рекомендацией Google](https://developers.google.com/web/updates/2017/04/headless-chrome)). Мы будем использовать `async / await`, чтобы гарантировать, что наше приложение ожидает запуск безголового браузера перед выполнением следующих шагов.

**Примечание:** Мы будем работать с функциями, требующим окончания определенных действий перед переходом к последующим шагам. Например, отрисовки страницы или завершён.я ряда взаимодействий. Многие из этих шагов не блокирующие, поэтому нам нужно использовать промисы для приостановки исполнения. Подробнее об `async`-функциях можно прочитать на [Mozilla Developer Network](https://developer.mozilla.org/ru/docs/Web/JavaScript/Reference/Statements/async_function) или [на SitePoint](https://www.sitepoint.com/simplifying-asynchronous-coding-async-functions/).

Далее нам нужно выявить области (*domains*), которые нам нужны для нашего тестирования:

```js
const {
  DOM,
  Page,
  Emulation,
  Runtime
} = protocol;
await Promise.all([Page.enable(), Runtime.enable(), DOM.enable()]);
```

Наиболее важный здесь объект `Page`: мы будем использовать его для доступа к содержимому пользовательского интерфейса. С его помощью мы укажем, куда мы переходим, с какими элементами взаимодействуем, где мы запускаем наши скрипты.

## Изучение страницы

После того, как мы инициализировали нашу сессию и определили наши области, мы можем начать навигацию по сайту. Для выбора точки входа мы используем домен `Page`, который мы включили выше, и переходим к:

```js
Page.navigate({
  url: 'https://en.wikipedia.org/wiki/SitePoint'
});
```

Этот код загрузит страницу. Затем, используя метод `loadEventFired`, мы определяем шаги, которые хотим осуществить в нашем приложении для воспроизведения сценария взаимодействия пользователя. В этом примере мы просто получаем содержимое первого абзаца.

```js
Page.loadEventFired(async() => {
  const script1 = "document.querySelector('p').textContent"
  // Выполняем script1
  const result = await Runtime.evaluate({
    expression: script1
  });
  console.log(result.result.value);

  protocol.close();
  chrome.kill();
});
```

Если вы запустите скрипт с помощью `node index.js`, вы увидите что-то вроде этого:

```bash
SitePoint is a Melbourne, Australia-based website, and publisher of books, courses and articles for web developers. In January 2014, SitePoint.com had an Alexa ranking of 889,[1] and a Quantcast rating of 14,934.[2]
```

## Идем дальше: делаем скриншоты

Мы так же легко можем заменить код в `script1` на любой другой, например, на нажимающий на ссылки, заполняющий поля форм или запускающий серию взаимодействий с помощью `query`-селекторов. Каждый шаг может быть сохранён в конфигурационном JSON-файле и загружен в ваши скрипты на Node.js для выполнения последовательно. Результаты этих сценариев могут быть проверены с использованием платформы тестирования, такой как Mocha, что позволяет удостовериться, что полученные значения соответствуют требованиям UI / UX.

В дополнение к вашим тестовым сценариям вы, вероятно, захотите сделать скриншоты своих страниц при навигации по сайту. К счастью, выбранная область (*Page*) имеет функцию `captureScreenshot`, которая именно этим и занимается.

```js
const chromeLauncher = require('chrome-launcher');
const CDP = require('chrome-remote-interface');
const file = require('fs');

(async function() {
  ...

  Page.loadEventFired(async() => {
    const script1 = "document.querySelector('p').textContent"
    // Выполняем script1
    const result = await Runtime.evaluate({
      expression: script1
    });
    console.log(result.result.value);

    const ss = await Page.captureScreenshot({format: 'png', fromSurface: true});
    file.writeFile('screenshot.png', ss.data, 'base64', function(err) {
      if (err) {
        console.log(err);
      }
    });

    protocol.close();
    chrome.kill();
  });
})();
```

Флаг `fromSurface` - ещё один флаг, требуемый для поддержки кроссплатформенности на момент написания этой статьи и может не понадобиться в будущем.

Запустите скрипт с помощью `node index.js` и вы получите примерно такой результат:

![](https://dab1nmslvvntp.cloudfront.net/wp-content/uploads/2017/07/1500638857headless-chrome-screenshot.png)

## Вывод

Если вы пишете автоматические тесты, вы должны начать использовать безголовый Chrome. Хотя он по-прежнему не полностью интегрирован с такими инструментами, как Selenium, преимущество имитации движка рендеринга Chrome не следует недооценивать. Это лучший способ полностью воссоздать пользовательский опыт.

Я покину вас, оставив список для дальнейшего чтения:

* Документация к API: https://chromedevtools.github.io/devtools-protocol/
* Начало работы с безголовым Chrome: https://developers.google.com/web/updates/2017/04/headless-chrome

---

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Статья на Medium](https://medium.com/devschacht/brian-greig-quick-tip-getting-started-with-headless-chrome-in-nodejs-23a09e3ec376)
