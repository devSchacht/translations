# Обрабатываем вызовы api изящным образом

[Оригинал](https://blog.angularindepth.com/handle-api-call-state-nicely-445ab37cc9f8)

В этой статье я расскажу о способе обработки состояний для вызовов API и сокращения стандартного шаблона путем сбора общей логики в абстракцию. Этот способ мощный, чистый, и менее подвержен ошибкам. В этой статье предполагается, что мы используем [NgRx](https://ngrx.io/) для управления состоянием.

Бьюсь об заклад, что наличие API вызовов являются одним из самых распространенных требований для веб-разработки. Многие приложения имеют массу API вызовов. С точки зрения пользовательского опыта всегда полезно указывать состояние вызова API, например, показывать крутилку или сообщение об ошибке. Я видел много способов моделирования состояния вызова API и нашел одну главную проблему: **тяжелый шаблон**, который обычно вызывает дальнейшие проблемы.

## Тяжелый шаблон

Например, предположим следующее бизнес требование:

1. Отправить запрос API, чтобы получить список сегодняшних новостей.
2. Показать крутилку во время загрузки
3. Показать загруженный список новостей при успехе загрузки.

Многие разработчики проектируют модель состояния следующим образом вместе с двумя действиями (скажем, `LoadNews` и `LoadNewsSuccess`, и двумя случаями редуктора для изменения состояния `loading` и `entities`).

```export interface News {
    loading: boolean;
    entities: string[];
}
```

Пока что мы не видим здесь никаких проблем. Это крепкий «стандарт».

Допустим, у нас есть 20 (или даже больше) запросов API в этом приложении. Теперь появляются проблемы:

1. **Много шаблонов.** Нам нужно обработать состояние API `loading` 20 раз, 40 действий и реализовать 40 случаев редуктора. Это много кода с повторяющейся логикой.

2. **Несогласованное именование.** Допустим, 20 вызовов API реализованы 4 разработчиками. Они могут иметь разные соглашения об именах. Например, загрузка может быть `isLoading`, `waiting`, `isWaiting`, `started` и т. д.

На самом деле, приведенная выше модель состояния API имеет только одно состояние `loading`. Однако предполагается, что полный набор будет иметь больше состояний API (о которых пойдет речь в следующем разделе), что сделает предыдущие 2 пункта еще хуже.

Давайте решим эту проблему изящно.

## Что такое полный набор состояний?

Полный цикл вызовов API может иметь следующие состояния:

1. Вызов API не запущен
2. Вызов API начался, но ответа пока нет
3. API-вызов получил успешный ответ
4. Вызов API получил ответ об ошибке

Таким образом, мы можем спроектировать общую модель следующим образом (назовем ее `Loadable`):

```
export interface Loadable {
    loading: boolean; 
    success: boolean; 
    error: any;
}
```

4 состояния легко сопоставить со значениями 3 полей.

Я бы также создал 4 простых вспомогательных функции для обновления загружаемого состояния. Обратите внимание, что они являются чистыми функциями и возвращают новые загружаемые объекты:

```
export function createDefaultLoadable() {
    loading: false,
    success: false,
    error: null,
}
export function onLoadableLoad(loadable) {
  return {
    ...loadable,
    loading: true,
    success: false,
    error: null,
  };
}
export function onLoadableSuccess(loadable) {
  return {
    ...loadable,
    loading: false,
    success: true,
    error: null,
  };
}
export function onLoadableError(loadable, error) {
  return {
    ...loadable,
    loading: false,
    success: false,
    error: error,
  };
}
```

## Применить `loadable` к нашему примеру загрузки списка новостей

### Модель

Помимо 3 полей `loadable`, нам нужно еще одно состояние для хранения списка новостей, которые мы получили от API. Итак, мы можем предположить следующую модель:

```
export interface News extends Loadable {
    news: string[];
}
export function createDefaultNews(): News {
  return {
    ...createDefaultLoadable(),
    entities: []
  };
}
```

### Действия (actions)

Действия остаются такими же, как в соглашенях ngrx.

```
export enum NewsActionsTypes {
  Load = '[NEWS PAGE] LOAD NEWS',
  LoadSuccess = '[NEWS PAGE] LOAD NEWS SUCCESS',
  LoadError = '[NEWS PAGE] LOAD NEWS ERROR',
}

export class LoadNews implements Action {
  readonly type = NewsActionsTypes.Load;
}

export class LoadNewsSuccess implements Action {
  readonly type = NewsActionsTypes.LoadSuccess;
  constructor(public payload: {entities: string[]}) {}
}

export class LoadNewsError implements Action {
  readonly type = NewsActionsTypes.LoadError;
  constructor(public error: any) {}
}
export type NewsActions = LoadNews | LoadNewsSuccess | LoadNewsError
```

### Редуктор (reducer)

Мы используем редуктор, чтобы изменить состояние в соответствии с 3 различными действиями.

```
export function newsReducer(state: News = createDefaultNews(), action: NewsActions): News {
  switch (action.type) {
    case NewsActionsTypes.Load:
      return onLoadableLoad(state);
    case NewsActionsTypes.LoadSuccess:
      return {
        ...onLoadableSuccess(state),
        entities: action.payload.entities
      };
    case NewsActionsTypes.LoadError:
      return onLoadableError(state, action.error);
    default:
      return state;
  }
}
```

### Побочные эффекты (effects)

```
@Effect()
loadNews = this.actions$.pipe(
  ofType(NewsActionsTypes.Load),
  switchMap(action => {
    return this.http.get('some url').pipe(
      map((response: any) => new LoadNewsSuccess({entities: response.todaysNews})),
      catchError(error => of(new LoadNewsError(error)))
    );
  }),
);
```

### UI Component

```
@Component({
  selector: 'app-news',
  template: `
  <button (click)="load()">Load News</button>

  <!--loading spinner-->
  <p *ngIf="(news$ | async).loading">loading...</p>
  
  <p *ngFor="let item of (news$ | async).entities">{{item}}</p>
  `
})
export class NewsComponent {

  news$: Observable<News>;

  constructor(private store: Store<{news: News}>) {
    this.news$ = this.store.select(state => state.news);
  }

  load() {
    this.store.dispatch(new LoadNews());
  }
}
```

Этого достаточно, чтобы заставить его работать. Тем не менее, это помогает только обеспечить согласованное именование за счет наследования `loadable`, и помогает убедиться в правильности изменения состояния с помощью вспомогательных функций. Это действительно не уменьшает шаблон. Представьте, что если у нас есть 20 вызовов API, нам все равно нужно обрабатывать каждое действие (load, loadSuccess, loadError) в каждом из 20 редукторов. И 20 из них имеют одинаковую логику смены состояний. (то есть `loading` `success` `error`)

## Абстрактная логика изменения состояния API от редуктора

Давайте определим функцию более высокого порядка `withLoadable`, которая принимает в качестве параметров редуктор, три строки типа действия, и возвращает новый улучшенный редуктор.

```
export function withLoadable(baseReducer, {loadingActionType, successActionType, errorActionType}) {
  return (state, action) => {
    if (action.type === loadingActionType) {
      state = onLoadableLoad(state);
    }
    if (action.type === successActionType) {
      state = onLoadableSuccess(state);
    }
    if (action.type === errorActionType) {
      state = onLoadableError(state, action.error);
    }
    return baseReducer(state, action);
  };
}
```

Таким образом, редуктор для новостей может быть таким:

```
// базовый редуктор должен обновлять только не loadable состояния
function baseNewsReducer(state: News = createDefaultNews(), action: NewsActions): News {
  switch (action.type) {
    case NewsActionsTypes.LoadSuccess:
      return {
        ...state,
        entities: action.payload.entities
      };
    default:
      return state;
  }
}

// withLoadable расширяет baseReducer для обновления состояния loadable
export function newsReducer(state: News, action: NewsActions): News {
  return withLoadable(baseNewsReducer, {
    loadingActionType: NewsActionsTypes.Load,
    successActionType: NewsActionsTypes.LoadSuccess,
    errorActionType: NewsActionsTypes.LoadError,
  })(state, action);
}

```

`baseNewsReducer` обрабатывает не `loadable` состояния (то есть `entities`)

`newsReducer` на самом деле будет применять `withLoadable` к `baseReducer`, чтобы придать `baseReducer` немного «магии», т.е. способность **автоматически** обрабатывать изменения состояния `loadable`.

Таким образом, если у нас есть 20 вызовов API, и мы хотим сохранить все 20 * 3 = 60 состояний, мы можем просто применить `withLoadable` к 20 базовым редукторам. В 20 базовых редукторах нас не волнует, как должно обновляться состояние `loadable`. Таким образом, это экономит нам много времени на ручное обновление состояния API.

## Бонус: подключение `loadable` в компонент пользовательского интерфейса

На самом деле `Loadable` обеспечивает действительно согласованный контракт, так что он может быть беспрепятственно связан с глобальным компонентом пользовательского интерфейса. Например, я могу создать общий `loadable-container` компонента для обработки пользовательского интерфейса загрузки, глобальный интерфейс ошибок. И единственный контракт с внешним миром - это просто  `Loadable` в `@Input`

```
@Component({
  selector: 'loading-container',
  template: `
    <div *ngIf="loadable.loading">This is loading spinner...</div>
    <div *ngIf="loadable.error">{{loadable?.error?.message || 'Something went wrong'}}</div>
    <ng-container *ngIf="loadable.success">
        <ng-content></ng-content>
    </ng-container>
  `
})
export class LoadingContainerComponent {
  @Input() loadable: Loadable;
}
```

Это позволит нам обрабатывать каждую крутилку/ошибку вызова API, просто используя этот компонент `loadable-container`, что также экономит множество кода в шаблонах.

```
<loading-container [loadable]="news$ | async">
  <p *ngFor="let item of (news$ | async).entities">{{item}}</p>
</loading-container>
```

Пожалуйста, найдите окончательный код в [StackBlitz](https://stackblitz.com/github/zhaosiyang/loadable-example) или в [Github Repo](https://github.com/zhaosiyang/loadable-example). Единственное отличие состоит в том, что он строго напечатан, чтобы иметь лучший опыт кодирования в реальной жизни. Кроме того, он использует ложный вызов API для получения списка новостей.

Если вы хотите использовать его в своем проекте, у меня есть пакет npm для вас. Смотрите  [тут](https://www.npmjs.com/package/loadable-state).

> Примечание переводчика: примеры кода дополнены комментариями, исправлены незначительные ошибки, текст незначительно сокращён для более литературно красивого перевода.

  
