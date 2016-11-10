;;; customizations --- personal customizations to the prelude

;;; Commentary:
; Put customisations to the prelude here.

(if (eq system-type 'windows-nt)
    (progn
      (server-start)
      (set-face-attribute 'default nil
                    :family "Consolas" :height 100)))

;;; Code:

(prelude-require-packages
 '(ace-jump-zap
   ace-window
   color-theme-sanityinc-tomorrow
   csharp-mode
   cursor-chg
   crux
   cyberpunk-theme
   elm-mode
   fsharp-mode
   ggtags
   ido-vertical-mode
   idris-mode
   lush-theme
   multiple-cursors
   quasi-monochrome-theme
   ujelly-theme))

(global-set-key (kbd "M-3") '(lambda()(interactive)(insert-string "#")))
(global-hl-line-mode -1)

(require 'cursor-chg)
(toggle-cursor-type-when-idle 1)
(change-cursor-mode 1)

;; Set Windows-specific preferences if running in a Windows environment.
(defun udf-windows-setup ()
  (interactive)
  ;; The variable `git-shell-path' contains the path to the `Git\bin'
  ;; file on my system. I install this in
  ;; `%USERPROFILE%\LocalAppInfo\apps\Git\bin'.
  (setq git-shell-path "C:\\Program Files (x86)\\Git\\bin")
  (setq git-shell-executable
        (concat git-shell-path "\\bash.exe"))
  (add-to-list 'exec-path git-shell-path)
  (setenv "PATH"
          (concat git-shell-path ";"
                  (getenv "PATH")))
  (message "Windows preferences set."))

(if (eq system-type 'windows-nt)
    (udf-windows-setup))

(menu-bar-mode -1)

;; ido

(require 'ido-vertical-mode)
(ido-vertical-mode)

(defun sd/ido-define-keys () ;; C-n/p is more intuitive in vertical layout
;  (define-key ido-completion-map (kbd "C-n") 'ido-next-match)
  (define-key ido-completion-map (kbd "<down>") 'ido-next-match)
;  (define-key ido-completion-map (kbd "C-p") 'ido-prev-match)
  (define-key ido-completion-map (kbd "<up>") 'ido-prev-match))

(require 'dash)

(defun my/ido-go-straight-home ()
  (interactive)
  (cond
   ((looking-back "~/") (insert "projects/"))
   ((looking-back "/") (insert "~/"))
   (:else (call-interactively 'self-insert-command))))

(defun my/setup-ido ()
  ;; Go straight home
  (define-key ido-file-completion-map (kbd "~") 'my/ido-go-straight-home)
  (define-key ido-file-completion-map (kbd "C-~") 'my/ido-go-straight-home)

  ;; Use C-w to go back up a dir to better match normal usage of C-w
  ;; - insert current file name with C-x C-w instead.
  (define-key ido-file-completion-map (kbd "C-w") 'ido-delete-backward-updir)
  (define-key ido-file-completion-map (kbd "C-x C-w") 'ido-copy-current-file-name)

  (define-key ido-file-dir-completion-map (kbd "C-w") 'ido-delete-backward-updir)
  (define-key ido-file-dir-completion-map (kbd "C-x C-w") 'ido-copy-current-file-name))

(add-hook 'ido-setup-hook 'my/setup-ido)


;; fsharp

(setq fsharp-indent-offset 4)

(add-hook 'fsharp-mode-hook
          (lambda ()
            (define-key fsharp-mode-map (kbd "M-RET") 'fsharp-eval-region)
            (define-key fsharp-mode-map (kbd "C-.") 'fsharp-ac/complete-at-point)
            (electric-indent-mode -1)))

;; elm

(add-hook 'elm-mode-hook #'elm-oracle-setup-completion)


;; cpp

(require 'ggtags)
(add-hook 'c-mode-common-hook
          (lambda ()
            (when (derived-mode-p 'c-mode 'c++-mode 'java-mode 'asm-mode)
              (ggtags-mode 1))))

(define-key ggtags-mode-map (kbd "C-c g s") 'ggtags-find-other-symbol)
(define-key ggtags-mode-map (kbd "C-c g h") 'ggtags-view-tag-history)
(define-key ggtags-mode-map (kbd "C-c g r") 'ggtags-find-reference)
(define-key ggtags-mode-map (kbd "C-c g f") 'ggtags-find-file)
(define-key ggtags-mode-map (kbd "C-c g c") 'ggtags-create-tags)
(define-key ggtags-mode-map (kbd "C-c g u") 'ggtags-update-tags)

(define-key ggtags-mode-map (kbd "M-,") 'pop-tag-mark)

(setq-local imenu-create-index-function #'ggtags-build-imenu-index)

;; crux

(require 'crux)
(global-set-key [remap move-beginning-of-line] #'crux-move-beginning-of-line)
(global-set-key (kbd "C-c o") #'crux-open-with)
(global-set-key [(shift return)] #'crux-smart-open-line)
(global-set-key (kbd "s-r") #'crux-recentf-ido-find-file)
(global-set-key (kbd "C-<backspace>") #'crux-kill-like-backwards)
(global-set-key [remap kill-whole-line] #'crux-kill-whole-line)

(provide 'customizations)
;;; customizations.el ends here
