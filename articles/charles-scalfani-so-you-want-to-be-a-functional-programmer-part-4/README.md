# Итак, вы хотите научиться функциональному программированию (Часть 4)
*Перевод статьи [Charles Scalfani](https://medium.com/@cscalfani): [So You Want to be a Functional Programmer (Part 4)](https://medium.com/@cscalfani/so-you-want-to-be-a-functional-programmer-part-4-18fbe3ea9e49) с [наилучшими пожеланиями от автора](https://twitter.com/cscalfani/status/933052963781722112).*

![Эволюция парадигм программирования](https://cdn-images-1.medium.com/max/800/1*AM83LP9sGGjIul3c5hIsWg.png)

Первый шаг к пониманию идей функционального программирования – самый важный и иногда самый сложный шаг. Но с правильным подходом никаких трудностей быть не должно.

Предыдущие части: [Часть 1](https://medium.com/devschacht/charles-scalfani-so-you-want-to-be-a-functional-programmer-part-1-6ef98e90d58d), [Часть 2](https://medium.com/devschacht/charles-scalfani-so-you-want-to-be-a-functional-programmer-part-2-ae095d9807b3), [Часть 3](https://medium.com/devschacht/charles-scalfani-so-you-want-to-be-a-functional-programmer-part-3-d1f567656158).

## Каррирование

![Каррирование — всего лишь сложение пазла](https://cdn-images-1.medium.com/max/800/1*zihd0We3yAkjAxleLPL2aA.png)

Как вы помните из [Части 3](https://medium.com/devschacht/charles-scalfani-so-you-want-to-be-a-functional-programmer-part-3-d1f567656158), причиной проблемы, из-за которой нам не удавалось скомпонировать функции `mult5` и `add`, является тот факт, что `mult5` принимает один параметр, а `add` — целых два.

Мы можем очень легко решить такую проблему, уменьшив количество входных данных для всех функций до одного. 

Поверьте мне. Это не так плохо, как звучит.

Мы просто пишем функцию сложения, которая использует 2 входных параметра, но принимает всего 1 за раз. Функции ***каррирования*** *("производные функции"  — прим. пер.)* позволяют нам сделать это.

> *Функция каррирования — это функция, принимающая один аргумент за раз*.

С их помощью мы передадим `add` первый параметр перед тем, как скомпонируем её с `mult5`. Затем, когда `mult5AfterAdd10` будет вызвана, `add` получит свой второй параметр.

В JavaScript мы можем реализовать эту идею, переписав `add`:

```js
var add = x => y => x + y;
```

Эта версия `add` — функция, принимающая один параметр сразу, а уже второй — позже.

Более детально, функция `add` принимает отдельный параметр, `x`, и возвращает ***функцию***, которая принимает следующий отдельный параметр, `y`, который, в конечном счёте, будет возвращать ***результат сложения `x` и `y`***.

Теперь мы можем использовать эту версию `add`, чтобы написать исправную версию `mult5AfterAdd10`:

```js
var compose = (f, g) => x => f(g(x));
var mult5AfterAdd10 = compose(mult5, add(10));
```

Функция компонирования (`compose`) получает на вход 2 параметра: `f` и `g`. После чего она возвращает функцию, принимающую 1 параметр, `x`, с вызовом которой композиция функций ***`f` после `g`*** осуществится с аргументом `x`.

Так что же мы на самом деле сделали? Что ж, мы конвертировали нашу простую старую функцию `add` в функцию каррирования. Это сделало `add` более гибкой, поскольку первый параметр, `10`, может быть передан перед непосредственным выполнением функции, а второй — когда функция `mult5AfterAdd10` будет вызвана.

Здесь вам, наверное, должно быть интересно, как же переписать функцию сложения в Elm. Оказывается, делать этого не нужно. В Elm и в других языках функционального программирования все функции автоматически каррированные.

Так что функция `add` остаётся неизменной:

```elm
add x y =
    x + y
```

А вот как должна была быть написана `mult5AfterAdd10`, возвращаясь к [Части 3](https://medium.com/devschacht/charles-scalfani-so-you-want-to-be-a-functional-programmer-part-3-d1f567656158):

```elm
mult5AfterAdd10 =
    (mult5 << add 10)
```

Говоря о синтаксисе, Elm одерживает верх над такими императивными языками, как JavaScript, поскольку он изначально оптимизирован для различных задач функционального программирования, например, каррирования или композиции функций.

## Каррирование и рефакторинг

![Начать всё с чистого "лица"](https://cdn-images-1.medium.com/max/800/1*kbFszF2qDVeeN591mpq8Ug.png)

---

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/%D0%B4%D0%B5%D0%B2%D1%88%D0%B0%D1%85%D1%82%D0%B0/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Статья на GitHub](https://github.com/communar/translations/tree/master/articles/charles-scalfani-so-you-want-to-be-a-functional-programmer-part-4)