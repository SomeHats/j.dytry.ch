document.addEventListener "DOMContentLoaded", ->
  # Navigation bits
  if document.body.classList.contains "hide-nav"
    status = true
    button = document.querySelector "header button"
    nav = document.querySelector "header ul"

    button.addEventListener "click", ->
      status = !status

      if status
        document.body.classList.add "hide-nav"
      else
        document.body.classList.remove "hide-nav"

    , false

  resize = (image) ->
    ratio = window.devicePixelRation || 1

    img = new Image()
    img.src = image.src
    targetWidth = img.width

    if targetWidth isnt 0
      actualWidth = image.width * ratio
      if actualWidth > targetWidth

        image.setAttribute "data-2x-loaded", true
        img = new Image()

        img.addEventListener "load", ->
          image.src = img.src
        , false

        img.src = image.getAttribute "data-2x"

  # Sort of responsive images!
  resizeImages = ->
    images = document.querySelectorAll "img"
    for image in images
      image.addEventListener "load", resizeImages, false
      if (!image.hasAttribute "data-2x-loaded") and image.hasAttribute "data-2x"
        resize image

  document.addEventListener "load", resizeImages, false
  window.addEventListener "resize", resizeImages, false
  resizeImages()
, false

`
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-37823930-1']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
`
