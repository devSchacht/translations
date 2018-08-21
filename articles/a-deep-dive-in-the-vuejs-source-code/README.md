
# Глубокое погружение в исходный код Vue.js #1
  
  ![Deep dive](https://cdn-images-1.medium.com/max/1600/0*P7_xt3xDqaXoZy1J.)
  
*Перевод статьи [A deep dive in the Vue.js source code](https://medium.com/@oneminutejs/a-deep-dive-in-the-vue-js-source-code-fd9638c05c05): [@oneminutejs](https://medium.com/@oneminutejs).*  
  
Данная серия представляет собой исчерпывающее погружение в исходный код Vue.js, чтобы продемонстрировать фундаментальные концепции JavaScript. Она попробует разбить концепции до уровня понятного начинающему JavaScript разработчику. Дополнительную информацию о будущих планах и развитии данной серии, смотрите в отдельном  [посте](https://medium.com/@oneminutejs/the-entire-vue-js-source-code-line-by-line-5-planning-update-from-the-front-line-fa6cfad12952). Чтобы следить за прогрессом, подписывайтесь на меня в [Twitter](https://twitter.com/oneminutejs). Список всех постов в серии можно посмотреть [здесь]([https://medium.com/@oneminutejs/the-entire-vue-js-source-code-line-by-line-5-planning-update-from-the-front-line-fa6cfad12952](https://medium.com/@oneminutejs/the-entire-vue-js-source-code-line-by-line-5-planning-update-from-the-front-line-fa6cfad12952)).

## Конструктор Vue

Экземпляр Vue наиболее подходящее место, откуда мы можем начать наше погружение. Как описывает документация Vue.js, "Каждое приложение Vue начинается с создания нового **экземпляра Vue** с помощью функции `Vue`"

В исходном коде новые Vue экземпляры создаются используя конструктор Vue:

```
function Vue (options) {  
  if (process.env.NODE_ENV !== 'production' &&  
    !(this instanceof Vue)  
  ) {  
    warn('Vue is a constructor and should be called with the `new` keyword');  
  }  
  this._init(options);  
}
```
[Конструктор объектов](https://www.w3schools.com/js/js_object_constructors.asp), это своего рода шаблон для создания дополнительных объектов. Имя функции конструктора пишется с большой буквы:
```
function Vue (options) {  
    [. . . .]
}
```
Вызывается конструктор с ключевым словом `new`. Например, вы можете вызвать конструктор Vue следующим образом: 
```
var vm = new Vue({  
  // Опции  
})
```
Вызов конструктора возвращает новый объект и устанавливает на нем контекст ``this``.

Конструктор Vue принимает один [параметр](https://www.w3schools.com/js/js_function_parameters.asp): `options`.
 
 ```
 function Vue (options) {  
  [. . . .]
}
```

Конструктор так же проверяет, что текущая среда выполнения _не_  является production, используя оператор [if](https://developer.mozilla.org/ru/docs/Web/JavaScript/Reference/Statements/if...else):

```
[....]  
  if (process.env.NODE_ENV !== 'production' && !(this instanceof Vue)) {
    warn('Конструктор Vue должен быть вызван с ключевым словом `new`');  
  }  
[....]
```
Если текущая среда выполнения production, благодаря быстрой оценке выражений (short-circuit) оператора `&&`, если первое выражение `false`, остальная часть не вычисляется.

Если же текущая среда development, конструктор проверяет что `this` не является экземпляром Vue с помощью [оператора](https://developer.mozilla.org/ru/docs/Web/JavaScript/Reference/Operators/instanceof)  `instanceof`

```
[....]  
  if (process.env.NODE_ENV !== 'production' && !(this instanceof Vue)) {
    warn('Конструктор Vue должен быть вызван с ключевым словом `new`');
  }  
[....]
```
Когда оба условия верны, конструктор вызывает функцию `warn`  c предупреждением о том, что конструктор должен вызываться, используя ключевое слово `new`:

```
[....]  
  if (process.env.NODE_ENV !== 'production’ && !(this instanceof Vue)) {
  warn('Vue is a constructor and should be called with the `new` keyword')
  }  
[....]
```
Мы рассмотрим детали реализации функции `warn` в другом посте. Если вы были внимательны, то обратили внимание на два типа кавычек, одинарные и обратный апостроф используемые в вызове `warn`:
```
warn('Vue is a constructor and should be called with the `new` keyword');
```
Два типа кавычек имеют очевидное преимущество — передаваемое выражение не прервется раньше времени.

Наконец, конструктор вызывает метод `this._init`, передавая `options` в качестве аргумента:

```
function Vue (options) {
  [....]
  this._init(options);
}
 ```

Но подождите, где же метод `init` ? Как мы видели,  в конструкторе он не определен. 
Быстрый поиск по исходному коду показывает, что данный метод добавлен в прототип  Vue отдельной функцией   `initMixin`.

Мы рассмотрим `initMixin`  в [следующий раз](https://medium.com/@oneminutejs/a-deep-dive-in-the-vue-js-source-code-the-initmixin-function-part-1-dc951603a3c).  Если вам нравится данная серия и вы хотите мотивировать меня продолжать над ней работу, хлопайте, подписывайте и делитесь  ссылкой :)

- - - -  
  
*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*
