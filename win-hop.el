;;; win-hop.el --- Fast window switcher -*- lexical-binding: t; -*-

;; Author: Nikita Onachko <behollder.kh@gmail.com>
;; Version: 0.4
;; Package-Requires: ((emacs "27.1"))
;; Keywords: window, location
;; Homepage: https://github.com/behollder/win-hop

;;; Commentary:
;; This package overrides the header-line of all visible windows,
;; assigns a shortcut letter to each, and jumps to the window.
;; Works perfectly on all text/terminal buffers including vterm and treemacs
;; without interfering with buffer contents or overlays.

;;; Code:

(require 'cl-lib)

(defgroup win-hop nil
  "Fast window switcher."
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
            ;; Inject labels strictly at the window level
            (cl-loop for win in all-windows
                     for key in win-hop-keys
                     do
                     (let ((orig-win-hdr (window-parameter win 'header-line-format))
                           (buf (window-buffer win)))

                       ;; Save buffer-local state only if we haven't touched this buffer yet
                       (unless (assoc buf original-headers)
                         (push (cons buf (with-current-buffer buf header-line-format))
                               original-headers))

                       ;; Save the window's own parameter state
                       (set-window-parameter win 'win-hop-orig-hdr orig-win-hdr)

                       (let ((label-str (propertize (format "==  %c  ==" (capitalize key))
                                                    'face 'win-hop-label-face)))
                         ;; Store unique key directly on the specific window instance
                         (set-window-parameter win 'header-line-format label-str))

                       ;; Force the buffer to read from the current window's parameters
                       (with-current-buffer buf
                         (setq-local header-line-format t))

                       ;; Map key -> window
                       (push (cons key win) window-map)))

            ;; Force a clean redraw so changes hit the screen instantly
            (force-mode-line-update t)
            (redisplay t)

            ;; Read single key
            (let* ((input (read-char "Select window: "))
                   (target-window (cdr (assoc input window-map))))

              (if (window-live-p target-window)
                  (select-window target-window)
                (message "Invalid selection: %c" input))))

        ;; Cleanup everything
        ;; Restore windows
        (dolist (win all-windows)
          (when (window-live-p win)
            (set-window-parameter win 'header-line-format (window-parameter win 'win-hop-orig-hdr))
            (set-window-parameter win 'win-hop-orig-hdr nil)))

        ;; Restore buffers
        (pcase-dolist (`(,buf . ,orig-buf-hdr) original-headers)
          (when (buffer-live-p buf)
            (with-current-buffer buf
              (if orig-buf-hdr
                  (setq header-line-format orig-buf-hdr)
                (kill-local-variable 'header-line-format)))))

        ;; Clear the frame-wide rendering cache to prevent stuck headers
        (force-mode-line-update t)
        (redisplay t)))))

(provide 'win-hop)

;;; win-hop.el ends here
