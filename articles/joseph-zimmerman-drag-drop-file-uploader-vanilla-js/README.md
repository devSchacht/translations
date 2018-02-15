# Как сделать Drag-and-Drop загрузчик файлов на чистом JavaScript

*Перевод статьи [Joseph Zimmerman](https://twitter.com/joezimjs): [How To Make A Drag-and-Drop File Uploader With Vanilla JavaScript](https://www.smashingmagazine.com/2018/01/drag-drop-file-uploader-vanilla-js/)*.

Известен факт, что поле загрузки файолов трудно стилизовать так, как хочется разработчику, многие просто скрывают его и добавляют кнопку, которая открывает диалог выбора файлов. Теперь, однако, у нас появился даже более модный способ обработки выбора файлов: drag and drop.

Технически, это уже было возможно сделать потому что большинство (если не все) реализаций поля выбора файлов позволяли перетаскивать файлы чтобы их выбрать, но это требовало от вас показывать элемент `file`. Так что давайте действительно использовать API, которое дает нам браузер, для реализации выбора файлов через drag-and-drop и их загрузчик.

В этой статье мы будем использовать чистый ES2015+ JavaScript (без фреймворков или библиотек) для завершения этого проекта, и это предполагает что у вас есть опыт работы с JavaScript в браузере. Этот пример — помимо ES2015+ синтаксиса, который можно легко изменить на синтаксис ES5 или транспилировать с помощью Babel — должен быть совместим со всеми вечнозелеными браузерами + IE 10 и 11.

Ниже пример того, что должно получиться:

![alt text](https://cloud.netlifyusercontent.com/assets/344dbf88-fdf9-42bb-adb4-46f01eedd629/8a415e72-c17f-4cc3-9b64-1c3ab14cf82c/uploader-preview.gif "Logo Title Text 1")

Демонстрационная страница на которой можно загрузить файлы с помощью drag and drop, предварительный просмотр изображений, загружаемых немедленно, и демонстрация прогресса в индикаторе загрузки.

## События Drag-and-Drop

Первое, что мы должны обсудить, - это события связаные с перетаскиванием, потому что они движущая сила этого функционала. В общем, есть восемь событий, срабатывающих в браузере и связанных с перетаскиванием: `drag`, `dragend`, `dragenter`, `dragexit`, `dragleave`, `dragover`, `dragstart` и `drop`. Мы не будем проходиться по ним всем, потому что события `drag`, `dragend`, `dragexit` и `dragstart` срабатывают на элементе, который перетаскивают, а это не наш случай, мы будем перетаскивать файлы из нашёй файловой системы вместо DOM элементов, так что эти события никогда не сработают.

Если эти события вас заинтересовали, то вы можете изучить [документацию связанную с ними на MDN](https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API#Drag_Events).

Как и следовало ожидать, вы можете зарегистрировать обработчики для нужных событий таким же образом, каким происходит регистрация обработчиков большинства браузерных событий: с помощью `addEventListener`.

```javascript
    let dropArea = document.getElementById('drop-area')
    dropArea.addEventListener('dragenter', handlerFunction, false)
    dropArea.addEventListener('dragleave', handlerFunction, false)
    dropArea.addEventListener('dragover', handlerFunction, false)
    dropArea.addEventListener('drop', handlerFunction, false)
```

Ниже приведена небольшая таблица описывающая что эти события делают, используем `dropArea` из примера кода для того, чтобы сделать язык чище:

| **Событие**     | **Когда оно срабатывает?**|
| ------------- |:-------------:|
| `dragenter`     | Перетаскиваемый объект перетаскивается над `dropArea`, делая `dropArea` источником возникновения события `drop`, если пользователь "бросит" его туда. |
| `dragleave`     | Перетаскиваемый объект перетащили за пределы `dropArea` на другой элемент, делая его источником возникновения события `drop` вместо `dropArea`.      |
| `dragover`      | Срабатывает каждые несколько сотен миллисекунд, пока объект перетаскивают над `dropArea`.     |
| `drop`          | Пользователь отпустил кнопку мыши, перетаскиваемый объект "бросили" на `dropArea`. |

Стоит отметить, что перетаскивании элемента над элементом, являющимся дочерним для `dropArea`, событие `dragleave` сработает над `dropArea`, а событие `dragenter` на дочернем элементе, потому что он становится `target`. Событие `drop` "всплывёт" до элемента `dropArea` (конечно, если до этого всплытие не остановит другой обработчик событий), так что событие сработает на `dropArea`, несмотря на то, что `target` у него будет другим.

Также обратите внимание, что для реализации пользовательских взаимодействий с перетаскиванием, вам необходимо вызывать `event.preventDefault()` на каждом из слушателей этих событий. Если вы этого не сделаете, то браузер в конечном итоге откроет файл, который вы перетаскиваете, вместо того, чтобы отправить его в обработчик события `drop`.

## Настраиваем нашу форму

До того как мы начнём добавлять функциональность drag-and-drop, нам надо добавить базовую форму со стандартным полем типа `file`. Технически это не обязательно, но это хорошая идея - предоставить такую альтернативу пользователям, чей браузер не поддерживает drag-and-drop API.

```html
<div id="drop-area">
  <form class="my-form">
    <p>Upload multiple files with the file dialog or by dragging and dropping images onto the dashed region</p>
    <input type="file" id="fileElem" multiple accept="image/*" onchange="handleFiles(this.files)">
    <label class="button" for="fileElem">Select some files</label>
  </form>
</div>
```

Довольно простая структура. Вы можете заметить обработчик события `onchange` на `input`. Посмотрим на него позже. Было бы также хорошей идеей добавить `action` к тегу `form` и кнопку `submit`, чтобы помочь людям, у которых выключен JavaScript. Тогда вы можете использовать JavaScript для того, чтобы избавиться от их чистой формы. В любом случае, вам *понадобится* серверный скрипт для загрузки файлов, не важно написан ли он дома или вы используете сервис, такой как [Cloudinary](https://cloudinary.com/documentation/javascript_image_and_video_upload). Кроме этих заметок, здесь нет ничего особенного, так что давайте набросаем стили:

```css
#drop-area {
  border: 2px dashed #ccc;
  border-radius: 20px;
  width: 480px;
  font-family: sans-serif;
  margin: 100px auto;
  padding: 20px;
}
#drop-area.highlight {
  border-color: purple;
}
p {
  margin-top: 0;
}
.my-form {
  margin-bottom: 10px;
}
#gallery {
  margin-top: 10px;
}
#gallery img {
  width: 150px;
  margin-bottom: 10px;
  margin-right: 10px;
  vertical-align: middle;
}
.button {
  display: inline-block;
  padding: 10px;
  background: #ccc;
  cursor: pointer;
  border-radius: 5px;
  border: 1px solid #ccc;
}
.button:hover {
  background: #ddd;
}
#fileElem {
  display: none;
}
```

Многие из этих стилей пока не вступили в игру, но это нормально. Основной момент сейчас это то, что поле `file` скрыто, а его подпись `label` стилизована так, чтобы выглядеть как кнопка, так люди поймут, что кликнув по нему вызовется диалог выбора файлов. Кроме того, мы следуем соглашению, согласно которому область куда следует бросить файл обозначается прерывистой линией.

## Добавляем функциональность Drag-and-Drop

Теперь можем перейти к сладкому: drag and drop. Давайте набрасаем скрипт внизу страницы или в отдельном файле, смотря как вам больше нравится. Первое, что нам понадобится это ссылка на область, куда предстоит тащить файл. Так мы сможем привязаться к событиям на ней:

```javascript
let dropArea = document.getElementById('drop-area')
```

Теперь давайте добавим несколько событий. Начнём с добавления обработчиков для всех событий, чтобы предотвратить поведение по-умолчанию и остановить всплытие выше необходимого:

```javascript
;['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
  dropArea.addEventListener(eventName, preventDefaults, false)
})

function preventDefaults (e) {
  e.preventDefault()
  e.stopPropagation()
}
```

Now let’s add an indicator to let the user know that they have indeed dragged the item over the correct area by using CSS to change the color of the border color of the drop area. The styles should already be there under the `#drop-area.highlight` selector, so let’s use JS to add and remove that `highlight` class when necessary.

```javascript
;['dragenter', 'dragover'].forEach(eventName => {
  dropArea.addEventListener(eventName, highlight, false)
})

;['dragleave', 'drop'].forEach(eventName => {
  dropArea.addEventListener(eventName, unhighlight, false)
})

function highlight(e) {
  dropArea.classList.add('highlight')
}

function unhighlight(e) {
  dropArea.classList.remove('highlight')
}
```

We had to use both dragenter and dragover for the highlighting because of what I mentioned earlier. If you start off hovering directly over dropArea and then hover over one of its children, then dragleave will be fired and the highlight will be removed. The dragover event is fired after the dragenter and dragleave events, so the highlight will be added back onto dropArea before we see it being removed.

We also remove the highlight when the dragged item leaves the designated area or when you drop the item.

Now all we need to do is figure out what to do when some files are dropped:

```javascript
dropArea.addEventListener('drop', handleDrop, false)

function handleDrop(e) {
  let dt = e.dataTransfer
  let files = dt.files

  handleFiles(files)
}
```

This doesn’t bring us anywhere near completion, but it does two important things:

01. Demonstrates how to get the data for the files that were dropped.
02. Gets us to the same place that the file input was at with its onchange handler: waiting for handleFiles.

Keep in mind that files is not an array, but a FileList. So, when we implement handleFiles, we’ll need to convert it to an array in order to iterate over it more easily:

```javascript
function handleFiles(files) {
  ([...files]).forEach(uploadFile)
}
```

That was anticlimactic. Let’s get into uploadFile for the real meaty stuff.

```javascript
function uploadFile(file) {
  let url = 'YOUR URL HERE'
  let formData = new FormData()

  formData.append('file', file)

  fetch(url, {
    method: 'POST',
    body: formData
  })
  .then(() => { /* Done. Inform the user */ })
  .catch(() => { /* Error. Inform the user */ })
}
```

Here we use FormData, a built-in browser API for creating form data to send to the server. We then use the fetch API to actually send the image to the server. Make sure you change the URL to work with your back-end or service, and formData.append any additional form data you may need to give the server all the information it needs. Alternatively, if you want to support Internet Explorer, you may want to use XMLHttpRequest, which means uploadFile would look like this instead:

```javascript
function uploadFile(file) {
  var url = 'YOUR URL HERE'
  var xhr = new XMLHttpRequest()
  var formData = new FormData()
  xhr.open('POST', url, true)

  xhr.addEventListener('readystatechange', function(e) {
    if (xhr.readyState == 4 && xhr.status == 200) {
      // Done. Inform the user
    }
    else if (xhr.readyState == 4 && xhr.status != 200) {
      // Error. Inform the user
    }
  })

  formData.append('file', file)
  xhr.send(formData)
}
```

Depending on how your server is set up, you may want to check for different ranges of status numbers rather than just 200, but for our purposes, this will work.

## Additional Features

That is all of the base functionality, but often we want more functionality. Specifically, in this tutorial, we’ll be adding a preview pane that displays all the chosen images to the user, then we’ll add a progress bar that lets the user see the progress of the uploads. So, let’s get started with previewing images.

### Image Preview

There are a couple of ways you could do this: you could wait until after the image has been uploaded and ask the server to send the URL of the image, but that means you need to wait and images can be pretty large sometimes. The alternative — which we’ll be exploring today — is to use the FileReader API on the file data we received from the drop event. This is asynchronous, and you could alternatively use FileReaderSync, but we could be trying to read several large files in a row, so this could block the thread for quite a while and really ruin the experience. So let’s create a previewFile function and see how it works:

```javascript
function previewFile(file) {
  let reader = new FileReader()
  reader.readAsDataURL(file)
  reader.onloadend = function() {
    let img = document.createElement('img')
    img.src = reader.result
    document.getElementById('gallery').appendChild(img)
  }
}
```

Here we create a new FileReader and call readAsDataURL on it with the File object. As mentioned, this is asynchronous, so we need to add an onloadend event handler in order to get the result of the read. We then use the base 64 data URL as the src for a new image element and add it to the gallery element. There are only two things that need to be done to make this work now: add the gallery element, and make sure previewFile is actually called.

First, add the following HTML right after the end of the form tag:

```html
<div id="gallery"></div>
```

Nothing special; it’s just a div. The styles are already specified for it and the images in it, so there’s nothing left to do there. Now let’s change the handleFiles function to the following:

```javascript
function handleFiles(files) {
  files = [...files]
  files.forEach(uploadFile)
  files.forEach(previewFile)
}
```

There are a few ways you could have done this, such as composition, or a single callback to forEach that ran uploadFile and previewFile in it, but this works too. And with that, when you drop or select some images, they should show up almost instantly below the form. The interesting thing about this is that — in certain applications — you may not actually want to upload images, but instead store the data URLs of them in localStorage or some other client-side cache to be accessed by the app later. I can’t personally think of any good use cases for this, but I’m willing to bet there are some.

### Tracking Progress

If something might take a while, a progress bar can help a user realize progress is actually being made and give an indication of how long it will take to be completed. Adding a progress indicator is pretty easy thanks to the HTML5 progress tag. Let’s start by adding that to the HTML code this time.

```html
<progress id="progress-bar" max=100 value=0></progress>
```

You can plop that in right after the label or between the form and gallery div, whichever you fancy more. For that matter, you can place it wherever you want within the body tags. No styles were added for this example, so it will show the browser’s default implementation, which is serviceable. Now let’s work on adding the JavaScript. We’ll first look at the implementation using fetch and then we’ll show a version for XMLHttpRequest. To start, we’ll need a couple of new variables at the top of the script :

```javascript
let filesDone = 0
let filesToDo = 0
let progressBar = document.getElementById('progress-bar')
```

When using fetch we’re only able to determine when an upload is finished, so the only information we track is how many files are selected to upload (as filesToDo) and the number of files that have finished uploading (as filesDone). We’re also keeping a reference to the #progress-bar element so we can update it quickly. Now let’s create a couple of functions for managing the progress:

```javascript
function initializeProgress(numfiles) {
  progressBar.value = 0
  filesDone = 0
  filesToDo = numfiles
}

function progressDone() {
  filesDone++
  progressBar.value = filesDone / filesToDo * 100
}
```

When we start uploading, initializeProgress will be called to reset the progress bar. Then, with each completed upload, we’ll call progressDone to increment the number of completed uploads and update the progress bar to show the current progress. So let’s call these functions by updating a couple of old functions:

```javascript
function handleFiles(files) {
  files = [...files]
  initializeProgress(files.length) // <- Add this line
  files.forEach(uploadFile)
  files.forEach(previewFile)
}

function uploadFile(file) {
  let url = 'YOUR URL HERE'
  let formData = new FormData()

  formData.append('file', file)

  fetch(url, {
    method: 'POST',
    body: formData
  })
  .then(progressDone) // <- Add `progressDone` call here
  .catch(() => { /* Error. Inform the user */ })
}
```

And that’s it. Now let’s take a look at the XMLHttpRequest implementation. We could just make a quick update to uploadFile, but XMLHttpRequest actually gives us more functionality than fetch, namely we’re able to add an event listener for upload progress on each request, which will periodically give us information about how much of the request is finished. Because of this, we need to track the percentage completion of each request instead of just how many are done. So, let’s start with replacing the declarations for filesDone and filesToDo with the following:

```javascript
let uploadProgress = []
```

Then we need to update our functions as well. We’ll rename progressDone to updateProgress and change them to be the following:

```javascript
function initializeProgress(numFiles) {
  progressBar.value = 0
  uploadProgress = []

  for(let i = numFiles; i > 0; i--) {
    uploadProgress.push(0)
  }
}

function updateProgress(fileNumber, percent) {
  uploadProgress[fileNumber] = percent
  let total = uploadProgress.reduce((tot, curr) => tot + curr, 0) / uploadProgress.length
  progressBar.value = total
}
```

Now initializeProgress initializes an array with a length equal to numFiles that is filled with zeroes, denoting that each file is 0% complete. In updateProgress we find out which image is having their progress updated and change the value at that index to the provided percent. We then calculate the total progress percentage by taking an average of all the percentages and update the progress bar to reflect the calculated total. We still call initializeProgress in handleFiles the same as we did in the fetch example, so now all we need to update is uploadFile to call updateProgress.

```javascript
function uploadFile(file, i) { // <- Add `i` parameter
  var url = 'YOUR URL HERE'
  var xhr = new XMLHttpRequest()
  var formData = new FormData()
  xhr.open('POST', url, true)

  // Add following event listener
  xhr.upload.addEventListener("progress", function(e) {
    updateProgress(i, (e.loaded * 100.0 / e.total) || 100)
  })

  xhr.addEventListener('readystatechange', function(e) {
    if (xhr.readyState == 4 && xhr.status == 200) {
      // Done. Inform the user
    }
    else if (xhr.readyState == 4 && xhr.status != 200) {
      // Error. Inform the user
    }
  })

  formData.append('file', file)
  xhr.send(formData)
}
```

The first thing to note is that we added an i parameter. This is the index of the file in the list of files. We don’t need to update handleFiles to pass this parameter in because it is using forEach, which already gives the index of the element as the second parameter to callbacks. We also added the progress event listener to xhr.upload so we can call updateProgress with the progress. The event object (referred to as e in the code) has two pertinent pieces of information on it: loaded which contains the number of bytes that have been uploaded so far and total which contains the number of bytes the file is in total.

The || 100 piece is in there because sometimes if there is an error, e.loaded and e.total will be zero, which means the calculation will come out as NaN, so the 100 is used instead to report that the file is done. You could also use 0. In either case, the error will show up in the readystatechange handler so that you can inform the user about them. This is merely to prevent exceptions from being thrown for trying to do math with NaN.

## Conclusion

That’s the final piece. You now have a web page where you can upload images via drag and drop, preview the images being uploaded immediately, and see the progress of the upload in a progress bar. You can see the final version (with XMLHttpRequest) in action on CodePen, but be aware that the service I upload the files to has limits, so if a lot of people test it out, it may break for a time.
