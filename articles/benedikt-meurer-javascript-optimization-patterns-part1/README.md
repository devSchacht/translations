# Паттерны оптимизации JavaScript. Часть 1
![](https://cdn-images-1.medium.com/max/2000/1*qSdEsX-Ba0LHDXSQ3PZ1rA.jpeg)

*Перевод статьи [Benedikt Meurer](http://benediktmeurer.de): [JavaScript Optimization Patterns (Part 1)](http://benediktmeurer.de/2017/06/20/javascript-optimization-patterns-part1/).*

Прошло время с моего последнего сообщения в блоге, главным образом из-за того, что мне не хватало времени или сил, чтобы сесть и написать все, что я хотел рассказать. Частично это было потому, что я был очень занят [запуском `Ignition` и `TurboFan`](https://v8project.blogspot.com/2017/05/launching-ignition-and-turbofan.html) в `Chrome 59`, что, к счастью, завершилось успехом. Частично из-за того, что я хотел провести время с семьей. И последнее, но не менее важное, я участвовал в [JSConf EU](https://2017.jsconf.eu/) и [Web Rebels](https://www.webrebels.org/), и на момент написания этой статьи я нахожусь на [enterJS](https://www.enterjs.de/), прокрастинируя вместо отшлифовки последних правок в моём докладе.

Тем временем я только что вернулся с очень интересного обеденного обсуждения с [Брайаном Терлсоном](https://twitter.com/bterlson), [Адой Роуз Эдвардс](https://twitter.com/Lady_Ada_King) и [Эшли Уильямс](https://twitter.com/ag_dubs) о *хороших подходах к оптимизации* JavaScript, которые мы можем дать в качестве совета, и в частности, о том, как трудно их вывести. Один конкретный вывод, который я сделал, заключался в том, что идеальная производительность часто зависит от контекста, в котором работает код, и это часто самая сложная часть. Поэтому я подумал, что, вероятно, стоит поделиться этой информацией со всеми. Я начну это как серию сообщений в блоге. В этой первой части я попытаюсь выделить влияние, которое может оказать конкретный контекст выполнения на производительность вашего JavaScript-кода.

Рассмотрим следующий искусственный класс `Point`, имеющий метод `distance`, который вычисляет [«манхэттенское расстояние»](https://ru.wikipedia.org/wiki/Расстояние_городских_кварталов) между двумя точками.

```javascript
class Point {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }

  distance(other) {
    const dx = Math.abs(this.x - other.x);
    const dy = Math.abs(this.y - other.y);
    return dx + dy;
  }
}
```

В дополнение к этому рассмотрим следующую тестирующую функцию, создающую пару экземпляров `Point` и вычисляющую расстояние между ними несколько миллионов раз, суммируя результат (да, я знаю, что это микро-бенчмарк, но потерпите немножко):

```javascript
function test() {
  const points = [
    new Point(10, 10),
    new Point(1, 1),
    new Point(8, 9)
  ];
  let result = 0;
  for (let i = 0; i < 10000000; ++i) {
    for (const point1 of points) {
      for (const point2 of points) {
        result += point1.distance(point2);
      }
    }
  }
  return result;
}
```

Теперь у нас есть правильный бенчмарк для класса `Point` и, в частности, его метод `distance`. Давайте проведём несколько запусков тестирующей функции, чтобы узнать, что такое производительность, используя следующий HTML-сниппет:

```html
<script>
    function test() {
        class Point {
            constructor(x, y) {
                this.x = x;
                this.y = y;
            }

            distance(other) {
                const dx = Math.abs(this.x - other.x);
                const dy = Math.abs(this.y - other.y);
                return dx + dy;
            }
        }

        const points = [
            new Point(10, 10),
            new Point(1, 1),
            new Point(8, 9)
        ];
        let result = 0;
        for (let i = 0; i < 10000000; ++i) {
            for (const point1 of points) {
                for (const point2 of points) {
                    result += point1.distance(point2);
                }
            }
        }
        return result;
    }

    for (let i = 1; i <= 5; ++i) {
        console.time("test " + i);
        test();
        console.timeEnd("test " + i);
    }
</script>
```

Если вы запустите это в Chrome 61 (Canary), в консоли Chrome Developer Tools вы увидите следующий вывод:

```
test 1: 595.248046875ms
test 2: 765.451904296875ms
test 3: 930.452880859375ms
test 4: 994.2890625ms
test 5: 3894.27392578125ms
```

Производительность отдельных прогонов очень противоречива. Вы можете видеть, что производительность становится хуже с каждым последующим запуском. Причина регрессии производительности заключается в том, что класс `Point` находится внутри тестирующей функции.

```html
<script>
    class Point {
        constructor(x, y) {
            this.x = x;
            this.y = y;
        }

        distance(other) {
            const dx = Math.abs(this.x - other.x);
            const dy = Math.abs(this.y - other.y);
            return dx + dy;
        }
    }

    function test() {
        const points = [
            new Point(10, 10),
            new Point(1, 1),
            new Point(8, 9)
        ];
        let result = 0;
        for (let i = 0; i < 10000000; ++i) {
            for (const point1 of points) {
                for (const point2 of points) {
                    result += point1.distance(point2);
                }
            }
        }
        return result;
    }

    for (let i = 1; i <= 5; ++i) {
        console.time("test " + i);
        test();
        console.timeEnd("test " + i);
    }
</script>
```

Если мы немного изменим фрагмент кода таким образом, чтобы класс `Point` был определен вне тестовой функции, мы получим другие результаты:

```
test 1: 598.794921875ms
test 2: 599.18115234375ms
test 3: 600.410888671875ms
test 4: 608.98388671875ms
test 5: 605.36376953125ms
```

Теперь производительность довольно стабильна с небольшим шумом. Обратите внимание, что в обоих случаях мы использовали точно такой же код для класса `Point` и точно такой же код для логики тестового драйвера. Единственное различие заключается в том, где именно мы размещаем класс `Point` в коде.

![](http://benediktmeurer.de/images/2017/class-20170620.png)

Также стоит отметить, что это не связанно с новым синтаксисом `class` ES2015: при использовании старого ES5-синтаксиса для класса `Point` мы получим такие же результаты.

```javascript
function Point(x, y) {
  this.x = x;
  this.y = y;
}
Point.prototype.distance = function (other) {
  var dx = Math.abs(this.x - other.x);
  var dy = Math.abs(this.y - other.y);
  return dx + dy;
}
```

Основная причина разницы в производительности, когда объявление класса `Point` расположено внутри функции `test`, заключается в том, что литерал `class` выполняется несколько раз (ровно 5 раз в моем примере выше), тогда как если он расположен вне функции `test`, он выполняется только один раз. Каждый раз, когда выполняется определение класса, создаётся новый объект-прототип, содержащий все методы класса. В дополнение к этому создаётся новый конструктор, соответствующий классу и имеющий объект прототипа, заданный как свойство `prototype`.

![](http://benediktmeurer.de/images/2017/devtools-20170620.png)

Новые экземпляры класса создаются с использованием этого свойства `prototype` в качестве объекта прототипа. Но так как V8 отслеживает прототип экземпляра как часть формы объекта или скрытого класса (см. раздел «[Setting up prototypes in V8](https://medium.com/@tverwaes/setting-up-prototypes-in-v8-ec9c9491dfe2)»), чтобы оптимизировать доступ к свойствам в цепочке прототипов, наличие разных прототипов автоматически подразумевает наличие разных форм у этих объектов. И как таковой сгенерированный код становится все более полиморфным с каждым новым определение класса, и, в конце концов, V8 отказывается от полиморфизма после того, как он видит более четырёх различных форм объектов и входит в так называемое мегаморфное состояние, что означает отказ от генерации высоко оптимизированного кода.

Таким образом, вывод из этого упражнения: идентичный код, помещенный в другое место, может легко привести к разнице в производительности в 6,5 раз! Это особенно важно, потому что популярные платформы для бенчмарков и сайты, такие как [esbench.com](https://esbench.com), как правило, выполняют код в другом контексте, чем ваше приложение (например, код вспомогательных функций-обёрток, запускающихся несколько раз), и, таким образом, результаты бенчмарков могут ввести в сильное заблуждение.

---

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*

[Статья на Medium](https://medium.com/devschacht/javascript-optimization-patterns-part1-d5699fcd59a)
