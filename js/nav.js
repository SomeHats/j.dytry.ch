/*jslint indent: 2, browser: true */

(function () {
  "use strict";

  document.addEventListener("DOMContentLoaded", function () {
    var button,
      nav,
      status;
    if (document.body.className.match("hide-nav") !== -1) {
      status = true;
      button = document.querySelector("header button");
      nav = document.querySelector("header ul");

      button.addEventListener("click", function () {
        status = !status;
        console.log("fire");
        if (status) {
          document.body.className += " hide-nav";
        } else {
          document.body.className = document.body.className.replace("hide-nav", "");
        }
      });
    }
  }, false);
}());