# Иногда undefined это defined

*Перевод статьи  [Benedikt Meurer](http://benediktmeurer.de): [Sometimes undefined is defined](https://medium.com/@bmeurer/sometimes-undefined-is-defined-7701e1c9eff8). Опубликовано с разрешения автора*

В JavaScript всегда была путаница с `undefined`. Я попытаюсь пролить немного света на эту проблему и объяснить, почему может быть лучше (т.е. безопаснее и/или быстрее) писать `void 0` в некоторых случаях.

[EcmaScript](https://tc39.github.io/ecma262) содержит специальный тип [**Undefined**](https://tc39.github.io/ecma262/#sec-ecmascript-language-types-undefined-type), имеющий ровно одно значение, называемое **undefined**.

![](https://cdn-images-1.medium.com/max/1440/1*YypO_ktnhkZt-PnQ49cU5g.png)

Это актуальная семантика выполнения **undefined**. На уровне синтаксиса `undefined` - это просто произвольный идентификатор – в отличие от `null`, `true` и `false`, являющихся ключевыми словами в JavaScript. Это означает, что, когда вы пишете `undefined` в программе JavaScript, вы на самом деле ссылаетесь на ранее связанное имя. По умолчанию это приведёт к поиску имени `undefined` в глобальном объекте, что и ожидается большинством людей.

![](https://cdn-images-1.medium.com/max/1440/1*BA91YUgpvZ9aOI4Xh3Wk8A.png)

Однако, поскольку это просто обычное имя переменной, оно может использоваться как таковое произвольными способами. Например, с точки зрения языка JavaScript, это вполне разумный код:

```javascript
const isDefined = (function() {
  const undefined = 1;
  return x => x !== undefined;
})();

console.log(isDefined(undefined));  // true
console.log(isDefined(1));          // false
```

Благодаря весёлым языковым конструкциям, таким как `eval` или `with`, это может быть даже несколько скрыто. Например, с помощью `eval`:

```javascript
const isDefined = (function(s) {
  eval(s);
  return x => x !== undefined;
})('var undefined = 1;');

console.log(isDefined(undefined));  // true
console.log(isDefined(1));          // false
```

Или используя `with`:

```javascript
const isDefined = (function(o) {
  with(o) return x => x !== undefined;
})({undefined: 1});

console.log(isDefined(undefined));  // true
console.log(isDefined(1));          // false
```

То же самое, кстати, относится и к `NaN`, которое также является просто незаписываемым, неконфигурируемым свойством глобального объекта. Это довольно запутанно, и является прекрасной причиной не использовать `eval` или `with` в вашем коде.

---

Вы можете избежать этих проблем, используя оператор `void` вместо `undefined`, когда хотите быть уверенны, что получили настоящее значение `undefined` (и поверьте мне, вы всегда этого хотите, если пишите `undefined`).

![](https://cdn-images-1.medium.com/max/1440/1*FiFSYpmswu-zbs4FcdAXzQ.png)
[tc39.github.io/ecma262/#sec-void-operator](https://tc39.github.io/ecma262/#sec-void-operator)

Оператор `void` всегда возвращает значение `undefined`. Так как выражение, переданное ему, вычисляется, но результат не используется, то для нашего трюка подойдёт любое. Я предлагаю придерживаться `void 0`, так как это читается коротко и легко.

```javascript
const isDefined = (function() {
  const undefined = 1;
  return x => x !== void 0;
})();

console.log(isDefined(undefined));  // false
console.log(isDefined(1));          // true
```

Теперь программа делает то, что мы хотим.

---

Очевидно, что здесь есть и аспект производительности. V8 на самом деле ведёт себя довольно умно и избегает поиска значения глобального свойства для `undefined` во многих случаях. На самом деле, V8 всегда будет сбрасывать `undefined` до фактического **undefined** значения (и отдавать его как константу), если у вас нет никакого `eval` или `with` в цепочке областей видимости.

![](https://cdn-images-1.medium.com/max/1440/1*VcwOlirpsR7mrc33t6wiiA.png)

Однако другие механизмы JavaScript могут не иметь такой оптимизации. Например, JavaScriptCore (движок внутри Safari) не применяет эту оптимизацию для выше приведённой функции `getUndefined` — по крайней мере, не на уровне байт-кода:

![](https://cdn-images-1.medium.com/max/1440/1*dgXA6fypc2JAgpR0mDGuAw.png)

---

Резюмируя: помните, что когда вы обращаетесь к `undefined` в вашем JavaScript, в зависимости от окружающего кода не всегда там может содержаться значение **undefined**. Возможно, будет безопаснее (и быстрее с точки зрения производительности) использовать вместо этого `void 0`.

---

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Статья на Medium](https://medium.com/devschacht/benedikt-meurer-sometimes-undefined-is-defined-91f32af4532c)
