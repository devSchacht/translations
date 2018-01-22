![Article Image](https://cdn-images-1.medium.com/max/800/1*8c333d_YNEHG4q3UDb1wTA.jpeg 'Article Image')

# Улучшаем ваш React с помощью конечных автоматов

_Перевод статьи [Jean-Paul Delimat](https://twitter.com/jpdelimat): [Boost your React with State Machines](https://medium.freecodecamp.org/boost-your-react-with-state-machines-1e9641b0aa43)._

Использование React совместно с конечными автоматами - замечательный способ для повышения вашей продуктивности как разработчика, также улучшающий часто шаткие взаимоотношения разработчиков/дизайнеров.

Идея конечного автомата очень проста: компонент может находиться в одном из состояний, число которых ограничено.

Но как это может быть полезно при разработке интерфейсов?

## Проблема

Рассмотрим простой компонент редактирования текста:

![Component States](https://cdn-images-1.medium.com/max/800/1*qH9LyaKS94HYKOfvhR1jGw.png 'Component States')
Возможные "состояния" такого компонента (слева направо):

* Отображение значения
* Редактирование значения
* Отображение состояния при сохранении
* Отображение ошибки, возникшей при сохранении

В простейшем случае состояние такого компонента может быть описано 5 свойствами:

```javascript
state: {
  processing: true, // Будет true в процессе сохранения
  error: null,      // Будет не null когда возникла ошибка сохранения
  value: null,      // Значение для отображения (только для чтения)
  edition: false,   // Находимся ли мы в режиме редактирования?
  editValue: null,  // Отредактированное, но ещё не сохраненное значение
}
```

Правильная комбинация этих свойств выдаст нам одно из 4 состояний, изображенных выше.

Проблема состоит в том, что на самом деле из этих свойств можно получить 2⁵ = 32 возможных состояний компонента. Таким образом, существует 28 неправильных способов использовать эти свойства.

Одна из распространенных ошибок при реализации таких компонентов - отсутствие удаления ошибки после успешного сохранения. Пользователь попробует сохранить поле, увидит сообщение об ошибке, исправит её, сохранит опять и попадёт в состояние отображения значения. Всё хорошо, но как только он снова переключится в состояние редактирования значения... ошибка всё еще будет отображаться. Бывает. Я много раз видел, как такие ошибки допускали менее опытные разработчики.

Несмотря на то, что наш компонент достаточно прост, он раскрывает проблему такого подхода:

Оперирование исходными свойствами состояния означает, что устойчивость состояния целиком зависит от корректного использования этих состояний... каждым разработчиком, который будет изменять этот код... на протяжении всей жизни проекта.

Все мы знаем, к чему это приводит!

## Решение

Рассмотрим другой подход с использованием "конечных автоматов". Состояния будут такими:

```javascript
state: {
  display: {
    processing: false,
    error: null,
    value: "Awesome",
    edition: false,
    editValue: null,
  },
  saving: {
    processing: true,
    error: null,
    value: "Awesome",
    edition: true, // Оставляем режим редактирования открытым, пока значение сохраняется
    editValue: "Awesome Edit",
  },
  edit: {
    processing: false,
    error: null,
    value: "Awesome",
    edition: true,
    editValue: "Awesome Editing",
  },
  save_error: {
    processing: false,
    error: "Значение должно быть не короче 4 символов",
    value: "Awesome",
    edition: true, // Оставляем окно редактирования открытым
    editValue: "Awe",
  }
}
```

Получилось более многословно, однако у такого подхода есть ряд преимуществ:

* Легко увидеть все состояния компонента, просто взглянув на конечный автомат. Состояния имеют логичные названия и каждое свойство самозадокументированно. Новые разработчики в команде почувствуют себя как дома.
* Легко понять, как расширять компонент: создаём новое состояние и выставляем соответствующие свойства. Никто в здравом уме не станет использовать обычный `setState()`, когда такой подход реализован в компоненте.
* Последнее, но не менее важное: взаимодействие с дизайнером становится простым, насколько это возможно. Вам необходим только макет для каждого из состояний, и, может быть, анимации для переходов. И всё.

Минимальная рабочая версия примера выше могла бы выглядеть так:

```javascript
import React, {Component, PropTypes} from 'react';

export default class InputStateMachine extends Component {
  constructor(props) {
    super(props);

    this.handleSubmit = this.handleSubmit.bind(this);
    this.goToState = this.goToState.bind(this);
    this.save = this.save.bind(this);

    this.state = {
      name: 'display',
      machine: this.generateState('display', props.initialValue),
    };
  }

  generateState(stateName, stateParam) {
    const previousState = this.state ? {...this.state.machine} : {};

    switch (stateName) {
      case 'display':
        return {
          processing: false,
          error: null,
          value: stateParam || previousState.value,
          editing: false,
          editValue: null,
        };
      case 'saving':
        return {
          processing: true,
          error: null, // Сброс предыдущей ошибки сохранения
          value: previousState.value,
          editing: true, // Отображение окна редактирования в процессе сохранения
          editValue: previousState.editValue,
        };
      case 'edit':
        return {
          processing: false,
          error: null,
          value: previousState.value,
          editing: true,
          editValue: stateParam,
        };
      case 'save_error':
        return {
          processing: false,
          error: stateParam,
          value: previousState.value,
          editing: true, // Оставляем окно редактирования открытым
          editValue: previousState.editValue,
        };
      case 'loading': // Идентично состоянию по умолчанию
      default:
        return {
          processing: true,
          error: null,
          value: null,
          editing: false,
          editValue: null,
        };
    }
  }

  goToState(stateName, stateParam) {
    this.setState({
      name: stateName,
      machine: this.generateState(stateName, stateParam),
    });
  }

  handleSubmit(e) {
    this.goToState('edit', e.target.value);
  }

  save(valueToSave) {
    this.goToState('saving');

    // Имитируем сохранение данных...
    setTimeout(() => this.goToState('display', valueToSave), 2000);
  }

  render() {
    const {processing, error, value, editing, editValue} = this.state.machine;

    if (processing) {
      return <p>Processing ...</p>;
    } else if (editing) {
      return (
        <div>
          <input
            type="text"
            onChange={this.handleSubmit}
            value={editValue || value}
          />
          {error && <p>Error: {error}</p>}
          <button onClick={() => this.save(editValue)}>Save</button>
        </div>
      );
    } else {
      return (
        <div>
          <p>{value}</p>
          <button onClick={() => this.goToState('edit', value)}>Edit</button>
        </div>
      );
    }
  }
}
```

Использование такого компонента:

```javascript
<InputStateMachine initialValue="Hello" />
```

При работе с конечными автоматами приходится писать немного шаблонного кода:

* Создайте утилитарный метод, который будет задавать название состояния и его содержимое. Позволяет легко получить текущее состояние и упрощает отладку компонента.
* Сохраняйте метод, генерирующий состояние компонента, чистым и используйте его для генерации изначального состояния в конструкторе.
* Используйте при деструктуризации `this.state.machine` вместо `this.state` в вашем методе `render`.
* Состоянию иногда необходимы параметры. Как правило, если ваше состояние требует более 3 параметров, вам не стоит использовать конечные автоматы в этом компоненте.

Некоторые библиотеки решают проблему дополнительного кода, но его так мало, что они вряд ли заслуживают место в зависимостях вашего проекта.

## Вывод

Конечные автоматы — хороший способ улучшения читаемости ваших компонентов и процесса разработки этих компонентов от дизайна до поддержки.

Однако будьте осторожны! Не стоит использовать этот подход на всех компонентах! Ваше приложение должно оставаться гибким и обрабатывать непредвиденные сложности. Количество состояний для компонентов высокого уровня может быстро возрасти и такой подход не даст никакой пользы.

Несмотря на это, используйте такой подход при разработке вашей библиотеки стандартных/базовых компонентов! Это основа вашего приложения. Рано или поздно каждый разработчик в команде будет с ней работать и сможет на себе ощутить пользу конечных автоматов.

Спасибо за прочтение!

---

_Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht)._
