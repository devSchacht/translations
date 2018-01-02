# Ember.js - идеальный фреймворк для веб приложений

*Перевод статьи [Graham Cox](https://twitter.com/grahamcox82): [Ember.js: The Perfect Framework for Web Applications](https://www.sitepoint.com/ember-js-perfect-framework-web-applications/).*

![Ember.js](https://dab1nmslvvntp.cloudfront.net/wp-content/uploads/2015/03/1425997476emberjs-logo-300x300.png)

Ember.js - зрелый фронтенд фреймворк, получивший много внимания в последнее время. Это статья познакомит вас с основными концепциями фреймворка на примере создания простого приложения и покажет, что с его помощью можно сделать.

Мы собираемся написать приложение Dice Roller, позволяющее кинуть кости и посмотреть историю всех совершенных бросков. Полностью работающие приложение можно увидеть на [GitHub](https://github.com/sazzer/dice-roller).

Ember.js вобрал в себя множество современных JavaScript концепций и технологий. Вот их неполный список:

* Транспайлер [Babel](https://babeljs.io/) для полноценной поддержки ES2015 синтаксиса.
* Поддержка юнит, интеграционного и приемочного тестирований с помощью [Testem](https://github.com/testem/testem) и [QUnit](https://qunitjs.com/).
* [Brocolli.js](http://broccolijs.com/) для сборки ассетов.
* Поддержка live-reload для сокращения отклика во время разработки.
* Шаблонизация с использованием [Handlebars](http://handlebarsjs.com/).
* Навигация в любую часть приложения благодаря системе роутинга.
* Полная поддержка [JSON API](http://jsonapi.org/), но при этом присутствует возможность использовать любой API, который вам необходим.

Для работы с Ember.js предполагается, что у вас установлены свежие версии Node.js и npm. Если нет, то их можно скачать и установить с сайта [Node.js](https://nodejs.org/en/).

Также стоит упомянуть, что Ember - исключительно фронтенд фреймворк. Есть множество способов взаимодействия с бэкендом на ваш выбор, но сам бэкенд никак не управляется Ember.

## Знакомство с [ember-cli](https://ember-cli.com/)

Немало возможностей Ember.js связано с его [интерфейсом командной строки или CLI](https://ru.wikipedia.org/wiki/Интерфейс_командной_строки). Этот инструмент, известный как ember-cli, управляет большой частью процесса разработки: от создания приложения и добавления различного функционала и до запуска тестов и деплоя на продакшен.

Практически всё во время разработки Ember.js приложения будет в какой-то степени связано с этим инструментом, поэтому важно понимать как им пользоваться. Мы будем использовать его при создании нашего приложения.

Первым делом нужно убедиться, что ember-cli установлен и актуален. Устанавливаем его c помощью npm: 

```
$ npm install -g ember-cli
```

и проверяем успешность установки:

```
$ ember --version
ember-cli: 2.15.0-beta.1
node: 8.2.1
os: darwin x64
```

## Создание вашего первого Ember.js приложения

С установленным ember-cli мы готовы приступить к созданию нашего приложения. В первый раз мы будем использовать ember-cli для того, чтобы создать всю структуру приложения и сделать первоначальные настройки.

```
$ ember new dice-roller
installing app
  create .editorconfig
  create .ember-cli
  create .eslintrc.js
  create .travis.yml
  create .watchmanconfig
  create README.md
  create app/app.js
  create app/components/.gitkeep
  create app/controllers/.gitkeep
  create app/helpers/.gitkeep
  create app/index.html
  create app/models/.gitkeep
  create app/resolver.js
  create app/router.js
  create app/routes/.gitkeep
  create app/styles/app.css
  create app/templates/application.hbs
  create app/templates/components/.gitkeep
  create config/environment.js
  create config/targets.js
  create ember-cli-build.js
  create .gitignore
  create package.json
  create public/crossdomain.xml
  create public/robots.txt
  create testem.js
  create tests/.eslintrc.js
  create tests/helpers/destroy-app.js
  create tests/helpers/module-for-acceptance.js
  create tests/helpers/resolver.js
  create tests/helpers/start-app.js
  create tests/index.html
  create tests/integration/.gitkeep
  create tests/test-helper.js
  create tests/unit/.gitkeep
  create vendor/.gitkeep
NPM: Installed dependencies
Successfully initialized git.
```

Наше приложение создалось и готово. У нас даже настроился Git, как система контроля версий.

> Примечание: Вы можете отключить интеграцию с Git, а также использовать Yarn вместо npm. Используйте команду `ember new --help` для более подробной информации.

Запуск сервера Ember.js приложения для целей разработки делается также с помощью ember-cli:

```
$ cd dice-roller
$ ember serve
Livereload server on http://localhost:49153
'instrument' is imported from external module 'ember-data/-debug' but never used
Warning: ignoring input sourcemap for vendor/ember/ember.debug.js because ENOENT: no such file or directory, open '/Users/coxg/source/me/writing/repos/dice-roller/tmp/source_map_concat-input_base_path-2fXNPqjl.tmp/vendor/ember/ember.debug.map'
Warning: ignoring input sourcemap for vendor/ember/ember-testing.js because ENOENT: no such file or directory, open '/Users/coxg/source/me/writing/repos/dice-roller/tmp/source_map_concat-input_base_path-Xwpjztar.tmp/vendor/ember/ember-testing.map'

Build successful (5835ms) – Serving on http://localhost:4200/



Slowest Nodes (totalTime => 5% )              | Total (avg)
----------------------------------------------+---------------------
Babel (16)                                    | 4625ms (289 ms)
Rollup (1)                                    | 445ms
```

Всё готово. Приложение запущено по адресу http://localhost:4200 и выглядит следующим образом:

![](https://dab1nmslvvntp.cloudfront.net/wp-content/uploads/2017/10/1507570414first-view.png)

Также запустился [LiveReload](http://livereload.com/) сервер, автоматически наблюдающий за изменениями в файловой системе. Это значит, что любое изменение в коде приведёт к автоматической перезагрузке нашего приложения в браузере. А изменения картинок или CSS применяется даже без перезагрузки.

Начальная страница подсказывает нам, что делать. Давайте изменим её и посмотрим, что произойдет. Мы собираемся изменить файл `app/templates/application.hbs`, чтобы он выглядел так:

```hbs
This is my new application.

{{outlet}}
```

> Примечание: `{{outlet}}` - это часть того, как роутинг работает в Ember. Мы ещё вернёмся к этому позже.

Первое, на что стоит обратить внимание, это результат работы ember-cli:

```
file changed templates/application.hbs

Build successful (67ms) – Serving on http://localhost:4200/

Slowest Nodes (totalTime => 5% )              | Total (avg)
----------------------------------------------+---------------------
SourceMapConcat: Concat: App (1)              | 9ms
SourceMapConcat: Concat: Vendor /asset... (1) | 8ms
SimpleConcatConcat: Concat: Vendor Sty... (1) | 4ms
Funnel (7)                                    | 4ms (0 ms)
```

Это говорит нам о том, что сервер заметил наши изменения в шаблоне, перезапустил всё без каких-либо действий с нашей стороны.

Теперь давайте посмотрим в браузер. LiveReload обновил страницу браузера с примененными изменениями и нам также ничего не нужно больше делать.

![](https://dab1nmslvvntp.cloudfront.net/wp-content/uploads/2017/10/1507570420first-change.png)

Может не очень впечатляюще, но мы получили это практически без усилий с нашей стороны.

В дополнение, у нас уже все готово для запуска тестов. Для этого мы вновь можем воспользоваться ember-cli таким образом:

```
$ ember test
⠸ Building'instrument' is imported from external module 'ember-data/-debug' but never used
⠴ BuildingWarning: ignoring input sourcemap for vendor/ember/ember.debug.js because ENOENT: no such file or directory, open '/Users/coxg/source/me/writing/repos/dice-roller/tmp/source_map_concat-input_base_path-S8aQFGaz.tmp/vendor/ember/ember.debug.map'
⠇ BuildingWarning: ignoring input sourcemap for vendor/ember/ember-testing.js because ENOENT: no such file or directory, open '/Users/coxg/source/me/writing/repos/dice-roller/tmp/source_map_concat-input_base_path-wO8OLEE2.tmp/vendor/ember/ember-testing.map'
cleaning up...
Built project successfully. Stored in "/Users/coxg/source/me/writing/repos/dice-roller/tmp/class-tests_dist-PUnMT5zL.tmp".
ok 1 PhantomJS 2.1 - ESLint | app: app.js
ok 2 PhantomJS 2.1 - ESLint | app: resolver.js
ok 3 PhantomJS 2.1 - ESLint | app: router.js
ok 4 PhantomJS 2.1 - ESLint | tests: helpers/destroy-app.js
ok 5 PhantomJS 2.1 - ESLint | tests: helpers/module-for-acceptance.js
ok 6 PhantomJS 2.1 - ESLint | tests: helpers/resolver.js
ok 7 PhantomJS 2.1 - ESLint | tests: helpers/start-app.js
ok 8 PhantomJS 2.1 - ESLint | tests: test-helper.js

1..8
# tests 8
# pass  8
# skip  0
# fail  0

# ok
```

Заметьте, что в выводе консоли упоминается [PhantomJS](http://phantomjs.org/). Это потому, что Ember имеет полную поддержку запуска интеграционных тестов в браузере и по умолчанию использует [безголовый браузер](https://en.wikipedia.org/wiki/Headless_browser) PhantomJS (*прим. пер., [с версии 2.15 по умолчанию используется headless chrome](https://www.emberjs.com/blog/2017/09/01/ember-2-15-released.html#toc_chrome-by-default)*). Вы можете настроить запуск тестов в любом браузере по вашему желанию. Например при настройке [непрерывной интеграции](https://ru.wikipedia.org/wiki/Непрерывная_интеграция) (*CI*) будет полезно воспользоваться этим, чтобы удостовериться, что приложение корректно работает во всех поддерживаемых вами браузерах.

## Как устроено Ember.js приложение

Перед тем, как мы приступим к написанию кода, давайте изучим структуру нашего приложения в файловой системе. Команда `ember new`, используемая нами ранее, создаёт целую директорию с файлами и папками. Понимание структуры этой директории необходимо для эффективной работы с инструментом и создания удивительных проектов.

В корне директории вы можете увидеть следующие файлы и папки:

* **README.md** – стандартный файл, описывающий ваше приложение.
* **package.json** – стандартный файл пакетного менеджера npm, также описывающий ваше приложение, но с точки зрения зависимостей. В нем описаны зависимости вашего приложения и их версии, чтобы они устанавливались корректно.
* **ember-cli-build.js** – конфигурационный файл для ember-cli.
* **testem.js** – конфигурационный файл для тестирующего фреймворка Testem. Он позволяет, среди прочего, определить в каких браузерах будут запускаться тесты. 
* **app/** – здесь хранится логика приложения. Многое происходит в этой папке и мы рассмотрим это ниже.
* **config/** – конфигурация нашего приложения:
  * **config/targets.js** – содержит список поддерживаемых браузеров. Это необходимо для Babel, чтобы он транспилировал ваш код в работающий во всех необходимых вам браузерах.
  * **config/environment.js** – содержит необходимые настройки приложения, отличающиеся в различных окружениях.
* **public/** – любые статические ресурсы, которые необходимы вашему приложению. Например, картинки или шрифты.
* **vendor/** – сюда можно сложить любые зависимости, которые не будут управляться системой сборки.
* **tests/** – это место для тестов:
  * **tests/unit** – все юнит тесты приложения.
  * **tests/integration** – все интеграционные тесты.

## Общая структура страницы

Пока мы не зашли слишком далеко, давайте добавим на нашу страницу немного разметки. А чтобы она смотрелась хорошо, будем использовать [Materialize CSS framework](http://materializecss.com/).

Добавление подобного стороннего контента может быть осуществлено несколькими способами:

* Указанием ссылки на внешний CDN сервис
* С помощью пакетных менеджеров вроде npm или Bower
* Подключив напрямую в приложение из папки `vendor/`
* Использовать [Ember Addon](https://guides.emberjs.com/v2.14.0/addons-and-dependencies/managing-dependencies/#toc_addons), если такой имеется 

К сожалению, аддон для Materialize пока что не совместим с последней версией Ember, поэтому мы просто добавим ссылку на него. Чтобы сделать это, мы обновим `app/index.html` файл, являющийся корневой страницей, в которую будет отрендерено наше приложение. Мы хотим добавить ссылки на CDN для jQuery, Google Icon Font и Materialize.

```html
<!-- Внутри тэга head -->
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/0.100.1/css/materialize.min.css">

<!-- Внутри тэга body -->
    <script type="text/javascript" src="https://code.jquery.com/jquery-3.2.1.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/0.100.1/js/materialize.min.js"></script>
```

Теперь мы можем обновить нашу главную страницу, добавив разметки. Для этого отредактируем файл `app/templates/application.hbs`:

```hbs
<nav>
    <div class="nav-wrapper">
        <a href="#" class="brand-logo">
            <i class="material-icons">filter_6</i>
            Dice Roller
        </a>
        <ul id="nav-mobile" class="right hide-on-med-and-down">
        </ul>
    </div>
</nav>

<div class="container">
    {{outlet}}
</div>
```

Мы добавили шапку, а также контейнер с тэгом `{{outlet}}`, упомянутым ранее.

В браузере это должно выглядеть так:

![](https://dab1nmslvvntp.cloudfront.net/wp-content/uploads/2017/10/1507570393layout.png)

Так, что же такое `outlet` тэг? Ember работает на основе роутов, где каждый роут является ребенком другого роута. Самый верхний роут в этой иерархии обрабатывается Ember автоматически и рендерит шаблон `app/templates/application.hbs`.

Тэг `outlet` определяет, где Ember отрендерит следующий роут в текущей иерархии. Таким образом роут первого уровня будет отрендерен в добавленный нами тэг в `application.hbs`, а роут второго уровня будет отрендерен в такой же тэг в темплейте роута первого уровня. И так далее.

## Создание нового роута

В Ember.js приложении каждая посещаемая страница доступна с помощью **роута**. Существует прямая связь между адресной строкой (URL) в браузере и роутом в приложении. 

Проще показать это на примере. Давайте добавим новый роут в наше приложение, позволяющий пользователю бросать кости. И вновь это делается с помощью ember-cli:

```
$ ember generate route roll
installing route
  create app/routes/roll.js
  create app/templates/roll.hbs
updating router
  add route roll
installing route-test
  create tests/unit/routes/roll-test.js
```

Что создалось с помощью этой команды?

* Обработчик для роута – `app/routes/roll.js`
* Шаблон для роута – `app/templates/roll.hbs`
* Тест для роута `tests/unit/routes/roll-test.js`
* Новый роут добавился в файл конфигурации роутера – `app/router.js`

Давайте посмотрим на это в действии. Для начала мы хотим создать довольно простую страницу, позволяющую нам получить число после броска костей. Для этого обновим файл `app/templates/roll.hbs`:

```hbs
<div class="row">
    <form class="col s12">
        <div class="row">
            <div class="input-field col s12">
                <input placeholder="Название" id="roll_name" type="text" class="validate">
                <label for="roll_name">Название попытки</label>
            </div>
        </div>
        <div class="row">
            <div class="input-field col s6">
                <input placeholder="Количество бросков" id="number_of_dice" type="number" class="validate" value="1">
                <label for="number_of_dice">Количество бросков</label>
            </div>
            <div class="input-field col s6">
                <input placeholder="Количество сторон у кости" id="number_of_sides" type="number" class="validate" value="6">
                <label for="number_of_sides">Количество сторон у кости</label>
            </div>
        </div>
        <div class="row">
            <button class="btn waves-effect waves-light" type="submit" name="action">
                Бросить кость
                <i class="material-icons right">send</i>
            </button>
        </div>
    </form>
</div>

{{outlet}}
```

Результат будет доступен в браузере по адресу http://localhost:4200/roll:

![](https://dab1nmslvvntp.cloudfront.net/wp-content/uploads/2017/10/1507570389roll.png)

Теперь нам нужна возможность попадать на эту страницу с главной страницы. Ember позволяет сделать это очень просто с помощью хелпера `link-to`, который принимает первым аргументом имя роута и рендерится в разметку, позволяющую нашему пользователю попасть на нужный роут.

В нашем случае нужно обновить файл `app/templates/application.hbs`, чтобы он содержал следующее:

```hbs
<ul id="nav-mobile" class="right hide-on-med-and-down">
    {{#link-to 'roll' tagName="li"}}
        <a href="roll">Бросить кость</a>
    {{/link-to}}
</ul>
```
Это добавит ссылку на роут `roll` в шапку страницы, как мы и задумывали:

![](https://dab1nmslvvntp.cloudfront.net/wp-content/uploads/2017/10/1507570402header-link.png)

## Создание модульных компонент

Если на данном этапе вы попробовали протестировать наше приложение, то могли заметить одну проблему. Переход по ссылке в роут `roll` работает корректно, но метки элементов форм не выстраиваются правильно. Это происходит потому что Materialize нужно использовать JavaScript, чтобы поставить метки на свои места, после того как они будут отрендерены. Но динамический роутинг предполагает, что страница не будет перезагружена. Таким образом, у нас пока что нет места, где можно инициализировать этот JavaScript код. 

На помощь приходят компоненты. Компоненты - это частички интерфейса пользователя, имеющие свой жизненный цикл, с которым мы можем взаимодействовать и в который мы можем встроить необходимый нам JavaScript код. Также они используются для создания переиспользуемых элементов интерфейса, но к этому мы ещё вернёмся.

Пока что мы собираемся создать компонент, представляющий собой форму для броска костей. Как обычно, создание компонента тоже можно осуществить с помощью ember-cli:

```
$ ember generate component roll-dice
installing component
  create app/components/roll-dice.js
  create app/templates/components/roll-dice.hbs
installing component-test
  create tests/integration/components/roll-dice-test.js
```

Мы получили:

* **app/components/roll-dice.js** – код, управляющий компонентом
* **app/templates/components/roll-dice.hbs** – шаблон компонента, где мы определим, как он выглядит
* **tests/integration/components/roll-dice-test.js** – тест, чтобы удостовериться, что компонент работает правильно

Мы перенесём всю разметку из роута `roll` в компонент, что не повлияет на работу приложения в целом, но позволит нам использовать всю силу компонент.

Обновим шаблон компонента `app/templates/components/roll-dice.hbs`:

```hbs
<form class="col s12">
    <div class="row">
        <div class="input-field col s12">
            <input placeholder="Название попытки" id="roll_name" type="text" class="validate">
            <label for="roll_name">Название попытки</label>
        </div>
    </div>
    <div class="row">
        <div class="input-field col s6">
            <input placeholder="Количество бросков" id="number_of_dice" type="number" class="validate" value="1">
            <label for="number_of_dice">Количество бросков</label>
        </div>
        <div class="input-field col s6">
            <input placeholder="Количество сторон у кости" id="number_of_sides" type="number" class="validate" value="6">
            <label for="number_of_sides">Количество сторон у кости</label>
        </div>
    </div>
    <div class="row">
        <button class="btn waves-effect waves-light" type="submit" name="action">
            Бросить кость
            <i class="material-icons right">send</i>
        </button>
    </div>
</form>
```

А также шаблон роута `app/templates/roll.hbs`:

```hbs
<div class="row">
    {{roll-dice}}
</div>

{{outlet}}
```

Тэг `roll-dice` в шаблоне говорит Ember, где отрендерить наш компонент.

## Жизненный цикл компонента

Компоненты в Ember имеют заданный жизненный цикл, которому они следуют, с множеством хуков, вызываемых на различных стадиях. Мы используем хук `didRender`, который будет вызван после того, как компонент будет отрендерен (в первый раз или в любые последующие), чтобы попросить Materialize обновить метки элементов форм.

Сделать это можно, обновив код компонента `app/components/roll-dice.js` таким образом:

```js
/* global Materialize:false */
import Ember from 'ember';

export default Ember.Component.extend({
    didRender() {
        Materialize.updateTextFields();
    }
});
```

Теперь при любом заходе в роут `roll` нужный нам код отработает и Materialize исправит отображение меток.

## Связывание данных

Мы также хотим иметь возможность вставлять и получать данные из нашего интерфейса пользователя с помощью компонент. Это удивительно просто сделать, но неожиданно [Ember гайд](https://guides.emberjs.com/v2.16.0/) не говорит об этом, поэтому это кажется сложнее, чем есть на самом деле.

Каждая частичка данных, с которой мы хотим взаимодействовать, имеет своё собственное поле в классе компонента. Когда мы хотим показать поля ввода, мы используем специальные хелперы в шаблоне компонента, связывающие поля ввода с переменными/полями в классе компонента. Таким образом, мы взаимодействует с полями ввода напрямую, не беспокоясь о работе с DOM.

В нашем случае у нас есть три поля ввода, поэтому нам нужно добавить три строчки внутри класса компонента в файле `app/components/roll-dice.js`:

```js
    rollName: '',
    numberOfDice: 1,
    numberOfSides: 6,
```

Затем мы обновим наш шаблон, заменив HTML разметку полей ввода на специальные хелперы.

```hbs
<div class="row">
    <div class="input-field col s12">
        <!-- This replaces the <input> tag for "roll_name" -->
        {{input placeholder="Название" id="roll_name" class="validate" value=(mut rollName)}}
        <label for="roll_name">Название попытки</label>
    </div>
</div>
<div class="row">
    <div class="input-field col s6">
        <!-- Заменяем HTML поле ввода <input> на хелпер {{input}} -->
        {{input placeholder="Количество бросков" id="number_of_dice" type="number" class="validate" value=(mut numberOfDice)}}
        <label for="number_of_dice">Количество бросков</label>
    </div>
    <div class="input-field col s6">
        <!-- Заменяем HTML поле ввода <input> на хелпер {{input}} -->
        {{input placeholder="Количество сторон у кости" id="number_of_sides" type="number" class="validate" value=(mut numberOfSides)}}
        <label for="number_of_sides">Количество сторон у кости</label>
    </div>
</div>
```

Обратите внимание, что атрибут `value` имеет слегка странный синтаксис. Подобный синтаксис может быть использован с любым атрибутом хелпера, не только с `value`. Вообще существует три способа передачи значения в атрибут:

* Как строку в кавычках (значением будет эта строка
* Как строку без кавычек (в этом случае значение будет взято из одноименного поля в классе компоненты, но компонента никогда не обновится)
* С использованием `(mut <name>)` (значение также возьмется из одноименного поля в классе компонента, но компонент будет изменяться, когда значение изменится в браузере)

Всё вышеизложенное означает, что теперь мы можем обращаться к добавленным в компонент полям как к значениям полей ввода, а всё остальное сделает Ember.

## Экшены компонент

Следующим шагом мы хотим добавить компоненту интерактивность. Например, хорошо бы обрабатывать нажатие кнопки «Бросить кость». Для этого в Ember есть экшены. Это методы, описанные в классе компонента, которые могут быть подключены в шаблон компонента. Обычно методы описывают в специальном объекте компонента `actions`.

Добавим экшен в наш компонент `app/components/roll-dice.js`:

```js
actions: {
    triggerRoll() {
        alert(`Rolling ${this.numberOfDice}D${this.numberOfSides} as "${this.rollName}"`);
        return false;
    }
}
```

Мы возвращаем `false`, чтобы предотвратить [всплытие события](https://learn.javascript.ru/event-bubbling). Это довольно стандартная процедура в веб-приложениях и в данном случае предотвращает отправку формы и перезагрузку страницы.

Вы можете заметить, что мы ссылаемся на поля, которые мы ранее объявили в классе, чтобы иметь доступ к значениям полей ввода. Здесь нет никакого взаимодействия с DOM: мы оперируем только JavaScript переменными.

Осталось подключить наш экшен. В шаблоне нам нужно сказать тэгу формы, что ему нужно вызвать `triggerRoll` экшен, когда случится событие `onsubmit`. Это делается добавлением всего одного атрибута с использованием `action` хелпера. В шаблоне `app/templates/components/roll-dice.hbs` это выглядит так:

```hbs
<form class="col s12" onsubmit={{action 'triggerRoll'}}>
```

Заполнив поля формы и нажав на кнопку, мы увидим диалоговое окно с результатом нашего ввода.

![](https://dab1nmslvvntp.cloudfront.net/wp-content/uploads/2017/10/1507570432alert.png)

## Взаимодействие с сервером

Следующим шагом будет написание логики настоящего броска кости. Это требует взаимодействия с сервером, так как сервер ответственен за запоминание результата броска кости.

Мы хотим достичь следующего:

* Пользователь определяет параметры для броска кости
* Пользователь нажимает на кнопку «Бросить кость»
* Приложение выполняет логику броска кости и отправляет результат и параметры совершенного броска на сервер
* Сервер запоминает результат и сообщает клиенту об удачном сохранении
* Браузер отображает результат броска

Звучит довольно просто. И конечно, с Ember, это действительно так.

Ember управляет этим, используя встроенную концепцию хранилища - `Store`, наполненного моделями - `Models`. **Хранилище** - единственный источник знаний о данных во всем приложении, а **модель** представляет часть этих данных в хранилище. Модели сами знают как сохранить себя на сервер, а хранилище знает как создавать и управлять моделями.

## Передача управления от компонент в роуты

Очень важно сохранять инкапсуляцию во всем нашем приложении. Роуты (и контроллеры, о которых мы не будем говорить здесь) имеют доступ к хранилищу. Компоненты - нет.

Это потому что роуты отвечают за определенную бизнес-логику в приложении, в то время как компоненты представляют собой маленькие кусочки интерфейса. Чтобы всё работало как надо, компоненты способны посылать сигналы вверх по иерархии вложенности, когда происходит какое-либо событие. Это очень похоже на то, как хелперы в шаблоне компонента посылают сигналы в компонент, когда что-то произошло.

Для начала переместим логику показа диалогового окна из компонента в роут. Для этого нам нужно изменить некоторые части нашего кода.

В классе, ответственном за управление роутом `app/routes/roll.js` зарегистрируем экшен `saveRoll`, которым мы собираемся выполнить:

```hbs
actions: {
    saveRoll: function(rollName, numberOfDice, numberOfSides) {
        alert(`Rolling ${numberOfDice}D${numberOfSides} as "${rollName}"`);
    }
}
```

И перепишем логику экшена компонента. Теперь мы хотим вызвать другой экшен в нашем компоненте, передав параметры броска в его аргументы. Это делается с помощью метода `sendAction`, доступного в классе компонента.

```hbs
triggerRoll() {
    this.sendAction('roll', this.rollName, this.numberOfDice, this.numberOfSides);
    return false;
}
```

Осталось связать экшен из роута и экшен компонента. Для этого изменим внешний вид вызова компонента в шаблоне роута `app/templates/roll.hbs`:

```hbs
{{roll-dice roll="saveRoll" }}
```

Это даст знать компоненту, что свойство `roll` теперь связано с экшеном `saveRoll` внутри роута. Теперь при вызове `roll` внутри компонента, управление передастся в экшен `saveRoll`. Имя `roll` весьма подходящее в рамках компонента, потому что компонент знает только то, что ему нужно запросить бросок костей, но для него не имеет значения как остальной код будет обрабатывать этот запрос и переданную информацию.

И вновь, всё сделанное нами никак не повлияло на работу приложения, но теперь все части в правильных местах.

## Сохранение в хранилище

Прежде чем мы сохраним данные в хранилище, нам необходимо определить модель, представляющую эти данные. Используя наш надежный инструмент ember-cli, создадим структуру модели и затем заполним её.

Чтобы создать модель, выполним команду:

```
$ ember generate model roll
installing model
  create app/models/roll.js
installing model-test
  create tests/unit/models/roll-test.js
```

Теперь мы можем заполнить модель `app/models/roll.js` атрибутами, необходимыми для представления наших данных:

```js
import DS from 'ember-data';

export default DS.Model.extend({
    rollName: DS.attr('string'),
    numberOfDice: DS.attr('number'),
    numberOfSides: DS.attr('number'),
    result: DS.attr('number')
});
```

`DS.attr` вызывается чтобы определить атрибут модели заданного типа. Эти типы в Ember называются преобразователями (`transform`). Варианты преобразователей по умолчанию: `"string"`, `"number"`, `"data"` или `"boolean"`. Но при необходимости вы всегда можете добавить свой.

Используем эту модель для создания броска кости в хранилище и сохранения на бэкенд. Для этого нам нужно получить доступ к хранилищу в классе роута `app/routes/roll.js`:

```js
saveRoll: function(rollName, numberOfDice, numberOfSides) {
    let result = 0;
    for (let i = 0; i < numberOfDice; ++i) {
        result += 1 + (parseInt(Math.random() * numberOfSides));
    }

    const store = this.get('store');
    // Создаем экземпляр модели 'roll' в хранилище с переданными атрибутами
    const roll = store.createRecord('roll', {
        rollName,
        numberOfDice,
        numberOfSides,
        result
    });
    // Это строчка отправить нашу модель для сохранения на бэкенд
    roll.save();
}
```

Если мы сейчас попробуем выполнить этот код, нажав на кнопку «Бросить кость», это приведёт к сетевому вызову на наш сервер. И это не сработает, потому что у нас нет сервера.

![](https://dab1nmslvvntp.cloudfront.net/wp-content/uploads/2017/10/1507570427create-roll.png)

Не будем беспокоиться об этом, потому что мы не затрагиваем здесь тему реализации бэкенда. Но если вам нужно разрабатывать Ember приложение совсем без бэкенда, есть различные варианты, например, использование аддона [ember-localstorage-adapter](https://github.com/locks/ember-localstorage-adapter), чтобы сохранять данные в local-storage браузера. Также можно использовать аддоны [ember-cli-mirage](http://www.ember-cli-mirage.com/) или [emberfire](https://github.com/firebase/emberfire).

## Загрузка из хранилища

Теперь, когда у нас есть данные в хранилище, мы можем получить их из него. Также мы напишем `index` роут, который будет использоваться при попадании на главную страницу.

Ember неявно использует роут под названием `index` для отображения первоначальной страницы приложения. Если для этого роута нет никаких файлов, то никакой ошибки не произойдет: просто на главной страницы ничего не будет отрендерено. Мы будем использовать этот роут для отображения всех совершенных бросков из хранилища.

Так как `index` роут уже существует, то нам не нужно вызывать никаких команд с помощью ember-cli, мы просто создадим файл `app/routes/index.js`, в который добавим:

```js
import Ember from 'ember';

export default Ember.Route.extend({
    model() {
        return this.get('store').findAll('roll');
    }
});
```

Наш роут напрямую обращается в хранилище и, используя метод `findAll`, загружает все сохраненные в нем броски кости. Затем мы предоставляем эти данные в шаблон с помощью хука роута `model`.

Создадим файл `app/templates/index.hbs` и добавим в него разметку:

```hbs
<table>
    <thead>
        <tr>
            <th>Название броска</th>
            <th>Параметры броска</th>
            <th>Результат</th>
        </tr>
    </thead>
    <tbody>
    {{#each model as |roll|}}
        <tr>
            <td>{{roll.rollName}}</td>
            <td>{{roll.numberOfDice}}D{{roll.numberOfSides}}</td>
            <td>{{roll.result}}</td>
        </tr>
    {{/each}}
    </tbody>
</table>


{{outlet}}
```

В шаблоне мы имеем доступ к модели, возвращённой роутом, и, итерируясь по ней, создаём таблицу, которая выглядит так:

![](https://dab1nmslvvntp.cloudfront.net/wp-content/uploads/2017/10/1507570398history.png)

## Заключение

На данный момент, благодаря относительно небольшим усилиям, мы создали приложение, позволяющее нам бросать кости и просматривать историю бросков. Это включает в себя связывание данных из нашей формы, сохранение данных в хранилище и чтение их из него, шаблоны для показа всех страниц и навигацию с помощью URL роутинга. Такое приложение может быть создано с нуля за час.

Использование Ember может очень сильно повысить эффективность разработки фронтенда. В противоположность библиотекам, вроде React, Ember даёт вам весь необходимый функционал без дополнительных усилий. Использование ember-cli и настроенных процессов сборки приложения выводит его на следующий уровень, делая процесс невероятно простым и безболезненным от начала и до конца. Добавив сюда поддержку [сообщества](https://www.emberjs.com/community/) практически не остаётся задач, которые не могли бы быть решены.

К сожалению, может быть сложно использовать Ember вместе с уже существующим проектом. Это работает прекрасно для старта нового проекта. Также Ember работает из коробки только с несколькими вариантами API бэкенда и если ваш бэкенд не соответствует им, то вы можете потратить много времени либо переписывая бэкенд, либо настраивая Ember на работу с вашим API. 

Ember способен на многое и позволяет очень быстро создавать веб-приложения различной сложности. Он навязывает свои представления о том как вы должны структурировать ваш код, но в большинстве случаев это не так плохо, как кажется, так как предлагаемая им структура в любом случае необходима.

---

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Статья на Medium](https://medium.com/devschacht/graham-cox-ember-the-perfect-framework-for-web-applications-970e817ded98)
