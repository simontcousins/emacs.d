(if (eq system-type 'windows-nt)
    (progn
      (setenv "PATH"
              (concat
               ;; Change this with your path to MSYS bin directory
               "C:\\msys64\\usr\\bin;"
               (getenv "PATH")))
      (setq find-program "C:\\msys64\\usr\\bin\\find.exe"
            grep-program "C:\\msys64\\usr\\bin\\grep.exe")))

(setq font-lock-maximum-decoration 1)
(setq prelude-theme 'dichromacy)
;(setq prelude-theme 'quasi-monochrome)
(global-hl-line-mode -1)
