# ECMAScript Observable
*Перевод [предложения](https://github.com/tc39/proposal-observable/blob/master/README.md) [Марка Беннета](https://github.com/MarkBennett) на рассмотрение типа Observable в стандартную библиотеку ECMAScript. Актуален по состоянию на 31.03.2017.*

### [Предложение на Medium](https://medium.com/devschacht/ecmascript-observable-1f29d5c5e95c)

Предложение вводит тип **Observable** в стандартную библиотеку ECMAScript. Тип **Observable** может использоваться для обработки источников данных, основанных на внешнем воздействии (*push*), таких как события DOM, интервалы таймера и сокеты. Кроме того, observables являются:

- *Композициями*: Observables могут быть объединены с комбинаторами высшего порядка.
- *Ленивыми*: Observables не начинают возвращать данные до тех пор, пока `observer` не подпишется.

### Пример: наблюдение за событиями клавиатуры
Используя конструктор Observable, мы можем создать функцию, принимающую элемент DOM и тип события и возвращающую `observable` поток событий.

```javascript
function listen(element, eventName) {
    return new Observable(observer => {
        // Создаем обработчик событий, отправляющий данные подписчику
        let handler = event => observer.next(event);

        // Добавляем подписку на событие
        element.addEventListener(eventName, handler, true);

        // Возвращаем функцию очистки, которая будет отменять поток событий
        return () => {
            // Удаляем подписку с элемента
            element.removeEventListener(eventName, handler, true);
        };
    });
}
```

Затем мы можем использовать стандартные комбинаторы для фильтрации и направления событий в потоке, словно мы используем массив.

```javascript
// Возвращает observable определенных команд клавиш клавиатуры
function commandKeys(element) {
    let keyCommands = { "38": "up", "40": "down" };

    return listen(element, "keydown")
        .filter(event => event.keyCode in keyCommands)
        .map(event => keyCommands[event.keyCode])
}
```

*Примечание: Методы «filter» и «map» не включены в текущее предложение. Они могут быть добавлены в будущую версию этой спецификации.*

Когда мы хотим получать поток событий, мы подписываемся на `observer`.

```javascript
let subscription = commandKeys(inputElement).subscribe({
    next(val) { console.log("Received key command: " + val) },
    error(err) { console.log("Received an error: " + err) },
    complete() { console.log("Stream complete") },
});
```

Объект, возвращаемый `subscribe`, позволит нам в любой момент отменить подписку. После отмены, функция очистки Observable будет выполнена.

```javascript
// После вызова этой функции события больше отправляться не будут
subscription.unsubscribe();
```

### Мотивация
Тип Observable - один из основных протоколов для работы с асинхронными потоками данных. Он особенно эффективен при обработке потоков данных, порождаемых во внешней среде и попадающих в приложение (например, событий пользовательского интерфейса). Предлагая Observable в качестве компонента стандартной библиотеки ECMAScript, мы даем возможность платформам и приложениям совместно использовать основанный на внешнем воздействии общий потоковый протокол.

### Реализации
- [RxJS 5](https://github.com/ReactiveX/RxJS)
- [zen-observable](https://github.com/zenparsing/zen-observable)

### Выполнение тестов
Для запуска модульных тестов установите пакет **es-observable-tests** в ваш проект.

```bash
npm install es-observable-tests
```

Затем вызовите экспортированную функцию `runTests` с конструктором, который вы хотите протестировать.

```javascript
require("es-observable-tests").runTests(MyObservable);
```

### API
#### Observable
Observable - последовательность значений, которые можно наблюдать.

```javascript
interface Observable {

    constructor(subscriber : SubscriberFunction);

    // Подписываемся на последовательности с observer
    subscribe(observer : Observer) : Subscription;

    // Подписываемся на последовательности с функциями обратного вызова
    subscribe(onNext : Function,
              onError? : Function,
              onComplete? : Function) : Subscription;

    // Возвращаем себя
    [Symbol.observable]() : Observable;

    // Конвертируем в Observable
    static of(...items) : Observable;

    // Конвертируем observable или итерируемый в Observable
    static from(observable) : Observable;

}

interface Subscription {
    // Отменяем подписку
    unsubscribe() : void;
    // Булевое значение, указывающее на закрытие подписки
    get closed() : Boolean;
}

function SubscriberFunction(observer: SubscriptionObserver) : (void => void)|Subscription;
```

#### Observable.of
`Observable.of` создает Observable из значений, переданных в качестве аргументов. Значения доставляются синхронно при вызове `subscribe`.

```javascript
Observable.of("red", "green", "blue").subscribe({
    next(color) {
        console.log(color);
    }
});

/*
 > "red"
 > "green"
 > "blue"
*/
```

#### Observable.from
`Observable.from` преобразует свой аргумент в Observable.

- Если аргумент имеет метод `Symbol.observable`, он возвращает результат вызова этого метода. Если результирующий объект не является экземпляром Observable, то он обертывается в Observable, который будет делегировать подписку.
- В противном случае предполагается, что аргумент является итерируемым, а значения итерации доставляются синхронно при вызове `subscribe`.

Преобразование из объекта, поддерживающего `Symbol.observable`, в Observable:

```javascript
Observable.from({
    [Symbol.observable]() {
        return new Observable(observer => {
            setTimeout(() => {
                observer.next("hello");
                observer.next("world");
                observer.complete();
            }, 2000);
        });
    }
}).subscribe({
    next(value) {
        console.log(value);
    }
});

/*
 > "hello"
 > "world"
*/

let observable = new Observable(observer => {});
Observable.from(observable) === observable; // true

```

Конвертация из итерируемого в Observable:

```javascript
Observable.from(["mercury", "venus", "earth"]).subscribe({
    next(value) {
        console.log(value);
    }
});

/*
 > "mercury"
 > "venus"
 > "earth"
*/
```

#### Observer
Observer используется для получения данных от Observable и передаётся как аргумент в `subscribe`. Все методы являются необязательными.

```javascript
interface Observer {

    // Получает объект подписки при вызове `subscribe`
    start(subscription : Subscription);

    // Получает следующее значение в последовательности
    next(value);

    // Получает ошибку последовательности
    error(errorValue);

    // Получает уведомление о завершён.и
    complete();
}
```

#### SubscriptionObserver
SubscriptionObserver - нормализованный Observer, который обертывает объект `observer`, переданный в `subscribe`.

```javascript
interface SubscriptionObserver {

    // Посылает следующее значение в последовательности
    next(value);

    // Посылает ошибку последовательности
    error(errorValue);

     // Посылает уведомление о завершён.и
    complete();

    // Булевое значение, указывающее на закрытие подписки
    get closed() : Boolean;
}
```

- - - -

*Читайте нас на [Медиуме](https://medium.com/devschacht), контрибьютьте на [Гитхабе](https://github.com/devSchacht), общайтесь в [группе Телеграма](https://t.me/devSchacht), следите в [Твиттере](https://twitter.com/DevSchacht) и [канале Телеграма](https://t.me/devSchachtChannel), скоро подъедет подкаст. Не теряйтесь.*
