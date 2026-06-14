;;; win-hop.el --- Fast window switcher -*- lexical-binding: t; -*-

;; Author: Nikita Onachko <behollder.kh@gmail.com>
;; Version: 0.1
;; Package-Requires: ((emacs "27.1"))
;; Keywords: window, location
;;; Homepage: https://github.com

;;; Commentary:
;; This package dims all visible windows, assigns a shortcut letter to each,
;; and jumps to the window corresponding to the pressed key. Works on all
;; windows including Treemacs, Neotree, vterm, internal buffers, etc.

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
     :weight bold
     :height 2.0
     :box (:line-width 4 :color "#ff3333")))
  "Face used for the large window selection label."
  :group 'win-hop)

(defface win-hop-dim-face
  '((t
     :foreground "#666666"))
  "Face used to dim window contents temporarily."
  :group 'win-hop)

;;;###autoload
(defun win-hop ()
  "Dim all visible windows, show labels, and switch on key press."
  (interactive)

  (let ((all-windows (window-list))
        (overlays nil)
        (window-map nil))

    (if (<= (length all-windows) 1)
        (message "Only one window visible!")

      (unwind-protect
          (progn

            ;; Create overlays and labels
            (cl-loop for win in all-windows
                     for key in win-hop-keys
                     do
                     (with-selected-window win

                       (let* ((start (window-start))
                              (end (window-end nil t))

                              ;; Place label near top of visible window
                              (label-pos
                               (save-excursion
                                 (goto-char start)
                                 ;; Move slightly down from top edge
                                 (forward-line 1)
                                 (line-beginning-position))))

                         ;; Dim overlay
                         (let ((dim-ov (make-overlay start end)))
                           (overlay-put dim-ov
                                        'face
                                        'win-hop-dim-face)
                           (push dim-ov overlays))

                         ;; Label overlay
                         (let ((label-ov
                                (make-overlay label-pos label-pos)))

                           ;; Use before-string so it works reliably
                           ;; in treemacs/vterm/etc.
                           (overlay-put
                            label-ov
                            'before-string
                            (propertize
                             (format " %c " key)
                             'face
                             'win-hop-label-face))

                           (overlay-put label-ov 'priority 9999)

                           (push label-ov overlays))

                         ;; Map key -> window
                         (push (cons key win) window-map))))

            ;; Force redraw
            (redisplay t)

            ;; Read single key
            (let* ((input (read-char "Select window: "))
                   (target-window (cdr (assoc input window-map))))

              (if (window-live-p target-window)
                  (select-window target-window)
                (message "Invalid selection: %c" input))))

        ;; Cleanup overlays
        (mapc #'delete-overlay overlays)))))

;;; Keybinding
(global-set-key (kbd "C-x o") #'win-hop)

(provide 'win-hop)

;;; win-hop.el ends here
