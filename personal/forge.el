;;; forge.el --- Emacs Minor Mode for Forge, FSharp's Package Manager.

;; Copyright (C) 2016 Simon Tyler Cousins

;; Author: Simon Tyler Cousins
;; Version  : 0.0.1
;; Keywords: tools
;; Package-Requires: ((emacs "24.3") (fsharp-mode "0.2.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Forge Minor mode.
;; Provides a number of key combinations and functions for managing Forge.
;; Current supported Forge Key Combinations:
;;  * forge-process--new-project
;;  * forge-process--new-file
;;  * forge-process--add-file
;;  * forge-process--add-reference
;;  * forge-process--remove-file
;;  * forge-process--remove-reference
;;  * forge-process--rename-file
;;  * forge-process--rename-project
;;  * forge-process--list-files
;;  * forge-process--list-references
;;  * forge-process--list-project-references
;;  * forge-process--list-gac
;;  * forge-process--list-templates
;;  * forge-process--move-file
;;  * forge-process--update-paket
;;  * forge-process--update-fake
;;  * forge-process--paket
;;  * forge-process--fake
;;
;;; Code:

(require 'forge-process)

(defgroup forge nil
  "Forge group."
  :prefix "forge-"
  :group 'tools)

(defvar forge-minor-mode-map (make-keymap) "Forge-mode keymap.")
(defvar forge-minor-mode nil)

;;;###autoload
(define-minor-mode forge-minor-mode
  "Forge minor mode. Used to hold keybindings for forge-mode"
  nil "forge" forge-minor-mode-map)

(define-key global-map (kbd "C-c C-c C-n p") 'forge-process--new-project)
(define-key global-map (kbd "C-c C-c C-n f") 'forge-process--new-file)
(define-key global-map (kbd "C-c C-c C-a f") 'forge-process--add-file)
(define-key global-map (kbd "C-c C-c C-a r") 'forge-process--add-reference)
(define-key global-map (kbd "C-c C-c C-r f") 'forge-process--remove-file)
(define-key global-map (kbd "C-c C-c C-r r") 'forge-process--remove-reference)
(define-key global-map (kbd "C-c C-c C-x f") 'forge-process--rename-file)
(define-key global-map (kbd "C-c C-c C-x p") 'forge-process--rename-project)
(define-key global-map (kbd "C-c C-c C-l f") 'forge-process--list-files)
(define-key global-map (kbd "C-c C-c C-l f") 'forge-process--list-references)
(define-key global-map (kbd "C-c C-c C-l p") 'forge-process--list-project-references)
(define-key global-map (kbd "C-c C-c C-l g") 'forge-process--list-gac)
(define-key global-map (kbd "C-c C-c C-l t") 'forge-process--list-templates)
(define-key global-map (kbd "C-c C-c C-m f") 'forge-process--move-file)
(define-key global-map (kbd "C-c C-c C-u p") 'forge-process--update-paket)
(define-key global-map (kbd "C-c C-c C-u f") 'forge-process--update-fake)
(define-key global-map (kbd "C-c C-c C-p") 'forge-process--paket)
(define-key global-map (kbd "C-c C-c C-f") 'forge-process--fake)

(provide 'forge)
;;; forge.el ends here
