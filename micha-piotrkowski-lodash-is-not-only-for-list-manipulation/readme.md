# Lodash не (только) для манипуляции списками!

*Перевод статьи  Michał Piotrkowski: [Lodash is not (only) for list manipulation!](https://blog.pragmatists.com/lodash-is-not-only-for-list-manipulation-791c2e3b9de1).*

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

> Дизклеймер (disclaimer - отказ от ответственности): Эта статья предполагает, что читатель хорошо знаком с концепцией функций высшего порядка и знает, как работают такие функции, как [_.curry](https://lodash.com/docs/#curry) и [_.partial](https://lodash.com/docs/#partial). Более того, в этой статье, когда я ссылаюсь на “Lodash”, я имею ввиду вариант `lodash/fp` библиотеки Lodash. Если вы никогда не слышали про `lodash/fp`, функции высшего порядка или просто хотите немного освежить свою память, пожалуйста взгляните на мою предыдущую статью по [Функциям высшего порядка в Lodash](https://medium.com/devschacht/michal-piotrkowski-higher-order-functions-in-lodash-56cb196c584d).

Одна из вещей, которую я люблю в Lodash, это то, что она крайне гибкая и адаптируемая. Даже если она не имеет конкретной нужной вам функции, скорее всего вы можете построить ее за несколько строк кода. Авторы Lodash предоставили возможности расширения по всей кодовой базе, что позволяет разработчикам кастомизировать (настраивать) ее поведение. Одна из таких точек расширения - это `Кастомизаторы`.


### Кастомизаторы.

Объектно-ориентированные программисты узнают `Кастомизаторы` как паттерн [Стратегия](https://ru.wikipedia.org/wiki/Стратегия_(шаблон_проектирования)) из знаменитой книги “Банды четырех”: [Приёмы объектно-ориентированного проектирования. Паттерны проектирования](https://ru.wikipedia.org/wiki/Design_Patterns).

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

К счастью, существует альтернативная версия функции `_.merge()`, принимающая дополнительную функцию, которая позволяет кастомизировать способ, которым свойства будут объединены. Эта кастомизирующая функция будет вызываться для каждого свойства (а также и вложенных свойств), которые должны быть объединены (свойства из второго объединяемого объекта). Значения объединяемого свойства будут переданы в качестве первых двух параметров. Давайте попробуем:
 
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

> Бонус: Другой вариант определения `customizer`: `let customizer = _.cond([[_.isArray, _.concat]])`;

Если одно из объединяемых свойств указывает на массив, тогда наш customizer возвращает новый массив, который содержит значения из обоих объединяемых объектов. Заметьте, что если объединяемое значение не массив, то наш customizer не будет возвращать никакого значения (или, другими словами, будет возвращать `undefined`). В такой ситуации Lodash будет использовать стандартную стратегию (используемую в функции `_.merge()`).

Но почему мы должны ограничивать себя только конкатенацией массивов? Вот как мы можем сделать наш customizer более общим:

```javascript
function customizer(val, fn){
  if(_.isFunction(fn)){
    return fn.apply(this, [val]);
  }
}
```

В этой новой версии customizer, если второй из объединяемых объектов содержит функцию, то, вместо присвоения этой функции в результирующий объект, мы просто применяем ее, передавая в качестве параметров значения соответствующего свойства из первого объекта.

Теперь мы можем передать наш customizer в качестве первого параметра функции `_.mergeWith()`. Давайте назовем получившуюся функцию `patch`:

```javascript
var patch = recipe => _.mergeWith(customizer, _, recipe);
```

Запомните, что все `lodash/fp` функции авто-каррируемы, так что мы можем передавать им подмножество параметров, а также заменители параметров _, и в результате мы будем получать результирующую функцию с некоторыми фиксированными параметрами.

Получившаяся функция `patch()` - это функция высшего порядка, которая возвращает новую функцию, трансформирующую объект в зависимости от предоставляемого параметра recipe. Параметр recipe формулируется довольно декларативным способом, но явно указывает, какую функцию использовать для объединения данного свойства. Если свойство указывает не на функцию, применяется стандартная стратегия объединения.

> Заметка: порядок параметров в `_.mergeWith(customizer, object, source)` немного неудачный, посколько он принимается параметр с данными (`object`) вторым и, при этом, не последним параметром. Иначе мы могли бы в полной мере воспользоваться каррированием и определить функцию `patch` просто как:

```javascript
var patch = recipe => _.mergeWith(customizer, _, recipe);
```

> Однако, нужный порядок параметров заставляет нас пропустить второй параметр, используя `_`.
Кроме того, мы могли бы переставить порядок параметров используя функцию [_.rearg()](https://lodash.com/docs/#rearg) таким образом:

```javascript
var mergeRearg = _.rearg(_.mergeWith, [0, 2, 1]);
var patch = mergeRearg(customizer);
```

> Или просто (используя [_.flip()](https://lodash.com/docs/#flip)):

```javascript
var patch = _.flip(_.mergeWith(customizer));
```

> `_.flip` и `_.rearg()` являются еще одним доказательством гибкости Lodash.

OK, после того как мы определили нашу функцию patch(), давайте посмотрим, на что она способна. Мы начнем переделывать пример с контактной информацией:

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

Теперь, давайте вообразим, что мы хотим иметь возможность переключать флаг favorite для нашего контакта:

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

В Lodash функция _.mergeWith() рекурсивна, благодаря этому наша функция patch() поддерживает вложенные свойства из коробки:

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

Заметили, как мы избежали стандартных проверок на null?

Последним упражнением, давайте напишем функцию patch, которая попробует распарсить строку адреса и извлечь zip-код, улицу и город. Для построения цепочки операций (выполнения регулярного выражения, извлечения удовлевлетворяющих регулярному выражению групп в массив, построения объекта из массива) мы будет использовать функцию _.flow():

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

Мы можем также сделать это таким способом:

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


Сначала операции, в конце данные
Заметьте, как во всех наших примерах мы сначала определяем преобразования, затем комбинируем их, а в конце передаем нужные данные в получившееся преобразование. Само преобразование не зависит от данных, только от структуры принимаемых данных. Этот подход сильно отличается от более классического, объектно-ориентированного стиля, где операторы привязываются к некоторому контексту (например this или переменным из  родительской области видимости). В следующем примере  функция findActiveItems() зависит от массива items:

```javascript
let items = [
  { active: true, /* ... */ }
  // ...
];  
    
function findActiveItems(){ 
  return _.filter(items, item => item.active);
}
```

Эта зависимость от контекста делает функции менее переиспользуемыми, посколько они не могут быть отделены от их контекста. В отличие от объектно ориентированного стиля, в функциональном программировании мы пытаемся отделить операции от данных настолько, насколько это возможно. Один из способов достижения этого, это откладывать передачу данных на как можно более поздний момент. Это характерно для функциональных библиотек (таких как lodash/fp или Rambda) - принимать данные последним параметром.

Реализация списка To-Do.
Давайте возвратимся к нашей функции patch() и увидим, насколько далеко мы сможем продвинуть нашу простую реализацию. Насколько сложную логику мы сможем создать с использованием этой элементарной функции patch(), перед тем как мы возвратимся к более классическому (императивному) стилю программирования? В качестве теста давайте попробуем реализовать все возможности известного проекта TodoMVC. Конечно, мы сфокусируемся на деталях реализации модели/предметной области (domain/model), и пропустим все части, связанные с интерфейсом пользователя.

Давайте перечислим все функции списка To-Do, поддерживаемые TodoMVC:

создание новой записи,
пометка всех записей как завершенных,
удаление всех завершенных записей,
пометка записи как завершенной,
переименование записи,
удаление записи.

Мы будем идти по пунктам этого списка один за другим, но сначала определим, как наша модель в нашем списке To-Do будет выглядеть:

```javascript
let model = {
  items: [
    { title: 'Implement To-Do list with Lodash', completed: false }
  ]
};
```

Создание новой записи
Добавление новой записи To-Do довольно прямолинейно после того, чему мы научились в предыдущих примерах.

```javascript
let addItem = item => patch({
  items: _.concat({title: item})
});
```

2. пометка всех записей как сделанных,
Сначала мы создадим функцию для завершения одной записи, а затем мы применим ее ко всем записям в списке:

```javascript
let complete = patch({
  completed: true
});
let forAll = _.map;
let completeAll = patch({
  items: forAll(complete)
});
```

Мы также создали альтернативное имя (alias) forAll для функции _.map, посколько это улучшает читаемость.

3. удаление всех завершенных записей
Удаление завершенных записей очень похоже на предыдущий пункт. Мы используем функцию _.matches() для фильтрации завершенных записей.

```javascript
let isCompleted = _.matches({
  complete: true
});
let removeIf = _.reject;
let clearCompleted = patch({
  items: removeIf(isCompleted)
});
```

Похожим образом мы создали альтернативу removeIf для функции _.reject().

4. пометка записи как завершенной

Определение функции, которая переключает флаг выполнения записи, простое:

```javascript
let toggle = _.negate(_.identity);
let toggleItem = patch({
  completed: toggle
});
```

Переключение записи в списке To-Do и оставление остальных записей нетронутыми - это совершенно другая история. Чтобы сделать это, мы сначала создадим функцию высшего порядка, которая будет вызывать функцию, переданную в качестве параметра в зависимости от переданного предиката:

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

Функция onlyIf() выглядит излишне императивной. Возможно Lodash может как-нибудь помочь нам с этим? Конечно может! Взгляните на _.cond(). Теперь мы имеем:

```javascript
let onlyIf = (fn, condFn) => _.cond([[condFn, fn]]);
let powN = onlyIf(pow, _.isNumber);
powN(4);
// → 16
```

Теперь нам нужна еще одна функция:

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

Должен сказать, что otherwise() выглядит довольно экстремально. Возможно, императивная версия будет значительно более понятной. Я оставлю задачу (изменить эту функцию) читателю в качестве упражнения. Фрагмент otherwise(onlyIf(pow), _.isNumber), _.constant('number expected!') отнюдь не лучше. Он не выглядит естественно. Определенно он менее читаем, чем powN(n){ return _.isNumber(n) ? n * n : 'number expected!'}. Возможно мы зашли слишком далеко. Но давайте попробуем еще один трюк, перед тем как сдаваться. Давайте присвоим обе функции в Function.prototype и передадим исходную функцию как параметр this:

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

Нам пришлось поменять стрелочную нотацию (() => {}) на выражение с function, так как стрелочные функции не создают собственный параметр this. Теперь мы можем вернуться к нашему исходному заданию: переключение одной конкретной записи.

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

4a. Собственные функции соответствия
Как вы можете видеть в коде выше, чтобы завершить одну запись нам нужно передать ее полное название. Это немного неудобно. Что если мы хотим завершить каждую запись, содержащую “Learn” или “learn” в названии? Нам нужна собственная функция соответствия, которая также принимает регулярные выражения. Чтобы достигнуть этого, мы будем использовать уже знакомую функцию кастомизаторов Lodash, но в этот раз мы применим ее с функцией _.isMatchWith() вместо _.isMergeWith(.

Мы можем переиспользовать наш предыдущий кастомайзер и расширить его поддержкой регулярных выражений:

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


Наш улучшенный кастомайзер эффективно преобразовывает _.isMatchWith в нечно даже более гибкое чем _.conforms(), так как позволяет проверять соответствие свойств объекта с: фиксированными значениями, регулярными выражениями и предикатами:

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

5. Переименование записи + 6. Удаление записи
С придуманными ранее функциями-помощниками, оставшаяся функциональность крайне проста:

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

Все вместе
Давайте соберем все куски кода вместе. Я разделил определения функций на дву группы. Первая группа состоит из более абстрактных и более переиспользуемых функций (высшего порядка). Вторая группа включает в себя функции, более зависимые от предметной области.

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

Вы можете также найти полный код и поиграться с ним в этом JS Fiddle. 

Заключение

В этой статье мы исследовали возможности кастомизации библиотеки Lodash. В результате, мы сделали простой, но мощный domail-specific язык для декларативного преобразования JSON-объектов в виде патчей (patches). Благодаря гибкости и расширяемости Lodash, мы сделали это, написав довольно небольшое количество строк кода.

В конце мы смогли составить из очень простых функций более сложные патчи, которые читаются практически как естественный язык.

Является ли этот функциональный подход лучше/чище/моднее/подставьте свое прилагательное чем классический императивный подход? Я оставлю читателю этот вопрос на его усмотрение. Однако, независимо от ответа, это определенно важно быть в курсе всех этих крутых функций кастомизации предоставляемых Lodash.

В следующей статья мы расширим наш пример интерфейсом пользователя и построим полностью работоспособное приложение списка To-Do. Оставайтесь на связи!
