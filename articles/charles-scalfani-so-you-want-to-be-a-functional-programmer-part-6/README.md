# Итак, вы хотите научиться функциональному программированию (Часть 6)
*Перевод статьи [Charles Scalfani](https://medium.com/@cscalfani): [So You Want to be a Functional Programmer (Part 6)](https://medium.com/@cscalfani/so-you-want-to-be-a-functional-programmer-part-6-db502830403) с [наилучшими пожеланиями от автора](https://twitter.com/cscalfani/status/933052963781722112).*

![Эволюция парадигм программирования](https://cdn-images-1.medium.com/max/800/1*AM83LP9sGGjIul3c5hIsWg.png)

Первый шаг к пониманию идей функционального программирования – самый важный и иногда самый сложный шаг. Но с правильным подходом никаких трудностей быть не должно.

Предыдущие части: [Часть 1](https://medium.com/devschacht/charles-scalfani-so-you-want-to-be-a-functional-programmer-part-1-6ef98e90d58d), [Часть 2](https://medium.com/devschacht/charles-scalfani-so-you-want-to-be-a-functional-programmer-part-2-ae095d9807b3), [Часть 3](https://medium.com/devschacht/charles-scalfani-so-you-want-to-be-a-functional-programmer-part-3-d1f567656158), [Часть 4](https://medium.com/devschacht/charles-scalfani-so-you-want-to-be-a-functional-programmer-part-4-58edb490d0da), [Часть 5](https://medium.com/devschacht/charles-scalfani-so-you-want-to-be-a-functional-programmer-part-5-d78044d54675).

## Что теперь?

![Вырвитесь из целофанновой реальности](https://cdn-images-1.medium.com/max/800/1*yVZA0aT5t6crvBPAMn46Kg.png)

Теперь, когда вы изучили вcе эти новые классные вещи, вы, возможно, подумаете: "И что теперь? Как мне использовать это в моём обычном коде?".

Здесь возможны разные варианты. Если вы умеете программировать на чистом функциональном языке типа Elm или Haskell, тогда вам будет легко привести в действие механизмы всех этих идей. И такие языки позволят сделать это просто.

Если же вы умеете программировать только на императивном языке типа JavaScript – на том уровне на котором мы все должны это уметь – тогда вы можете продолжить использовать всё, что уже изучили, но теперь должным образом дисциплинируя себя. 

## Функциональный JavaScript

![Работает, как часы](https://cdn-images-1.medium.com/max/800/1*w_gG-CXQX4TV3B5bN24nqg.png)

JavaScript имеет множество фич, позволяющих вам программировать на более функциональной манер. Идеальной чистоты не будет, но вы можете добиться некоторой неизменяемости с помощью самого языка и ещё большей с помощью библиотек.

Это не идеально, но если вам нужно использовать эти возможности, тогда почему бы не получить некоторые преимущества функционального языка?

### Неизменяемость

Первая вещь, принятая во внимание – это неизменяемость. В ES2015 или ES6, как он ещё называется, появилось новое ключевое слово для объявления переменных – `const`. Оно означает, что если однажды переменная была установлена, она не может переопределена:

```js
const a = 1;
a = 2; // выбросит TypeError в Chrome, Firefox или Node
       // (прим. пер.; также и в Safari с версии 10.1)
```

Здесь `a` определена как константа и по этой причине не может быть изменена после установки. Вот почему выражение `a = 2` выбрасывает ошибку.

Проблема `const` в том, что в JavaScript она не заходит в своей идее так далеко, как должна. Следующий пример проиллюстрирует её предел:

```
const a = {
    x: 1,
    y: 2
};
a.x = 2; // НЕТ ИСКЛЮЧЕНИЯ!
a = {}; // а вот это выбросит TypeError
```

Заметьте, что `a.x = 2` НЕ выбрасывает исключения. Единственное значение, остающееся неизменяемым с `const` – это сама переменная `a`. Всё, что `a` в себе определяет может быть изменено. 

Это ужасное разочарование, потому что отсутствие такого недостатка сделало бы JavaScript гораздо лучше.

Как же мы можем достичь полной неизменяемости в JavaScript?

К сожалению, это возможно только с помощью библиотеки [Immutable.js](https://facebook.github.io/immutable-js/). Она должна дать нам должный уровень неизменяемости, но, увы, её использование также сделает наш код больше похожим на Java, чем на JavaScript.

### Каррирование и композиция

### `map`, `filter`, `reduce`

## Недостатки JavaScript

![Или всё-таки нет...](https://cdn-images-1.medium.com/max/800/1*GjSzT5C7dKD0GPgSZVFGIw.png)

## Elm

![Elm](https://cdn-images-1.medium.com/max/800/1*oVJSlb6bJfNCXYacQmcvew.png)

## Будущее

![Функциональный Гагарин](https://cdn-images-1.medium.com/max/800/1*0FpreasFPaa5rYns6Mpe6w.png)

---

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/%D0%B4%D0%B5%D0%B2%D1%88%D0%B0%D1%85%D1%82%D0%B0/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Статья на GitHub](https://github.com/communar/translations/tree/master/articles/charles-scalfani-so-you-want-to-be-a-functional-programmer-part-6)