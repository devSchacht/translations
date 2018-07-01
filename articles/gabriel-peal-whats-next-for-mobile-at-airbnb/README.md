# React Native в Airbnb: Что дальше с мобильной разработкой
### Возвращение к нативной разработке.

*Перевод статьи [Gabriel Peal](https://medium.com/@gpeal): [What’s Next for Mobile at Airbnb](https://medium.com/airbnb-engineering/whats-next-for-mobile-at-airbnb-5e71618576ab).*

![](https://cdn-images-1.medium.com/max/2000/1*_N3sz8fhNFU5tB5YTVfGHg.jpeg)

*Это пятая статья [в серии](../gabriel-peal-react-native-at-airbnb), в которой мы поделимся нашим опытом с React Native и расскажем, что ждёт в дальнейшем мобильную разработку в Airbnb.*

## Захватывающие времена впереди
Даже экспериментируя с React Native, мы продолжали наращивать наши усилия и в области нативной разработки. Сегодня у нас есть ряд интересных проектов в продакшене или в производстве. Некоторые из этих проектов были вдохновлены опытом работы с React Native.

## Рендеринг на стороне сервера
Несмотря на то, что мы не используем React Native, мы по-прежнему видим ценность в написании кода продукта единожды. Мы по-прежнему сильно полагаемся на нашу систему универсального языка дизайна ([DLS](http://sketchapp.me/vizualnyj-yazyk-ot-kompanii-airbnb/), и многие экраны выглядят почти идентичными на Android и iOS.

Несколько команд экспериментировали и начали объединяться вокруг мощных фреймворков серверного рендеринга. С помощью этих фреймворков сервер отправляет данные на устройство, описывающие компоненты для визуализации, конфигурацию экрана и действия, которые могут произойти. Затем каждая мобильная платформа интерпретирует эти данные и отображает собственные экраны или даже целые пользовательские сценарии с помощью DLS-компонентов.

Управляемый сервером рендеринг поставляется с собственным набором проблем. Вот горстка, которую мы решаем:

* Безопасное обновление определений компонентов при сохранении обратной совместимости.
* Совместное использование определений типов для наших компонентов на разных платформах.
* Реагирование на события во время выполнения, такие как нажатие кнопок или пользовательский ввод.
* Переход между несколькими экранами, управляемыми JSON, с сохранением внутреннего состояния.
* Визуализация полностью настраиваемых компонентов, которые не имеют существующих реализаций во время сборки. Мы экспериментируем с форматом [Lona](https://github.com/airbnb/Lona/) для этого.

Фреймворки серверного рендеринга уже предоставили огромную ценность, позволяя нам экспериментировать и мгновенно обновлять функциональность без обновления приложения у пользователя.

## Компоненты Epoxy
В 2016 году мы выложили в опенсорс Epoxy для Android. Epoxy — это фреймворк, который делает доступными гетерогенные RecyclerViews, UICollectionViews и UITableViews. Сегодня большинство новых экранов используют Epoxy. Это позволяет разбить каждый экран на отдельные компоненты и добиться ленивого рендеринга. Сегодня у нас есть Epoxy на Android и iOS.

Вот как это выглядит на iOS:

```swift
BasicRow.epoxyModel(
  content: BasicRow.Content(
    titleText: "Settings",
    subtitleText: "Optional subtitle"),
  style: .standard,
  dataID: "settings",
  selectionHandler: { [weak self] _, _, _ in
    self?.navigate(to: .settings)
  })
```
https://gist.github.com/gpeal/93452a45351ddabf2b06e12cca7271b9#file-documentmarquee-swift

На Android мы использовали возможности DSL в Kotlin, чтобы сделать реализации компонент простыми для написания и типобезопасными:

```kt
basicRow {
 id("settings")
 title(R.string.settings)
 subtitleText(R.string.settings_subtitle)
 onClickListener { navigateTo(SETTINGS) }
}
```
https://gist.github.com/gpeal/94cc2a65cfdc00ed1283329f614c98e1#file-epoxy-kt

## Вычисление разницы в Epoxy
В React вы возвращаете список компонентов из [функции рендера](https://reactjs.org/tutorial/tutorial.html#what-is-react). Ключ к производительности React заключается в том, что эти компоненты являются просто моделью данных фактических представлений/HTML, которые вы хотите отобразить. Затем дерево компонентов сравнивается и отправляются только изменения. Мы создали подобную концепцию для Epoxy. В Epoxy модели объявляются для всего экрана в [buildModels](https://reactjs.org/tutorial/tutorial.html#what-is-react). Это, в сочетании с элегантным Kotlin DSL делает его концептуально очень похожим на React и выглядит так:

```kt
override fun EpoxyController.buildModels() {
  header {
    id("marquee")
    title(R.string.edit_profile)
  }
  inputRow {
    id("first name")
    title(R.string.first_name)
    text(firstName)
    onChange { 
      firstName = it 
      requestModelBuild()
    }
  }
  // Put the rest of your models here...
}
```
https://gist.github.com/gpeal/45094cb71ebe1bf943cfd20b10c65227#file-simpleepoxycontroller-kt

Каждый раз, когда ваши данные изменяются, вы вызываете функцию `requestModelBuild()` и она перерисовывает ваш экран с оптимальными обработками вызовов RecyclerView.

На iOS, это будет выглядеть так:

```swift
override func itemModel(forDataID dataID: DemoDataID) -> EpoxyableModel? {
  switch dataID {
  case .header:
    return DocumentMarquee.epoxyModel(
      content: DocumentMarquee.Content(titleText: "Edit Profile"),
      style: .standard,
      dataID: DemoDataID.header)
  case .inputRow:
    return InputRow.epoxyModel(
      content: InputRow.Content(
        titleText: "First name",
        inputText: firstName)
      style: .standard,
      dataID: DemoDataID.inputRow,
      behaviorSetter: { [weak self] view, content, dataID in
        view.textDidChangeBlock = { _, inputText in
          self?.firstName = inputText
          self?.rebuildItemModel(forDataID: .inputRow)
        }
      })
  }
}
```
https://gist.github.com/gpeal/fb032ca2ee20a3d2541d369101356fca#file-epoxy-swift

## Новый фреймворк для Android (MvRx)
Одно из самых ярких последних событий — это новая платформа, которую мы развиваем, внутри мы называем её MvRx. MvRx совмещает самое лучшее от Epoxy, [Jetpack](https://developer.android.com/jetpack/), [RxJava](https://github.com/ReactiveX/RxJava), и Kotlin со множеством принципов React для того чтобы сделать создание новых экраны более легким и более бесшовным чем когда-либо. Это самоуверенный, но гибкий фреймворк, который был разработан на основе общих паттернов разработки, которые мы наблюдали, а также берёт лучшие части React. Он также потокобезопасен, и почти все работает в отдельном потоке от основного, что делает прокрутку и анимацию плавной и гладкой.

До сих пор он работал на различных экранах и почти исключил потребность работать с жизненными циклами. В настоящее время мы оцениваем его по целому ряду продуктов на Android и планируем открыть исходный код, если результат будет успешным. Это полный код, необходимый для создания функционального экрана, который делает сетевой запрос:

```kt
data class SimpleDemoState(val listing: Async<Listing> = Uninitialized)

class SimpleDemoViewModel(override val initialState: SimpleDemoState) : MvRxViewModel<SimpleDemoState>() {
    init {
        fetchListing()
    }

    private fun fetchListing() {
        // This automatically fires off a request and maps its response to Async<Listing>
        // which is a sealed class and can be: Unitialized, Loading, Success, and Fail.
        // No need for separate success and failure handlers!
        // This request is also lifecycle-aware. It will survive configuration changes and
        // will never be delivered after onStop.
        ListingRequest.forListingId(12345L).execute { copy(listing = it) }
    }
}

class SimpleDemoFragment : MvRxFragment() {
    // This will automatically subscribe to the ViewModel state and rebuild the epoxy models
    // any time anything changes. Similar to how React's render method runs for every change of
    // props or state.
    private val viewModel by fragmentViewModel(SimpleDemoViewModel::class)

    override fun EpoxyController.buildModels() {
        val (state) = withState(viewModel)
        if (state.listing is Loading) {
            loader()
            return
        }
        // These Epoxy models are not the views themself so calling buildModels is cheap. RecyclerView
        // diffing will be automaticaly done and only the models that changed will re-render.
        documentMarquee {
            title(state.listing().name)
        }
        // Put the rest of your Epoxy models here...
    }

    override fun EpoxyController.buildFooter() = fixedActionFooter {
        val (state) = withState(viewModel)
        buttonLoading(state is Loading)
        buttonText(state.listing().price)
        buttonOnClickListener { _ -> }
    }
}
```
https://gist.github.com/gpeal/87099abc09503f2e14a1c31b7bdcdc06#file-simpledemo-kt

MvRx имеет простые конструкции для обработки `Fragment args`, сохраняет savedInstanceState при перезапуски процесса, отслеживает TTI, и содержит ряд других особенностей.

Мы также работаем над аналогичной платформой для iOS, которая находится в раннем тестировании.

Вы можете услышать больше об этом в самое ближайшее время, и мы рады прогрессу, которого мы достигли.

## Скорость итераций
Одна вещь, которая была сразу очевидна при переключении с React Native обратно в нативную разработку — это скорость итерации. Переход из мира, где вы можете надежно проверить свои изменения за секунду или две к миру, где, возможно, придется ждать до 15 минут, был неприемлемым. К счастью, мы также смогли оказать необходимую помощь.

Мы построили инфраструктуру на Android и iOS, которая позволить скомпилировать только часть приложения. 

На Android это сделано при помощи [gradle product flavors](https://developer.android.com/studio/build/build-variants#product-flavors). Наши модули gradle выглядят так:

![](https://cdn-images-1.medium.com/max/2000/1*KVrbsdwESyfbtKFeh2acXg.png)

Этот новый уровень косвенности позволяет инженерам работать с тонким срезом приложения. В сочетании с [выгрузкой модулей в IntelliJ](https://blog.jetbrains.com/idea/2017/06/intellij-idea-2017-2-eap-introduces-unloaded-modules/) это значительно улучшает производительность сборки и IDE на MacBook Pro.

Мы написали скрипты для создания нового тестируемого flavor и всего за несколько месяцев мы уже создали более 20. Сборки для разработки, использующие эти новые flavor, в среднем в 2,5 раза быстрее, а процент сборок, которые занимают больше пяти минут, в 15 раз меньше.

Для справки, это [фрагмент gradle-кода](https://gist.github.com/gpeal/d68e4fc1357ef9d126f25afd9ab4eee2), используемый для динамического создания разновидностей приложения с корневой зависимостью.

Аналогично, на iOS наши модули выглядят так:

![](https://cdn-images-1.medium.com/max/1600/1*AVB7em_JCmj-JmjTCkLdQw.png)

Те же результаты в сборках, которые теперь проходят в 3 — 8 раз  быстрее.

## Выводы
Интересно находиться в компании, которая не боится пробовать новые технологии, но стремится поддерживать невероятно высокую планку для качества, скорости и опыта разработчика. В конце концов, React Native был важным инструментом для быстрой доставки нового функционала и дал нам новые способы мышления о мобильной разработке. Если это звучит как путешествие, частью которого вы хотели бы быть, [дайте нам знать](https://www.airbnb.com/careers/departments/engineering)!

---

Это пятая часть в серии статей, освещающих наш опыт работы с React Native в Airbnb.

Часть 1: [React Native в Airbnb](../gabriel-peal-react-native-at-airbnb)

Часть 2: [Технология](../gabriel-peal-react-native-at-airbnb-the-technology)

Часть 3: [Создание кроссплатформенной мобильной команды](../gabriel-peal-building-a-cross-platform-mobile-team)

Часть 4: [Принятие решения по React Native](../gabriel-peal-sunsetting-react-native)

Часть 5: [Что дальше с мобильной разработкой](../gabriel-peal-whats-next-for-mobile-at-airbnb)

- - - -

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*
