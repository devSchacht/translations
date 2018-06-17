# Функция render() - что такое аргумент h

![logo](./images/logo.png)

*Перевод статьи [Sarah Drasner](https://sarahdrasnerdesign.com/): [What does the ‘h’ stand for in Vue’s render method?](https://css-tricks.com/what-does-the-h-stand-for-in-vues-render-method/). Опубликовано с разрешения автора.*

***

Если вы когда-либо работали с фреймворком [Vue.js](https://ru.vuejs.org/), то вам приходилось сталкиваться в файле `main.js` с подобным способом рендеринга приложения:

```js
new Vue({
 render: h => h(App)
}).$mount('#app')
```

В последней версии консольной утилиты [vue-cli](https://github.com/vuejs/vue-cli) такой способ является способом по умолчанию.

Другим возможным случаем, когда вам приходилось сталкиваться с функцией рендеринга `render()`, является использование синтаксического расширения [JSX](https://jsx.github.io/) в локальном компоненте Vue-приложения:

```js
Vue.component('jsx-example', {
  render (h) {
    return <div id="foo">bar</div>
  }
})
```

В обоих случаях у вас мог возникнуть вопрос - что такое `h` и для чего оно предназначено?

Если кратко - `h` является сокращением от **hyperscript**. Это название является (в свою очередь) сокращением для [Hypertext Markup Language](https://ru.wikipedia.org/wiki/HTML). Такое имя используется потому, что при работе с Vue-приложением мы фактически имеем дело со скриптом, результатом работы которого является виртуальное DOM-дерево. Использование подобного сокращения также встречается в официальной документации других JavaScript-фреймворков. Например, в документации [Cycle.js](https://cycle.js.org/) есть определение `h` - [The hyperscript function h()](https://cycle.js.org/api/dom.html#api-h).

Из [официальной документации Vue.js](https://ru.vuejs.org/v2/guide/render-function.html#JSX):

> Сокращение createElement до h — распространённое соглашение в экосистеме Vue и обязательное для использования JSX. В случае отсутствия h в области видимости, приложение выбросит ошибку.

В [одном из ишью](https://github.com/vuejs/babel-plugin-transform-vue-jsx/issues/6) создатель фреймворка Vue.js Эван Ю ([Evan You](https://twitter.com/youyuxi)) так объясняет, что такое `h`:

> Термин hyperscript можно объяснить так - это "скрипт, который генерирует HTML-структуру"

Сокращение `h` используется при написании кода - так быстрее и легче. Более подробно это сокращение также объясняется Эваном в [Advanced Vue Workshop](https://frontendmasters.com/courses/advanced-vue/render-function-api/) - курсов для фронтенд-разработчиков [Frontend Masters](https://frontendmasters.com/).

Про сокращение `h` можно думать как о более краткой форме функции `createElement`. Например, полная форма функции `createElement` представлена ниже:

```js
render: function (createElement) {
  return createElement(App);
}
```

Если заменить `createElement` на `h`, то получим более сокращенный вариант этой функции:

```js
render: function (h) {
  return h(App);
}
```

... который можно сократить еще больше при помощи возможностей ES6:

```js
render: h => h (App)
```

Vue-версия функции `render()` принимает три аргумента:

```js
render(h) {
  return h('div', {}, [...])
}
```

* первый аргумент - это тип элемента (в примере представлен `div`);
* второй аргумент - это объект данных (здесь можно передать свойства, атрибуты, классы или стили);
* третий аргумент - это массив дочерних Node-узлов; здесь можно размещать вложенные вызовы функции `createElement` и вернуть обратно дерево виртуальных DOM-узлов;

Термин **hyperscript** может вводить в заблуждение в некоторых случаях, так как это имя JavaScript-библиотеки [hyperscript](https://github.com/hyperhype/hyperscript), у которой есть одноименная [экосистема](https://github.com/hyperhype/hyperscript#ecosystem). В нашем конкретном случае речь не идет об этих сущностях.

Надеюсь, статья оказалась полезной для тех читателей, которые задавались подобным вопросом.
