# Использование vue-template-loader с Vue.js для компиляции шаблонов HTML

*Перевод статьи [Akanksha Sharma](https://github.com/Akanksha-26): [Using vue-template-loader with Vue.js to Compile HTML Templates](https://alligator.io/vuejs/vue-template-loader/).*

> Большинство людей, знакомых с Angular 2+, знают, что для компиляции HTML-шаблонов просто нужно добавить URL-адрес шаблона в TypeScript-файл компонента и дело с концом. В случае Vue рекомендуется использовать теги `<template>` для сборки разметки шаблона в подавляющем большинстве случаев. 

Мы можем использовать [vue-template-loader](https://github.com/ktsn/vue-template-loader), если хотим использовать Vue со способом сборки шаблонов, как в Angular. Поскольку __vue-template-loader__ поддерживает `vue-class-component`, мы можем использовать декораторы для стилевых классов компонентов (class-styled components).

> vue-template-loader компилирует HTML в отдельные функции отрисовки в соответствующих TypeScript- или JavaScript-файлах.

## Установка

Нам понадобится обычный проект `Vue.js` вместе с зависимостями `webpack`.

Установите `vue-template-loader`, используя `yarn` или `npm`, например так:

```bash
# yarn
$ yarn add vue-template-loader

# npm
$ npm install vue-template-loader
```

## Конфигурация webpack для JavaScript

Теперь мы можем интегрировать __vue-template-loader__ с использованием `webpack`.

Добавьте `vue-template-loader` в качестве правила в вашем конфигурационном файле `webpack.config.js`:

```js
module.exports = {
  module: {
    rules: [
        {
          test: /\.html$/,
          loader: 'vue-template-loader',
          // Мы не хотим передавать файл `src/index.html` этому загрузчику.
          exclude: /index.html/,
        }
    ]
  }
}
```

Отрисовку ресурсов, используемых в HTML-шаблоне, связанных с обработкой атрибута `src` в тегах, можно указать с помощью опций:

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.html$/,
        loader: 'vue-template-loader',

        // Мы не хотим передавать файл `src/index.html` этому загрузчику.
        exclude: /index.html/,
        options: {
          transformToRequire: {
            img: 'src'
          }
        }
      }
    ]
  }
}
```

Обратите внимание, что для работы вышеуказанных опций также необходимо добавление загрузчика для обработки файлов изображений (см. [file-loader](https://github.com/webpack-contrib/file-loader)).

## Конфигурация для TypeScript

Если мы хотим использовать __vue-template-loader__ с TypeScript, нам нужны зависимости `tsloader` и `typescript`, установленные в проекте вместе с `webpack`.

> `vue-template-loader` используется аналогичным образом для конфигурации webpack как для JavaScript, так и для TypeScript.

Единственное дополнение будет в каталоге `typings` нашего проекта. Нам нужно добавить шим в `typings`, чтобы TypeScript понимал файлы `.vue`:

```ts
// Для работы/импорта файлов *.vue в TypeScript, требуется шим
declare module '*.vue' {
  import Vue from 'vue';
  export default Vue;
}

// Определение типа модуля TypeScript, требуемого vue-template-loader
declare module '*.html' {
  import Vue, { ComponentOptions } from 'vue';

  interface WithRender {
    <V extends Vue>(options: ComponentOptions<V>): ComponentOptions<V>
    <V extends typeof Vue>(component: V): V
  }

  const withRender: WithRender
  export = withRender
}
```

## Использование в файлах JavaScript/TypeScript

Теперь давайте создадим файл с шаблоном с названием `nest.html`:

```html
<div class="nest">
  <p>{{ text }}</p>
  <button type="button" @click="baz()">Нажми на меня!</button>
</div>
```

Теперь давайте добавим файл `nest.js`, использующий `nest.html`. Мы может использовать __vue-template-loader__ с или без декораторов класса, используя `es6` с `Vue`:

```js
// Без декораторов класса в JavaScript
import withRender from './nest.html';

export default withRender({
  data () {
    return {
      text: 'Я крокодил'
    };
  },
  methods: {
    baz () {
      console.log('Кнопка нажата!');
    };
  };
});
```

```js
// С декораторами
import Vue from 'vue';
import Component from 'vue-class-component';
import WithRender from './nest.html';

@WithRender
@Component
export default class Nest extends Vue {
  text = 'Я крокодил!';

  baz() {
    console.log('Кнопка нажата!');
  }
}
```

Его также можно использовать в TypeScript следующим образом в файле `nest.ts`:

```ts
import Vue from 'vue';
import { Component } from 'vue-property-decorator';
import WithRender from './nest.html';

@WithRender
@Component({})
export default class NestComponent extends Vue {
  data() {
    return {
      text: 'Я крокодил!'
    }
  };

  baz() {
    console.log('Кнопка нажата!');
  }
};
```

## Вывод

Использование __vue-template-loader__ обеспечивает отличную поддержку TypeScript, а также может уменьшить количество компилируемых файлов, так как исключаются файлы `.vue`. Наконец, это очень легко понять людьми, работающими с Angular.

- - - -

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*
