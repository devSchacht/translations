# Начните использовать ngrx/effects для этого

[Оригинал статьи](https://medium.com/r/?url=https%3A%2F%2Fblog.angularindepth.com%2Fstart-using-ngrx-effects-for-this-e0b2bd9da165) [Документация ngrx](https://medium.com/r/?url=https%3A%2F%2Fngrx.io%2Fdocs) [Справочник RxJS](https://medium.com/r/?url=https%3A%2F%2Fstackblitz.com%2Fedit%2Frxjs-aj4vwd)

Скорее всего, вы используете библиотеку эффектов (ngrx/Effects) только для коммуникации с внешним источником, вызывая побочный эффект (ngrx/Effect) с помощью действия (ngrx/Action). Но знаете ли вы, что библиотеку эффектов можно использовать для чего-то ещё?

## ngrx/Effects

Библиотека эффектов предоставляет способ изолировать побочные эффекты в своей собственной модели, вне хранилища (ngrx/Store) и компонентов Angular. Она предоставляет нам наблюдаемые действия (Observable/actions), проще говоря - поток(stream) всех отправленных (dispatched) действий. Для каждого отправленного действия она вызывает редуктор (ngrx/Reducer), и создаёт новое значение. Она также предоставляет RxJS оператор ofType, который используется для фильтрации действий по их типу.

Типичный эффект использует наблюдаемые действия в качестве источника и использует оператор ofType для выполнения своего побочного эффекта только при отправке соответствующего действия. Например, мы хотим получить список клиентов из внешнего ресурса. Для этого нам нужно создать эффект getCustomers. Этот эффект прослушивает каждое отправляемое действие, и когда он получает действие с типом [Страница клиентов] Get, то он отправляет HTTP-запрос. В зависимости от ответа эффект будет отправлять действие GetCustomersSuccess, если запрос был успешным, или действие GetCustomersFailed, если запрос вернул ошибку. Чтобы найти клиентов, мы должны отправить действие GetCustomers. Внутри нашего компонента, где мы хотим показать список всех клиентов, мы должны использовать селектор, чтобы выбрать всех клиентов из состояния хранилища.

```
    // для объявления эффекта мы используем декоратор @Effect 
    @Effect()
    getCustomers = this.actions.pipe(
    // отфильтруем все действия '[Customers Page] Get'  
    ofType(CustomerActionTypes.Get),
    // стартуем новый асинхронный поток на каждое значение
    switchMap(() =>
        // вызов внешнего сервиса
        this.service.get().pipe(
        // возвращаем GetCustomersSuccess в случае успеха
        map(customers => new GetCustomersSuccess(customers)),
        // возвращаем GetCustomersFailed в случае ошибки
        catchError(error => of(new GetCustomersFailed(error))),
        ),
    ),
    );
```

## 1. Внешние ресурсы

Наблюдаемые действия являются наиболее известным, и наиболее часто используемым источником ваших эффектов. Однако, мы можем использовать любой наблюдаемый объект(Observable) в качестве источника.

### Используем наблюдаемые объекты RxJS

```
@Effect() 
ping = interval(1000).pipe(mapTo(new Ping()));
```

### Используем JavaScript API и RxJS

```
@Effect()
online = merge(
  of(navigator.onLine),
  fromEvent(window, 'online').pipe(mapTo(true)),
  fromEvent(window, 'offline').pipe(mapTo(false)),
).pipe(map(online => online ? new IsOnline() : new IsOffline()));
```

### Используем Angular Material CDK

```
@Effect()
breakpoint = this.breakpointObserver
  .observe([Breakpoints.HandsetLandscape])
  .pipe(
    map(result => result.matches 
      ? new ChangedToLandscape() 
      : new ChangedToPortrait())
  );
```

## 2. Перехват действий диалоговых окон Angular Material

Вместо обработки действий диалога внутри компонента можно использовать эффект. Эффект определяет, когда открывать и закрывать диалог, и отправляет действие с результатом диалога.

```
@Effect()
openDialog = this.actions.pipe(
  // отфильтровываем действие открытия окна
  ofType(LoginActionTypes.OpenLoginDialog),
  // пропускаем входящие значения пока не завершили обработку текущего значения
  exhaustMap(_ => {
    // открываем окно
    let dialogRef = this.dialog.open(LoginDialog);
    // возвращаем обработчик закрытия окна в поток
    return dialogRef.afterClosed();
  }),
  map((result: any) => {
    if (result === undefined) {
      // обрабатываем пустое значение
      return new CloseDialog();
    }
    // обрабатываем возврат окна диалога
    return new LoginDialogSuccess(result);
  }),
);
```

## 3. Показываем уведомления

Обработка уведомлений внутри эффекта делает остальную часть вашего приложения чистой и более понятной. Рассмотрим пример окна напоминалки на базе [Snackbar](https://medium.com/r/?url=https%3A%2F%2Fmaterial.angular.io%2Fcomponents%2Fsnack-bar%2Foverview) Angular Material.

```
// отключаем дальнейшую отправку действий, чтобы не попасть в бесконечный цикл
@Effect({ dispatch: false })
reminder = this.actions.pipe(
  // отфильтровываем действия напоминалки
  ofType<Reminder>(ActionTypes.Reminder),
  map(({ payload }) => {
    // открываем уведомление
    this.snackBar.openFromComponent(ReminderComponent, {         
      data: payload,
    });
  })
)
```

Или окна ошибки

```
// отключаем дальнейшую отправку действий, чтобы не попасть в бесконечный цикл
@Effect({ dispatch: false })
error = this.actions.pipe(
 // отфильтровываем действия ошибок
 ofType<ServerError>(ActionTypes.ServerError),
 map(({ payload }) => {
   // открываем уведомление
   this.snackBar.open(payload.message, 'Close');
 })
)
```

## 4. Используем селектор внутри эффектов

Иногда вам нужно получить доступ к состоянию хранилища(ngrx\Store) внутри эффекта. Для этого мы можем использовать оператор RxJS withLatestFrom в сочетании с селектором для получения фрагмента(slice) состояния хранилища.

```
@Effect()
shipOrder = this.actions.pipe(
  // Отфильтровываем действия отгрузки
  ofType<ShipOrder>(ActionTypes.ShipOrder),
  // берём данные из действия
  map(action => action.payload),
  // при поступлении значения payload берём текущее значение имени пользователя из хранилища
  withLatestFrom(this.store.pipe(select(getUserName))),
  // withLatestFrom возвращает как значение из основного потока payload, так и значение select(getUserName)
  map([payload, username] => {
    console.log(payload, username);
  })
)
```

Чтобы сделать следующий шаг, мы можем использовать данные, полученные селектором, чтобы проверить, существует ли уже сущность в хранилище. Это дает нам возможность блокировать ненужные запросы GET, если объект уже сохранен в хранилище.

```
@Effect()
getOrder = this.actions.pipe(
  // отфильтровываем действия заказа
  ofType<GetOrder>(ActionTypes.GetOrder),
  // берём данные из действия
  map(action => action.payload),
  // при поступлении значения payload берём текущее значение имени заказа из хранилища
  withLatestFrom(this.store.pipe(select(getOrders))),
  // отфильтровываем непустые заказы orders.xxxxx
  filter(([{payload}, orders]) => !!orders[payload.orderId]),
  // обрабатываем каждое полученное в потоке действие
  mergeMap([{payload}] => {
    console.log(payload);
  })
)
```

## 5. Навигация на основе действий

Внедряя(inject) маршрут(Angular router) в эффекты, можно перенаправить пользователя на основе определенных действий. В приведенном ниже примере мы отправляем пользователя на домашнюю страницу, когда он или она выходит из системы.
Обратите внимание, что мы передаем @Effect({dispatch:false}), потому что мы не отправляем никакого события. Если бы мы этого не сделали, мы бы застряли в бесконечном цикле, потому что эффект повторяет одно и то же действие снова и снова.

```
// отключаем дальнейшую отправку действий, чтобы не попасть в бесконечный цикл
@Effect({ dispatch: false })
logOut = this.actions.pipe(
  // отфильтровываем действия выхода
  ofType(ActionTypes.LogOut),
  // меняем маршрут пользователя на главную страницу
  tap([payload, username] => {
    this.router.navigate(['/']);
  })
)
```

## 6. Аналитика / мониторинг

Поскольку каждое отправленное действие генерирует новое значение для источника действий, мы можем использовать этот источник для получения статистики приложения. Мы можем регистрировать все действия или некоторые, фильтруя их с помощью оператора ofType. В приведенном ниже примере мы регистрируем каждое действие в appInsights.

```
@Effect({ dispatch: false })
trackEvents = this.actions.pipe(
  tap(({ type, payload }) => {
    appInsights.trackEvent(type, payload);
  })
)
```

## Заключение

Используя эти способы, мы можем переместить часть кода из наших компонентов или ngrx/Store, в модель ngrx/Effects. Это сделает компоненты более чистыми, и поможет хранить побочные эффекты нашего приложения отдельно. В результате получается код, который легче понимать и тестировать.
Теперь, когда вы знаете, в каких случаях эффекты можно использовать, стоит посмотреть когда этого делать не стоит.

Часть 2. Прекратите использовать ngrx/effects для этого

Примечание переводчика: примеры кода дополнены комментариями, исправлены незначительные ошибки, текст незначительно сокращён для более литературно красивого перевода.
