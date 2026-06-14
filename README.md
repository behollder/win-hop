# win-hop

[![GPLv3 license](https://img.shields.io/badge/License-GPLv3-blue.svg)](http://perso.crans.org/besson/LICENSE.html)

`win-hop` is an Emacs package to jump to a any window by label. It uses header line to show a jump label and allow jump to any window including vterm float window.

Bind the jump function to you key:

``` emacs-lisp
(global-set-key (kbd "C-x o") 'win-hop)
```

It uses letters: ```a, s, d, f, j, k, l, g, q, w```

