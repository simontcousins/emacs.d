;;; customizations --- personal customizations to the prelude

;;; Commentary:
; Put customisations to the prelude here.

;;; Code:

(prelude-require-packages
 '(ace-jump-zap
   ace-window
   fsharp-mode
   ido-vertical-mode
   idris-mode))

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

(add-hook 'fsharp-mode-hook
          (lambda ()
            (define-key fsharp-mode-map (kbd "M-RET") 'fsharp-eval-region)
            (define-key fsharp-mode-map (kbd "C-.") 'fsharp-ac/complete-at-point)))

(provide 'customizations)
;;; customizations.el ends here
