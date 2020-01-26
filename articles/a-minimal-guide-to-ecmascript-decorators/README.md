# Минимальное руководство по декораторам ECMAScript

*Перевод статьи [Uday Hiwarale](https://twitter.com/thatisuday): [A minimal guide to ECMAScript Decorators](https://itnext.io/a-minimal-guide-to-ecmascript-decorators-55b70338215e).*

Краткое введение в предложение «декораторов» в JavaScript с простыми примерами и немного о ECMAScript

![](https://cdn-images-1.medium.com/max/2000/1*CMwgpS7hFNgPqnz62gaBqA.png)

Почему **декораторы ECMAScript** вместо **декораторы JavaScript** в заголовке?
Поскольку [**ECMAScript**](https://ru.wikipedia.org/wiki/ECMAScript) — стандарт для написания скриптовых языков,
таких как **JavaScript**, он не следит за тем, что JavaScript будет поддерживать все спецификации, однако движок
JavaScript (__используемый разными браузерами__) может поддерживать возможность, введённую в ECMAScript,
или поддерживать её с небольшим различием в поведении.

Рассмотрим ECMAScript как **язык**, на котором вы разговариваете, например, **английский**.
Тогда JavaScript будет **диалектом**, скажем, **британского английского**.
Диалект — сам по себе тоже язык, но основан он на принципах языка, из которого произошёл.
Итак, ECMAScript — это книга рецептов для приготовления/написания JavaScript, и только от шеф-повара/разработчика зависит, следовать его ингредиентам/правилам или нет.

Как правило, последователи (adopters) JavaScript соблюдают все спецификации, написанные в языке (иначе разработчики сойдут с ума),
и отправляют новую версию движка JavaScript очень поздно, пока до конца не убедятся, что всё работает как надо.
**TC39** или технический комитет 39 (Technical Committee 39) в ассоциации ECMA International отвечает за поддержку
спецификаций языка ECMAScript. Члены этой команды являются частью ECMA International, разработчиками браузеров и представителями компаний,
заинтересованных вебом в целом.


Поскольку ECMAScript — это открытый стандарт, любой может предложить новые идеи или возможности и работать над ними.
Следовательно, предложение новой функциональной возможности проходит через 4 основные этапа, и TC-39 участвует в этом процессе до тех пор,
пока предложение не будет готово к внедрению.

этап | название | mission
- | - | - |
0 | кандидат на предложение (strawman) | Представить новую возможность (предложение) в комитет TC-39. Как правило, представляется членом TC39 или помощником (contributor) TC39.
1 | предложение (proposal) | Определить варианты использования предложения, зависимости, задачи, демонстрации, полифилы и т.д. Куратор (член TC39) будет отвечать за это предложение.
2 | черновик (draft) | Это первоначальная версия возможности, которая в конечном счёте будет добавлена. Следовательно, должны быть представлены описание и синтаксис. Транспилер, такой как Babel, должен поддерживать и продемонстрировать реализацию.
3 | кандидат (candidate) | Предложение почти готово и некоторые изменения могут быть сделаны в ответ на критические проблемы, поднятые последователями и комитетом TC39.
4 | готов (finished) | Предложение готово для включения в стандарт.

В настоящее время (*июнь 2018*) __декораторы__ находятся на **втором этапе**, и у нас есть Babel-плагин для транспиляции декораторов `babel-plugin-transform-decorators-legacy`.
Предложения, находящиеся на втором этапе не рекомендуются для использования в продакшене, поскольку синтаксис новой возможности подвержен изменениям.
В любом случае, декораторы прекрасны и очень полезны для ускорения процесса разработки.

С этого момента мы работаем с экспериментальным JavaScript, поэтому ваша версия  Node.js может не поддерживать данную возможность. Поэтому нам нужен транспилятор Babel или TypeScript. Используйте плагин [__js-plugin-starter__](https://github.com/thatisuday/js-plugin-starter)  для настройки очень простого проекта, в котором я добавил поддержку декораторов, которые мы рассмотрим в статье.

* * *

Для понимания декораторов нужно сначала разобраться, что такое __дескриптор свойства__ (property descriptor) объекта в JavaScript. Дескриптор свойства представляет собой набор правил для свойства объекта, как например, является ли свойство доступным для записи (__writable__) или перечислимым (__enumerable__). Когда мы создаём простой объект и добавляем некоторые свойства, у каждого из свойств есть дескриптор свойства по умолчанию.

```js
var myObj = {
    myPropOne: 1,
    myPropTwo: 2
};
```

`myObj` — простой JavaScript-объект, который выглядит следующим образом в консоли

![](https://cdn-images-1.medium.com/max/800/1*Y8y_yHAuU4e5qQ98328h9A.png)

Теперь, если присвоим новое значение для свойства, как показано ниже, операция завершится успешно и мы получим изменённое значение.

```js
myObj.myPropOne = 10;
console.log(myObj.myPropOne); //==> 10
```

Для получения дескриптора свойства, нам нужно использовать метод `Object.getOwnPropertyDescriptor(obj, propName)`. **Own** означает вернуть дескриптор свойства `propName`, только если оно принадлежит объекту `obj`, а не его цепочке прототипов.

```js
const descriptor = Object.getOwnPropertyDescriptor(
    myObj,
    'myPropOne'
);

console.log(descriptor);
```

![](https://cdn-images-1.medium.com/max/800/1*_hI_shyJTWzbDzxAZRG2cw.png)

Метод `Object.getOwnPropertyDescriptor` возвращает объект с ключами, описывающими разрешения и текущее состояние свойства. `value` — текущее значение свойства, `writable` — может ли пользователь назначить новое значение для свойства, `enumerable` — будет ли это свойство отображаться при перечислениях, например, при итерациях цикла `for in` или `for of`, либо в `Object.keys` и т.д., `configurable` — есть ли у пользователя разрешение изменять **дескриптор свойства** и может ли он изменять значение на  `writable` или `enumerable`. В дескрипторе свойств есть ключи `get` и `set` — промежуточные функции для возврата или обновления значений, но эти ключи необязательные.

Для создания нового свойства объекта или обновления существующего свойства с пользовательским дескриптором, мы можем воспользоваться `Object.defineProperty`. Давайте изменим существующее свойство `myPropOne` с `writable` на `false`, что **запретит изменения** в `myObj.myPropOne`.

```js
'use strict';

let myObj = {
    myPropOne: 1,
    myPropTwo: 2
};

// изменяем дескриптор свойства
Object.defineProperty(myObj, 'myPropOne', {
    writable: false
});

// распечатываем дескриптор свойства
let descriptor = Object.getOwnPropertyDescriptor(
    myObj, 'myPropOne'
);
console.log(descriptor);

// устанавливаем новое значение
myObj.myPropOne = 2;
```

![](https://cdn-images-1.medium.com/max/800/1*OA4CAoOYemieJ9lB5wmqCg.png)

Как видно из вышеприведённой ошибки, наше свойство `myPropOne` недоступно для записи, поэтому, если пользователь попытается присвоить ему новое значение, будет выброшена ошибка.

> Если `Object.defineProperty` обновляет существующий дескриптор свойства, тогда **исходный дескриптор** будет **переопределен** новыми изменениями. `Object.defineProperty` возвращает исходный объект `myObj` после изменений.

Давайте посмотрим, что произойдёт, если мы установим ключ дескриптора `enumerable` в значение `false`.

```js
let myObj = {
    myPropOne: 1,
    myPropTwo: 2
};

// изменяем дескриптор свойства
Object.defineProperty(myObj, 'myPropOne', {
    enumerable: false
});

// распечатываем дескриптор свойства
let descriptor = Object.getOwnPropertyDescriptor(
    myObj, 'myPropOne'
);
console.log(descriptor);

// распечатываем ключи
console.log(Object.keys(myObj));
```

![](https://cdn-images-1.medium.com/max/800/1*Aa-unAIvyxiw3kGjIz4Ewg.png)

Как видно из приведённого выше результата в консоли, мы не видим свойство `myPropOne` при вызове `Object.keys`.

Если мы определим новое свойство с помощью `Object.defineProperty` и передадим пустой дескриптор `{}`, будет задан дескриптор по умолчанию, который выглядит так:

![](https://cdn-images-1.medium.com/max/800/1*e3FZCJKiLjbMVJnFbHcKIg.png)

Теперь давайте определим новое свойство с пользовательским дескриптором, где для ключа дескриптора `configurable` установлено значение `false`. Мы сохраним `writable` в значение `false`, а `enumerable` в значение `true` с `value`, установленным в `3`.

```js
let myObj = {
    myPropOne: 1,
    myPropTwo: 2
};

// изменяем дескриптор свойства
Object.defineProperty(myObj, 'myPropThree', {
    value: 3,
    writable: false,
    configurable: false,
    enumerable: true
});

// распечатываем дескриптор свойства
let descriptor = Object.getOwnPropertyDescriptor(
    myObj, 'myPropThree'
);
console.log(descriptor);

// изменяем дескриптор свойства
Object.defineProperty(myObj, 'myPropThree', {
    writable: true
});
```

![](https://cdn-images-1.medium.com/max/800/1*QulK_GxuflHPaJ6X4UwqAA.png)

Установив дескриптор ключа `configurable` в значение `false`, мы потеряли возможность изменять дескриптор нашего свойства `myPropThree`. Это очень полезно, если вы не хотите, чтобы ваши пользователи манипулировали рекомендуемым поведением объекта.

**get** (геттер) и **set** (сеттер) в свойстве также можно установить в дескрипторе свойства. Но когда вы определяете геттер, придётся кое-чем пожертвовать. У вас нет **начального значения** или ключа `value` в дескрипторе вообще, потому что геттер вернёт значение этого свойства. Вы также не можете использовать ключ `writable` в дескрипторе, потому что ваши записи выполняются через сеттер, и вы можете предотвратить запись там. Взгляните на документацию MDN по [геттеру](https://developer.mozilla.org/ru/docs/Web/JavaScript/Reference/Functions/get) и [сеттеру](https://developer.mozilla.org/ru/docs/Web/JavaScript/Reference/Functions/set), или прочитайте [эту статью](https://codeburst.io/javascript-object-property-attributes-ac012be317e2), если вам не нужны подробные объяснения.

> Вы можете и/или обновлять сразу несколько свойств, используя `Object.defineProperties`, принимающий два аргумента. Первый аргумент — **целевой объект**, свойства которого должны быть добавлены/изменены, а второй аргумент — это объект с `key` в качестве **имени свойства** и `value` как дескриптор свойства. Эта функция возвращает **целевой объект**.

У функции `Object.create` следующий синтаксис:

```js
let obj = Object.create(prototype, {property: descriptor, ... })
```

Здесь `prototype` — это объект, который будет прототипом `obj`. Если `prototype` равен `null`, тогда у `obj` не будет прототипа. Когда вы определяете пустой или непустой объект с синтаксисом `var obj= {}` по умолчанию `obj.__proto__` будет указывать на `Object.prototype`, следовательно, `obj` имеет прототип класса `Object`.

Это похоже на использование `Object.create` вместе с `Object.prototype` в качестве первого аргумента (*прототип создаваемого объекта*).

```js
'use strict';

let obj = Object.create(Object.prototype, {
    a: { value: 1, writable: false },
    b: { value: 2, writable: true }
});

console.log(obj.__proto__);
console.log(`obj.hasOwnProperty('a') => ${obj.hasOwnProperty('a')}`);
```

![](https://cdn-images-1.medium.com/max/800/1*Fc2_huyI1qxhEif4E9wHRw.png)

Но когда мы устанавливаем **prototype** в значение `null`, мы получаем ошибку, показанную ниже.

```js
'use strict';

let obj = Object.create(null, {
    a: { value: 1, writable: false },
    b: { value: 2, writable: true }
});

console.log(obj.__proto__);
console.log(`obj.hasOwnProperty('a') => ${obj.hasOwnProperty('a')}`);
```

![](https://cdn-images-1.medium.com/max/800/1*JOvcTkY5uzgrjlOBhz0QtQ.png)

* * *

## ✱ Декоратор метода класса

Теперь, когда мы выяснили, как мы можем определять и настраивать новые или существующие свойства объекта, давайте обратим внимание на декораторы и почему мы вообще мы обсуждали дескрипторы свойств вообще.

Декоратор — это функция JavaScript (*рекомендуется чистая функция*), которая используется для изменения свойств/методов класса или для изменения самого класса. Когда вы добавляете синтаксис `@decoratorFunction` в начало **свойства класса** или **метода**, либо самого **класса**, `decoratorFunction` **вызывается** с несколькими аргументами, **которые мы можем использовать для изменения класса или свойств класса**.

Давайте создадим простую функцию декоратора `readonly`. Но до этого давайте создадим класс `User` с методом `getFullName`, который возвращает полное имя пользователя, путём объединения `firstName` и `lastName`.

```js
class User {
    constructor(firstname, lastName) {
        this.firstname = firstname;
        this.lastName = lastName;
    }

    getFullName() {
        return `${this.firstname} ${this.lastName}`;
    }
}

// создаём экземпляр
const user = new User('John', 'Doe');
console.log(user.getFullName());
```

Код выше выведет `John Doe` на консоль. Но есть огромная проблема, поскольку кто-то может изменить метод `getFullName`.

```js
User.prototype.getFullName = function() {
    return 'ВЗЛОМАНО!';
}
```

При это мы получим следующий результат.

```
ВЗЛОМАНО!
```

Чтобы избежать общедоступного доступа для переопределения любого из наших методов, нам нужно изменить дескриптор свойства метода `getFullName`, который находится в объекте `User.prototype`.

```js
Object.defineProperty(User.prototype, 'getFullName', {
    writable: false
});
```

Теперь, если пользователь попытается переопределить метод `getFullName`, он получит ошибку.

![](https://cdn-images-1.medium.com/max/800/1*UVOaz8O1FoSa7KVpIBFMxA.png)

Но если у нас несколько методов в классе `User`, делать это вручную не очень удобно. В таком случае на помощь приходят декораторы. Мы можем добиться того же, добавив синтаксис `@readonly` перед методом `getFullName`, как показано ниже.

```js
function readonly(target, property, descriptor) {
    descriptor.writable = false;
    return descriptor;
}

class User {
    constructor(firstname, lastName) {
        this.firstname = firstname;
        this.lastName = lastName;
    }

    @readonly
    getFullName() {
        return `${this.firstname} ${this.lastName}`;
    }
}

User.prototype.getFullName = function() {
    return 'ВЗЛОМАНО!';
}
```

Посмотрите на метод `readonly`. Он принимает три аргумента. `property` — это имя свойства/метода в объекте `target` (*который идентичен `User.prototype`*), а `descriptor` — дескриптор переданного свойства. Внутри функции декоратора мы должны возвратить `descriptor`. Этот `descriptor` заменит существующий дескриптор свойства  для этого свойства.

Существует ещё одна версия синтаксиса декоратора, похожая на `@decoratorWrapperFunction(...customArgs)`. Но с этим синтаксисом `decoratorWrapperFunction` должен вернуть `decoratorFunction`, который аналогичен в используемом ранее примере.

```js
function log(logMessage) {
    // возвращаем функцию декоратора
    return function (target, property, descriptor) {
        // сохраняем исходное значение, которое является методом (функцией)
        const originalMethod = descriptor.value;

        // заменяем реализацию метода
        descriptor.value = function(...args) {
            console.log('[LOG]', logMessage);

            // вызов исходного метода
            // `this` указываем на экземпляр
            return originalMethod.call(this, ...args);
        };

        return descriptor;
    }
}

class User {
    constructor(firstname, lastName) {
        this.firstname = firstname;
        this.lastName = lastName;
    }

    @log('calling getFullName method on User class')
    getFullName() {
        return `${this.firstname} ${this.lastName}`;
    }
}

var user = new User('John', 'Doe');
console.log(user.getFullName());
```

![](https://cdn-images-1.medium.com/max/800/1*sUHsV_OSQUSehgfblsYvRg.png)

Декораторы не различают статические и нестатические методы. Код ниже будет работать прекрасно, изменится только то, как вы будете получать доступ к методу. То же самое относится к **декораторам полей экземпляра**, которые мы увидим ниже.

```js
@log('calling getFullName method on User class')
static getVersion() {
    return 'v1.0.0';
}

console.log(User.getVersion());
```

## ✱ Декоратор полей экземпляра класса

До сих пор мы видели изменение дескриптора свойства с помощью синтаксиса `@decorator` или `@decorator(..args)`, но как насчёт **общедоступных/закрытых свойств** (*полей экземпляра класса*)?

В отличие от `typescript` или `java` у JavaScript-классов нет полей экземпляра класса или свойств класса. Это связано с тем, что всё, что определено в `class` и вне `constructor`, должно принадлежать **прототипу**. Но есть новое [предложение](https://github.com/tc39/proposal-class-fields) для включения полей экземпляра класса с модификаторами доступа `public` и `private`, который сейчас находится на [третьем этапе](https://github.com/tc39/proposals), и для него есть [соответствующий Babel-плагин](https://babeljs.io/docs/plugins/transform-class-properties/).

Давайте определим простой класс `User`, но на этот раз нам не нужно устанавливать значения по умолчанию для `firstName` и `lastName`.

```js
class User {
    firstName = 'default_first_name';
    lastName = 'default_last_name';

    constructor(firstName, lastName) {
        if (firstName) {
            this.firstName = firstName;
        }
        if (lastName) {
            this.lastName = lastName;
        }
    }

    getFullName() {
        return `${this.firstname} ${this.lastName}`;
    }
}

const defaultUser = new User();
console.log('[defaultUser] ==> ', defaultUser);
console.log('[defaultUser.getFullName] ==> ', defaultUser.getFullName());

const user = new User( 'John', 'Doe' );
console.log('[user] ==> ', user);
console.log('[user.getFullName] ==> ', user.getFullName());
```

![](https://cdn-images-1.medium.com/max/800/1*44yA-f6PZURlQ-FOf4Vrww.png)

Теперь, если проверите `prototype` класса `User`, вы не увидите свойства `firstName` и `lastName`.

![](https://cdn-images-1.medium.com/max/1600/1*pUvV2kP_Evs0JWbhYK-KFg.png)


**Поля экземпляров класса** очень полезная и важная часть объектно-ориентированного программирования (ООП). Хорошо, что есть предложение для этого, но эта история ещё далека от завершения.

В отличие от **методов класса, которые находятся в прототипе класса**, **поля экземпляра класса существуют в объекте/экземпляра**. Поскольку поле экземпляра класса не является ни частью класса, ни его прототипом, очень сложно изменить его дескриптор. Babel даёт нам функцию `initializer` в дескрипторе свойства поля экземпляра класса вместо `value`. Почему используется функция `initializer` вместо ключа `value` — эта тема обсуждается, и поскольку декораторы находятся на **второй стадии**, окончательный черновик ещё не опубликован, чтобы объяснить причины этого, но вы можете последовать ответу на [Stack Overflow](https://stackoverflow.com/questions/31433630/does-the-es7-decorator-spec-require-descriptors-to-have-an-initializer-method), чтобы понять предысторию.

С учётом вышесказанного давайте изменим предыдущей пример и создадим простой декоратор `@upperCase`, который изменит регистр значение поля по умолчанию экземпляра класса.

```js
function upperCase( target, name, descriptor ) {
    const initValue = descriptor.initializer();

    descriptor.initializer = function() {
        return initValue.toUpperCase();
    }

    return descriptor;
}
class User {
    @upperCase
    firstName = 'default_first_name';

    lastName = 'default_last_name';

    constructor(firstName, lastName) {
        if (firstName) {
            this.firstName = firstName;
        }
        if (lastName) {
            this.lastName = lastName;
        }
    }

    getFullName() {
        return `${this.firstname} ${this.lastName}`;
    }
}
console.log(new User());

```

![](https://cdn-images-1.medium.com/max/800/1*5_SX5itRYtBIojyjY7-wHQ.png)

Мы также можем использовать **функцию декоратора с параметрами**, чтобы сделать его более настраиваемым.

```js
function toCase(CASE = 'lower') {
    return function (target, name, descriptor) {
        const initValue = descriptor.initializer();

        descriptor.initializer = function() {
            return
                (CASE === 'lower') ?
                initValue.toLowerCase() :
                initValue.toUpperCase();
        }

        return descriptor;
    }
}
class User {
    @toCase('upper')
    firstName = 'default_first_name';

    lastName = 'default_last_name';

    constructor(firstName, lastName) {
        if (firstName) {
            this.firstName = firstName;
        }
        if (lastName) {
            this.lastName = lastName;
        }
    }

    getFullName() {
        return `${this.firstname} ${this.lastName}`;
    }
}

console.log(new User());
```

Функция `descriptor.initializer` используется внутри **Babel** для создания ключа `value` дескриптора свойства в свойстве объекта. Эта функция возвращает начальное значение, присвоенное полю экземпляра класса. Внутри декоратора нам нужно вернуть ещё одну функцию `initializer`, которая вернет окончательное значение.

> Предложение поля экземпляра класса — крайне экспериментальная возможность, и существует большая вероятность, что её синтаксис может измениться до того, как она перейдет на **четвёртый этап**. Поэтому, пока не рекомендуется использовать поля экземпляра класса вместе с декораторами.

* * *

## Декоратор класса

Теперь мы уже знаем на что способны декораторы. Они могут изменять свойства и поведение методов класса и полей экземпляра класса, предоставляя гибкость для динамического достижения всего этого с помощью более простого синтаксиса.

**Декораторы класса** немного отличаются от декораторов, которые мы видели ранее. Раньше мы использовали **дескриптор свойства** для изменения поведения свойства или метода, но в случае с декоратором класса нам нужно вернуть функцию конструктора.

Давайте разберёмся сначала, что такое функция конструктора. JavaScript-класс на самом деле это не что иное, как функция, используемая для добавления **методов прототипа** и определения некоторых значений для полей.

```js
function User(firstName, lastName) {
    this.firstName = firstName;
    this.lastName = lastName;
}

User.prototype.getFullName = function() {
    return `${this.firstname} ${this.lastName}`
}

const user = new User('John', 'Doe');

console.log(user);
console.log(user.__proto__);
console.log(user.getFullName());
```

![](https://cdn-images-1.medium.com/max/800/1*8upRjd8kwXbOntVmrjvOqg.png)

> [Вот большая статья](https://blog.bitsrc.io/what-is-this-in-javascript-3b03480514a7) для понимания `this` в JavaScript.

Итак, когда мы вызываем `new User`, вызывается функция `User` с аргументами, которые мы передали, и взамен мы получаем объект. Получается, `User` — функция-конструктор. Кстати говоря, каждая функция в JavaScript является функцией-конструктором, поскольку, если вы посмотрите на `function.prototype`, вы получите свойство `constructor`. Пока мы используем ключевое слово `new` с функцией, мы должны ожидать возврата объекта.

> Если вы вернете корректный объект JavaScript из функции конструктора, то это значение будет использоваться вместо создания нового объекта, используя присваивания через `this`. Это сломает цепочку прототипов, потому что у возвращённого объекта не будет методов прототипа функции конструктора.

Имея это в виду, давайте сосредоточимся на том, что может сделать декоратор класса. Декоратор класса должен быть наверху класса, по аналогии, как раньше это было сделано с названием метода или поля. Этот декоратор по-прежнему функция, но которая возвращает функцию-конструктор или класс.

Предположим, у меня есть простой класс `User`, как показано ниже.

```js
class User {
    constructor(firstName, lastName) {
        this.firstName = firstName;
        this.lastName = lastName;
    }
}
```

Сейчас у нашего класса `User` нет никаких методов. Как говорилось ранее, декоратор класса должен вернуть функцию-конструктор.

```js
function withLoginStatus(UserRef) {
    return function(firstName, lastName) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.loggedIn = false;
    }
}

@withLoginStatus
class User {
    constructor(firstName, lastName) {
        this.firstName = firstName;
        this.lastName = lastName;
    }
}

let user = new User('John', 'Doe');
console.log(user);
```

![](https://cdn-images-1.medium.com/max/800/1*rM3KBl5wFGoMNkq3DDFrgg.png)

Функция декоратора класса получает целевой класс `UserRef`, который в приведённом выше примере является `User` (*к которому применяется декоратор*) и должна вернуть функцию-конструктор. Это открывает двери для бесконечных возможностей, которые можно сделать с декоратором. Следовательно, декораторы класса более популярны, чем декораторы методов/свойств.

Но приведённый выше пример слишком простой, и мы не хотим создавать новый конструктор, тогда как наш класс `User` может иметь массу свойств и прототипов. Хорошая новость заключается в том, что у нас есть ссылка на класс внутри функции декоратора, то есть `UserRef`. Мы можем вернуть новый класс из функции конструктора, который расширяет `User` класс (*точнее класс `UserRef`*). Поскольку класс тоже функция-конструктор, то это сработает.

```js
function withLoginStatus( UserRef ) {
    return class extends UserRef {
        constructor(...args ) {
            super(...args);
            this.isLoggedIn = false;
        }

        setLoggedIn() {
            this.isLoggedIn = true;
        }
    }
}

@withLoginStatus
class User {
    constructor(firstName, lastName) {
        this.firstName = firstName;
        this.lastName = lastName;
    }
}

let user = new User('John', 'Doe');
console.log('Before ===> ', user);

// установить, что пользователь вошёл
user.setLoggedIn();
console.log('After ===> ', user);
```

![](https://cdn-images-1.medium.com/max/800/1*uWCbna4Q89ZWCz5Xmv5Hdg.png)


* * *

Вы можете объединить несколько декораторов вместе, разместив их друг под другом. Порядок выполнения их будет таким же, как порядок добавления.

* * *

Декораторы — это красивый способ быстрее достичь цели. Подождите некоторое время, пока они не будут добавлены в спецификации ECMAScript.

- - - -

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*
