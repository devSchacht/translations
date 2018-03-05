# Модульное тестирование React-приложения с помощью Jest и Enzyme

*Перевод статьи [Berry de Witte](https://facebook.com/1676107812418806): [Unit testing your React application with Jest and Enzyme](https://medium.com/wehkamp-techblog/unit-testing-your-react-application-with-jest-and-enzyme-81c5545cee45).*
 
![](https://cdn-images-1.medium.com/max/1000/1*xWtpIKyjAVuWAlz_HjCkFA.jpeg)

Я не считаю, что должен вам рассказывать про важность модульного тестирования вашего кода, поэтому я непосредственно перейду к модульному тестированию с использованием Jest и Enzyme. 

Прежде всего, что такое [Jest](https://facebook.github.io/jest/) и Enzyme? Jest был создан в Facebook и представляет собой фреймворк для тестирования кода JavaScript и React-приложений. Разработанный Airbnb [Enzyme](http://airbnb.io/enzyme/index.html) — утилита, которая идеально подходит для тестирования приложения на React.

## Снимки спешат на помощь

Давайте начнём с тестирования простого компонента без состояния (также известного как глупый компонент), который отображает простой элемент ссылки, содержащий заголовок и URL.

```js
import React from 'react';
import { string } from 'prop-types';

const Link = ({ title, url }) => <a href={url}>{title}</a>;

Link.propTypes = {
  title: string.isRequired,
  url: string.isRequired
};

export default Link;
```

Мы хотим протестировать компонент выше, проверив, приходят ли свойства в компонент и корректно ли они отображаются. С помощью Jest у нас есть очень простой способ проверки этого — создание снимка (snapshots). В первый раз, когда запускается тест, создаётся файл снимка. После этого вы можете посмотреть созданный файл, чтобы проверить, соответствует ли отрендеренный компонент ожидаемому результату. Давайте напишем первый тест для нашего компонента. В этом случае мы будем использовать [неглубокий рендеринг (shallow rendering)](http://airbnb.io/enzyme/docs/api/shallow.html) в Enzyme для создания снимка.


```js
import React from 'react';
import { shallow } from 'enzyme';
import { shallowToJson } from 'enzyme-to-json';

import Link from './Link';

describe('Link', () => {
  it('should render correctly', () => {
    const output = shallow(
      <Link title="mockTitle" url="mockUrl" />
    );
    expect(shallowToJson(output)).toMatchSnapshot();
  });
});
```

После запуска тестов Jest автоматически создаст директорию `__snapshots__` вместе с файлом снимка, содержащего результат теста. В данном случае он создаёт файл `Link-spec.js.snap`, в котором находится результат рендеринга нашего компонента `Link`.

```js
// Снимок Jest первой версии, см. документацию по адресу https://goo.gl/fbAQLP для получения подробностей
exports[`Link should render correctly 1`] = `
<a
  href="mockUrl"
>
  mockTitle
</a>
`;
```

## Имитация событий

Давайте обновить наш компонент, добавив событие `click`. Это в свою очередь означает, что мы должны переписать наш компонент, используя нотацию класса, поскольку мы собираемся привязать обработчик события `click` к компоненту. Это легко сделать, создав стрелочную функцию внутри компонента.

```js
import React, { Component } from 'react';
import { string } from 'prop-types';

class Link extends Component {
  handleClick() => {
    alert('Кликнули по ссылке!');
  };
  
  render() {
    const { title, url } = this.props;
    
    return <a href={url} onClick={this.handleClick}>{title}</a>;
  }
}
```

Если вы сейчас запустите предыдущий тест, он потерпит неудачу, так как ваш сохранённый снимок не соответствует новому снимку, потому что было добавлено свойство `onClick`. Если снимок выглядит корректно, его можно легко обновить, нажав _u_. Теперь снимок будет выглядеть так:

```js
exports[`Link should render correctly 1`] = `
<a
  href="mockUrl"
  onClick={[Function]}
  target=""
>
  mockTitle
</a>
`;
```

Мы собираемся создать второй тестовый пример для проверки того, правильно ли обработано событие `onClick`. Наш обработчик события вызывает предупреждение, и мы можем легко написать имитацию (mock) этой функциональности, используя [_jest.fn()_](http://facebook.github.io/jest/docs/jest-object.html#jestfnimplementation). После неглубокого рендеринга нашего компонента мы имитируем событие `click` и проверяем, вызывается ли предупреждение с ожидаемым содержимым. (В этом случае не создаётся снимок, поскольку мы не используем функциональность создания снимков)

```js
it('should handle the click event', () => {
  window.alert = jest.fn();
  const output = shallow(
    <Link title="mockTitle" url="mockUrl" />
  );

  output.simulate('click');
  expect(window.alert).toHaveBeenCalledWith('Кликнули по ссылке!');
});
```

## Тестирование состояния

Мы также можем легко проверить состояние нашего компонента. Обновите компонент, инициировав состояние в конструкторе, а затем используйте его с помощью функции `setState` в обработчике события `click`. При нажатии на элемент мы также собираемся обновить свойство состояние `clicked` с `false` на `true`.

```js
class Link extends Component {
  constructor(props) {
    super(props);
    this.state = { clicked: false };
  }

  handleClick = () => {
    alert('clicked');
    this.setState({ clicked: true });
  }

  // ...
}
```

Давайте создадим третий тест, который будет рендерить вывод и проверять состояние. При первой проверке свойство `clicked` состояния должно быть `false`. После клика значение свойства должно измениться на `true`.

```js
it('should handle state changes', () => {
  const output = shallow(
    <Link title="mockTitle" url="mockUrl" />
  );
  
  expect(output.state().clicked).toEqual(false);
  output.simulate('click');
  expect(output.state().clicked).toEqual(true);
});
```

## Искусство имитации

Одним из преимуществ Jest является простота создания всех видов имитации. Мы уже использовали _jest.fn()_ в одном из модульных тестов, который имитирует очень маленькую функцию, которая возвращает шпиона (spy), но можно также имитировать целые файлы.

> Если вы ничего не имитируете, то это не модульное тестирование!

Самый простой способ имитации через файлы - использовать функцию _jest.mock_, которая автоматически имитирует файл, возвращаемая имитированные функции. Попробуйте имитировать _react-dom_ и затем проверьте, была ли вызвана функция `render`.

```js
import React from 'react';
import { render } from 'react-dom';
import Link from './Link';

jest.mock('react-dom');

describe('Link', () => {
  it('should render correctly', () => {
    expect(render).toHaveBeenCalledWith(
      <Link title="mockTitle" url="mockUrl" />, 'element-node'
    );
    expect(render).toHaveBeenCalledTimes(1);
  });
});
```

Мы создаём тест как обычно, но добавляем строку с _jest.mock_. Теперь функция `render` из _react-dom_ возвращает шпион, который мы теперь можем использовать в нашем тесте для проверки, была ли она вызвана с корректными свойствами.

Если вы не хотите, чтобы Jest автоматически создавал имитированные функции вашего файла, вы можете легко создать имитированный файл самостоятельно. Просто создайте создайте директорию `__mocks__` и добавьте в неё имитированный файл. Теперь Jest будет использовать этот файл, когда вы вызываете `jest.mock` в вашем модульном тесте. В случае примера с react-dom, создайте файл `react-dom.js`, который возвращает функцию-шпион `render`.

```js
export default {
  render: jest.fn(),
};
```

В нашем примере мы возвращаем функцию шпиона, использовав которую, можно проверить, правильно ли она вызывается, хотя шпион может также возвращать значения или иметь собственную реализацию.

```js
render: jest.fn().mockReturnValue('component is rendered'),

render: jest.fn().mockImplementation(() => 'mock implementation'),
```

## Итоги

Таким образом, это самые основы модульного тестирования вашего приложения с использованием Jest и Enzyme. Оба инструмента имеют хорошую документацию, начните с этой заметки и пишите модульные тесты быстрым, эффективным и простым способом. 

Нет никакой причины не начать тестирование сегодня ;)

- - -
 
*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*
