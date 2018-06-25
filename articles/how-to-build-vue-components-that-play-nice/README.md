# Как писать Vue-компоненты, которые хорошо взаимодействуют

*Перевод статьи [Kevin Ball](https://twitter.com/@kball11): [How To Build Vue Components That Play Nice](https://vuejsdevelopers.com/2018/06/18/vue-components-play-nicely/).*

Очень мало людей, которые пишут Vue-компоненты, изначально собираются выложить их в открытый доступ.
Большинство из нас начинают писать компоненты для себя: у нас проблема, мы хотим её решить, написав компонент.
Иногда мы хотим решить одну и ту же проблему в новых местах нашей кодовой базы, и поэтому берём наш компонент
и рефакторим его немного для того, чтобы сделать его повторно используемым. Затем мы хотим использовать его в другом проекте,
и поэтому переносим его в отдельный пакет. И тогда у нас возникает мысль: «Эй, почему бы не поделиться этим с миром?»,
так что делаем такой компонент свободно доступным.

С одной стороны, это здорово, что означает большую и растущую доступность компонентов с открытым исходным кодом для всех,
кто работает с Vue ([поиск по «vue» на npmjs.com](https://www.npmjs.com/search?q=vue) показывает более 13 000 пакетов).

С другой стороны, поскольку большинство из этих компонентов эволюционировали из конкретной ситуации, и не у всех из нас 
имеется опыт разработки компонентов для повторного использования во многих окружениях,
многие из них не "хорошо взаимодействуют" (в оригинале "play nice" — прим. пер.) с экосистемой Vue.

Что значит "хорошо взаимодействует"? На высоком уровне это означает, что он выглядит вполне естественным для разработчиков
Vue, а также его легко расширить и интегрировать в любое приложение.

После изучения широкого ассортимента компонентов с открытым исходным кодом, вот что я думаю о Vue-компонентов,
которые хорошо взаимодействуют:

1. Реализована совместимость с `v-model`
1. Прозрачны для событий
1. Присваивают атрибуты нужным элементам
1. Придерживаются норм браузеров для навигации по клавиатуре
1. Отдают предпочтение событиям, а не колбэкам
1. Ограничивают стили внутри компонентах

## Реализована совместимость с `v-model`

Для компонентов, которые по сути являются полями формами — будь то автозаполнение полей для поиска, поля с календарём
для ввода даты или что-то ещё, которые реализуют дополнительную функциональность для одного поля, позволяющую пользователю
указывать данные — одним из наиболее важных способов быть естественным для Vue является поддержка `v-model`.

Согласно [руководству Vue по компонентам](https://ru.vuejs.org/v2/guide/components.html#%D0%98%D1%81%D0%BF%D0%BE%D0%BB%D1%8C%D0%B7%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5-v-model-%D0%BD%D0%B0-%D0%BA%D0%BE%D0%BC%D0%BF%D0%BE%D0%BD%D0%B5%D0%BD%D1%82%D0%B0%D1%85) `v-model` на компонентах, в основном, работает передачей свойства `value` с применением обработчиком событий `input`.

Например, если мы реализовывали элемент ввода даты, который оборачивает поле ввода,
мы бы инициализировали его с использованием свойства `value`, а при выборе даты вызывалось событие `input`,
в итоге код выглядел следующим образом:

```js
import datepicker from 'my-magic-datepicker';

export default {
  props: ['value'],
  mounted() {
    datepicker(this.$el, {
      date: this.value,
      onDateSelected: (date) => {
        this.$emit('input', date);
      },
    });
  }
}
``` 

## Прозрачны для событий

Для реализации поддержки `v-model` необходимо реализовать событие `event`. 
Но как насчёт других событий, таких как события нажатий, управление с клавиатуры и т.д.?
В то время как нативные события всплывают в HTML, обработчики событий во Vue по умолчанию не делают это.

Например, если я сделаю что-то подобное, это не сработает:

```html
<my-textarea-wrapper @focus="showFocus">
```

До тех пор, пока мы не напишем код в компоненте-обёртке, который на самом деле генерирует событие `focus`,
обработчик события `showFocus` никогда не будет вызван. _Однако_ Vue предоставляет нам способ для доступа к применяемым
компоненту обработчикам событий, поэтому мы можем присвоить в нужным месте объект `$listeners`.

```js
<div class="my-textarea-wrapper">
  <textarea v-on="$listeners"></textarea>
</div>
```

Теперь события, которые происходят на текстовом многострочном поле, будут всплывать как обычно.

## Присваивают атрибуты нужным элементам

Как насчёт таких атрибутов как `rows` для полей с текстовыми областями или `title` для добавления простой подсказки
к любому атрибуту через соответствующий HTML-атрибут.

По умолчанию Vue принимает атрибуты, применяемые к атрибуту, и помещает их в корневой элемент этого компонента.
Это не всегда, что вам нужно. Однако, если мы снова посмотрим на обёртка над тегом `textarea`, то в этом случае имело
смысл применять атрибуты к самому элементу, а не оборачивающему тегу `div`.

Чтобы сделать это, мы указываем компоненту не применять атрибуты по умолчанию, а вместо это назначает их непосредственно,
используя объект `$attrs`. В нашем JavaScript-коде:

```js
export default {
  inheritAttrs: false,
}
```

А затем в нашем шаблоне:

```html
<div class="my-textarea-wrapper">
  <textarea v-bind="$attrs"></textarea>
</div>
```

## Придерживаются норм браузеров для навигации по клавиатуре

Доступность и навигация с помощью клавиатуры — одно из наиболее часто забываемых частей веб-разработки, и одновременно
все они являются важны для правильного сделанного компонента, если вам нужен такой компонент, который хорошо взаимодействует
в экосистеме.

В основе этого лежит соответствие стандартам браузера: клавиша табуляция должна позволять выбирать поля формы.
Клавиша ввода обычно используется для нажатия на кнопку или перехода по ссылке.

Полный список навигаций по клавиатуре для стандартных компонентов можно найти на [сайте W3C](https://www.w3.org/TR/wai-aria-practices/#aria_ex). 
Следуя этим рекомендациям, ваш можно будет использовать компонент во всех приложениях, а не только в тех, которым нужна доступность.

## Отдают предпочтение событиям, а не колбэкам

Когда дело до взаимодействия данными и пользовательскими действиями от вашего компонента к его родителям, то есть два
распространённых варианта: колбэки в входных параметрах (они же свойства) и события. Поскольку пользовательские события
не всплывают как нативные браузерные события, они функционально одинаковы, но для возможности повторного использования
я почти всегда рекомендую использовать события вместо колбэков. Почему?

В [одном выпуске подкаста Fullstack Radio](http://www.fullstackradio.com/87) Крис Фриц, член основной команды Vue, привёл следующие причины: 

1. Использование событий делают компонент очень ясным в плане того, что должны о нём знать родительские компоненты.
    Он создаёт чёткое разделение между тем, что получено от родительских компонентов и тем, что отравлено им.
1. Вы можете использовать выражения непосредственно в обработчиках событий, позволяя держать их очень компактными для обычных случаев.
1. Это больше соответствует Vue — примеры и документация Vue обычно используют события для связи взаимодействия компонента с родительскими компонентами.    

К счастью, если вы используете подход «колбэки в свойствах» (callbacks-in-props), довольно просто изменить компонент для генерации событий вместо этого.
Компонент, использующий колбэки, может быть таким:

```js
// файл my-custom-component.vue
export default {
  props: ['onActionHappened', ...]
  methods() {
    handleAction() {
      // остальной код...
      if (typeof this.onActionHappened === 'function') {
        this.onActionHappened(data);
      }
    }
  }
}
```

Далее при его использование может выглядит так:

```html
<my-custom-component :onActionHappened="actionHandler" />
```

Переход на новый подход, основанный на событиях, будет выполнен следующим образом:

```js
// файл my-custom-component.vue
export default {
  methods() {
    handleAction() {
      // остальной код...
      this.$emit('action-happened', data);
    }
  }
}
```

И использование компонента изменится на:

```html
<my-custom-component @action-happened="actionHandler" />
```

## Ограничивают стили внутри компонентах

Однофайловые компоненты позволяют встраивать стили непосредственно в в компоненты,
и особенно в сочетании с ограничением области видимости CSS через атрибут `scoped` даёт нам отличный способ использовать
полностью упакованные, стилизованные компоненты таким образом, чтобы они не влияли на другие части приложения.

Из-за мощи такой возможности может возникнуть соблазн поместить все ваши стили компонента в сам компонент и отправлять
в открытый доступ такой полностью стилизованный компонент. Здесь следующая проблема: не все стили приложения одинаковые,
и те стили, из-за которых ваше приложение выглядит хорошо, в чьём-то другом приложении будет выглядит как бельмо в глазу.

Для предотвращения этого, я рекомендую, чтобы любые структурные CSS-стили (цвета, рамки, тени и т.д.) должны либо
исключены из самого файла компонента, либо должны быть доступны для отключения. Вместо этого рассмотрите возможность
использование пользовательского настраиваемого файла (partial) SCSS, который позволит пользователям вашего компонента 
стилизовать его как душе угодно.

Недостаток использования SCSS заключается в том, что вашим пользователям нужно включать этот файл в свою систему сборки
для компиляции стилей в CSS, иначе им будет показан компонент без стилей. Для получения лучшего из обоих миров, вы можете
ограничить область действия стилей в файле компонента служебным классом, передаваемый через входные параметры (свойств),
для отключения стилей по умолчанию и удовлетворения потребностей тех пользователей, которые хотят иметь собственное оформление компонента.
Если вы структурируете ваш SCSS как миксин, вы могли бы использовать одинаковый SCSS для пользователей, требующим применения больше своих стилей.

```html
<template>
  <div :class="isStyledClass">
    <!-- мой компонент -->
  </div>
</template>
```

Далее в вашем JavaScript-коде компонента:

```js
export default {
  props: {
    disableStyles: {
      type: Boolean,
      default: false
    }
  },
  computed: {
    isStyledClass() {
      if (!this.disableStyles) {
        return 'is-styled';
      }
  },
}
```

Тогда вы сможете использовать так:

```css
@import 'my-component-styles';

.is-styled {
  @include my-component-styles();
}
```

Данное решение позволит стилизовать компонент из коробки, но даёт возможность пользователям определять собственную
стилизацию компонента с помощью установки свойства `disableStyles` в значение `true` без всякого переопределения стилей
с более высокой специфичностью, либо использовать ваш миксин с их стилями, или вообще полностью с нуля стилизовать компонент.

- - - -

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*