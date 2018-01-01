# Паттерны оптимизации JavaScript. Часть 2
*Перевод статьи [Benedikt Meurer](http://benediktmeurer.de): [JavaScript Optimization Patterns (Part 2)](http://benediktmeurer.de/2017/06/29/javascript-optimization-patterns-part2/).*

Вслед за [первой частью этой серии](https://medium.com/devschacht/javascript-optimization-patterns-part1-d5699fcd59a), вышедшей на прошлой неделе, я представляю ещё одну (надеюсь, интересную) заметку о паттернах оптимизации JavaScript (основанную на моем четырёхлетнем опыте работы над движком V8). На этой неделе мы рассмотрим оптимизацию под названием *специализация контекста функции* (*function context specialization*), которую мы добавили в V8 с запуском TurboFan (другие движки, такие как JavaScriptCore, используют аналогичные оптимизации). Название этой оптимизации немного вводит в заблуждение. В основном это означает, что TurboFan может оборачивать в константы определенные значения при создании оптимизированного кода, и он делает это, специализируясь на сгенерированном машинном коде функции в окружающем её контексте, который V8 отдаёт для представления скоупа (области выполнения) во время выполнения.

Рассмотрим следующий простой фрагмент кода:

```javascript
const INCREMENT = 1;

function incr(x) { return x + INCREMENT; }
```

Предположим, что мы запускаем это на уровне `<script>` в Chrome (или на верхнем уровне в оболочке `d8`), тогда мы получим следующий байткод, сгенерированный для функции `incr`:

```
$ out/Release/d8 --print-bytecode ex1.js
...SNIP...
[generating bytecode for function: incr]
Parameter count 2
Frame size 0
   35 E> 0x1859bd52f4fe @    0 : 92                StackCheck
   41 S> 0x1859bd52f4ff @    1 : 13 04             LdaImmutableCurrentContextSlot [4]
   52 E> 0x1859bd52f501 @    3 : 97 00             ThrowReferenceErrorIfHole [0]
   50 E> 0x1859bd52f503 @    5 : 2b 02 03          Add a0, [3]
   63 S> 0x1859bd52f506 @    8 : 96                Return
Constant pool (size = 1)
0x1859bd52f4b1: [FixedArray] in OldSpace
 - map = 0x2f062f402309 <Map(PACKED_HOLEY_ELEMENTS)>
 - length: 1
           0: 0x1859bd52ef11 <String[9]: INCREMENT>
Handler Table (size = 16)
$
```

Самое интересно здесь - это доступ к константе `INCREMENT` в скоупе скрипта: она загружается из окружающего контекста через байткод LdaImmutableCurrentContextSlot, а затем сразу же проверяется, является ли её значение тем, что мы называем `the_hole` в V8. `the_hole` является внутренним маркером, который используется для реализации временной мертвой зоны для лексического окружения (подробнее в [Variables and scoping in ECMAScript 6](http://2ality.com/2015/02/es6-scoping.html) [Акселя Раушмайера](https://twitter.com/rauschma)). Это выглядит несколько противоречиво для многих разработчиков, с которыми я общаюсь, поскольку интуитивно мы ожидаем, что виртуальной машине нужно делать меньше работы для `const`, чем `var`, особенно внутри локального скоупа, но реальность такова: (по крайней мере изначально) движку необходимо сделать ещё больше работы из-за дополнительной проверки TDZ (временной мертвой зоны). Это необходимо из-за того, как работает скоупинг, то есть посмотрим на `ex2.js`:

```javascript
console.log(incr(5));

const INCREMENT = 1;

function incr(x) { return x + INCREMENT; }
```

И запустим его в оболочке `d8`:

```
$ out/Release/d8 ex2.js
ex2.js:5: ReferenceError: INCREMENT is not defined
function incr(x) { return x + INCREMENT; }
                              ^
ReferenceError: INCREMENT is not defined
    at incr (ex2.js:5:31)
    at ex2.js:1:13

$
```

Проверка TDZ завершилась неудачно, потому что назначение `const INCREMENT = 1` не было выполнено до запуска `incr`. Я должен признать, что, хотя я уже некоторое время работаю на стороне разработки VM, я все ещё считаю это поведение очень противоречивым, но я также не считаю себя очень хорошим дизайнером языка... Хорошо, прочь проповеди. Если снова взглянуть на пример, он, очевидно, будет работать, если вы поместим вызов `incr` в самый конец

```javascript
const INCREMENT = 1;

function incr(x) { return x + INCREMENT; }

console.log(incr(5));
```

и запустим код в оболочке `d8`:

```
$ out/Release/d8 ex3.js
6
$
```

Так много скрыто в бэкграунде для временной мертвой зоны (TDZ).

В вопросе производительности здесь есть одно очень интересное (и, возможно, очевидное) наблюдение: после того, как назначается конкретный слот `const` в контексте, он сохранит это значение и не вернется к тому, чтобы когда-либо снова содержать `the_hole` (это гарантирует `const`). И мы используем именно этот факт в TurboFan, чтобы каждый раз не загружать и не проверять значения слота `const`.

```javascript
const INCREMENT = 1;

function incr(x) { return x + INCREMENT; }

// Прогрев
incr(3);
incr(4);
%OptimizeFunctionOnNextCall(incr);
console.log(incr(5));
```

Мы можем видеть это в оптимизированном машинном коде, который генерирует TurboFan:

```
$ out/Release/d8 --allow-natives-syntax --print-opt-code --code-comments ex4.js
...SNIP...
                  -- B0 start (construct frame) --
0x11e35a6041e0     0  55             push rbp
0x11e35a6041e1     1  4889e5         REX.W movq rbp,rsp
0x11e35a6041e4     4  56             push rsi
0x11e35a6041e5     5  57             push rdi
0x11e35a6041e6     6  493ba5680c0000 REX.W cmpq rsp,[r13+0xc68]
0x11e35a6041ed     d  0f862a000000   jna 0x11e35a60421d  <+0x3d>
                  -- B2 start --
                  -- B3 start (deconstruct frame) --
0x11e35a6041f3    13  488b4510       REX.W movq rax,[rbp+0x10]
0x11e35a6041f7    17  a801           test al,0x1
0x11e35a6041f9    19  0f8535000000   jnz 0x11e35a604234  <+0x54>
0x11e35a6041ff    1f  488bd8         REX.W movq rbx,rax
0x11e35a604202    22  48c1eb20       REX.W shrq rbx, 32
0x11e35a604206    26  83c301         addl rbx,0x1
0x11e35a604209    29  0f802a000000   jo 0x11e35a604239  <+0x59>
0x11e35a60420f    2f  48c1e320       REX.W shlq rbx, 32
0x11e35a604213    33  488bc3         REX.W movq rax,rbx
0x11e35a604216    36  488be5         REX.W movq rsp,rbp
0x11e35a604219    39  5d             pop rbp
0x11e35a60421a    3a  c21000         ret 0x10
...SNIP...
$
```

Единственная действительно интересная строка здесь — строка с смещением 26 с инструкцией `addl rbx, 0x1`, где `rbx` содержит целочисленное значение параметра `x`, переданного функции (на основе того, что мы прогрели `incr` целочисленными значениями для `x` ранее), а `0x1` - зафиксированное значение константы `INCREMENT` из окружающего контекста. Фиксация константы в этом случае действительна только потому, что TurboFan знает, что никто больше не может изменить значение `INCREMENT`, как только он уже не является `the_hole` (то есть вне TDZ). На самом деле это не TurboFan, это интерпретатор Ignition пересылает эту информацию в TurboFan через выделенный байткод `LdaImmutableCurrentContextSlot`, который мы видели ранее, в частности, это неизменный бит в этом байткоде, который сообщает TurboFan, что контекстный слот больше не может меняться, когда он содержит непустое значение. Мы можем увидеть разницу, если пробуем тот же пример с `let`:

```javascript
let INCREMENT = 1;

function incr(x) { return x + INCREMENT; }

// Прогрев
incr(3);
incr(4);
%OptimizeFunctionOnNextCall(incr);
console.log(incr(5));
```

Исполнение этого кода `ex5.js` в оболочке `d8` и проверка как байтового кода, так и оптимизированного машинного кода выглядит следующим образом:

```
$ out/Release/d8 --print-bytecode --allow-natives-syntax --print-opt-code --code-comments ex5.js
...SNIP...
[generating bytecode for function: incr]
Parameter count 2
Frame size 0
   33 E> 0xa9399d2f63e @    0 : 92                StackCheck
   39 S> 0xa9399d2f63f @    1 : 12 04             LdaCurrentContextSlot [4]
   50 E> 0xa9399d2f641 @    3 : 97 00             ThrowReferenceErrorIfHole [0]
   48 E> 0xa9399d2f643 @    5 : 2b 02 03          Add a0, [3]
   61 S> 0xa9399d2f646 @    8 : 96                Return
...SNIP...
                  -- B0 start (construct frame) --
0x25139be041e0     0  55             push rbp
0x25139be041e1     1  4889e5         REX.W movq rbp,rsp
0x25139be041e4     4  56             push rsi
0x25139be041e5     5  57             push rdi
0x25139be041e6     6  4883ec08       REX.W subq rsp,0x8
0x25139be041ea     a  493ba5680c0000 REX.W cmpq rsp,[r13+0xc68]
0x25139be041f1    11  0f864b000000   jna 0x25139be04242  <+0x62>
                  -- B2 start --
                  -- B3 start --
0x25139be041f7    17  48b8d1f4d299930a0000 REX.W movq rax,0xa9399d2f4d1    ;; object: 0xa9399d2f4d1 <FixedArray[5]>
0x25139be04201    21  488b402f       REX.W movq rax,[rax+0x2f]
0x25139be04205    25  493945a8       REX.W cmpq [r13-0x58],rax
0x25139be04209    29  0f844a000000   jz 0x25139be04259  <+0x79>
                  -- B4 start (deconstruct frame) --
0x25139be0420f    2f  488b5d10       REX.W movq rbx,[rbp+0x10]
0x25139be04213    33  f6c301         testb rbx,0x1
0x25139be04216    36  0f8564000000   jnz 0x25139be04280  <+0xa0>
0x25139be0421c    3c  a801           test al,0x1
0x25139be0421e    3e  0f8561000000   jnz 0x25139be04285  <+0xa5>
0x25139be04224    44  48c1e820       REX.W shrq rax, 32
0x25139be04228    48  488bd3         REX.W movq rdx,rbx
0x25139be0422b    4b  48c1ea20       REX.W shrq rdx, 32
0x25139be0422f    4f  03c2           addl rax,rdx
0x25139be04231    51  0f8053000000   jo 0x25139be0428a  <+0xaa>
0x25139be04237    57  48c1e020       REX.W shlq rax, 32
0x25139be0423b    5b  488be5         REX.W movq rsp,rbp
0x25139be0423e    5e  5d             pop rbp
0x25139be0423f    5f  c21000         ret 0x10
...SNIP...
$
```

Здесь мы видим, что Ignition должен использовать `LdaCurrentContextSlot`, то есть он не может доказать, что значение `INCREMENT` не может измениться впоследствии, потому что любой другой скрипт может просто изменить `INCREMENT` позже. И поскольку TurboFan не может подставить из константы значение `1` напрямую, он вместо этого должен генерировать явный код для загрузки `INCREMENT` из контекста скрипта и проверять, что это не `the_hole` (код между смещением 17 и 2f в приведенном выше списке делает это).

Поэтому в этом смысле `const` помогает повышению производительности, но только после того, как она достигает оптимизирующего компилятора, и если срабатывает *специализация контекста функции*, что зависит от довольно простого условия, которое может быть не очевидным: она разрешена только для первого замыкания любой функции в данном нативном контексте (так в V8 называется `<iframe>`). Так что это значит? В приведенных выше примерах всегда было только одно замыкание `incr`. Но давайте рассмотрим этот простой пример `ex6.js`:

```javascript
const INCREMENT = 1;

function makeIncr() {
  function incr(x) { return x + INCREMENT; }
  return incr;
}

function test(incr) {
  // Прогрев
  incr(3);
  incr(4);
  %OptimizeFunctionOnNextCall(incr);
  console.log(incr(5));
}

test(makeIncr());
test(makeIncr());
```

Это определенно немного искусственно, но важно выделить ключевую деталь: теперь есть несколько замыканий для одной и той же функции `incr`, созданной `makeIncr`. Выполнение этого в `d8` показывает то, что я только что описал:

```
$ out/Release/d8 --print-bytecode --allow-natives-syntax --print-opt-code --code-comments ex6.js
...SNIP...
[generating bytecode for function: incr]
Parameter count 2
Frame size 0
   59 E> 0x34d1b322fb56 @    0 : 92                StackCheck
   65 S> 0x34d1b322fb57 @    1 : 13 04             LdaImmutableCurrentContextSlot [4]
   76 E> 0x34d1b322fb59 @    3 : 97 00             ThrowReferenceErrorIfHole [0]
   74 E> 0x34d1b322fb5b @    5 : 2b 02 03          Add a0, [3]
   87 S> 0x34d1b322fb5e @    8 : 96                Return
...SNIP...
                  -- B0 start (construct frame) --
0x30d8696041e0     0  55             push rbp
0x30d8696041e1     1  4889e5         REX.W movq rbp,rsp
0x30d8696041e4     4  56             push rsi
0x30d8696041e5     5  57             push rdi
0x30d8696041e6     6  493ba5680c0000 REX.W cmpq rsp,[r13+0xc68]
0x30d8696041ed     d  0f862a000000   jna 0x30d86960421d  <+0x3d>
                  -- B2 start --
                  -- B3 start (deconstruct frame) --
0x30d8696041f3    13  488b4510       REX.W movq rax,[rbp+0x10]
0x30d8696041f7    17  a801           test al,0x1
0x30d8696041f9    19  0f8535000000   jnz 0x30d869604234  <+0x54>
0x30d8696041ff    1f  488bd8         REX.W movq rbx,rax
0x30d869604202    22  48c1eb20       REX.W shrq rbx, 32
0x30d869604206    26  83c301         addl rbx,0x1
0x30d869604209    29  0f802a000000   jo 0x30d869604239  <+0x59>
0x30d86960420f    2f  48c1e320       REX.W shlq rbx, 32
0x30d869604213    33  488bc3         REX.W movq rax,rbx
0x30d869604216    36  488be5         REX.W movq rsp,rbp
0x30d869604219    39  5d             pop rbp
0x30d86960421a    3a  c21000         ret 0x10
...SNIP...
                  -- B0 start (construct frame) --
0x30d8696042c0     0  55             push rbp
0x30d8696042c1     1  4889e5         REX.W movq rbp,rsp
0x30d8696042c4     4  56             push rsi
0x30d8696042c5     5  57             push rdi
0x30d8696042c6     6  4883ec08       REX.W subq rsp,0x8
0x30d8696042ca     a  493ba5680c0000 REX.W cmpq rsp,[r13+0xc68]
0x30d8696042d1    11  0f8649000000   jna 0x30d869604320  <+0x60>
                  -- B2 start --
                  -- B3 start --
0x30d8696042d7    17  488b45f8       REX.W movq rax,[rbp-0x8]
0x30d8696042db    1b  488b582f       REX.W movq rbx,[rax+0x2f]
0x30d8696042df    1f  49395da8       REX.W cmpq [r13-0x58],rbx
0x30d8696042e3    23  0f844e000000   jz 0x30d869604337  <+0x77>
                  -- B4 start (deconstruct frame) --
0x30d8696042e9    29  488b5510       REX.W movq rdx,[rbp+0x10]
0x30d8696042ed    2d  f6c201         testb rdx,0x1
0x30d8696042f0    30  0f8568000000   jnz 0x30d86960435e  <+0x9e>
0x30d8696042f6    36  f6c301         testb rbx,0x1
0x30d8696042f9    39  0f8564000000   jnz 0x30d869604363  <+0xa3>
0x30d8696042ff    3f  48c1eb20       REX.W shrq rbx, 32
0x30d869604303    43  488bca         REX.W movq rcx,rdx
0x30d869604306    46  48c1e920       REX.W shrq rcx, 32
0x30d86960430a    4a  03d9           addl rbx,rcx
0x30d86960430c    4c  0f8056000000   jo 0x30d869604368  <+0xa8>
0x30d869604312    52  48c1e320       REX.W shlq rbx, 32
0x30d869604316    56  488bc3         REX.W movq rax,rbx
0x30d869604319    59  488be5         REX.W movq rsp,rbp
0x30d86960431c    5c  5d             pop rbp
0x30d86960431d    5d  c21000         ret 0x10
...SNIP...
$
```

Ignition использует байткод `LdaImmutableCurrentTextSlot`, поскольку это слот контекста `const`, но *специализация контекста функции* запускается только для первого замыкания. Второе замыкание получает новый оптимизированный код, который не специализирован. Причина этого заключается в том, что если у вас есть несколько замыканий для функции, мы хотели бы выделить общий код для различных замыканий, поскольку создание отдельного объекта кода для каждого замыкания было бы пустой тратой ресурсов (как времени, так и памяти). Если вы используете стрелочные функции с функциями более высокого порядка, например,

```javascript
let b = a.map(x => x + 1);
```

вы не хотите, чтобы оптимизирующий компилятор запускался каждый раз, когда вы выполняете эту строку, просто для создания специализированного кодового объекта для `x => x + 1`. Итак, здесь простое правило: вы получаете *специализацию контекста функции* только для первого замыкания каждой функции в любом заданном `<iframe>` (родной контекст в понятиях V8). Нативный контекст не применяется в Node.js, поскольку там у вас есть только один нативный контекст, за исключением случаев использования модуля `vm`.

Теперь, учитывая, что `class` подобен `let`, то есть это изменчивое (мутабельное) связывание (опять же по причинам, которые я не выбирал), вы не обязательно получаете выгоду от *специализации контекста функции* при использовании классов. Рассмотрим `ex7.js`:

```javascript
class A {};

function makeA() { return new A; }

makeA();
makeA();
%OptimizeFunctionOnNextCall(makeA);
makeA();
```

Исследуя байткод и оптимизированный код для `makeA`, мы наблюдаем следующее:

```
$ out/Release/d8 --print-bytecode --allow-natives-syntax --print-opt-code --code-comments ex7.js
...SNIP...
[generating bytecode for function: makeA]
Parameter count 1
Frame size 8
   27 E> 0x1fcce9caf75e @    0 : 92                StackCheck
   32 S> 0x1fcce9caf75f @    1 : 12 04             LdaCurrentContextSlot [4]
         0x1fcce9caf761 @    3 : 97 00             ThrowReferenceErrorIfHole [0]
         0x1fcce9caf763 @    5 : 1e fa             Star r0
   39 E> 0x1fcce9caf765 @    7 : 58 fa fa 00 03    Construct r0, r0-r0, [3]
   46 S> 0x1fcce9caf76a @   12 : 96                Return
...SNIP...
                  -- B0 start (construct frame) --
0x19518f5041e0     0  55             push rbp
0x19518f5041e1     1  4889e5         REX.W movq rbp,rsp
0x19518f5041e4     4  56             push rsi
0x19518f5041e5     5  57             push rdi
0x19518f5041e6     6  4883ec08       REX.W subq rsp,0x8
0x19518f5041ea     a  493ba5680c0000 REX.W cmpq rsp,[r13+0xc68]
0x19518f5041f1    11  0f8673000000   jna 0x19518f50426a  <+0x8a>
                  -- B2 start --
                  -- B3 start --
0x19518f5041f7    17  48b821f5cae9cc1f0000 REX.W movq rax,0x1fcce9caf521    ;; object: 0x1fcce9caf521 <FixedArray[5]>
0x19518f504201    21  488b402f       REX.W movq rax,[rax+0x2f]
0x19518f504205    25  493945a8       REX.W cmpq [r13-0x58],rax
0x19518f504209    29  0f8488000000   jz 0x19518f504297  <+0xb7>
                  -- B4 start --
0x19518f50420f    2f  48bb29b9e84758150000 REX.W movq rbx,0x155847e8b929    ;; object: 0x155847e8b929 <JSFunction A (sfi = 0x1fcce9caf169)>
0x19518f504219    39  483bd8         REX.W cmpq rbx,rax
0x19518f50421c    3c  0f859c000000   jnz 0x19518f5042be  <+0xde>
0x19518f504222    42  498b8578e40300 REX.W movq rax,[r13+0x3e478]
0x19518f504229    49  488d5818       REX.W leaq rbx,[rax+0x18]
0x19518f50422d    4d  49399d80e40300 REX.W cmpq [r13+0x3e480],rbx
0x19518f504234    54  0f864a000000   jna 0x19518f504284  <+0xa4>
                  -- B6 start --
                  -- B7 start (deconstruct frame) --
0x19518f50423a    5a  488d5818       REX.W leaq rbx,[rax+0x18]
0x19518f50423e    5e  4883c001       REX.W addq rax,0x1
0x19518f504242    62  49899d78e40300 REX.W movq [r13+0x3e478],rbx
0x19518f504249    69  48bb9105294321300000 REX.W movq rbx,0x302143290591    ;; object: 0x302143290591 <Map(PACKED_HOLEY_ELEMENTS)>
0x19518f504253    73  488958ff       REX.W movq [rax-0x1],rbx
0x19518f504257    77  498b5d70       REX.W movq rbx,[r13+0x70]
0x19518f50425b    7b  48895807       REX.W movq [rax+0x7],rbx
0x19518f50425f    7f  4889580f       REX.W movq [rax+0xf],rbx
0x19518f504263    83  488be5         REX.W movq rsp,rbp
0x19518f504266    86  5d             pop rbp
0x19518f504267    87  c20800         ret 0x8
...SNIP...
$
```

Это идеальный x64 машинный код для `makeA`, в этом коде нет лишних проверок (есть две проверки: проверка стека, чтобы гарантировать, что V8 не переполняет исполняемый стек, и выталкивающая проверка указателя, чтобы запускать сборку мусора, когда новое пространство заполнено).

---

До сих пор единственным способом получить `LdaImmutableCurrentContextSlot` вместо `LdaCurrentContextSlot` было использование `const`. Но это было потому, что я демонстрировал только код, работающий на лексически связанных именах на уровне скрипта (или на верхнем уровне в `d8`). Если мы вернемся к простому примеру `let` в `ex5.js` и запустим это в Node 9 (или 8.2.0-rc1), мы увидим, что `INCREMENT` получает константу, несмотря на использование `let`:

```
$ node --print-opt-code --code-comments --allow-natives-syntax ex5.js
...SNIP...
                  -- B0 start (construct frame) --
0x2f2f61804f60     0  55             push rbp
0x2f2f61804f61     1  4889e5         REX.W movq rbp,rsp
0x2f2f61804f64     4  56             push rsi
0x2f2f61804f65     5  57             push rdi
0x2f2f61804f66     6  493ba5680c0000 REX.W cmpq rsp,[r13+0xc68]
0x2f2f61804f6d     d  0f862a000000   jna 0x2f2f61804f9d  <+0x3d>
                  -- B2 start --
                  -- B3 start (deconstruct frame) --
0x2f2f61804f73    13  488b4510       REX.W movq rax,[rbp+0x10]
0x2f2f61804f77    17  a801           test al,0x1
0x2f2f61804f79    19  0f8535000000   jnz 0x2f2f61804fb4  <+0x54>
0x2f2f61804f7f    1f  488bd8         REX.W movq rbx,rax
0x2f2f61804f82    22  48c1eb20       REX.W shrq rbx, 32
0x2f2f61804f86    26  83c301         addl rbx,0x1
0x2f2f61804f89    29  0f802a000000   jo 0x2f2f61804fb9  <+0x59>
0x2f2f61804f8f    2f  48c1e320       REX.W shlq rbx, 32
0x2f2f61804f93    33  488bc3         REX.W movq rax,rbx
0x2f2f61804f96    36  488be5         REX.W movq rsp,rbp
0x2f2f61804f99    39  5d             pop rbp
0x2f2f61804f9a    3a  c21000         ret 0x10
                  -- B4 start (no frame) --
                  -- B1 start (deferred) --
                  -- </usr/local/google/home/bmeurer/Projects/v8/ex5.js:3:14> --
0x2f2f61804f9d    3d  48bb40690e0100000000 REX.W movq rbx,0x10e6940
0x2f2f61804fa7    47  33c0           xorl rax,rax
0x2f2f61804fa9    49  488b75f8       REX.W movq rsi,[rbp-0x8]
0x2f2f61804fad    4d  e82ef6e7ff     call 0x2f2f616845e0     ;; code: STUB, CEntryStub, minor: 8
0x2f2f61804fb2    52  ebbf           jmp 0x2f2f61804f73  <+0x13>
0x2f2f61804fb4    54  e847f0cfff     call 0x2f2f61504000     ;; deoptimization bailout 0
0x2f2f61804fb9    59  e84cf0cfff     call 0x2f2f6150400a     ;; deoptimization bailout 1
...SNIP...
$
```

И аналогично, если мы запускаем `ex7.js` с биндингом `class` для `A` в Node 9 (или 8.2.0-rc1):

```
$ node --print-opt-code --code-comments --allow-natives-syntax ex7.js
...SNIP...
                  -- B0 start (construct frame) --
0x2e1f81f84e80     0  55             push rbp
0x2e1f81f84e81     1  4889e5         REX.W movq rbp,rsp
0x2e1f81f84e84     4  56             push rsi
0x2e1f81f84e85     5  57             push rdi
0x2e1f81f84e86     6  493ba5680c0000 REX.W cmpq rsp,[r13+0xc68]
0x2e1f81f84e8d     d  0f8648000000   jna 0x2e1f81f84edb  <+0x5b>
                  -- B2 start --
                  -- B3 start --
0x2e1f81f84e93    13  498b85a8ec0300 REX.W movq rax,[r13+0x3eca8]
0x2e1f81f84e9a    1a  488d5818       REX.W leaq rbx,[rax+0x18]
0x2e1f81f84e9e    1e  49399db0ec0300 REX.W cmpq [r13+0x3ecb0],rbx
0x2e1f81f84ea5    25  0f8647000000   jna 0x2e1f81f84ef2  <+0x72>
                  -- B5 start --
                  -- B6 start (deconstruct frame) --
0x2e1f81f84eab    2b  488d5818       REX.W leaq rbx,[rax+0x18]
0x2e1f81f84eaf    2f  4883c001       REX.W addq rax,0x1
0x2e1f81f84eb3    33  49899da8ec0300 REX.W movq [r13+0x3eca8],rbx
0x2e1f81f84eba    3a  48bb012f6b7ceb110000 REX.W movq rbx,0x11eb7c6b2f01    ;; object: 0x11eb7c6b2f01 <Map(PACKED_HOLEY_ELEMENTS)>
0x2e1f81f84ec4    44  488958ff       REX.W movq [rax-0x1],rbx
0x2e1f81f84ec8    48  498b5d70       REX.W movq rbx,[r13+0x70]
0x2e1f81f84ecc    4c  48895807       REX.W movq [rax+0x7],rbx
0x2e1f81f84ed0    50  4889580f       REX.W movq [rax+0xf],rbx
0x2e1f81f84ed4    54  488be5         REX.W movq rsp,rbp
0x2e1f81f84ed7    57  5d             pop rbp
0x2e1f81f84ed8    58  c20800         ret 0x8
...SNIP...
$
```

Мы видим, что это идеальный код. Причиной этому является модульная система CommonJS, используемая Node. Каждый модуль неявно завернут в функцию. Поэтому `ex7.js` в Node примерно соответствует следующему коду в Chrome или `d8`:

```javascript
(function() {
  class A {};

  function makeA() { return new A; }

  makeA();
  makeA();
  %OptimizeFunctionOnNextCall(makeA);
  makeA();
})();
```

Это упрощено (так как здесь я не хочу объяснять и [webpack](http://webpack.js.org/)). Что тут интересно, так это то, что `A` является локальным для анонимного замыкания, и, таким образом, парсер может фактически доказать, что `A` никогда не менялся после первоначального определения, потому что никакой код вне замыкания не может видеть (и не прикасаться) к биндингу `A`. Таким образом, Ignition может использовать `LdaImmutableCurrentContextSlot`, и TurboFan может генерировать потрясающий код для `makeA`:

```
$ out/Release/d8 --print-bytecode --allow-natives-syntax --print-opt-code --code-comments ex9.js
...SNIP...
[generating bytecode for function: makeA]
Parameter count 1
Frame size 8
   45 E> 0x22ac28a2f7e6 @    0 : 92                StackCheck
   50 S> 0x22ac28a2f7e7 @    1 : 13 04             LdaImmutableCurrentContextSlot [4]
         0x22ac28a2f7e9 @    3 : 97 00             ThrowReferenceErrorIfHole [0]
         0x22ac28a2f7eb @    5 : 1e fa             Star r0
   57 E> 0x22ac28a2f7ed @    7 : 58 fa fa 00 03    Construct r0, r0-r0, [3]
   64 S> 0x22ac28a2f7f2 @   12 : 96                Return
...SNIP...
                  -- B0 start (construct frame) --
0x138cd23841e0     0  55             push rbp
0x138cd23841e1     1  4889e5         REX.W movq rbp,rsp
0x138cd23841e4     4  56             push rsi
0x138cd23841e5     5  57             push rdi
0x138cd23841e6     6  493ba5680c0000 REX.W cmpq rsp,[r13+0xc68]
0x138cd23841ed     d  0f8648000000   jna 0x138cd238423b  <+0x5b>
                  -- B2 start --
                  -- B3 start --
0x138cd23841f3    13  498b8578e40300 REX.W movq rax,[r13+0x3e478]
0x138cd23841fa    1a  488d5818       REX.W leaq rbx,[rax+0x18]
0x138cd23841fe    1e  49399d80e40300 REX.W cmpq [r13+0x3e480],rbx
0x138cd2384205    25  0f8647000000   jna 0x138cd2384252  <+0x72>
                  -- B5 start --
                  -- B6 start (deconstruct frame) --
0x138cd238420b    2b  488d5818       REX.W leaq rbx,[rax+0x18]
0x138cd238420f    2f  4883c001       REX.W addq rax,0x1
0x138cd2384213    33  49899d78e40300 REX.W movq [r13+0x3e478],rbx
0x138cd238421a    3a  48bb910501aa382d0000 REX.W movq rbx,0x2d38aa010591    ;; object: 0x2d38aa010591 <Map(PACKED_HOLEY_ELEMENTS)>
0x138cd2384224    44  488958ff       REX.W movq [rax-0x1],rbx
0x138cd2384228    48  498b5d70       REX.W movq rbx,[r13+0x70]
0x138cd238422c    4c  48895807       REX.W movq [rax+0x7],rbx
0x138cd2384230    50  4889580f       REX.W movq [rax+0xf],rbx
0x138cd2384234    54  488be5         REX.W movq rsp,rbp
0x138cd2384237    57  5d             pop rbp
0x138cd2384238    58  c20800         ret 0x8
...SNIP...
$
```

Таким образом, выводы из этого упражнения:

1. Рассмотрение сгенерированного x64 машинного кода может быть пугающим.
2. Вместе с `сonst` вы получаете стоимость проверки TDZ, но это может окупиться в оптимизированном коде.
3. Использование `class` эквивалентно использованию `let`, используйте `const`, чтобы получить иммутабельную привязку к скоупу сценария.
4. Виртуальные машины JavaScript пытаются быть умными в скоупе функций (и это используется в Node и Webpack).

---

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Статья на Medium](https://medium.com/devschacht/javascript-optimization-patterns-part1-d5699fcd59a)
