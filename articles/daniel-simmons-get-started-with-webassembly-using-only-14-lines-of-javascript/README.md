# Начало работы с WebAssembly, используя только 14 строк на JavaScript
![](https://cdn-images-1.medium.com/max/2000/1*sHlMI2kxKBlm76U2Gmt2Cw.jpeg)

*Перевод статьи [Daniel Simmons](https://medium.freecodecamp.org/@dsimmons_23530): [Get started with WebAssembly — using only 14 lines of JavaScript](https://medium.freecodecamp.org/get-started-with-webassembly-using-only-14-lines-of-javascript-b37b6aaca1e4).*

[WebAssembly — это новая веб-технология](https://www.youtube.com/watch?v=6v4E6oksar0&t=241s) с огромным потенциалом. Она окажет существенное влияние на то, как веб-приложения будут разрабатываться в будущем.

Но иногда мне кажется, что эта технология просто не хочет, чтобы люди её поняли... Можно сказать, даже в странной пассивно-агрессивной манере.

Когда я смотрю документацию или обучающие материалы, которых уже целая куча, то не могу не чувствовать себя фермером, который молил о дожде, чтобы потом утонуть в потопе. Технически я получил то, что хотел... просто не так, как надеялся. "Ты хочешь дождь?! О, я дам тебе дождь!"

Так происходит потому, что WebAssembly даёт очень много новых возможностей, которые могут быть реализованы множеством разных способов. Но он настолько сильно изменился по пути к официальному MVP в феврале, что когда вы впервые узнаете о нём, то легко можете утонуть в море деталей.

В продолжение метафоры дождя, эта статья — моя попытка предоставить лёгкий душ из введения в WebAssembly. Никакой концепции или болтов и гаек, а фактическая реализация скрипта с использованием этой технологии.

Я покажу вам несколько шагов для реализации простого проекта, исключая сложность, где это возможно. После того как вы реализуете простейший проект с WebAssembly хотя бы раз, многие из идей более высокого уровня станут гораздо проще для понимания.

- - - -

*Слушайте наш подкаст в [iTunes](https://itunes.apple.com/ru/podcast/девшахта/id1226773343) и [SoundCloud](https://soundcloud.com/devschacht), читайте нас на [Medium](https://medium.com/devschacht), контрибьютьте на [GitHub](https://github.com/devSchacht), общайтесь в [группе Telegram](https://t.me/devSchacht), следите в [Twitter](https://twitter.com/DevSchacht) и [канале Telegram](https://t.me/devSchachtChannel), рекомендуйте в [VK](https://vk.com/devschacht) и [Facebook](https://www.facebook.com/devSchacht).*