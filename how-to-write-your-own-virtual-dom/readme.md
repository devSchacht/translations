# Как написать ваш собственный виртуальный DOM
*Перевод статьи [deathmood](https://twitter.com/_deathmood) [How to write your own Virtual DOM](https://medium.com/@deathmood/how-to-write-your-own-virtual-dom-ee74acc13060)*

Есть две вещи, которые вам необходимо знать для написания вашего собственного виртуального DOM. Вам даже не нужно погружаться в исходный код React или в исходный код любой другой имплементации виртуального DOM. Они такие большие и комплексные, но в действительности основная часть виртуального DOM может быть написана меньше чем за 50 строк кода. 50. Строк. Кода. !!!

Здесь заложено две концепции:
* Виртуальный DOM - любое представление настоящего DOM
* Когда мы что-то меняем в нашем виртуальном DOM дереве, мы создаем новое виртуальное дерево. Алгоритм сравнивает эти два дерева (старое и новое), находит разницу и вносит только необходимые минимальные изменения в настоящий DOM, чтобы он соответствовал виртуальному.

Это все! Давайте углубимся в каждую из этих концепций.

## Представление нашего DOM дерева
Хорошо, в первую очередь нам нужно как-то хранить наше DOM дерево в памяти. И мы можем сделать это с помощью простых JS объектов. Предположим, у нас есть это дерево:

```html
<ul class="list">
    <li>item 1</li>
    <li>item 2</li>
</ul>
```

Выглядит просто, не так ли? Как мы можем это представить с помощью простых JS объектов:

```js
{
  type: 'ul', props: { 'class': 'list' }, children: [
    { type: 'li', props: {}, children: ['item 1'] },
    { type: 'li', props: {}, children: ['item 2'] }
  ]
}
```

Здесь вы можете заметить две вещи:

* Мы представляем DOM элементы в объектом виде

```js
{ type: '…', props: { … }, children: [ … ] }
```

* Мы описываем текстовые ноды простыми JS строками

Но писать большие деревья таким способом довольно сложно. Так давайте напишем вспомогательную функцию, чтобы нам стало проще понимать структуру:

```js
function h(type, props, …children) {
  return { type, props, children };
}
```

Теперь мы можем описывать наше DOM дерево в таком виде:

```js
h('ul', { class: 'list' },
  h('li', {}, 'item 1'),
  h('li', {}, 'item 2'),
);
```

Выглядит намного чище, не правда ли? Но мы даже можем пойти дальше. Вы ведь слышали про JSX, не так ли? Да, я хотел бы применить его идеи тут. Так как же он работает?

Если вы читали официальную документацию Babel к JSX [здесь](https://babeljs.io/docs/plugins/transform-react-jsx/),
вы знаете, что Babel транспилирует этот код:

```html
<ul className=”list”>
  <li>item 1</li>
  <li>item 2</li>
</ul>
```

во что-то вроде этого:

```js
React.createElement('ul', { className: 'list' },
  React.createElement('li', {}, 'item 1'),
  React.createElement('li', {}, 'item 2'),
);
```

Заметили сходство? Да, да... Если бы мы только могли просто заменить вызов `React.createElement(...)` на наш `h(...)`... Оказывается, мы можем, используя jsx pragma. Нам только требуется вставить похожую на комментарий строчку в начале нашего файла с исходным кодом.

```html
/** @jsx helper */
<ul className=”list”>
  <li>item 1</li>
  <li>item 2</li>
</ul>
```

Хорошо, на самом деле сообщает babel'ю - "эй, скомпилируй этот jsx но вместо React.createElement, подставь h. Вы можете подставить все, что угодно вместо h здесь. И это будет скомпилированно.

Итак, подводя итоги того, что я сказал раньше, мы будем писать наш дом таким образом:
```html
/** @jsx h */
const a = (
  <ul className=”list”>
    <li>item 1</li>
    <li>item 2</li>
  </ul>
);
```
И это будест скомпилированно babel'ем в такой код:
```js
const a = (
  h(‘ul’, { className: ‘list’ },
    h(‘li’, {}, ‘item 1’),
    h(‘li’, {}, ‘item 2’),
  );
);
```

When function `h` executes, it will return plain JS objects — our Virtual DOM representation:
Выполнение функции h вернет обычный JS объект - наше представление виртуального дома.

```js
const a = (
  { type: ‘ul’, props: { className: ‘list’ }, children: [
    { type: ‘li’, props: {}, children: [‘item 1’] },
    { type: ‘li’, props: {}, children: [‘item 2’] }
  ] }
);
```
Попробуйте сами на [JSFiddle](https://jsfiddle.net/deathmood/5qyLubt4/?utm_source=website&utm_medium=embed&utm_campaign=5qyLubt4) (Не забуте указать Babel в качестве языка)

## Применение нашего DOM дерева

Теперь, когда мы имеем DOM представление в обычном JS объекте, имеющем свою собственную структуру, нам нужно создать механизм, который сможет строить из нее настоящий DOM.
Сначала давайте сделаем некоторые предположения и введем терминологию:
* Названия переменных с реальными DOM элементами будут начинаться с символа — $.
* Virtual DOM будет храниться в переменной с именем node.
* Аналогично React все узлы будут хранится в корневом элементе

Теперь напишем функцию, которая вернет DOM элемент, пока без «props» и «children»:
```
function createElement(node) {
  if (typeof node === ‘string’) {
    return document.createTextNode(node);
  }
  return document.createElement(node.type);
}
```


Так мы можем создавать текстовые узлы из обычных строк и элементы из JS объектов.
```js
{ type: ‘…’, props: { … }, children: [ … ] }
```


Теперь давайте подумаем о детях, каждый их них является либо строкой либо js объектов. Мы можем создавать их при помощи наШей функции createElement(). Да, ты чувсвтуешь это? Чувствешь рекурсивно? :)) Vы можем вызвать метод createelement(...) для каждого из детей элемента, а затем appendchild() в наш элемент вот так:

```js
function createElement(node) {
  if (typeof node === ‘string’) {
    return document.createTextNode(node);
  }
  const $el = document.createElement(node.type);
  node.children
    .map(createElement)
    .forEach($el.appendChild.bind($el));
  return $el;
}
```
Вау, это выглядит крсиво. Давайте пока не будем рассматривать props'ы. Мы вернемся к ним позже. Они не нужны нам для базового понимания концепций Virtual DOM, но добавят больше сложностей.

Сейчас пойдем и попробуем это на [JSFiddle](https://jsfiddle.net/deathmood/cL0Lc7au/?utm_source=website&utm_medium=embed&utm_campaign=cL0Lc7au)

## Обработка изменений

Ок, теперь мы можем превратить наш виртуальный дом в настоящий,
пора подумать про сравние наших виртуальных деревьев.
Нам нужно написать алгоритм, который будет сравнивать два виртуальных дерева
— старое и новое и делать только необходимые изменения в настоящем доме.

Для получения нового дерева нам нужно написать класс, предоставляющий следующие методы:
* Если нет старого узла, нужно добавить новый - appendChild(…)
![appendChild](https://cdn-images-1.medium.com/max/800/1*GFUWrX6pBgiDQ5Z-IvzjUw.png "appendChild")
* Нет узла на сатром месте - нужно удалить узел removeChild(…)
![removeChild](https://cdn-images-1.medium.com/max/800/1*VRoYwAeWPF0jbiWXsKb2HA.png "removeChild")

* Если узел изменился, нужно заменить узел replaceChild(…)
![replaceChild](https://cdn-images-1.medium.com/max/800/1*6iQYEH0APjbuPvYmnD7Qlw.png "replaceChild")

* Метод который будет «заглядывать внутрь», в случае если узлы одинаковые
![](https://cdn-images-1.medium.com/max/800/1*x1Eq-uuqgL0z9d9qn_opww.png "")


Ок, давайте напишем функцию updateElement(), которая принимает 3 параметра: $parent, oldNode, newNode.
Где $parent элемент реального DOM узла родительского блока. Сейчас мы увидим все случаи обработки узлов описанных выше.

### Если нет oldNode

у, это довольно просто здесь, я даже не буду комментировать:
```
function updateElement($parent, newNode, oldNode) {
  if (!oldNode) {
    $parent.appendChild(
      createElement(newNode)
    );
  }
}
```

### Если нет нового узла (newNode)

Тут проблема — если нет узла для текущего места, мы должны удалить это из реального DOM. Но как это сделать? Мы также можем передавать
позицию узла для удаления. У нас есть родительский элемент (он передается в функцию) и, следовательно, мы должны вызвать  $parent.removeChild(…) и передать реальную ссылку на dom-элемент.

```
function updateElement($parent, newNode, oldNode, index = 0) {
  if (!oldNode) {
    $parent.appendChild(
      createElement(newNode)
    );
  } else if (!newNode) {
    $parent.removeChild(
      $parent.childNodes[index]
    );
  }
}
```

### Измененный узел

Напишем функцию, которая сравнивает 2 узла. Мы должны учитывать, что это могут быть как элементы так и текстовые узлы:


```
function changed(node1, node2) {
  return typeof node1 !== typeof node2 ||
         typeof node1 === ‘string’ && node1 !== node2 ||
         node1.type !== node2.type
}
```

И теперь, имея индекс текущего узла родителя, мы можем легко заменить его на вновь созданный узел:

```
function updateElement($parent, newNode, oldNode, index = 0) {
  if (!oldNode) {
    $parent.appendChild(
      createElement(newNode)
    );
  } else if (!newNode) {
    $parent.removeChild(
      $parent.childNodes[index]
    );
  } else if (changed(newNode, oldNode)) {
    $parent.replaceChild(
      createElement(newNode),
      $parent.childNodes[index]
    );
  }
}
```

## Различия дочерних элементов

И последнее, но не менее важное — мы должны пройти через каждого ребенка на обоих узлах и сравнивать их
— если есть отличия, то вызвать updateElement(…) для каждого из них. Да, рекурсия снова.

```
function updateElement($parent, newNode, oldNode, index = 0) {
  if (!oldNode) {
    $parent.appendChild(
      createElement(newNode)
    );
  } else if (!newNode) {
    $parent.removeChild(
      $parent.childNodes[index]
    );
  } else if (changed(newNode, oldNode)) {
    $parent.replaceChild(
      createElement(newNode),
      $parent.childNodes[index]
    );
  } else if (newNode.type) {
    const newLength = newNode.children.length;
    const oldLength = oldNode.children.length;
    for (let i = 0; i < newLength || i < oldLength; i++) {
      updateElement(
        $parent.childNodes[index],
        newNode.children[i],
        oldNode.children[i],
        i
      );
    }
  }
}
```

## Собираем все вместе
Как я и обещал < 50 строк кода

```
function helper(type, props, ...children) {
  return { type, props, children };
}

function createElement(node) {
  if (typeof node === 'string') {
    return document.createTextNode(node);
  }
  const $el = document.createElement(node.type);
  node.children
    .map(createElement)
    .forEach($el.appendChild.bind($el));
  return $el;
}

function changed(node1, node2) {
  return typeof node1 !== typeof node2 ||
         typeof node1 === 'string' && node1 !== node2 ||
         node1.type !== node2.type
}

function updateElement($parent, newNode, oldNode, index = 0) {
  if (!oldNode) {
    $parent.appendChild(
      createElement(newNode)
    );
  } else if (!newNode) {
    $parent.removeChild(
      $parent.childNodes[index]
    );
  } else if (changed(newNode, oldNode)) {
    $parent.replaceChild(
      createElement(newNode),
      $parent.childNodes[index]
    );
  } else if (newNode.type) {
    const newLength = newNode.children.length;
    const oldLength = oldNode.children.length;
    for (let i = 0; i < newLength || i < oldLength; i++) {
      updateElement(
        $parent.childNodes[index],
        newNode.children[i],
        oldNode.children[i],
        i
      );
    }
  }
}

// ---------------------------------------------------------------------

const a = (
  <ul>
    <li>item 1</li>
    <li>item 2</li>
  </ul>
);

const b = (
  <ul>
    <li>item 1</li>
    <li>hello!</li>
  </ul>
);

const $root = document.getElementById('root');
const $reload = document.getElementById('reload');

updateElement($root, a);
$reload.addEventListener('click', () => {
  updateElement($root, b, a);
});
```

## Вывод
Поздравляю! Мы сделали это.
Мы написали реализацию Virtual DOM. И это работает.
Я надеюсь, что прочитав эту статью, вы поняли основные понятия и то, как Virtual DOM должен работать под капотом.

Однако, есть вещи, которые мы пропустили:

* Установка атрибутов, сравнение и замена
* Обработчики событий для наших элементов
* Создание компонент аналогичных React
* Получение ссылок на реальный дом узлы
* Использование Virtual DOM с библиотеками, которые непосредственно мутируют настоящий дом — такие, как jQuery и ее плагины.
* И много другое…

Вторая статья о работе с атрибутами и событиями в Virtual DOM [здесь](https://medium.com/@deathmood/write-your-virtual-dom-2-props-events-a957608f5c76).

- - - -

*Читайте нас на [Медиуме](https://medium.com/devschacht), контрибьютьте на [Гитхабе](https://github.com/devSchacht), общайтесь в [группе Телеграма](https://t.me/devSchacht), следите в [Твиттере](https://twitter.com/DevSchacht) и [канале Телеграма](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht). Скоро подъедет подкаст, не теряйтесь.*
