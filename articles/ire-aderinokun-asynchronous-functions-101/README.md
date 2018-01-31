# Асинхронные функции 101

*Перевод статьи [Ire Aderinokun](https://ireaderinokun.com): [Asynchronous Functions 101](https://bitsofco.de/asynchronous-functions-101/). Опубликовано с разрешения автора.*

![](octopus.jpg)

Одно из основных преимуществ JavaScript в том, что все асинхронно. В большинстве случаев, различные части вашего кода не влияют на выполнение других.

```js
doALongThing(() => console.log("Я буду выведен вторым!"));
console.log("Я буду выведен первым!");
```

К сожалению, это также один из основных недостатков JavaScript. Поскольку по умолчанию все асинхронно, сделать так, чтобы код исполнялся синхронно, намного сложнее.

Функции обратного вызова были первым решением этой проблемы. Если часть вашего кода зависела от результата выполнения другой, мы вкладывали её в качестве функции обратного вызова:

```js
doSomething((response) => {
   doSomethingElse(response,(secondResponse) => {
        doAThirdThing(secondResponse);
   });
})
```

Вложенные функции обратных вызовов функций обратных вызовов, как известно, становились неподдерживаемыми. Так появились промисы. Это позволило нам иметь дело с синхронным кодом в гораздо более чистом и плоском виде.

```js
doSomething()
.then((response) => doSomethingElse(response))
.then((secondResponse) => doAThirdThing(secondResponse));

// Даже чище
doSomething().then(doSomethingElse).then(doAThirdThing);
```

Как и все, промисы тоже не были идеальны. Таким образом, в рамках спецификации ES2017 был определен другой метод для работы с синхронным кодом - асинхронные функции. Они позволяют нам писать асинхронный код так, словно он синхронный.

## Создание асинхронной функции
Асинхронная функция определяется функциональным выражением c ключевым словом `async`. Базовая функция выглядит так:

```js
async function foo() {
    const value = await somePromise();
    return value;
}
```

Мы определяем функцию как асинхронную, помещая перед декларацией функции `async`. Это ключевое слово может использоваться с любым синтаксисом объявления функции:

```js
// Базовая функция
async function foo() {  … }

// Стрелочная функция
const foo = async () => { … }

// Метод класса
class Bar {
    async foo() { … }
}
```

Как только мы определили функцию как асинхронную, мы можем использовать ключевое слово `await`. Это ключевое слово помещается перед вызовом промиса, что приостанавливает выполнение функции до тех пор, пока промис не будет выполнен (*fulfilled*) или отклонен (*rejected*).

## Обработка ошибок
Обработка ошибок в асинхронных функциях выполняется с помощью блоков `try` и `catch`. Первый блок, `try`, позволяет нам попытаться произвести действие. Второй блок, `catch`, вызывается, если действие произвести не удалось. Он принимает один параметр, содержащий выброшенную ошибку.

```js
async function foo() {
    try {
        const value = await somePromise();
        return value;
    }
    catch (err) {
        console.log("Упс, произошла ошибка :(");
    }
}
```

## Использование асинхронных функций
Асинхронные функции не являются заменой промисов. Они работают сообща. Асинхронная функция ожидает (`await`) исполнения промиса и всегда возвращает промис.

Промис, возвращаемый асинхронной функцией, будет разрешен (*resolve*) с тем значением, которое вернет функция.

```js
async function foo() {
    await somePromise();
    return ‘success!’
}

foo().then((res) => console.log(res)) // ‘success!’
```

Если будет выдана ошибка, промис будет отклонен (*rejected*) с этой ошибкой.

```js
async function foo() {
    await somePromise();
    throw Error(‘oops!’)
}

foo()
.then((res) => console.log(res))
.catch((err) => console.log(err)) // ‘oops!’
```

## Параллельное выполнение асинхронных функций
С промисами мы можем выполнять несколько промисов параллельно с помощью метода `Promise.all()`.

```js
function pause500ms() {
    return new Promise((res) => setTimeout(res, 500));
}

const promise1 = pause500ms();
const promise2 = pause500ms();

Promise.all([promise1, promise2]).then(() => {
   console.log("Я буду выведен через 500 миллисекунд");
});
```

С асинхронными функциями нам нужно немного поработать, чтобы получить тот же эффект. Если мы просто перечислим функции, ожидающие в последовательности, они будут выполняться последовательно, так как `await` приостанавливает выполнение остальной части функции.

```js
async function inSequence() {
    await pause500ms();
    await pause500ms();
    console.log("Я буду выведен через 1000 миллисекунд");
}
```

Это займет 1000 миллисекунд, так как второе ожидание не запустится, пока не завершится первое. Чтобы это обойти, мы должны обращаться к функция следующим образом:

```js
async function inParallel() {
    const await1 = pause500ms();
    const await2 = pause500ms();
    await await1;
    await await2;
    console.log("Я буду выведен через 500 миллисекунд");
}
```

Это займет всего 500 миллисекунд, потому что обе функции `pause500ms()` выполняются одновременно.

## Промисы или асинхронные функции
Как я уже упоминала, асинхронные функции не заменяют промисы, они используются вместе. Асинхронные функции предоставляют собой альтернативный, а в некоторых случаях и лучший, способ работы с основанными на промисах функциями. Но они все ещё используют и производят промисы.

Поскольку возвращается промис, асинхронная функция может быть вызвана другой асинхронной функцией или промисом. Мы можем смешивать и сочетать их в зависимости от того, какой синтаксис лучше всего подходит для каждого конкретного случая.

``` js
function baz() {
    return new Promise((res) => setTimeout(res, 1000));
}

async function foo() {
    await baz();
    return 'foo complete!';
}

async function bar() {
    const value = await foo();
    console.log(value);
    return 'bar complete!';
}

bar().then((value) => console.log(value));
```

Происходит следующее:
1. Ожидание 1000 миллисекунд
2. Вывод "foo complete!"
3. Вывод "bar complete!"

## Поддержка
На момент написания статьи асинхронные функции и промисы доступны в текущих версиях всех основных браузеров, за исключением Internet Explorer и Opera Mini.

[Промисы](http://caniuse.com/#feat=promises)
[Асинхронные функции](http://caniuse.com/#feat=async-functions)

*Перевод статьи [Ire Aderinokun](https://ireaderinokun.com): [Asynchronous Functions 101](https://bitsofco.de/asynchronous-functions-101/)*

- - - -

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Статья на Medium](https://medium.com/devschacht/ire-aderinokun-asynchronous-functions-101-7bc145afe930)
