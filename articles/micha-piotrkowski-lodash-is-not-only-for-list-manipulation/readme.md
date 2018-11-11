# Lodash не (только) для манипуляции списками!

*Перевод статьи  Michał Piotrkowski: [Lodash is not (only) for list manipulation!](https://blog.pragmatists.com/lodash-is-not-only-for-list-manipulation-791c2e3b9de1).*

![](https://cdn-images-1.medium.com/max/800/1*QJrflfHhpKS8RlR_79_idQ.jpeg)

Это продолжение моего предыдущего поста про [Функции высшего порядка в Lodash](https://medium.com/devschacht/michal-piotrkowski-higher-order-functions-in-lodash-56cb196c584d). Большинство людей знает Lodash по конструкциям вроде такой:

```javascript
var cities = require('./cities.json');

_(cities)
  .filter(c => c.population >= 5000000)
  .countBy('country')
  .toPairs()
  .map(c => _.zipObject(['country', 'numOfCities'], c))
  .orderBy('numOfCities', 'desc')
  .take(5)
  .value();
```

Но Lodash - это гораздо больше чем библиотека манипулирования списками. В этом посте я хочу пролить свет на несколько менее популярные, но, по моему мнению, крайне полезные функции Lodash.

> **_Дизклеймер_** (*disclaimer* - отказ от ответственности): Эта статья предполагает, что читатель хорошо знаком с концепцией **функций высшего порядка** и знает, как работают такие функции, как [_.curry](https://lodash.com/docs/#curry) и [_.partial](https://lodash.com/docs/#partial). Более того, в этой статье, когда я ссылаюсь на «Lodash», я имею ввиду вариант `lodash/fp` библиотеки Lodash. Если вы никогда не слышали про `lodash/fp`, функции высшего порядка или просто хотите немного освежить свою память, пожалуйста, взгляните на мою предыдущую статью по [Функциям высшего порядка в Lodash](https://medium.com/devschacht/michal-piotrkowski-higher-order-functions-in-lodash-56cb196c584d).

Одна из вещей, которую я люблю в Lodash, это то, что она крайне гибкая и адаптируемая. Даже если она не имеет конкретной нужной вам функции, скорее всего вы можете построить её за несколько строк кода. Авторы Lodash предоставили возможности расширения по всей кодовой базе, что позволяет разработчикам кастомизировать (настраивать) её поведение. Одна из таких точек расширения - это **Кастомизаторы**.


### Кастомизаторы

Объектно-ориентированные программисты узнают **Кастомизаторы** как паттерн [Стратегия](https://ru.wikipedia.org/wiki/Стратегия_(шаблон_проектирования)) из знаменитой книги *«Банды четырех»*: [Приёмы объектно-ориентированного проектирования. Паттерны проектирования](https://ru.wikipedia.org/wiki/Design_Patterns).

Кастомизаторы позволят вам значительно изменять поведение объекта, заменяя одну стратегию другой.

Давайте взглянем, как кастомизаторы работают на практике. Предположим, у нас есть разбитая по частям контактная информация, которую мы хотим объединить в один объект. Как вы можете ожидать, Lodash уже предлагает функцию, которая делает эту работу за нас. Функция [_.merge()](https://lodash.com/docs/#merge) объединяет два объекта, свойство за свойством:

```javascript
let contact1 = {
  name: 'Sherlock Holmes',
  phone: ['555-123-456']
};
let contact2 = {
  address: '221B Baker Street',
  phone: ['555-654-321']
};
_.merge(concact1, concact2);
// →
// {
//   name: 'Sherlock Holmes',
//   address: '221B Baker Street',
//   phone: ['555-654-321']
// }
```

Однако, если одинаковые свойства представлены в обоих объединяемых объектах, свойство из последнего объекта побеждает. В нашем примере это нежелательно, поскольку мы теряем информацию про один из телефонных номеров контакта.

К счастью, существует альтернативная версия функции `_.merge()`, принимающая дополнительную функцию, позволяющую кастомизировать способ, которым свойства будут объединены. Эта кастомизирующая функция будет вызываться для каждого свойства (в том числе и для вложенных свойств), которые должны быть объединены (свойства из второго объединяемого объекта). Значения объединяемого свойства будут переданы в качестве первых двух параметров. Давайте попробуем:
 
 ```javascript
 function customizer(src, dst){
  if(_.isArray(src)){
    return _.concat(src, dst);
  }
}
_.mergeWith(customizer, concact1, contact2);
// →
// {
//   name: 'Sherlock Holmes',
//   address: '221B Baker Street, London NW1 6XE',
//   phone: ['555-123-456', '555-654-321']
// }
```

> **_Бонус_**: Другой вариант определения `customizer`: `let customizer = _.cond([[_.isArray, _.concat]])`.

Если одно из объединяемых свойств указывает на массив, тогда наш `customizer` возвращает новый массив, который содержит значения из обоих объединяемых объектов. Заметьте, что если объединяемое значение не массив, то `customizer` не будет возвращать никакого значения (или, другими словами, будет возвращать `undefined`). В такой ситуации Lodash будет использовать стандартную стратегию (используемую в функции `_.merge()`).

Но почему мы должны ограничивать себя только конкатенацией массивов? Вот как мы можем сделать наш `customizer` более общим:

```javascript
function customizer(val, fn){
  if(_.isFunction(fn)){
    return fn.apply(this, [val]);
  }
}
```

В новой версии `customizer`, если второй из объединяемых объектов содержит функцию, то, вместо присвоения этой функции в результирующий объект, мы просто применяем её, передавая в качестве параметров значения соответствующего свойства из первого объекта.

Теперь мы можем передать наш `customizer` в качестве первого параметра функции `_.mergeWith()`. Давайте назовем получившуюся функцию `patch`:

```javascript
var patch = recipe => _.mergeWith(customizer, _, recipe);
```

Запомните, что все `lodash/fp` функции авто-каррируемы, так что мы можем передавать им подмножество параметров, а также заменители параметров `_`, и в результате мы будем получать результирующую функцию с некоторыми фиксированными параметрами.

Получившаяся функция `patch()` - это *функция высшего порядка*, возвращающая новую функцию, трансформирующую объект в зависимости от предоставляемого параметра *recipe*. Параметр recipe формулируется довольно декларативным способом, но явно указывает, какую функцию использовать для объединения данного свойства. Если свойство указывает не на функцию, применяется стандартная стратегия объединения.

> **_Заметка для продвинутых_**: Порядок параметров в `_.mergeWith(customizer, object, source)` немного неудачный, поскольку он принимает параметр с данными (`object`) вторым и при этом не последним параметром. Иначе мы могли бы в полной мере воспользоваться каррированием и определить функцию `patch` просто как:

```javascript
var patch = recipe => _.mergeWith(customizer, _, recipe);
```

> Однако нужный порядок параметров заставляет нас пропустить второй параметр, используя `_`. 

> Кроме того, мы могли бы переставить порядок параметров, используя функцию [_.rearg()](https://lodash.com/docs/#rearg) таким образом:

```javascript
var mergeRearg = _.rearg(_.mergeWith, [0, 2, 1]);
var patch = mergeRearg(customizer);
```

> Или просто (используя [_.flip()](https://lodash.com/docs/#flip)):

```javascript
var patch = _.flip(_.mergeWith(customizer));
```

> `_.flip` и `_.rearg()` являются ещё одним доказательством гибкости Lodash.

---

Хорошо, после того как мы определили нашу функцию `patch()`, давайте посмотрим, на что она способна. Мы начнём переделывать пример с контактной информацией:

```javascript
let contact = {  
  name: 'Sherlock Holmes',
  address: '221B Baker Street, London NW1 6XE',
  phone: ['555-123-456']
};
let addPhone = patch({  
  phone: _.concat('555-654-321')
});
addPhone(contact);
// →
// {
//   ...
//   phone: ['555-123-456', '555-654-321']
// }
```

Теперь давайте вообразим, что мы хотим иметь возможность переключать флаг `favorite` для нашего контакта:

```javascript
let toggleFavorite = patch({
  favorite: fav => !fav     // alternatively: _.negate(_.identity)
});
let contact2 = toggleFavorite(contact);
// →
// {
//   ...
//   favorite: true
// }
toggleFavorite(contact2);
// →
// {
//   ...
//   favorite: false
// }
```

В Lodash функция `_.mergeWith()` рекурсивна. Благодаря этому наша функция `patch()` поддерживает вложенные свойства из коробки:

```javascript

let deepPatch = patch({ 
  flags: { 
    favorite: fav => !fav
  }
});
deepPatch({});
// →
// {
//   flags: {
//     favorite: true  
//   }
// }
```

Заметили, как мы избежали стандартных проверок на `null`?

Последним упражнением давайте напишем функцию `parseAddress`, которая попробует распарсить строку адреса и извлечь zip-код, улицу и город. Для построения цепочки операций (выполнения регулярного выражения, извлечения удовлетворяющих регулярному выражению групп в массив, построения объекта из массива) мы будем использовать функцию [_.flow()](https://lodash.com/docs/#flow):

```javascript
let addrRegexp = /^([^,]+),\s*(.+)\s+(\w{2,4}\s\w{3})$/;
let parseAddress = patch({
  address: _.flow(
    addr => addrRegexp.exec(addr),
    _.tail,
    _.zipObject(['street', 'city', 'postalCode'])
  )
});
parseAddress(contact);
// →
// {
//   ...
//   address: {
//     street: '221B Baker Street',
//     city: 'London',
//     postalCode: 'NW1 6XE'
//   }
// }
```

Теперь мы можем объединить все эти преобразования:

```javascript
let transform = _.flow([
    addPhone, 
    toggleFavorite, 
    parseAddress
  ]);
transform(contact);
```

Мы также можем сделать это таким способом:

```javascript
let append = val => _.concat(val); 
let toggle = val => !val;
let parse = (regex, props) => _.flow(
   val => regex.exec(val),
   _.tail,
   _.zipObject(props)
 );
let transform = patch({
  phone: append('555-654-321'),
  favorite: toggle,
  address: parse(addrRegexp, ['street', 'city', 'postalCode'])
});
transform(contact);
```

#### Сначала операции, в конце данные

Заметьте, как во всех наших примерах мы сначала определяем преобразования, затем комбинируем их, а в конце передаём нужные данные в получившееся преобразование. Само преобразование не зависит от данных, только от структуры принимаемых данных. Этот подход сильно отличается от более классического, объектно-ориентированного стиля, где операторы привязываются к некоторому *контексту* (например `this` или переменным из родительской области видимости). В следующем примере функция `findActiveItems()` зависит от массива `items`:

```javascript
let items = [
  { active: true, /* ... */ }
  // ...
];  
    
function findActiveItems(){ 
  return _.filter(items, item => item.active);
}
```

Эта зависимость от контекста делает функции менее переиспользуемыми, поскольку они не могут быть отделены от их контекста. В отличие от объектно-ориентированного стиля, в функциональном программировании мы пытаемся отделить операции от данных настолько, насколько это возможно. Один из способов достижения этого - откладывать передачу данных на как можно более поздний момент. Это характерно для функциональных библиотек (таких как [lodash/fp](https://github.com/lodash/lodash/wiki/FP-Guide) или [Ramda](http://ramdajs.com)) - принимать данные последним параметром.

### Реализация списка To-Do.

Давайте возвратимся к нашей функции `patch()` и увидим, насколько далеко мы сможем продвинуть нашу простую реализацию. Насколько сложную логику мы сможем создать с использованием этой элементарной функции `patch()`, перед тем как мы возвратимся к более классическому (императивному) стилю программирования? В качестве теста давайте попробуем реализовать все возможности известного проекта [TodoMVC](http://todomvc.com). Конечно, мы сфокусируемся на деталях реализации модели/предметной области (domain/model), и пропустим все части, связанные с интерфейсом пользователя.

Давайте перечислим все функции списка To-Do, поддерживаемые TodoMVC:

1. создание новой записи
2. пометка всех записей как завершён.ых
3. удаление всех завершён.ых записей
4. пометка записи как завершён.ой
5. переименование записи
6. удаление записи

Мы будем идти по пунктам этого списка один за другим, но сначала определим, как наша модель в списке To-Do будет выглядеть:

```javascript
let model = {
  items: [
    { title: 'Implement To-Do list with Lodash', completed: false }
  ]
};
```

#### 1. Создание новой записи

После того, чему мы научились в предыдущих примерах, добавление новой записи To-Do довольно прямолинейно.

```javascript
let addItem = item => patch({
  items: _.concat({title: item})
});
```

#### 2. Пометка всех записей как завершён.ых

Сначала мы создадим функцию для завершён.я одной записи, а затем мы применим её ко всем записям в списке:

```javascript
let complete = patch({
  completed: true
});
let forAll = _.map;
let completeAll = patch({
  items: forAll(complete)
});
```

Мы также создали альтернативное имя (*alias*) `forAll` для функции `_.map` для улучшения читаемости.

#### 3. Удаление всех завершён.ых записей

Удаление завершён.ых записей очень похоже на предыдущий пункт. Мы используем функцию [_.matches()](https://lodash.com/docs/#matches) для фильтрации завершён.ых записей.

```javascript
let isCompleted = _.matches({
  complete: true
});
let removeIf = _.reject;
let clearCompleted = patch({
  items: removeIf(isCompleted)
});
```

Похожим образом мы создали альтернативу `removeIf` для функции [_.reject()](https://lodash.com/docs/#reject).

#### 4. Пометка записи как завершён.ой

Определение функции, переключающей флаг выполнения записи, простое:

```javascript
let toggle = _.negate(_.identity);
let toggleItem = patch({
  completed: toggle
});
```

Переключить записи в списке To-Do и оставить другие записи нетронутыми - это совершенно другая история. Чтобы реализовать это, мы сначала создадим новую функцию высшего порядка, которая будет вызывать функцию, переданную в качестве параметра в зависимости от переданного предиката:

```javascript
function onlyIf(fn, condFn){
  return function(){
    let args = _.toArray(arguments);
    if(condFn.apply(this, args)){
      return fn.apply(this, args);
    }
  };
}
function pow(n) { return n*n; }
let powN = onlyIf(pow, _.isNumber);
powN(4);
// → 16
powN('4');
// → undefined
```

Функция `onlyIf()` выглядит излишне императивной. Возможно Lodash может как-нибудь помочь нам с этим? Конечно может! Взгляните на [_.cond()](https://lodash.com/docs/#cond). Теперь мы имеем:

```javascript
let onlyIf = (fn, condFn) => _.cond([[condFn, fn]]);
let powN = onlyIf(pow, _.isNumber);
powN(4);
// → 16
```

Но нам нужна ещё одна функция:

```javascript
let otherwise = (fn, defaultFn) => _.cond([
    [_.flow([fn, _.negate(_.isUndefined)]), fn]
    [_.T, defaultFn]
  ]);
let powN = otherwise(onlyIf(pow, _.isNumber), _.constant('number expected!'));
powN(4);
// → 16
powN('4');
// → number expected!
```

Должен сказать, что `otherwise()` выглядит довольно экстремально. Возможно, императивная версия будет значительно более понятной. Я оставлю задачу (изменить эту функцию) читателю в качестве упражнения. Фрагмент `otherwise(onlyIf(pow), _.isNumber), _.constant('number expected!')` отнюдь не лучше. Он не выглядит естественно. Определенно он менее читаем, чем `powN(n){ return _.isNumber(n) ? n * n : 'number expected!'}`. Возможно мы зашли слишком далеко. Но давайте попробуем ещё один трюк, перед тем как сдаваться. Давайте присвоим обе функции в `Function.prototype` и передадим исходную функцию, как параметр `this`:

```javascript
Function.prototype.onlyIf = function(condFn) {
  return _.cond([[condFn, this]]);
};
Function.prototype.otherwise = function(defaultFn) {
  let noResult = _.flow([this, _.isUndefined]);
  return _.cond([[noResult, defaultFn], [_.T, this]]);
};
let powN = pow.onlyIf(_.isNumber).otherwise(_.constant('number expected!'));
powN(4);
// → 16
powN('4');
// → number expected!
```

Нам пришлось поменять стрелочную нотацию (`() => {}`) на выражение с `function`, так как стрелочные функции не создают собственный параметр `this`. Теперь мы можем вернуться к нашему исходному заданию: переключение одной конкретной записи.

```javascript
let completeItemIf = (condFn) => patch({
  items: forAll(complete.onlyIf(condFn).otherwise(_.identity))
});
var completeLearning = completeItemIf(_.matches({title: 'Learn FP'}));
completeLearning({
  items: [
    { title: 'Learn FP' },
    { title: 'Read tutorial & learn Lodash' }
  ]
});
// →
// {
//   items: [
//     { title: 'Learn FP', completed: true },
//     { title: 'Read tutorial & learn Lodash' }
//   ]
// }
```

#### 4a. Собственные функции соответствия

Как вы можете видеть в коде выше, чтобы завершить одну запись, нам нужно передать её полное название. Это немного неудобно. Что если мы хотим завершить каждую запись, содержащую «Learn» или «learn» в названии? Нам нужна собственная функция соответствия, которая также принимает регулярные выражения. Чтобы достигнуть этого, мы будем использовать уже знакомую функцию кастомизаторов Lodash, но в этот раз мы применим её с функцией [_.isMatchWith()](https://lodash.com/docs/#isMatchWith) вместо `_.mergeWith()`.

Мы можем переиспользовать наш `customizer` и расширить его поддержкой регулярных выражений:

```javascript
function customizer(val, operator){
  if(_.isFunction(operator)){
    return operator.apply(this, [val]);
  }
  if(_.isRegExp(operator)){
    return operator.test(val);
  }
}
let matches = _.isMatchWith(customizer);
```

Улучшенный `customizer` эффективно преобразовывает `_.isMatchWith` в нечто даже более гибкое чем [_.conforms()](https://lodash.com/docs/#conforms), поскольку позволяет проверять соответствие свойств объекта как с фиксированными значениями, так и c регулярными выражениями и c предикатами:

```javascript
let involvesLearning = matches({ title: /[Ll]earn/ });
involvesLearning({
  title: 'Learn Function Programming'
});
// → true
involvesLearning({
  title: 'Walk the dog'
});
// → false
let hasNonEmptyTitle = matches({ title: _.negate(_.isEmpty) });
hasNonEmptyTitle({
  title: ''
})
// → false
```

#### 5. Переименование записи + 6. Удаление записи

С придуманными ранее функциями-помощниками оставшаяся функциональность крайне проста:

```javascript
let changeTitleTo => title => patch({
  title: title
});
let hasTitle = title => matches({
  title: title
});
let renameItem = (newTitle, oldTitle) => patch({
  items: forAll(changeTitleTo(newTitle).onlyIf(hasTitle(oldTitle)).otherwise(_.identity))
});
let removeItem = (title) => patch({
  items: removeIf(hasTitle(oldTitle))
});
```

### Все вместе

Давайте соберём все куски кода вместе. Я разделил определения функций на две группы. Первая группа состоит из более абстрактных и более переиспользуемых функций (высшего порядка). Вторая группа включает в себя функции, более зависимые от предметной области.

```javascript
let _ = require('lodash/fp');

function customizer(val, op){
  if(_.isFunction(op)){
    return op.apply(this, [val]);
  }
  if(_.isRegExp(op)){
    return op.test(val);
  }
}

// general-purpose, higher-order functions:

let patch = recipe => _.mergeWith(customizer, _, recipe);
let matches = _.isMatchWith(customizer);
let forAll = _.map;
let removeIf = _.reject;
let toggle = _.negate(_.identity);

Function.prototype.onlyIf = function(condFn) {
  return _.cond([[condFn, this]]);
};
Function.prototype.otherwise = function(defaultFn) {
  let noResult = _.flow([this, _.isUndefined]);
  return _.cond([[noResult, defaultFn], [_.T, this]]);
};

// domain-specific functions:

let addItem = item => patch({
  items: _.concat({title: item})
});
let complete = patch({
  completed: true
});
let completeAll = patch({
  items: forAll(complete)
});
let isCompleted = matches({
  completed: true
});
let clearCompleted = patch({
  items: removeIf(isCompleted)
});
let toggleItem = patch({
  completed: toggle
});
let completeItemIf = condFn => patch({
  items: forAll(complete.onlyIf(condFn).otherwise(_.identity))
});
let changeTitleTo = title => patch({
  title: title
});
let hasTitle = title => matches({
  title: title
});
let renameItem = (newTitle, oldTitle) => patch({
  items: forAll(changeTitleTo(newTitle).onlyIf(hasTitle(oldTitle)).otherwise(_.identity))
});
let removeItem = (title) => patch({
  items: removeIf(hasTitle(oldTitle))
});

// demo:

let program = _.flow([
  addItem('Learn Lodash'),
  addItem('Learn FP'),
  addItem('Write Blog Post'),
  renameItem('Learn Functional Programming', 'Learn FP'),
  completeItemIf(hasTitle(/Learn/))
]);

console.log(program({items: []}));

// →
// { 
//   items: [ 
//     { title: 'Write Blog Post' },
//     { title: 'Learn Functional Programming', completed: true },
//     { title: 'Learn Lodash', completed: true } 
//   ] 
// }
```

Вы также можете найти полный код и поиграться с ним в этом [JS Fiddle](https://jsfiddle.net/67bdchwg/1/). 

### Заключение

В этой статье мы исследовали возможности кастомизации библиотеки Lodash. В результате мы сделали простой, но мощный *предметно-ориентированный язык* для декларативного преобразования JSON-объектов в виде *патчей* (*patches*). Благодаря гибкости и расширяемости Lodash, мы сделали это, написав довольно небольшое количество строк кода.

В конце мы смогли составить из очень простых функций более сложные патчи, которые читаются практически как естественный язык.

Является ли этот функциональный подход лучше/чище/моднее/подставьте_свое_прилагательное, чем классический императивный подход? Я оставлю читателю этот вопрос на его усмотрение. Однако, независимо от ответа, определенно важно быть в курсе всех этих крутых функций кастомизации, предоставляемых Lodash.

В следующей статье мы расширим наш пример интерфейсом пользователя и построим полностью работоспособное приложение списка To-Do. Оставайтесь на связи!

----

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Статья на Medium](https://medium.com/@dmitriy.gershun/lodash-не-только-для-манипуляции-списками-c78a5929a62c)
