;;; win-hop.el --- Fast window switcher -*- lexical-binding: t; -*-

;; Author: Nikita Onachko <behollder.kh@gmail.com>
;; Version: 0.2
;; Package-Requires: ((emacs "27.1"))
;; Keywords: window, location
;;; Homepage: https://github.com

;;; Commentary:
;; This package overrides the header-line of all visible windows,
;; assigns a shortcut letter to each, and jumps to the window.
;; Works perfectly on all text/terminal buffers including vterm and treemacs
;; without interfering with buffer contents or overlays.

;;; Code:

(require 'cl-lib)

(defgroup win-hop nil
  "Custom window switcher configurations."
  :group 'convenience)

(defcustom win-hop-keys
  '(?a ?s ?d ?f ?j ?k ?l ?g ?q ?w)
  "Keys assigned to windows for quick switching."
  :type '(repeat character)
  :group 'win-hop)

(defface win-hop-label-face
  '((t
     :foreground "white"
     :background "#ff3333"
     :weight bold))
  "Face used for the window selection label in the header line."
  :group 'win-hop)

;;;###autoload
(defun win-hop ()
  "Hijack header lines, show labels, and switch on key press."
  (interactive)

  (let ((all-windows (delq (selected-window) (window-list)))
        (window-map nil)
        (original-headers nil))

    (if (= (length all-windows) 0)
        (message "Only one window visible!")

      (unwind-protect
          (progn
            ;; Save original states and inject labels into header-lines
            (cl-loop for win in all-windows
                     for key in win-hop-keys
                     do
                     (let ((orig-header (window-parameter win 'header-line-format))
                           (orig-header-state (with-current-buffer (window-buffer win)
                                                header-line-format)))

                       ;; Track original configuration to restore later
                       (push (list win orig-header orig-header-state) original-headers)

                       ;; Format a high-visibility block at the top of the window
                       (let ((label-str (propertize (format "==  %c  ==" (capitalize key))
                                                    'face 'win-hop-label-face)))

                         ;; Set it at the window level so it overrides buffer defaults
                         (set-window-parameter win 'header-line-format label-str)

                         ;; Force buffer-local override to guarantee visibility in strict modes
                         (with-current-buffer (window-buffer win)
                           (setq-local header-line-format label-str)))

                       ;; Map key -> window
                       (push (cons key win) window-map)))

            ;; Force a clean redraw so changes hit the screen instantly
            (redisplay t)

            ;; Read single key
            (let* ((input (read-char "Select window: "))
                   (target-window (cdr (assoc input window-map))))

              (if (window-live-p target-window)
                  (select-window target-window)
                (message "Invalid selection: %c" input))))

        ;; Cleanup: Restore absolutely everything to how it was
        (pcase-dolist (`(,win ,orig-win-hdr ,orig-buf-hdr) original-headers)
          (when (window-live-p win)
            (set-window-parameter win 'header-line-format orig-win-hdr)
            (when (buffer-live-p (window-buffer win))
              (with-current-buffer (window-buffer win)
                (setq-local header-line-format orig-buf-hdr)))))))))

;;; Keybinding
(global-set-key (kbd "C-x o") #'win-hop)

(provide 'win-hop)

;;; win-hop.el ends here
