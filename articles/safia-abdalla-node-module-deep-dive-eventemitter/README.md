# Глубокое погружение в модуль Node.js: EventEmmiter
![](https://coresites-cdn.factorymedia.com/mpora_new/wp-content/uploads/2016/12/Scuba-Diving-Courses-Beginners-PADI-BSAC-SSI-UK.jpg)

*Перевод статьи [Сафии Абдалла (Safia Abdalla)](https://twitter.com/captainsafia): [Node module deep-dive: EventEmitter](https://blog.safia.rocks/post/169618575955/node-module-deep-dive-eventemitter).* Опубликовано с разрешения автора.

В своём [предыдущем посте](https://blog.safia.rocks/post/169543119660/how-does-processbinding-in-node-work) я хорошенько намучалась с C++ кодом и решила, что вернусь в зону комфорта с ещё одним разбором кода на JavaScript.  

Когда я только начала изучать Node.js, одной из вещей, вызвавших у меня трудности, стала событийно-ориентированная природа языка. Я не очень много работала с языками программирования такого типа. Хотя, оглядываясь назад, понимаю, что всё-таки работала. Например, до изучения Node.js я использовала `.on` и `.click` в коде на jQuery, а эти функции как раз представляют собой событийно-ориентированный стиль программирования. В любом случае, одна из вещей, в которую было бы любопытно погрузиться — это генерация событий в Node.js. Давайте начнём.

Если вы не знакомы с событийно-ориентированной природой Node.js, то вот несколько записей в блогах, которые объяснят её лучше меня.  

- [Understanding Node.js Event-Driven Architecture](https://medium.freecodecamp.org/understanding-node-js-event-driven-architecture-223292fcbc2d)
- [event driven architecture node.js](https://garywoodfine.com/event-driven-architecture-node-js/)
- [Understanding the Node.js Event Loop](http://nodesource.com/blog/understanding-the-nodejs-event-loop/)
- [Events documentation in Node.js](https://nodejs.org/api/events.html)

Итак, я хочу прочитать код EventEmitter и посмотреть, получится ли у меня понять, что происходит под капотом класса `EventEmitter`. Вы можете найти код, на который я буду ссылаться, [здесь](https://github.com/nodejs/node/blob/61b4d60c5d9694e79069b1680b3736c96a5de501/lib/events.js).

Две наиболее важные функции в любом объекте `EventEmitter` — это `.on` и `.emit`. Функция `.on`  отвечает за прослушивание события конкретного типа, а `.emit` — за диспетчеризацию событий конкретного типа. Я решила начать своё исследование с изучения кода этих функций, прежде всего с `.emit`, так как имеет смысл сперва посмотреть, как происходят события, а уже потом — как прослушиваются. 

Итак, объявление функции для `emit` довольно очевидно, если вы работали с объектами EventEmitter. Она принимает тип в качестве аргумента, который обычно является строкой, и набор аргументов, который будет передан обработчику.

```
EventEmitter.prototype.emit = function emit(type, ...args) {
```

В первую очередь я заметила в этом коде то, что события типа "error" и события других типов обрабатываются по-разному. Если честно, потребовалось некоторое время, чтобы понять, что происходит в коде ниже, особенно во фрагменте `if-else if`. В основном, эта часть кода проверяет, является ли генерируемое событие ошибкой. Если это так, то выясняется, есть ли слушатель событий `error` в наборе слушателей, прикреплённых к `EventEmitter`. Если слушатель прикреплён, то функция возвращает `false`.

```
let doError = (type === 'error');

const events = this._events;
if (events !== undefined)
  doError = (doError && events.error === undefined);
else if (!doError)
  return false;
```

Если слушателя события нет (как говорится в комментарии), то эмиттер выдаст пользователю ошибку.

```
// Если нет слушателя для события 'error'
if (doError) {
  let er;
  if (args.length > 0)
    er = args[0];
  if (er instanceof Error) {
    throw er; // Необработанное событие 'error'
  }
  // Дать пользователю хоть какой-то контекст
  const errors = lazyErrors();
  const err = new errors.Error('ERR_UNHANDLED_ERROR', er);
  err.context = er;
  throw err;
}
```
С другой стороны, если тип, который передали, не является ошибкой, то функция `emit` будет просматривать слушателей событий, прикреплённых к объекту `EventEmmiter`, чтобы узнать, какие из них объявлены для это типа, а затем вызовет их.

```
const handler = events[type];

if (handler === undefined)
  return false;

if (typeof handler === 'function') {
  Reflect.apply(handler, this, args);
} else {
  const len = handler.length;
  const listeners = arrayClone(handler, len);
  for (var i = 0; i < len; ++i)
    Reflect.apply(listeners[i], this, args);
}

return true;
```
Теперь о функции `on`.

Функция `on` в `EventEmitter` неявно вызывает внутреннюю функцию `_addListener`, которая объявляется следующим образом:

```
function _addListener(target, type, listener, prepend)
```

Большинство этих параметров не требует пояснений, единственным любопытным для меня оказался `prepend`. Как выяснилось, по умолчанию он имеет значение `false` и не может переопределяться с помощью любых общедоступных API.

Примечание: Просто шучу! Я наткнулась на некоторые сообщения к коммитам на GitHub, которые прояснили это. По-видимому, в объекте `_addListener` установлено значение `false` потому, что многие разработчики ненадлежащим образом обращаются к внутреннему атрибуту `_events` объекта EventEmitter, чтобы добавить слушателей в начало списка. Если вы хотите это сделать, используйте `prependListener`.

Функция `_addListener` начинается с базовой проверки параметров. Мы не хотим, чтобы кто-то стрелял в ногу! После установки параметров функция попытается добавить `listener` для `type` к свойству `events` текущего объекта `EventEmitter`. Ниже один из фрагментов кода, которые я считаю интересными:

```
if (events === undefined) {
  events = target._events = Object.create(null);
  target._eventsCount = 0;
} else {
  // Чтобы избежать рекурсии в случае, если type === "newListener"!
  // Перед добавлением его к слушателям, сначала сгенерируем "newListener"
  if (events.newListener !== undefined) {
    target.emit('newListener', type,
                listener.listener ? listener.listener : listener);

    // Переназначаем `events`, потому что обработчик newListener 
    // мог привести к тому, что this._events будет назначен новому объекту
    events = target._events;
  }
  existing = events[type];
}
```

Здесь мне особенно любопытен блок `else`. Если свойство `events` уже было проинициализировано в текущем объекте `EventEmitter` (это значит, что мы уже добавили слушатель ранее), то выполняется какая-то странная проверка. Я решила провести раскопки на GitHub, чтобы выяснить, когда это изменение было добавлено, получить дополнительный контекст возникновения ошибки и таким образом узнать причины добавления этого кода.  Это была плохая идея, потому что данная часть логики была в коде примерно четыре года, и у меня возникли проблемы с отслеживанием. Я попыталась прочитать код более внимательно, чтобы узнать, для каких крайних случаев проводится проверка. 

В конце концов я поняла это не из кода. Дети, не забывайте есть овощи и читать всю документацию! В документации Node.js говорится:

> Все EventEmitters генерируют событие `'newListener'`, когда новые слушатели добавляются, и `'removeListener'`, когда существующие слушатели удаляются.

Таким образом, событие `newListener` обычно генерируется, когда новый слушатель добавляется до того, как фактический слушатель добавляется к атрибуту `_events` в `EventEmitter`. Это происходит потому, что если вы добавляете слушателя `newListener`, и он попадает в список событий перед тем, как `newListener` будет сгенерирован по умолчанию, то он будет вызывать сам себя. Вот почему этот код генерации `newListener` находится в верхней части функции.

Следующий фрагмент кода пытается выяснить, подключён ли слушатель такого же типа. Это нужно для того, чтобы убедиться, что если есть только один слушатель события, то он устанавливается как значение функции в ассоциативном массиве `_events`. Если слушателей больше одного, то они образуют массив. Это незначительная оптимизация, но большое количество маленьких оптимизаций и делает Node.js отличным языком.

```
if (existing === undefined) {
  // Оптимизация случая с одним слушателем. Дополнительный объект массива не нужен
  existing = events[type] = listener;
  ++target._eventsCount;
} else {
  if (typeof existing === 'function') {
    // При добавлении второго слушателя необходимо заменить на массив
    existing = events[type] =
      prepend ? [listener, existing] : [existing, listener];
    // Если у нас уже есть массив, то просто добавляем
  } else if (prepend) {
    existing.unshift(listener);
  } else {
    existing.push(listener);
  }
```

Последняя проверка в этой функции пытается подтвердить, было ли прикреплено слишком много слушателей к конкретному генератору события для конкретного типа события. Если это так, то в коде может быть ошибка. В общем, я не думаю, что это хорошая практика, когда много слушателей привязаны к одному событию, поэтому Node.js проводит несколько полезных проверок, чтобы предупредить вас об этом.

```
  // Проверка утечки слушателя
  if (!existing.warned) {
    m = $getMaxListeners(target);
    if (m && m > 0 && existing.length > m) {
      existing.warned = true;
      // Нет кода ошибки, так как это предупреждение
      const w = new Error('Possible EventEmitter memory leak detected. ' +
                          `${existing.length} ${String(type)} listeners ` +
                          'added. Use emitter.setMaxListeners() to ' +
                          'increase limit');
      w.name = 'MaxListenersExceededWarning';
      w.emitter = target;
      w.type = type;
      w.count = existing.length;
      process.emitWarning(w);
    }
  }
}
```

Вот и всё! В результате функция `.on` возвращает объект `EventEmitter`, к которому она привязана.

Мне понравилось читать код для EventEmitter, он показался мне понятным и доступным (в отличие от приключений с C++ из прошлого поста), хотя я подозреваю, что это связано с моим уровнем знания языка.
- - - -

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*
