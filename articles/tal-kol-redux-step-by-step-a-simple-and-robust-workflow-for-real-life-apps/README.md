# Redux: шаг за шагом

*Redux стал одной самых популярных реализаций идей Flux'a для управления потоком данных в приложениях на реакте.
Однако изучая Redux'а можно попасть в некоторое замешательство, когда "из за деревьев мы не видим леса".
Далее будет представлено простое и продуманное рабочее окружение для работы с приложениями, использующими Redux.
На примерах мы шаг за шагом реализуем рабочее приложение. Попытаемся применить принципы Redux на практике и обосновать каждое решение*


## An opinionated approach for idiomatic Redux
[Redux](https://github.com/reactjs/redux) это не просто библтотека. Это целая экосистема. Одна из причин его популярности — это возсожность применять различные паттерны и подкоды к написанию кода. К примеру, если нужно совершить некоторые асинхронные действия, то что мне стоит использовать? [Санки](https://github.com/gaearon/redux-thunk)? Или может быть [промисы](https://github.com/acdlite/redux-promise)? Или [саги](https://github.com/redux-saga/redux-saga)?

Существует не один "правильный" ответ на вопрос какой подход "лучше". И нет "лучшего" пути использования Redux. Стоит сказать, что большой выбор подходов ставит в тупик. Я хочу показать свой личный вариант использования. Он понятный, применимы к самым разным  "живым" сценариям и, что самое главное, он прост в освоении.

## Итак, пора создать наже приложение!

Для продолжения нам нужен реальный пример. As long as we’re being opinionated, the most interesting place on the Internet is Reddit. Давайте, создамим приложение, показывающее самые популярные посты оттуда.

На первом экране будем выяснять у пользователя наиболее интересные темы.We’ll pull the list of topics from Reddit’s list of default front page subreddits.

ПОсле того, как пользователь сделает выбор, будем показывать список постов по выбранным темам (все посты либо посты по конкретной теме). По клику на пост в списке будем показывать его содержимое.

## Установка
Поскольку мы используем React, то для начала работы возьмем [Create React App](https://github.com/facebookincubator/create-react-app) — официальный стартовый шаблон. ТАкже установим [redux](), [react-redux]() и [redux-thunk]().

Добавим index.js, создадим в нем хранилище(store), подключим санки.

```javascript
import React from 'react';
import ReactDOM from 'react-dom';
import { createStore, applyMiddleware, combineReducers } from 'redux';
import { Provider } from 'react-redux';
import thunk from 'redux-thunk';
import App from './App';
import './index.css';

import * as reducers from './store/reducers';
const store = createStore(combineReducers(reducers), applyMiddleware(thunk));

ReactDOM.render(
  <Provider store={store}>
    <App />
  </Provider>,
  document.getElementById('root')
);
```
