;;; forge-process.el --- Forge Process Major Mode

;; Copyright (C) 2016 Simon Tyler Cousins

;; Author: Simon Tyler Cousins
;; Keywords: processes, tools

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

;; Forge Process Major mode.
;; Used to run Forge commands.
;; Current supported Forge functions:
;;  * forge-process--new-project             - Run the forge new project command
;;  * forge-process--new-file                - Run the forge new file command
;;  * forge-process--add-file                - Run the forge add file command
;;  * forge-process--add-reference           - Run the forge add reference command
;;  * forge-process--remove-file             - Run the forge remove file command
;;  * forge-process--remove-reference        - Run the forge remove reference command
;;  * forge-process--rename-file             - Run the forge rename file command
;;  * forge-process--rename-project          - Run the forge rename project command
;;  * forge-process--list-files              - Run the forge list files command
;;  * forge-process--list-references         - Run the forge list references command
;;  * forge-process--list-project-references - Run the forge list project references command
;;  * forge-process--list-gac                - Run the forge list gac command
;;  * forge-process--list-templates          - Run the forge list templates command
;;  * forge-process--move-file               - Run the forge move file command
;;  * forge-process--update-paket            - Run the forge update paket command
;;  * forge-process--update-fake             - Run the forge update fake command
;;  * forge-process--paket                   - Run the forge paket command
;;  * forge-process--fake                    - Run the forge fake command



;; TODO:
;; forge exit status 1 for success???
;; forge command to get list of build actions???
;; add project
;; add reference
;; remove project
;; remove reference
;; rename project
;; rename folder


;;; Code:

(require 'compile)
(require 'button)

(defgroup forge-process nil
  "Forge Process group."
  :prefix "forge-process-"
  :group 'forge)

(defvar forge-process-mode-map
  (nconc (make-sparse-keymap) compilation-mode-map)
  "Keymap for Forge major mode.")

(defvar forge-process-last-command nil "Command used last for repeating.")

(defface forge-process--ok-face
  '((t (:foreground "#00ff00")))
  "Ok face"
  :group 'forge-process)

(defface forge-process--error-face
  '((t (:foreground "#FF0000")))
  "Error face"
  :group 'forge-process)

(defface forge-process--warning-face
  '((t (:foreground "#eeee00")))
  "Warning face"
  :group 'forge-process)

(defface forge-process--pointer-face
  '((t (:foreground "#ff00ff")))
  "Pointer face"
  :group 'forge-process)

(defface forge-process--standard-face
  '((t (:foreground "#ffa500")))
  "Standard face"
  :group 'forge-process)

(defface forge-process--errno-face
  '((t :foreground "#7777ff"
       :underline t))
  "Error number face"
  :group 'forge-process)

(defconst forge-process-font-lock-keywords
  '(("error\\:" . 'forge-process--error-face)
    ("warning\\:" . 'forge-process--warning-face)
    ("^\s*\\^\\~*\s*$" . 'forge-process--pointer-face)
    ("^\s*Compiling.*" . 'forge-process--standard-face)
    ("^\s*Running.*" . 'forge-process--standard-face)
    ("^\s*Updating.*" . 'forge-process--standard-face)
    ("test result: FAILED." . 'forge-process--error-face)
    ("test result: ok." . 'forge-process--ok-face)
    ("test\s.*\sFAILED" . 'forge-process--error-face)
    ("test\s.*\sok" . 'forge-process--ok-face))
  "Minimal highlighting expressions for forge-process mode.")

(defconst forge-process--build-actions
  '("Compile"
    "Content"
    "Reference"
    "None"
    "Resource"
    "EmbeddedResource")
  "File build actions.")

(defconst forge-process--file-templates
  '("fs" "fsx")
  "File templates.")

(defconst forge-process--default-args
  " --no-prompt"
  "Default arguments.")

(defconst forge-process--default-build-action
  "Compile"
  "Default build action.")

(define-derived-mode forge-process-mode compilation-mode "Forge-Process."
  "Major mode for the Forge process buffer."
  (use-local-map forge-process-mode-map)
  (setq major-mode 'forge-process-mode)
  (setq mode-name "Forge-Process")
  (setq-local truncate-lines t)
  (run-hooks 'forge-process-mode-hook)
  (font-lock-add-keywords nil forge-process-font-lock-keywords))

(defun forge-process--remove-bom (string)
  "Remove byte order mark from STRING."
  (replace-regexp-in-string "\u200f\\|\ufeff\\|ufffc" "" string))

(defun forge-process--add-default-args (command)
  "Add the default args to COMMAND."
  (concat command forge-process--default-args))

(defun forge-process--execute-command (command)
  "Execute the COMMAND."
  (let ((command (forge-process--add-default-args command)))
    (with-temp-buffer
      (call-process-shell-command command nil (current-buffer) nil))))

(defun forge-process--execute-command-lines (command)
  "Execute COMMAND, returning its output as a list of lines.
Signal an error if the command returns with a non-one exit status (forge exits with one???)."
  (with-temp-buffer
    (let* ((command (forge-process--add-default-args command))
           (status (apply 'call-process-shell-command command nil (current-buffer) nil)))
      (unless (eq status 1)
        (error "%s exited with status %s" command status))
      (goto-char (point-min))
      (let (lines)
        (while (not (eobp))
          (setq lines (cons (forge-process--remove-bom (buffer-substring-no-properties
                                                        (line-beginning-position)
                                                        (line-end-position)))
                            lines))
          (forward-line 1))
        (nreverse lines)))))

(defun forge-process--execute-command-buffer (command buffer-name)
  "Execute COMMAND in buffer BUFFER-NAME."
  (let ((command (forge-process--add-default-args command))
        (buffer (get-buffer-create buffer-name)))
    (switch-to-buffer buffer)
    (erase-buffer)
    (save-excursion
      (call-process-shell-command command nil (current-buffer) nil)
      (view-buffer buffer))))

(defun forge-process--compilation-name (mode-name)
  "Name of the Forge Process.  MODE-NAME is unused."
  "*Forge Process*")

(defun forge-process--finished-sentinel (process event)
  "Execute after PROCESS return and EVENT is 'finished'."
  (compilation-sentinel process event)
  (when (equal event "finished\n")
    (message "Forge Process finished.")))

(defun forge-process--cleanup (buffer)
  "Clean up the old Forge process BUFFER when a similar process is run."
  (when (get-buffer-process (get-buffer buffer))
    (delete-process buffer)))

(defun forge-process--activate-mode (buffer)
  "Execute commands BUFFER at process start."
  (with-current-buffer buffer
    (funcall 'forge-process-mode)
    (setq-local window-point-insertion-type t)))

;;; Project

(defun forge-process--find-sln-or-fsproj (dir-or-file)
  "Search for a solution or F# project file in any enclosing folders relative to DIR-OR-FILE."
  (or (forge-process--find-sln dir-or-file)
      (forge-process--find-fsproj dir-or-file)))

(defun forge-process--find-sln (dir-or-file)
  "Search for a solution file in any enclosing folders relative to DIR-OR-FILE."
  (forge-process--search-upwards (rx (0+ nonl) ".sln" eol)
                              (file-name-directory dir-or-file)))

(defun forge-process--find-fsproj (dir-or-file)
  "Search for a project file in any enclosing folders relative to DIR-OR-FILE."
    (forge-process--search-upwards (rx (0+ nonl) ".fsproj" eol)
     (file-name-directory dir-or-file)))

(defun forge-process--search-upwards (regex dir)
  "Search for a file matching REGEX in any enclosing folders relative to DIR."
  (when dir
    (or (car-safe (directory-files dir 'full regex))
        (forge-process--search-upwards regex (forge-process--parent-dir dir)))))

(defun forge-process--parent-dir (dir)
  "Return the parent folder of DIR."
  (let ((p (file-name-directory (directory-file-name dir))))
    (unless (equal p dir)
      p)))

(defun forge-process--start (name command)
  "Start the Forge process NAME with the forge command COMMAND."
  (let ((buffer (concat "*Forge " name "*"))
        (command (forge-process--add-default-args (forge-process--maybe-read-command command)))
        (project-root (forge-process--find-fsproj default-directory)))
    (save-some-buffers (not compilation-ask-about-save)
                       (lambda ()
                         (and project-root
                              buffer-file-name
                              (string-prefix-p project-root
                                               (file-truename buffer-file-name)))))
    (setq forge-process-last-command (list name command))
    (forge-process--cleanup buffer)
    (compilation-start command
                       'forge-process-mode 'forge-process--compilation-name)
    (with-current-buffer "*Forge Process*"
      (rename-buffer buffer))
    (set-process-sentinel
     (get-buffer-process buffer) 'forge-process--finished-sentinel)))

(defun forge-process--start2 (name command)
  "Start the Forge process NAME with the forge command COMMAND."
  (let ((buffer (concat "*Forge " name "*"))
        (command (forge-process--maybe-read-command command))
        (project-root (forge-process--find-fsproj default-directory)))
    (save-some-buffers (not compilation-ask-about-save)
                       (lambda ()
                         (and project-root
                              buffer-file-name
                              (string-prefix-p project-root
                                               (file-truename buffer-file-name)))))
    (setq forge-process-last-command (list name command))
    (forge-process--cleanup buffer)
    (compilation-start command
                       'forge-process-mode 'forge-process--compilation-name)
    (with-current-buffer "*Forge Process*"
      (rename-buffer buffer))
    (set-process-sentinel
     (get-buffer-process buffer) 'forge-process--finished-sentinel)))

(defun forge-process--maybe-read-command (default)
  "Prompt to modify the DEFAULT command when the prefix argument is present.
Without the prefix argument, return DEFAULT immediately."
  (if current-prefix-arg
      (read-shell-command "Forge command: " default)
    default))

(defun forge-process--template-list ()
  "List templates."
  ;; TODO: refresh templates???
  (let ((command "forge list templates"))
    (forge-process--execute-command-lines command)))

(defun forge-process--file-list-by-project (project)
  "List files in PROJECT."
  (let ((command (format "forge list files --project %s" project)))
    (forge-process--execute-command-lines command)))

;;; ----------------------------------------------------------------------
;;; New commands
;;; ----------------------------------------------------------------------

;;;###autoload
(defun forge-process--new-project (name dir template use-paket use-fake)
  "Run the Forge new project command.
NAME is the project name.
DIR is the project directory.
TEMPLATE is the name of the template to use to create the project.
USE-PAKET use Paket for package management.
USE-FAKE use FAKE for build if non-nil."
  (interactive
   (list
    (read-string "Project: ")
    (read-directory-name "Dir: ")
    (completing-read "Template: " (forge-process--template-list))
    (y-or-n-p "Use Paket? ")
    (y-or-n-p "Use FAKE? ")))
  (let*
      ((no-paket (when (not use-paket) " --no-paket"))
       (no-fake (when (not use-fake) " --no-fake"))
       (command
        (concat
         (format "forge new project --name %s --folder %s --template %s"
                 name dir template)
         no-paket no-fake)))
    (forge-process--start "New Project" command)))

;;;###autoload
(defun forge-process--new-file (project name template build-action)
  "Add a new file to a project.
PROJECT is the name of the project.
NAME is the name of the file to add to the project.
TEMPLATE is the template to use for the file.
BUILD-ACTION is the new file's build-action."
  (interactive
   (let ((fsproj (forge-process--find-fsproj default-directory)))
     (list
      (read-file-name "Project: " nil fsproj t fsproj nil)
      (read-string "File: ")
      (completing-read "Template: " forge-process--file-templates)
      (completing-read "Build Action: " forge-process--build-actions))))
  (let* ((name-less-ext (replace-regexp-in-string "\.fsx?$" "" name))
         (name-with-ext (concat name-less-ext "." template))
         (command
          (format
           "forge new file --name %s --template %s --project %s --build-action %s"
           name-less-ext template project build-action)))
    (forge-process--execute-command command)
    (message "Added new file %s.%s to project %s."
             (file-name-nondirectory name)
             template
             (file-name-nondirectory project))
    (sit-for 0.5)
    (find-file name-with-ext)))

;;; ----------------------------------------------------------------------
;;; Add commands
;;; ----------------------------------------------------------------------

;;;###autoload
(defun forge-process--add-file (project name build-action position-type)
  "Add an existing file to a project.
PROJECT is the name of the project.
NAME is the name of the file to add to the project.
BUILD-ACTION is the build-action to assign to the file.
POSITION-TYPE is where to add the file within the project."
  ;; TODO: link option
  ;; TODO: restrict project file selection to .fsproj files
  ;; ISSUE: forge option --above does not work
  ;; ISSUE: forge option --below does not work
  (interactive
   (let ((fsproj (forge-process--find-fsproj default-directory)))
     (list
      (read-file-name "Project: " nil fsproj t fsproj nil)
      (read-file-name "File: " nil nil t)
      (completing-read "Build Action: " forge-process--build-actions
                       nil t nil nil "Compile" nil)
      (completing-read "Position: " (list "Default" "Below" "Above")
                       nil t nil nil "Default" nil))))
  (let* ((file-list (forge-process--file-list-by-project project))
         (position-file
          (unless (string= position-type "Default")
            (completing-read (format "%s File: " position-type) file-list)))
         (position-option
          (unless (string= position-type "Default")
            (format " --%s %s" (downcase position-type)
                    (expand-file-name position-file))))
         (command
          (concat
           (format "forge add file --project %s --name %s --build-action %s"
                   project name build-action)
           position-option)))
    (forge-process--execute-command command)
    (message "Added file %s to project %s."
             (file-name-nondirectory name)
             (file-name-nondirectory project))
    (sit-for 0.5)))

;;;###autoload
(defun forge-process--add-reference (project name)
  "Add a reference to a project.
PROJECT is the name of the project.
NAME is the name of the reference to add to the project."
  (interactive
   (let ((fsproj (forge-process--find-fsproj default-directory)))
     (list
      (read-file-name "Project: " nil fsproj t fsproj nil)
      (read-string "Reference: "))))
  (let* ((name-less-ext (replace-regexp-in-string "\.dll$" "" name))
         (command (format "forge add reference --project %s --name %s"
                         project name-less-ext)))
    (forge-process--execute-command command)
    (message "Added reference %s to project %s"
             name (file-name-nondirectory project))
    (sit-for 0.5)))

;;; ----------------------------------------------------------------------
;;; Remove commands
;;; ----------------------------------------------------------------------

;;;###autoload
(defun forge-process--remove-file (project)
  "Within PROJECT, remove file NAME."
  (interactive
   (let ((fsproj (forge-process--find-fsproj default-directory)))
     (list
      (read-file-name "Project: " nil fsproj t fsproj nil))))
  (let* ((file-list (forge-process--file-list-by-project project))
         (name (completing-read "File: " file-list nil t))
         (command (format "forge remove file --project %s --name %s" project name)))
    (forge-process--execute-command command)
    (message "Removed file %s from %s."
             (file-name-nondirectory name)
             (file-name-nondirectory project))
    (sit-for 0.5)))

;;;###autoload
(defun forge-process--remove-reference (project name)
  "Remove a reference from a project.
PROJECT is the name of the project.
NAME is the name of the reference to add to the project."
  (interactive
   (let ((fsproj (forge-process--find-fsproj default-directory)))
     (list
      (read-file-name "Project: " nil fsproj t (file-name-nondirectory fsproj))
      ;; TODO: completing read from project references?
      (read-string "Reference: ")
      )))
  (let ((command (format "forge remove reference --project %s --name %s"
                         project name)))
    (forge-process--execute-command command)
    (message "Removed reference %s from project %s"
             name (file-name-nondirectory project))
    (sit-for 0.5)))

;;; ----------------------------------------------------------------------
;;; Rename commands
;;; ----------------------------------------------------------------------

;;;###autoload
(defun forge-process--rename-file (project)
  "Within PROJECT, rename file NAME to NEW-NAME."
  (interactive
   (let ((fsproj (forge-process--find-fsproj default-directory)))
     (list
      (read-file-name "Project: " nil fsproj t (file-name-nondirectory fsproj)))))
  (let* ((file-list (forge-process--file-list-by-project project))
         (name (completing-read "File: " file-list nil t))
         (new-name (read-string "New name: "))
         (command (format "forge rename file --project %s --name %s --rename %s"
                          project name new-name)))
    (forge-process--execute-command command)
    (message "Renamed file %s to %s in %s."
             (file-name-nondirectory name)
             new-name
             (file-name-nondirectory project))
    (sit-for 0.5)))

;;;###autoload
(defun forge-process--rename-project (project name)
  "Rename a project.
PROJECT is the name of the project to rename.
NAME is the new name for the project."
  (interactive
   (let ((fsproj (forge-process--find-fsproj default-directory)))
     (list
      (read-file-name "Project: " nil fsproj t (file-name-nondirectory fsproj))
      (read-string "Name: "))))
  (let ((command (format "forge rename project --name %s --rename %s"
                         project name)))
    (forge-process--execute-command command)
    (message "Renamed project %s to %s." (file-name-nondirectory project) name)
    (sit-for 0.5)))

;;; ----------------------------------------------------------------------
;;; List commands
;;; ----------------------------------------------------------------------

;;;###autoload
(defun forge-process--list-files (project)
  "List the files in the PROJECT."
  (interactive
   (let ((fsproj (forge-process--find-fsproj default-directory)))
     (list
      (read-file-name "Project: " nil fsproj t fsproj nil))))
  (let ((command (format "forge list files --project %s" project)))
    (forge-process--execute-command-buffer command "*forge list files project*")))

;;;###autoload
(defun forge-process--list-references (project)
  "List the references in the PROJECT."
  (interactive
   (list
    (read-file-name "Project: ")))
  (let ((command (format "forge list reference --project %s" project)))
    (forge-process--execute-command-buffer command "*forge list references*")))

;;;###autoload
(defun forge-process--list-project-references (project)
  "List the project references in the PROJECT."
  (interactive
   (list
    (read-file-name "Project: ")))
  (let
      ((command
        (format "forge list projectReferences --project %s" project)))
    (forge-process--execute-command-buffer command "*forge list files project*")))

;;;###autoload
(defun forge-process--list-projects (solution)
  "List the projects in the SOLUTION."
  (interactive
   (list
    (read-file-name "Solution: ")))
  (let ((command (format "forge list project --solution %s" solution)))
    (forge-process--execute-command-buffer command "*forge list projects*")))

;;;###autoload
(defun forge-process--list-gac ()
  "List the assemblies in the Global Assembly Cache."
  (message "not implemented: forge-process--list-gac"))

;;;###autoload
(defun forge-process--list-templates ()
  "List the templates in the template cache."
  (interactive)
  (let ((command "forge list templates"))
    (forge-process--execute-command-buffer command "*forge list templates*")))

;;; ----------------------------------------------------------------------
;;; Move commands
;;; ----------------------------------------------------------------------

;;;###autoload
(defun forge-process--move-file (project)
  "Within PROJECT, move file NAME in DIRECTION."
  (interactive
   (let ((fsproj (forge-process--find-fsproj default-directory)))
     (list
      (read-file-name "Project: " nil fsproj t (file-name-nondirectory fsproj)))))
  (let* ((file-list (forge-process--file-list-by-project project))
         (name (completing-read "File: " file-list nil t))
         (direction (completing-read "Direction: " (list "Up" "Down") nil t))
         (direction-option (format " --%s" (downcase direction)))
         (command
          (concat
           (format "forge move file --project %s --name %s" project name)
           direction-option)))
    (forge-process--execute-command command)
    (message "Moved file %s %s in %s."
             (file-name-nondirectory name)
             (downcase direction)
             (file-name-nondirectory project))
    (sit-for 0.5)))

;;; ----------------------------------------------------------------------
;;; Update commands
;;; ----------------------------------------------------------------------

;;;###autoload
(defun forge-process--update-paket ()
  "Update Paket to the latest version."
  (interactive)
  (let ((command "forge update paket"))
    (forge-process--start "Update" command)))

;;;###autoload
(defun forge-process--update-fake ()
  "Update FAKE to the latest version."
  (interactive)
  (let ((command "forge update fake"))
    (forge-process--start "Update" command)))

;;; ----------------------------------------------------------------------
;;; Paket commands
;;; ----------------------------------------------------------------------

;;;###autoload
(defun forge-process--paket ()
  "Update Paket to the latest version."
  (interactive)
  (let ((command "forge paket"))
    (forge-process--start2 "Paket" command)))

;;; ----------------------------------------------------------------------
;;; FAKE commands
;;; ----------------------------------------------------------------------

;;;###autoload
(defun forge-process--fake ()
  "Update FAKE to the latest version."
  (interactive)
  (let ((command "forge fake"))
    (forge-process--start "FAKE" command)))

;;; ======================================================================

(provide 'forge-process)
;;; forge-process.el ends here
