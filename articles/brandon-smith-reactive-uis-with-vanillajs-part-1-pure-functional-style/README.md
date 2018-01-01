# Реактивные интерфейсы на ванильном JavaScript - Часть 1: Чистый функциональный стиль

*Перевод статьи [Brandon Smith](http://www.brandonsmith.ninja/): [Reactive UI’s with VanillaJS – Part 1: Pure Functional Style](https://css-tricks.com/reactive-uis-vanillajs-part-1-pure-functional-style/).*

![](tools.jpg)

20 апреля Крис Койер написал [пост](https://css-tricks.com/project-need-react), исследуя вопрос: «При каких условиях проекту нужен React?». Другими словами, когда преимущества использования React (или другого веб-фреймворка для приложений с нетривиальной логикой), вместо серверных шаблонов и jQuery, перевешивают сложность настройки требуемого инструментария, процесса сборки, разрешения зависимостей и так далее? Через неделю Саша Грайф выразил в своей [статье](https://css-tricks.com/projects-need-react) противоположное мнение о преимуществах постоянного использования такой структуры для каждого веб-проекта. Его аргументы состояли в том, что фреймворк обеспечивает устойчивую расширяемость, упрощенный рабочий процесс от проекта к проекту (единую архитектуру, отсутствие необходимости в сопровождении нескольких типов структур проекта) и улучшенный пользовательский интерфейс благодаря рендерингу на стороне клиента, даже если контент меняется не часто.

В этой паре статей пробуем найти золотую середину: написание пользовательского интерфейса в реактивном стиле в ванильном JavaScript - без фреймворков, без препроцессоров.

Существует два способа создания компонентов React.

1. Вы можете написать их как классы. Объекты с состоянием, обработчиками жизненного цикла и внутренними данными.
2. Или вы можете написать их как функции. Просто часть HTML, которая создаётся и обновляется на основе передаваемых параметров.

Первый вариант более полезен для больших сложных приложений с динамичным интерфейсом, а второй является элегантным способом отображения информации, при отсутствии сложного динамического состояния. Если вы когда-либо использовали шаблонный движок, например Handlebars или Swig, их синтаксис довольно похож на функциональный код React.

В этой серии статей наша цель - статичные сайты, которые при использовании рендеринга на основе JavaScript получат определенные преимущества в случае отсутствия накладных расходов на создание такой структуры, как React. Блоги, форумы и так далее. Поэтому этот первый пост будет посвящен функциональному подходу к написанию пользовательского интерфейса на основе компонентов, поскольку такой интерфейс будет более практичным для такого сценария. Второй пост будет скорее экспериментом: я постараюсь расширить грани того, как далеко мы можем продвинуться без фреймворка, пытаясь максимально точно скопировать структуру компонентов на классах React, используя только ванильный JavaScript (возможно, за счет небольшой потери практичности).

## О функциональном программировании

За последние пару лет функциональное программирование стремительно развивалось, по большей части в Clojure, Python и React. Полное объяснение понятия функционального программирования выходит за рамки этой публикации. Актуальная для нас часть - это концепция величин, которые являются функциями других величин.

Скажем, ваш код должен представлять концепцию прямоугольника. Прямоугольник имеет ширину и высоту, но также имеет площадь, периметр и другие атрибуты. Сначала можно представить прямоугольник следующим объектом:

```js
var rectangle = {
	width: 2,
	height: 3,
	area: 6,
	perimeter: 10
};
```

Сразу видно, что есть проблема. Что произойдет, если ширина изменится? При этом мы должны изменить площадь и периметр, иначе они будут неверны. Возможно будут конфликтующие значения, которые нельзя просто изменить, не обновляя что-то ещё. Это называется наличием множественных источников истины.

В примере с прямоугольником решение в функциональном стиле состоит в том, чтобы сделать область и периметр функциями прямоугольника:

```js
var rectangle = {
	width: 2,
	height: 3
};

function area(rect) {
	return rect.width * rect.height;
}

function perimeter(rect) {
	return rect.width * 2 + rect.height * 2;
}

area(rectangle); // = 6
perimeter(rectangle); // = 10
```

Таким образом, если изменяется ширина или высота, нам не нужно вручную изменять что-либо ещё, чтобы отразить этот факт. Площадь и периметр просто всегда верны. Это называется наличием единственного источника истины.

Сила этой идеи также проявляется, когда вместо длины и ширины прямоугольника - данные вашего приложения, а вместо площади и периметра - HTML. Если вы можете сделать HTML функцией от данных, заботиться нужно будет только об их изменении, а DOM отобразится на странице неявным способом.

## UI компоненты как функции

Мы хотим сделать HTML функцией от наших данных. Давайте рассмотрим пример сообщения в блоге:

```js
var blogPost = {
	author: 'Brandon Smith',
	title: 'A CSS Trick',
	body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
};

function PostPage(postData) {
	return '<div class="page">' +
		'<div class="header">' + 
			'Home' +
			'About' +
			'Contact' +
		'</div>' + 
		'<div class="post">' + 
			'<h1>' + postData.title + '</h1>' + 
			'<h3>By ' + postData.author + '</h3>' +
			'<p>' + postData.body + '</p>' +
		'</div>' +
	'</div>';
}

document.querySelector('body').innerHTML = PostPage(blogPost);
```

Хорошо. Мы создали функцию объекта сообщения, возвращающую строку HTML, которая отображает наше сообщение в блоге. На самом деле это пока не компонентно. Это - единый большой шаблон. Что делать, если мы хотим отобразить все наши сообщения в блоге последовательно на главной странице? Что делать, если мы хотим повторно использовать этот заголовок на разных страницах? К счастью, можно легко построить функции из других функций. Это называется композиция:

```js
var blogPost = {
  author: 'Brandon Smith',
  title: 'A CSS Trick',
  body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
};

function Header() {
  return '<div class="header">' + 
            'Home' +
            'About' +
            'Contact' +
          '</div>';
}

function BlogPost(postData) {
  return '<div class="post">' + 
            '<h1>' + postData.title + '</h1>' + 
            '<h3>By ' + postData.author + '</h3>' +
            '<p>' + postData.body + '</p>' +
          '</div>';
}

function PostPage(postData) {
  return  '<div class="page">' +
            Header() +
            BlogPost(postData) +
          '</div>';
}

function HomePage() {
  return '<div class="page">' +
            Header() +
            '<h1>Welcome to my blog!</h1>' +
            '<p>It\'s about lorem ipsum dolor sit amet, consectetur ad...</p>' +
          '</div>';
}

document.querySelector('body').innerHTML = PostPage(blogPost);
```

Так гораздо приятнее. Нам не пришлось дублировать заголовок для домашней страницы и у нас есть единственный источник истины для этого HTML-кода. Если мы захотим отобразить сообщение в другом контексте, мы сможем легко это сделать.

## Достаточный синтаксис с шаблонами

Хорошо, но эти конкатенации ужасны. Их нудно печатать, и они затрудняют чтение. Должен быть лучший способ, не так ли? Люди в W3C опережают нас в этом. Они создали шаблонные литералы, которые, хотя и относительно новы, уже имеют довольно [хорошую поддержку в браузерах](https://caniuse.com/#feat=template-literals). Просто оберните свою строку в обратные кавычки и она получит пару дополнительных сверхспособностей.

Первая суперсила - это способность охватывать несколько строк. Наш компонент `BlogPost` может стать таким:

```js
// ...

function BlogPost(postData) {
  return `<div class="post">
            <h1>` + postData.title + `</h1>
            <h3>By ` + postData.author + `</h3>
            <p>` + postData.body + `</p>
          </div>`;
}

// ...
```

Неплохо. Но другая фишка ещё приятнее: подстановка переменных. Переменные (или любое выражение JavaScript, включая вызовы функций!) могут быть вставлены непосредственно в строку, если они завернуты в `${}`:

```
// ...

function BlogPost(postData) {
  return `<div class="post">
            <h1>${postData.title}</h1>
            <h3>By ${postData.author}</h3>
            <p>${postData.body}</p>
          </div>`;
}

// ...
```

Намного лучше. Сейчас это похоже на JSX. Наш полный пример с шаблонными литералами теперь выглядит так:

```
var blogPost = {
  author: 'Brandon Smith',
  title: 'A CSS Trick',
  body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
};

function Header() {
  return `<div class="header">
            Home
            About
            Contact
          </div>`;
}

function BlogPost(postData) {
  return `<div class="post">
            <h1>${postData.title}</h1>
            <h3>By ${postData.author}</h3>
            <p>${postData.body}</p>
          </div>`;
}

function PostPage(postData) {
  return  `<div class="page">
            ${Header()}
            ${BlogPost(postData)}
          </div>`;
}

function HomePage() {
  return `<div class="page">
            ${Header()}
            <h1>Welcome to my blog!</h1>
            <p>It's about lorem ipsum dolor sit amet, consectetur ad...</p>
          </div>`;
}

document.querySelector('body').innerHTML = PostPage(blogPost);
```

## Больше, чем просто заполнение пробелов

Таким образом, мы можем подставить значения переменных и даже другие компоненты через функции, но иногда необходима более сложная логика. Иногда нам нужно перебирать данные или отвечать на изменение состояния. Давайте рассмотрим некоторые функции JavaScript, упрощающие выполнение более сложного рендеринга в функциональном стиле.

## Тернарный оператор

Начнем с простейшей логики: `if-else`. Поскольку наши компоненты пользовательского интерфейса - просто функции, мы можем использовать `if-else`, если хотим. Посмотрим, как это будет выглядеть:

```js
var blogPost = {
  isSponsored: true,
  author: 'Brandon Smith',
  title: 'A CSS Trick',
  body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
};

function BlogPost(postData) {
  var badgeElement;
  if(postData.isSponsored) {
    badgeElement = `<img src="badge.png">`;
  } else {
    badgeElement = '';
  }

  return `<div class="post">
            <h1>${postData.title} ${badgeElement}</h1>
            <h3>By ${postData.author}</h3>
            <p>${postData.body}</p>
          </div>`;
}
```

Это все... не идеально. Мы добавляем много строк для несложной логики и отделяем код рендеринга от его места в остальной части HTML. Это связано с тем, что классический оператор `if-else` решает, какие строки кода запускать, а не какое значение вычислять. Это важное для понимания различие. Вы не можете вставить последовательность в шаблонный литерал, только одно выражение.

Тернарный оператор подобен `if-else`, но он пишется одним выражением:

```js
var wantsToGo = true;
var response = wantsToGo ? 'Yes' : 'No'; // response = 'Yes'

wantsToGo = false;
response = wantsToGo ? 'Yes' : 'No'; // response = 'No'
```

Он имеет вид `[условие] ? [ЗначениеIfTrue] : [ЗначениеIfFalse]`. Итак, приведенный выше пример блога:

```js
var blogPost = {
  isSponsored: true,
  author: 'Brandon Smith',
  title: 'A CSS Trick',
  body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
};

function BlogPost(postData) {
  return `<div class="post">
            <h1>
              ${postData.title} ${postData.isSponsored ? '<img src="badge.png">' : ''}
            </h1>
            <h3>By ${postData.author}</h3>
            <p>${postData.body}</p>
          </div>`;
}
```

Так намного лучше.

## Array.map()

Перейдем к циклам. Когда у нас есть массив данных, которые мы хотим отобразить, нам нужно перебрать значения, чтобы сгенерировать соответствующий HTML. Но если бы мы использовали цикл `for`, мы столкнулись бы с той же проблемой, что и с приведенной выше инструкцией `if-else`. Цикл `for` не оценивает значение, он выполняет ряд инструкций определенным образом. К счастью, ES6 добавил некоторые очень полезные методы к типу `Array`, которые служат для этой конкретной потребности.

`Array.map()` - это метод `Array`, принимающий один аргумент - функцию обратного вызова. Он перебирает массив, на котором вызван (аналогично `Array.forEach()`), и применяет один раз функцию обратного вызова для каждого элемента, передавая в неё элемент массива. Его отличие от `Array.forEach()` заключается в том, что обратный вызов должен возвращать значение - предположительно такое, которое вычисляется с учетом значения текущего элемента массива, и `map` возвращает новый массив всех элементов, возвращаемых из функции обратного вызова. Например:

```js
var myArray = [ 'zero', 'one', 'two', 'three' ];

// приводится к [ 'ZERO', 'ONE', 'TWO', 'THREE' ]
var capitalizedArray = myArray.map(function(item) {
  return item.toUpperCase();
});
```

Вы возможно уже поняли, почему такой способ эффективен для нас. Ранее мы определили концепцию: значение - функция от другого значения. `Array.map()` позволяет нам получить целый массив, для которого каждый элемент является функцией соответствующего элемента в другом массиве. Допустим, у нас есть массив сообщений в блогах, которые мы хотим отобразить:

```js
function BlogPost(postData) {
  return `<div class="post">
            <h1>${postData.title}</h1>
            <h3>By ${postData.author}</h3>
            <p>${postData.body}</p>
          </div>`;
}

function BlogPostList(posts) {
  return `<div class="blog-post-list">
            ${posts.map(BlogPost).join('')}
          </div>`
}

var allPosts = [
  {
    author: 'Brandon Smith',
    title: 'A CSS Trick',
    body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
  },
  {
    author: 'Chris Coyier',
    title: 'Another CSS Trick',
    body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
  },
  {
    author: 'Bob Saget',
    title: 'A Home Video',
    body: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
  }
]

document.querySelector('body').innerHTML = BlogPostList(allPosts);
```

Каждый объект, содержащий данные одного сообщения в блоге, передаётся последовательно в функцию `BlogPost`, а возвращаемые строки HTML формируют новый массив. Затем мы просто вызываем `join()` на этом новом массиве, чтобы объединить массив строк в одну строку (разделенную пустой строкой), и готово. Нет циклов `for`, просто список объектов, преобразованных в список элементов HTML.

## Перерисовка

Теперь мы можем неявно генерировать HTML из входных данных, компоновать и использовать этот код для других данных, и все это на стороне клиента. Но как обновлять HTML при изменении данных? Как вообще понять в какой момент произошли изменения? Этот вопрос является одним из самых сложных и горячо обсуждаемых в сообществе фреймворков JavaScript. Осуществление частых обновлений DOM - удивительно сложная проблема, над которой инженеры из Facebook и Google работают уже много лет.

К счастью, наш сайт - это всего лишь блог. Содержание ощутимо меняется только при просмотре другого сообщения в блоге. Нет множества взаимодействий для отслеживания, нам не нужно оптимизировать операции с DOM. Когда мы загружаем новое сообщение, мы можем просто удалить DOM и перестроить его.

```js
document.querySelector('body').innerHTML = PostPage(postData);
```

Мы могли бы сделать это немного лучше, обернув в функцию:

```js
function update() {
  document.querySelector('body').innerHTML = PostPage(postData);
}
```

Теперь, когда мы загружаем данные сообщения, просто вызываем `update()` и отображается нужный HTML. Если бы наше приложение было достаточно сложным и его нужно было бы часто перерисовывать (например, пару раз в секунду), оно быстро начало бы тормозить. Можно написать сложную логику, чтобы определять, какие части страницы действительно нуждаются в обновлении, учитывая конкретное изменение данных, и обновлять только их, но это как раз тот случай, когда надо просто использовать фреймворк.

## Не только для контента

На данный момент почти весь наш код рендеринга использовался для определения фактического содержимого HTML и текста внутри элементов, но мы не должны останавливаться на достигнутом. Поскольку мы просто создаём HTML-строку, туда можно добавить кое-что ещё. Классы CSS?

```js
function BlogPost(postData) {
  return `<div class="post ${postData.isSponsored ? 'sponsored-post' : ''}">
            <h1>
              ${postData.title} ${postData.isSponsored ? '<img src="badge.png">' : ''}
            </h1>
            <h3>By ${postData.author}</h3>
            <p>${postData.body}</p>
          </div>`;
}
```

Сделано. HTML-атрибуты?

```js
function BlogPost(postData) {
  return `<div class="post ${postData.isSponsored ? 'sponsored-post' : ''}">
            <input type="checkbox" ${postData.isSponsored ? 'checked' : ''}>
            <h1>
              ${postData.title} ${postData.isSponsored ? '<img src="badge.png">' : ''}
            </h1>
            <h3>By ${postData.author}</h3>
            <p>${postData.body}</p>
          </div>`;
}
```

Сделано. Не стесняйтесь проявлять творческий подход. Подумайте о своих данных и подумайте о том, как все различные их аспекты должны быть представлены в разметке и пишите выражения, превращающие одно в другое.

## Итоги

Надеюсь, что эта статья даёт вам хороший набор инструментов для написания простых реактивных веб-интерфейсов, управляемых данными, без накладных расходов в лице каких-либо инструментов или фреймворков. Этот тип кода намного проще писать и поддерживать, чем jQuery лапшу, и нет никакого препятствия для использования его прямо сейчас. Все, о чем мы говорили здесь, поддерживается всеми достаточно современными браузерами, без дополнительных библиотек.

Во второй части основное внимание будет уделено классам, компонентам с состоянием, которые будут на грани сложного и разумного использования нативного JavaScript. Но мы все равно попробуем, и это будет интересно.

- - - -

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Статья на Medium](https://medium.com/devschacht/brandon-smith-reactive-uis-with-vanillajs-part-1-pure-functional-style-eab429612ba2)
