# Написание абстрактных компонентов во Vue.js

*Перевод статьи [Joshua Bemenderfer](https://twitter.com/@tribex_): [Writing Abstract Components with Vue.js](https://alligator.io/vuejs/vue-abstract-components/).*

> Компоненты Vue великолепны, не так ли? Они инкапсулируют представление и поведение приложения в красивые небольшие компонуемые части. Если вам нужна небольшая дополнительная функциональность, просто присоедините директивы! Дело в том, что директивы довольно негибкие и не подходят для всего. Например, директивы не могут (казалось бы самое простое?) генерировать события. Что ж, это Vue и, конечно, есть решение — абстрактные компоненты!

Абстрактные компоненты похожи на обычные компоненты, за исключением того, что они ничего не отрисовывают в DOM, а просто добавляют дополнительное поведение к существующим компонентам. Вам наверняка знакомы встроенные абстрактные компоненты Vue, такие как `<transition>`, `<component>` и `<slot>`.

Отличный вариант использования абстрактных компонентов наблюдается, когда элемент входит в область просмотра с помощью `IntersectionObserver`. Давайте посмотрим на реализацию простого абстрактного компонента для обработки такой ситуации.

> Если вам нужна соответствующая готовая для продакшена реализация, взгляните на [vue-intersect](https://github.com/heavyy/vue-intersect), на котором основана эта статья.

## Приступаем к работе

Сначала на скорую руку создадим компонент, который просто отрисовывает его содержимое. Для этого мы ненадолго посмотрим на функции отрисовки.

Файл `IntersectionObserver.vue`:

```js
export default {
   // Включает абстрактный компонент во Vue.
   // Это свойство не задокументировано и может измениться в любой момент,
   // но ваш компонент должен работать без него.
  abstract: true,
  // Ура, функция отрисовки!
  render() {
    // Без компонента-обёртки мы можем отрисовать только один дочерний компонент.
    try {
      return this.$slots.default[0];
    } catch (e) {
      throw new Error('IntersectionObserver.vue может отрисовывать один и только один дочерний компонент.');
    }

    return null;
  }
}
```

Поздравляем! У вас теперь есть абстрактный компонент, который, ну, ничего не делает! Отрисовкой занимается дочерний компонент.

## Добавление IntersectionObserver

Хорошо, теперь давайте добавим логики для `IntersectionObserver`.

> Внимание: IntersectionObserver изначально не поддерживается IE или Safari, поэтому вам может понадобиться для него полифил

Файл `IntersectionObserver.vue`:

```js
export default {
  // Остальной код из предыдущего примера...

  mounted () {
    // Нет реальной потребности объявлять наблюдателя в качестве свойства данных,
    // потому что он не должен быть реактивным.

    this.observer = new IntersectionObserver((entries) => {
      this.$emit(entries[0].isIntersecting ? 'intersect-enter' : 'intersect-leave', [entries[0]]);
    });

    // Нужно подождать следующего тика для того, чтобы дочерний элемент смог отрисоваться.
    this.$nextTick(() => {
      this.observer.observe(this.$slots.default[0].elm);
    });
  }
}
```

Хорошо, теперь у нас есть абстрактный компонент, который можно использовать следующий образом:

```html
<intersection-observer @intersect-enter="handleEnter" @intersect-leave="handleLeave">
  <my-honest-to-goodness-component></my-honest-to-goodness-component>
</intersection-observer>
```

Однако, это ещё не конец.

## Заканчиваем работу

Нам нужно убедиться, что нет оставшихся `IntersectionObservers` при удалении компонента из DOM, поэтому давайте по-быстрому исправим это.

```js
export default {
  // Остальной код из предыдущих примеров...
  
  destroyed() {
    // Кстати, почему W3C выбрало "disconnect" для названия метода?
    this.observer.disconnect();
  }
}
```

И в качестве бонусных очков, давайте добавим настраиваемый порог видимости элемента (threshold) для наблюдателя с помощью входных параметров.

Файл `IntersectionObserver.vue`:

```js
export default {
// Остальной код из предыдущих примеров...

  // Входные параметры отлично работают в абстрактных компонентах!
  props: {
    threshold: {
      type: Array
    }
  },
  
  // Остальной код из предыдущих примеров...
  
  this.observer = new IntersectionObserver((entries) => {
    this.$emit(entries[0].isIntersecting ? 'intersect-enter' : 'intersect-leave', [entries[0]]);
  }, {
    threshold: this.threshold || 0
  });
  
  // Остальной код из предыдущих примеров...
}
```

> Полный код `IntersectionObserver.vue` можно найти [здесь](https://gist.github.com/lex111/b94f0fa80f510cc1e335321413376322)

Окончательное использование будет выглядит так:

```html
<intersection-observer @intersect-enter="handleEnter" @intersect-leave="handleLeave" :threshold="[0, 0.5, 1]">
  <my-honest-to-goodness-component></my-honest-to-goodness-component>
</intersection-observer>
```

Вот и всё, ваш первый абстрактный компонент!

Большое спасибо Thomas Kjærgaard / Heavyy за [первоначальную реализацию и идею](https://github.com/heavyy/vue-intersect)!

- - - -

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*
