# JIT для начинающих: Small Integer и Double
![](https://cdn-images-1.medium.com/max/800/1*CqKlEeRH3amQwBDuplpXug.jpeg)

*Перевод статьи [Фёдора Индутного](https://blog.indutny.com/): [Allocating numbers](http://darksi.de/6.smis-and-doubles/). Распространяется по [лицензии MIT](http://opensource.org/licenses/mit-license.php).*

Это третий пост в серии «JIT для начинающих». Для лучшего понимания материала, пожалуйста, ознакомьтесь с [предыдущей статьёй](https://medium.com/devschacht/fedor-indutny-alocating-numbers-b0b138d0c684).

## Цель
В прошлый раз мы реализовали очень простое выталкивающее распределение памяти и научили наш код работать с числами с плавающей запятой (типа double), хранящимися в выделенных областях кучи. Однако числа с плавающей запятой не подходят для некоторых операций, в которых важна точность, а также, поскольку они хранятся в памяти, требуются дополнительные операции чтения и записи памяти, что снижает производительность кода.

Обе эти проблемы можно решить, работая с целыми числами, хранящимися в регистрах (как это было сделано в [первой статье серии](https://medium.com/devschacht/how-to-start-jitting-ee9fcbc9065a)), а это означает, что нам нужно поддерживать оба типа чисел во время работы нашего компилятора (double и integer).

## Тегирование
Напомним, что мы сохраняем как указатели, так и числа в 64-битных регистрах общего назначения (`rax`, `rbx` и так далее). Основная проблема здесь заключается в том, что, опрашивая некоторый регистр (скажем, `rax`), мы должны быть в состоянии определить, является ли он указателем на область кучи (*boxed value*) или содержит целое число (*unboxed value*, *Small Integer* или *SMI*).

Обычно для решения этой проблемы используется метод тегирования. Несмотря на то, что существуют [различные способы](http://wingolog.org/archives/2011/05/18/value-representation-in-javascript-implementations) реализации тегирования, в том числе: [Nan-Boxing](http://evilpie.github.io/sayrer-fatval-backup/cache.aspx.htm)(пролистайте до **Mozilla’s New JavaScript Value Representation**), Nun-Boxing и, возможно, некоторые другие, наш компилятор просто зарезервирует младший бит 64-битного регистра и установит его в 1, если значение является указателем, и в 0, если это SMI (*Small Integer*).

Вот пример этого представления:

![](http://darksi.de/images/smi-and-pointer.png)

Обратите внимание, что для получения фактического значения SMI («нетегированного») нам нужно будет сдвинуть его вправо на один бит (`>> 1`), а для преобразования целого числа в SMI — сделать сдвиг влево (`<< 1`). Использование нуля для тегирования SMI очень выгодно, так как нам не нужно преобразовывать числа к нетегированному виду для выполнения сложения и вычитания.

Чтобы использовать тегированные указатели для объектов кучи, нам надо взять один байт за фактическим значением, что относительно просто реализуется в командах ассемблера:

```javascript
// Предположим, что тегированный указатель находится в `rbx`
// и мы загружаем его содержимое в `rax`
this.mov('rax', ['rbx', -1]);
```

И просто для для удобства, пример получения SMI:

```javascript
// Без с тега
this.shr('rax', 1);
// С тегом
this.shl('rax', 1);
```

И теперь самая важная операция, которую мы собираемся производить довольно часто — проверка, является ли значение указателем:

```javascript
// Проверка последнего бита `rax`
this.test('rax', 1);

// 'z' означает 0
// Переход на метку, если `(rax & 1) == 0`
this.j('z', 'is-smi');

// 'nz' означает не 0
// То есть переходим на метку, если `(rax & 1) != 0`
this.j('nz', 'is-heap-object-pointer');
```

## Переработка предыдущего кода
Используя код из [предыдущей статьи](https://medium.com/devschacht/fedor-indutny-alocating-numbers-b0b138d0c684), мы можем, наконец, приступить к реализации всего этого недавно изученного материала.

Во-первых, давайте добавим удобные вспомогательные методы в ассемблерный контекст.

```javascript
function untagSmi(reg) {
  this.shr(reg, 1);
};

function checkSmi(value, t, f) {
  // Если не переданы колбэки `true-` и `false-` —
  // то просто проверяем `value`
  if (!t && !f)
    return this.test(value, 1);

  // Вход в область, в которой можно использовать именованные метки
  this.labelScope(function() {
    // Проверка value
    this.test(value, 1);

    // Пропускаем вариант SMI, если результат не нулевой
    this.j('nz', 'non-smi');

    // Обрабатываем случай SMI
    t.call(this);

    // Переходим к выходу
    this.j('end');

    // Случай Non-SMI
    this.bind('non-smi');
    f.call(this);

    // Выход
    this.bind('end');
  });
};

function heapOffset(reg, offset) {
  // ПРИМЕЧАНИЕ: 8 - размер указателя в архитектуре x64.
  // Мы добавляем 1 к смещению, потому что первое
  // quad word используется для хранения типа объекта кучи.
  return [reg, 8 * ((offset | 0) + 1) - 1];
};
```

Мы можем использовать эти методы в контексте `jit.js`, передав их в качестве хелперов для метода API `jit.compile()`:

```javascript
var helpers = {
  untagSmi: untagSmi,
  checkSmi: checkSmi,
  heapOffset: heapOffset
};

jit.compile(function() {
  // Мы можем использовать хелперы здесь:
  this.untagSmi('rax');

  this.checkSmi('rbx', function() {
    // Работа с SMI
  }, function() {
    // Работа с указателем
  });

  this.mov(this.heapOffset('rbx', 0), 1);
}, { stubs: stubs, helpers: helpers });
```

## Выделение памяти
Теперь мы должны научить заглушку `Alloc` возвращать тегированные значения. Также мы воспользуемся возможностью и немного её улучшим, добавив аргументы `tag` и `size` (таким образом, в будущем возможно обобщение с переменным размером и тегом):

```javascript
stubs.define('Alloc', function(size, tag) {
  // Сохраняем регистры 'rbx' и 'rcx'
  this.spill(['rbx', 'rcx'], function() {
    // Загружаем `offset`
    //
    // ПРИМЕЧАНИЕ. Мы будем использовать указатель на переменную `offset`,
    // чтобы иметь возможноть обновить её ниже
    this.mov('rax', this.ptr(offset));
    this.mov('rax', ['rax']);

    // Загружаем `end`
    //
    // NOTE: То же самое для `end`, хотя мы не обновляем его значение прямо сейчас
    this.mov('rbx', this.ptr(end));
    this.mov('rbx', ['rbx']);

    // Рассчитываем новый `offset`
    this.mov('rcx', 'rax');

    // Добавляем размер тега и тела
    this.add('rcx', tag);
    this.add('rcx', size);

    // Проверяем, не переполним ли мы буфер фиксированного размера
    this.cmp('rcx', 'rbx');

    // `this.j()` выполняет условный переход к указанной метке.
    // 'g' означает 'greater'
    // 'overflow' это имя метки, указанной ниже
    this.j('g', 'overflow');

    // Ок, мы готовы, обновляем смещение
    this.mov('rbx', this.ptr(offset));
    this.mov(['rbx'], 'rcx');

    // Первый 64-х битный указатель зарезервирован под 'tag',
    // второй - это значение типа `double`
    this.mov('rcx', tag);
    this.mov(['rax'], 'rcx');

    // !!!!!!!!!!!!!!!!!!!!
    // ! Указатель на Тег !
    // !!!!!!!!!!!!!!!!!!!!
    this.or('rax', 1);

    // Возвращаем 'rax'
    this.Return();

    // Переполнение :(
    this.bind('overflow')

	 // Вызов функции на JavaScript!
    // ПРИМЕЧАНИЕ: Это выглядит забавно, но
    // прямо сейчас я не собираюсь погружаться глубже
    this.runtime(function() {
      console.log('GC is needed, but not implemented');
    });

    // Поломка
    this.int3();

    this.Return();
  });
});
```

## Заглушки для математических операций
Кроме того, поскольку мы собираемся добавить больше скрупулезности в математических операциях для поддержки как SMI, так и чисел с плавающей запятой, давайте разделим их на части и поместим код для работы с плавающей запятой в заглушку:

```javascript
var operators = ['+', '-', '*', '/'];
var map = { '+': 'addsd', '-': 'subsd', '*': 'mulsd', '/': 'divsd' };

// Определяем заглушки `Binary+`, `Binary-`, `Binary*` и `Binary/`
operators.forEach(function(operator) {
  stubs.define('Binary' + operator, function(left, right) {
    // Сохраняем 'rbx' и 'rcx'
    this.spill(['rbx', 'rcx'], function() {
      // Загружаем аргументы в 'rax' и 'rbx'
      this.mov('rax', left);
      this.mov('rbx', right);

      // Конвертируем оба числа в double
      [['rax', 'xmm1'], ['rbx', 'xmm2']].forEach(function(regs) {
        var nonSmi = this.label();
        var done = this.label();

        this.checkSmi(regs[0]);
        this.j('nz', nonSmi);

        // Конвертируем integer в double
        this.untagSmi(regs[0]);
        this.cvtsi2sd(regs[1], regs[0]);

        this.j(done);
        this.bind(nonSmi);

        this.movq(regs[1], this.heapOffset(regs[0], 0));
        this.bind(done);
      }, this);

      var instr = map[operator];

      // Выполняем бинарную операцию
      if (instr) {
        this[instr]('xmm1', 'xmm2');
      } else {
        throw new Error('Unsupported binary operator: ' + operator);
      }

      // Выделяем память под новое число и кладём туда полученное значение
      // Примечание: Последние два аргумента - это параметры для заглушки (`size` и `tag`)
      this.stub('rax', 'Alloc', 8, 1);
      this.movq(this.heapOffset('rax', 0), 'xmm1');
    });

    this.Return();
  });
});
```

Обратите внимание, что эта заглушка также преобразует все входящие числа в числа с плавающей запятой.

## Компилятор
Вернёмся к коду компилятора:

```javascript
function visitProgram(ast) {
  assert.equal(ast.body.length, 1, 'Only one statement programs are supported');
  assert.equal(ast.body[0].type, 'ExpressionStatement');

  // У нас есть указатель в 'rax', конвертируем его в целое число
  visit.call(this, ast.body[0].expression);

  // Получение числа с плавающей точкой из кучи
  this.checkSmi('rax', function() {
    // Убираем тег из SMI
    this.untagSmi('rax');
  }, function() {
    this.movq('xmm1', this.heapOffset('rax', 0));

    // Округляем к нулю
    this.roundsd('zero', 'xmm1', 'xmm1');

    // Конвертируем к целому числу
    this.cvtsd2si('rax', 'xmm1');
  });
}

function visitLiteral(ast) {
  assert.equal(typeof ast.value, 'number');

  if ((ast.value | 0) === ast.value) {
    // Small Integer (SMI), тегированное значение, с последним битом, установленным в 0to zero
    this.mov('rax', utils.tagSmi(ast.value));
  } else {
    // Получаем новое число из кучи
    this.stub('rax', 'Alloc', 8, 8);

    // Сохраняем регистр 'rbx'
    this.spill('rbx', function() {
      this.loadDouble('rbx', ast.value);

      // Примечание: указатели имеют последний бит, установленный в 1
      // Вот почему мы вынужденны использовать функцию 'heapOffset'
      // для получения доступа к области памяти
      this.mov(this.heapOffset('rax', 0), 'rbx');
    });
  }
}

function visitBinary(ast) {
  // Сохраняем начальное состояние 'rbx' до выхода из узла AST
  this.spill('rbx', function() {
    // Проверяем правую часть выражения
    visit.call(this, ast.right);

    // Помещаем её в 'rbx'
    this.mov('rbx', 'rax');

    // Проверяем левую часть выражения (результат в 'rax')
    visit.call(this, ast.left);

    //
    // Итак, левая часть в 'rax' и правая в 'rbx'
    //

    if (ast.operator === '/') {
      // Вызываем заглушку для деления
      this.stub('rax', 'Binary' + ast.operator, 'rax', 'rbx');
    } else {
      this.labelScope(function() {
        // Проверяем, что оба числа SMI
        this.checkSmi('rax');
        this.j('nz', 'call stub');
        this.checkSmi('rbx');
        this.j('nz', 'call stub');

        // Сохраняем 'rax' в случае переполнения
        this.mov('rcx', 'rax');

        // Примечание: оба регистра 'rax' и 'rbx' являются тегированными.
        // Тег не нужно удалять, если мы делаем сложение или вычитание.
        // Однако в случае умножения результат будет в 2x больше,
        // если мы не уберём тэг с одного из аргументов.
        if (ast.operator === '+') {
          this.add('rax', 'rbx');
        } else if (ast.operator === '-') {
          this.sub('rax', 'rbx');
        } else if (ast.operator === '*') {
          this.untagSmi('rax');
          this.mul('rbx');
        }

        // При переполнении восстановить 'rax' из 'rcx' и вызвать заглушку
        this.j('o', 'restore');

        // Иначе вернуть 'rax'
        this.j('done');
        this.bind('restore');

        this.mov('rax', 'rcx');

        this.bind('call stub');

        // Вызвать заглушку и вернуть число из кучи в 'rax'
        this.stub('rax', 'Binary' + ast.operator, 'rax', 'rbx');

        this.bind('done');
      });
    }
  });
}

function visitUnary(ast) {
  if (ast.operator === '-') {
    // Отрицательный аргумент через эмуляцию бинарного выражения
    visit.call(this, {
      type: 'BinaryExpression',
      operator: '*',
      left: ast.argument,
      right: { type: 'Literal', value: -1 }
    })
  } else {
    throw new Error('Unsupported unary operator: ' + ast.operator);
  }
}
```

Итак, теперь мы работаем с SMI по умолчанию, осуществляем инлайнинг всех операций ради скорости, и возвращаемся к числам с плавающей запятой в случае переполнения или любой другой проблемы, например, попытки суммирования double и SMI!

Вот и все, увидимся здесь в следующий раз! Вот полный код компилятора из этой статьи: [github](https://github.com/indutny/jit.js/tree/master/example/heap-smi-and-double). Попробуйте склонировать, запустить и поиграть с ним! Надеюсь, вам понравилась эта статья.

---

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Статья на Medium](https://medium.com/devschacht/fedor-indutny-smis-and-doubles-c0baccaaa88b)
