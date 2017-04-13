# Изучение React на примере написания Mini-Redux

*Перевод статьи [JAKOB LIND](https://twitter.com/karljakoblind): [Learn Redux by coding a Mini-Redux](http://blog.jakoblind.no/2017/03/13/learn-redux-by-coding-a-mini-redux/?utm_source=forwebdev_tlgrm&utm_medium=announcement&utm_campaign=luchshiy-sposob-izuchit-biblioteku--napis)*

Есть множество ресурсов по изучению Redux. Это официальная документация, примеры, руководства, блоги, шаблоны, Youtube видео, подкасты и т.д. Список можно продолжать. И хотя у нас есть так много замечательных ресурсов для изучения, новые разработчики, которые приходят иногда находятся в замешательстве. Всё из-за огромного количества материалов и трудностей по отбору нужных вещей.

Другая стратегия обучения — это самостоятельное написание кода простого Redux для развития губокого понимания основополагающих принципов библиотеки. Для меня это был настоящий прорыв в моём процессе обучения когда я сделал это. Теперь я чувствую, что знаю Redux как тот код, который я написал самостоятельно.

**Не беспокойстесь, это не сложно.** Ядро Redux удивительно простое. Вы увидете это прочитав и написав код с помощью этого поста.

Прежде чем мы начнём, нам необходимо общее представление о том, что же делает Redux.

## Что же делает Redux?

Суть Redux — это иметь единственный источник состояния (State) вашего приложения. Состояние хранится как обычный JavaScript-объект в одном месте: в Redux **хранилище** (Store). Объект с состоянием доступен только для чтения. Если вы хотите изменить состояние, то вам необходимо эмитировать (Emit) **действие** (Action), которое представляет собой обычный JavaScript-объект.

Ваше приложение может **подписаться** (subscribe), чтобы получить уведомление, когда хранилище изменяется. Когда Redux используется с React — компоненты React получают нотификации когда состояние изменилось и могут перерисовываться на основе нового контента в хранилище.

![](./redux.png)

Хранилищу необходим способ, с помощью которого оно может обновить своё состояние когда получает действие. Для этого оно использует простую JavaScript-функцию, которую Redux называет **преобразователь** (reducer). Функция-преобразователь передается при создании хранилища.

## Начнём программировать!

Подводя итог, мы должны сделать три вещи для нашего хранилиша, чтобы оно могло:

1. Получить текущее состояние хранилища
2. Передавать (dispatch) действие в качестве аргумента к преобразователю, чтобы обновить состояние в хранилище
3. Слушать (listen), когда хранилище изменяется

Мы также должны определить преобразователь и начальное состояние (initial state) на момент запуска. Давайте с этого и начнём:

```js
function createStore(reducer, initialState) {
    var currentReducer = reducer;
    var currentState = initialState;
}
```

### 1. Получение состояния
Итак, мы создали функцию, которая просто сохраняет начальное состояние и преобразователь как локальные переменные. Теперь давайте реализуем возможность получать состояние нашего хранилища.

```js
function createStore(reducer, initialState) {
    var currentReducer = reducer;
    var currentState = initialState;

    return {
        getState() {
            return currentState;
        }
    };
}
```

Теперь мы можем получать объект-состояние с помощью `getState()` ! Это было несложно.

### 2. Передать действие
Следующий шаг заключается в реализации поддержки направления действия.

```js
function createStore(reducer, initialState) {
    var currentReducer = reducer;
    var currentState = initialState;

    return {
        getState() {
            return currentState;
        },
        dispatch(action) {
            currentState = currentReducer(currentState, action);
            return action;
        }
    };
}
```

Функция `dispatch` передаёт текущее состояние и преобразует действие через функцию-преобразователь, которую мы определили при инициализации. Затем она перезаписывает старое состояние новым состоянием.

### 3. Подписка на события
Теперь мы можем получать текущее состояние и обновлять его! Последний шаг — это научиться слушать изменения:

```js
function createStore(reducer, initialState) {
    var currentReducer = reducer;
    var currentState = initialState;
    var listener = () => {};

    return {
        getState() {
            return currentState;
        },
        dispatch(action) {
            currentState = currentReducer(currentState, action);
            listener(); // Заметьте, что мы добавили эту строку!
            return action;
        },
        subscribe(newListener) {
            listener = newListener;
        }
    };
}
```

Теперь мы можем вызвать `subscribe` c функцией обратного вызова в качестве параметра, который будет вызываться всякий раз, когда происходит передача какого-нибудь действия.

## Мы закончили. Воспользуемся этим!

*Вот и вся реализация mini-Redux!* На самом деле это урезанная версия настоящего кода Redux

На [официальном гитхабе Redux](https://github.com/reactjs/redux) есть пример использования Redux. Мы можем скопировать этот пример, чтобы проверить нашу собственную реализацию Redux:

```js
function counter(state = 0, action) {
  switch (action.type) {
  case 'INCREMENT':
    return state + 1
  case 'DECREMENT':
    return state - 1
  default:
    return state
  }
}

let store = createStore(counter)

store.subscribe(() =>
  console.log(store.getState())
)

store.dispatch({ type: 'INCREMENT' })
store.dispatch({ type: 'INCREMENT' })
store.dispatch({ type: 'DECREMENT' })
```

Получить полный код для запуска на вашем компьютере вы можете [здесь](https://gist.github.com/jakoblind/6b90d0b677d26effcebbed69b24cb05f).

## Итог
Мы реализовали полностью рабочую версию Redux в 18 строк кода! Довольно впечатляюще!

Код, который мы написали, само собой, **не подходит для production**. По сравнению с "реальным" Redux, мы убрали обработку ошибок, не реализовали поддержку нескольких слушателей, не реализовали поддержку middlewares и т.д.

Теперь вы знаете основные принципы работы Redux и будете лучше подготовлены, продолжая ваше учебное путешествие!

В следующем [посте](http://blog.jakoblind.no/2017/03/20/learn-react-redux-by-coding-the-connect-function-yourself/) мы будем реализовывать функцию connect, которая связывает хранилище Redux c React компонентами.

- - - -

*Читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht). Скоро подъедет подкаст, не теряйтесь.*
