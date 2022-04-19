;; sudo apt install -y cmake libtool libtool-bin xsel isync
;; Hiding UI elements
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;; General
(setq inhibit-startup-message t) ; Don't show emacs startup screen
(setq indent-tabs-mode nil) ; Set tabs to spaces
(setq default-tab-width 2) ; Tabs are two spaces
(setq tab-width 2) ; Tabs are two space
;(setq indent-line-function 'insert-tab) ; Tab key doesn't try to match indentation level
(setq initial-scratch-message ";; Happy Hacking!\n") ; Message displayed in scratchpad 
(setq confirm-kill-emacs 'y-or-n-p) ; Prompt before killing emacs
;(set-face-attribute 'default nil :font "SauceCodePro Nerd Font" :height 150) ; Font
;(set-face-attribute 'default nil :font "TerminessTTF Nerd Font" :height 150)
(set-face-attribute 'default nil :font "TerminessTTF NF" :height 180)
(setq backup-directory-alist `(("." . "~/.local/emacs.cache"))) ; Change the location for emacs backup files
(setq backup-by-copying t) ; Create full file backups
(setq delete-old-versions t ; Rotate backups
  kept-new-versions 6
  kept-old-versions 2
  version-control t)
(electric-pair-mode 1) ; Automatically enclose brackets
(cd (getenv "HOME")) ; Always start emacs in the users home folder
(global-auto-revert-mode t) ; Refresh a file if it's changed on disk 
(setq global-auto-revert-non-file-buffers t) ; Refresh dired buffers
(setq auto-revert-verbose nil) ; Refresh dired buffers
(defalias 'yes-or-no-p 'y-or-n-p) ; Allow "y" and "n" for interactive prompts
(setq vc-follow-symlinks t) ; Follow git controlled links
(setq gc-cons-threshold (* 50 1000 1000)) ;; Garbage collection hack
(setq show-paren-delay 0) ; Highlight matching parenthesis
(show-paren-mode 1) ; Highlight matching parenthesis
(setq show-paren-style 'mixed) ; Highlight matching parenthesis
(setq-default left-margin-width 2) ; Emacs margins left
(setq-default right-margin-width 2) ; Emacs margins right
;(setq split-width-threshold 0) ; Open new windows vertically by default
;(setq split-height-threshold nil) ; Open new windows vertically by default

;; Package manager setup
(require 'package)
(setq package-enable-at-startup nil)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))
(package-initialize)
(unless package-archive-contents
    (package-refresh-contents))

;; Use-Package
(unless (package-installed-p 'use-package)
    (package-refresh-contents)
    (package-install 'use-package))

;; Use-Package Quelpa
(use-package quelpa-use-package
  :ensure t
  :pin melpa
  :init
  (setq quelpa-update-melpa-p nil))

;; Download Which-Key
(use-package which-key
  :ensure t
  :config
  (which-key-mode))

;; Download Evil
(use-package evil
  :ensure t
  :init
  (setq evil-want-C-u-scroll t)
  (setq evil-want-keybinding nil)
  (setq evil-want-integration t)
  (setq evil-auto-indent nil)
  (setq evil-want-minibuffer t)
  :config
  (define-key evil-normal-state-map (kbd ">") 'indent-for-tab-command)
  (define-key evil-normal-state-map (kbd "C-w s") 'split-and-follow-horizontally)
  (define-key evil-normal-state-map (kbd "C-w v")'split-and-follow-vertically)
  (define-key evil-normal-state-map (kbd "C-w C-s") 'split-and-follow-horizontally)
  (define-key evil-normal-state-map (kbd "C-w C-v")'split-and-follow-vertically)
  (define-key evil-normal-state-map (kbd "C-w C-q")'evil-quit)
  (define-key evil-normal-state-map (kbd "C-q")' evil-quit)
  (define-key evil-normal-state-map (kbd "C-x C-x C-f")'toggle-maximize-buffer)
  (define-key evil-normal-state-map (kbd "C-b")'switch-to-buffer)
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :ensure t
  :config
  (evil-collection-init))

(use-package evil-escape ; Use C-g to go to normal mode
  :ensure t
  :commands evil-escape-mode
  :init
  (setq evil-escape-excluded-states '(normal visual multiedit emacs motion)
        evil-escape-excluded-major-modes '(neotree-mode)
        evil-escape-key-sequence "jk"
        evil-escape-delay 0.25)
  (add-hook 'after-init-hook #'evil-escape-mode)
  :config
  ;; no `evil-escape' in minibuffer
  (cl-pushnew #'minibufferp evil-escape-inhibit-functions :test #'eq)

  (define-key evil-insert-state-map  (kbd "C-g") #'evil-escape)
  (define-key evil-insert-state-map  (kbd "M-g") #'evil-escape)
  (define-key evil-replace-state-map (kbd "C-g") #'evil-escape)
  (define-key evil-visual-state-map  (kbd "C-g") #'evil-escape)
  (define-key evil-operator-state-map (kbd "C-g") #'evil-escape))

;; Download Undo-Fu
(use-package undo-fu
  :ensure t
  :after evil
  :config
  (define-key evil-normal-state-map "u" 'undo-fu-only-undo)
  (define-key evil-normal-state-map "\C-r" 'undo-fu-only-redo))

;; Download Doom Modeline, Doom themes, and Icons
(use-package all-the-icons
  :ensure t)

(use-package doom-themes
  :ensure t
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-molokai t)
  (doom-themes-visual-bell-config) ; Enable flashing mode-line on errors
  (doom-themes-org-config)) ; Corrects (and improves) org-mode's native fontification.

(use-package doom-modeline
  :ensure t
  :init
  (setq doom-modeline-height 10) ; How tall the modeline bar should be
  (setq doom-modeline-bar-width 4) ; How wide the modeline bar should be
  (setq doom-modeline-hud nil) ; Whether to use hud instead of the default bar
  (setq display-time-format "%I:%M")
  (setq display-time-default-load-average nil)
  (display-battery-mode)
  (display-time-mode)
  :config
  (doom-modeline-mode 1))

;; Download IBuffer
(use-package ibuffer
  :ensure nil
  :bind ("C-x C-b" . ibuffer)
  :hook
  (ibuffer-mode . hl-line-mode)
  :config
  (setq ibuffer-expert t)
  (setq ibuffer-show-empty-filter-groups nil)
  ;(add-to-list 'ibuffer-never-show-predicates "^\\*Warning")
  ;; Use human readable Size column instead of original one
  (define-ibuffer-column size-h
    (:name "Size" :inline t)
    (cond
     ((> (buffer-size) 1000000) (format "%7.1fM" (/ (buffer-size) 1000000.0)))
     ((> (buffer-size) 100000) (format "%7.0fk" (/ (buffer-size) 1000.0)))
     ((> (buffer-size) 1000) (format "%7.1fk" (/ (buffer-size) 1000.0)))
     (t (format "%8d" (buffer-size)))))

;; Modify the default ibuffer-formats
  (setq ibuffer-formats
        '((mark modified read-only " "
                (name 40 40 :left :elide)
                " "
                (mode 16 16 :left :elide)
                " "
                filename-and-process)))
  (setq ibuffer-saved-filter-groups
      '(("home"
         ("Programs" (mode . exwm-mode))
         ("Emacs" (or (filename . ".emacs.d")
                             (filename . "emacs-config")))
         ("Org" (or (mode . org-mode)
                    (filename . "OrgMode")))
         ("Web Dev" (or (mode . html-mode)
                        (mode . css-mode)))
         ("Terminal" (mode . vterm-mode))
         ("Dired" (mode . dired-mode))
         ("Magit" (name . "\*magit"))
         ("Help" (or (name . "\*Help\*")
                     (name . "\*Apropos\*")
                     (name . "\*info\*")))
         ("Browser" (mode . eaf-mode))
         ("Ement" (name . "\*Ement *")))))
  (add-hook 'ibuffer-mode-hook
          (lambda ()
             (ibuffer-switch-to-saved-filter-groups "home")))) ; [built-in] Powerful interface for managing buffers
(add-hook 'ibuffer-mode-hook (lambda () (ibuffer-auto-mode 1)))

;; Download EWW Web Browser
(use-package eww
  :ensure t)

;; Download Orgmode
(use-package org
  :ensure t)

;; Download EyeBrowse
(use-package eyebrowse
  :ensure t
  :config
  (define-key eyebrowse-mode-map (kbd "C-1") 'eyebrowse-switch-to-window-config-1)
  (define-key eyebrowse-mode-map (kbd "C-2") 'eyebrowse-switch-to-window-config-2)
  (define-key eyebrowse-mode-map (kbd "C-3") 'eyebrowse-switch-to-window-config-3)
  (define-key eyebrowse-mode-map (kbd "C-4") 'eyebrowse-switch-to-window-config-4)
  (define-key eyebrowse-mode-map (kbd "C-5") 'eyebrowse-switch-to-window-config-5)
  (define-key eyebrowse-mode-map (kbd "C-6") 'eyebrowse-switch-to-window-config-6)
  (define-key eyebrowse-mode-map (kbd "C-7") 'eyebrowse-switch-to-window-config-7)
  (define-key eyebrowse-mode-map (kbd "C-8") 'eyebrowse-switch-to-window-config-8)
  (define-key eyebrowse-mode-map (kbd "C-9") 'eyebrowse-switch-to-window-config-9)
  (eyebrowse-mode t)
  (setq eyebrowse-new-workspace t))

;; Download Powershell Mode
(use-package powershell
  :ensure t)

;; Download Company Mode (code completion)
(use-package company
  :ensure t
  :config
  (define-key company-active-map (kbd "C-n") 'company-select-next)
  (define-key company-active-map (kbd "C-p") 'company-select-previous)
  (setq company-idle-delay 0.0)
)
(use-package company-web
  :ensure t)
(use-package company-shell
  :ensure t)
(use-package company-php
  :ensure t)
(use-package company-nginx
  :ensure t)
(use-package company-go
  :ensure t)
(use-package company-org-block
  :ensure t)

;; Download General.el (keybinding)
(use-package general
  :ensure t
  :config
  (general-create-definer leader
    :prefix "SPC")
  (leader
    :keymaps '(normal visual)
    "b" 'switch-to-buffer
    "c" 'comment-region
    "C" 'uncomment-region
    "e" 'eval-region
    "f" 'fzf-find-file
    "s" 'swiper-isearch
    "wv" 'evil-window-vsplit
    "ws" 'evil-window-split
    ";" 'eshell
    "q" 'evil-quit
    "wq" 'evil-quit
    "wj" 'evil-window-down
    "wk" 'evil-window-top
    "wh" 'evil-window-left
    "wl" 'evil-window-right))

;; Download Swiper
(use-package swiper
  :ensure t
  :config
  (progn
    (set-face-attribute 'ivy-current-match nil :foreground "white")
    (set-face-attribute 'ivy-minibuffer-match-face-2 nil :foreground "white" :background "red")
    (set-face-attribute 'ivy-minibuffer-match-face-3 nil :foreground "white" :background "darkgreen")
    (set-face-attribute 'ivy-minibuffer-match-face-4 nil :foreground "white" :background "blue")
    (set-face-attribute 'swiper-match-face-2         nil :foreground "white" :background "red")
    (set-face-attribute 'swiper-match-face-3         nil :foreground "white" :background "darkgreen")
    (set-face-attribute 'swiper-match-face-4         nil :foreground "white" :background "blue")))
(use-package counsel
  :ensure t)
(use-package ivy
  :ensure t
  :init
  (setq ivy-use-virtual-buffers t)
  (setq enable-recursive-minibuffers t)
  :config
  (ivy-mode))

;; Download Rainbow Parenthesis
(use-package rainbow-delimiters
  :ensure t
  :config
  (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))

;; Download saveplace (saves cursor position)
(use-package saveplace
  :ensure t
  :config
  (save-place-mode))

;; Download dired
(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  :custom ((dired-listing-switches "-agho --group-directories-first"))
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "h" 'dired-single-up-directory
    "l" 'dired-single-buffer))

(use-package dired-single
  :ensure t)

(use-package dired-open
  :ensure t
  :config
  ;; Doesn't work as expected!
  ;;(add-to-list 'dired-open-functions #'dired-open-xdg t)
  (setq dired-open-extensions '(("png" . "feh")
                                ("mkv" . "mpv"))))
(use-package dired-hide-dotfiles
  :ensure t
  :hook (dired-mode . dired-hide-dotfiles-mode)
  :config
  (evil-collection-define-key 'normal 'dired-mode-map
    "H" 'dired-hide-dotfiles-mode))
(add-hook 'dired-mode-hook        (lambda ()
            (dired-hide-details-mode)
      (auto-revert-mode)))

;; Download VTerm
;(use-package vterm
;  :ensure t)

;; Download PDF-Tools
(use-package pdf-tools
  :ensure t
  :defer t
  :config
  (pdf-tools-install)
  (setq-default pdf-view-display-size 'fit-page))

;; Download EPA (gpg)
(use-package epg
  :init
  (setq epg-gpg-program "gpg")
  (setq epg-pinentry-mode 'loopback)
  (setenv "GPG_AGENT_INFO" nil)
  :ensure t)

;; Download Dmenu
(use-package dmenu
  :ensure t
  :bind ("M-r" . dmenu)
  )

;; Download Proced (htop)
(use-package proced
  :ensure t)

;; Download TRAMP
(use-package tramp
  :ensure t
  :init
  (setq tramp-default-method "plink")
  )

;; Download WS-Butler (trim whitespace)
(use-package ws-butler
  :config
  (add-hook 'prog-mode-hook #'ws-butler-mode)
  :ensure t)

;; Download Eshell
(defun eshell-new()
  "Open a new instance of eshell."
  (interactive)
  (eshell 'N))

(defun me/eshell-mode-hook()
  (me/eshell-add-aliases)
  (company-mode -1))

(defun me/eshell-add-aliases ()
"Doc-string."
  (dolist (var '(("ff" "find-file $1")
                 ("ssh" "cd /ssh:$1:~")
                 ("plink" "cd /plink:$1:~")))
    (add-to-list 'eshell-command-aliases-list var)))

;; (setq eshell-prompt-regexp "^[^#$\n]*[#$] "
;;       eshell-prompt-function
;;       (lambda nil
;;         (concat
;;          (if (string= (eshell/pwd) (getenv "HOME"))
;;              "~" (eshell/basename (eshell/pwd)))
;;          (if (= (user-uid) 0) "# " " > "))))

(use-package eshell
  :ensure t
  :config
  (add-hook 'eshell-post-command-hook 'me/eshell-mode-hook)
  (add-hook 'eshell-post-command-hook 'me/eshell-add-aliases)
  ;(setq display-buffer-alist '(("\\`\\*e?shell" display-buffer-pop-up-window))) ; Always open Eshell in a new window
)

;; Download Games
(use-package typit
  :ensure t)
(use-package tetris
  :ensure t)
(use-package snake
  :ensure t)
(use-package pong
  :ensure t)
(use-package minesweeper
  :ensure t)

;; Untabify on save
(defvar untabify-this-buffer)
(defun untabify-all ()
  "Untabify the current buffer, unless `untabify-this-buffer' is nil."
  (and untabify-this-buffer (untabify (point-min) (point-max))))
(define-minor-mode untabify-mode
  "Untabify buffer on save." nil " untab" nil
  (make-variable-buffer-local 'untabify-this-buffer)
  (setq untabify-this-buffer (not (derived-mode-p 'makefile-mode)))
  (add-hook 'before-save-hook #'untabify-all))
(add-hook 'prog-mode-hook 'untabify-mode)

;; Split and follow new windows automatically
(defun split-and-follow-horizontally ()
  (interactive)
  (split-window-below)
  (balance-windows)
  (other-window 1))

(defun split-and-follow-vertically ()
  (interactive)
  (split-window-right)
  (balance-windows)
  (other-window 1))

;; Open scratchpad in another Window
(defun scratchpad-other-window-vertically()
  (interactive)
  (split-window-right)
  (balance-windows)
  (other-window 1)
  (switch-to-buffer "*scratch*"))

(defun scratchpad-other-window-horizontally()
  (interactive)
  (split-window-below)
  (balance-windows)
  (other-window 1)
  (switch-to-buffer "*scratch*"))

;; Copy Paste from clipboard
(defun copy-to-clipboard ()
  (interactive)
  (if (display-graphic-p)
      (progn
        (message "Yanked region to x-clipboard!")
        (call-interactively 'clipboard-kill-ring-save)
        )
    (if (region-active-p)
        (progn
          (shell-command-on-region (region-beginning) (region-end) "xsel -i -b")
          (message "Yanked region to clipboard!")
          (deactivate-mark))
      (message "No region active; can't yank to clipboard!")))
  )

(defun paste-from-clipboard ()
  (interactive)
  (if (display-graphic-p)
      (progn
        (clipboard-yank)
        (message "graphics active")
        )
    (insert (shell-command-to-string "xsel -o -b"))
    )
  )

;; Display startup time on startup
(defun efs/display-startup-time ()
  (message "Emacs loaded in %s with %d garbage collections."
           (format "%.2f seconds"
                   (float-time
                   (time-subtract after-init-time before-init-time)))
           gcs-done))

(add-hook 'emacs-startup-hook #'efs/display-startup-time)

;; Lower brightness keys
(defun my/lower-brightness()
  (interactive)
  (shell-command "/home/anon/.bin/brightness down"))
(defun my/raise-brightness()
  (interactive)
  (shell-command "/home/anon/.bin/brightness up"))

(global-set-key (kbd "C-x <") 'my/lower-brightness)
(global-set-key (kbd "C-x >") 'my/raise-brightness)

;; Shutdown computer
(defun my/shutdown()
  (interactive)
  (if (y-or-n-p "Shutdown this computer?")
      (if (eq system-type 'windows-nt)
          (progn (shell-command "C:/Windows/system32/shutdown.exe /f /s /t 0")))
    (if (eq system-type 'gnu/linux)
        (progn (shell-command "/usr/sbin/poweroff")))
    ))
(defun my/reboot()
  (interactive)
  (if (y-or-n-p "Reboot this computer?")
      (if (eq system-type 'windows-nt)
          (progn (shell-command "C:/Windows/system32/shutdown.exe /r /f /t 0")))
    (if (eq system-type 'gnu/linux)
        (progn (shell-command "/usr/sbin/reboot")))
    ))
(global-set-key (kbd "C-x C-p") 'my/shutdown)
(global-set-key (kbd "C-x C-r") 'my/reboot)

;; Quickly switch to previous buffer
(defun switch-to-last-buffer ()
  (interactive)
  (switch-to-buffer nil))
(global-set-key (kbd "C-s") 'switch-to-last-buffer)

;; Toggle fullscreen for a buffer
(defun toggle-maximize-buffer () "Maximize buffer"
  (interactive)
  (if (= 1 (length (window-list)))
      (jump-to-register '_)
    (progn
      (window-configuration-to-register '_)
      (delete-other-windows))))

;; Follow 80 column rule
;; (setq-default
;;  whitespace-line-column 8
;;  whitespace-style       '(face lines-tail))
;; (add-hook 'prog-mode-hook #'whitespace-mode)

;; Resize text with Alt + and Alt -
(global-set-key (kbd "M-=") 'text-scale-increase)
(global-set-key (kbd "M--") 'text-scale-decrease)

;; Window creating
(define-key evil-normal-state-map (kbd "M-\\") 'scratchpad-other-window-vertically)
(define-key evil-normal-state-map (kbd "M-|")'scratchpad-other-window-horizontally)
;; Window resizing
(global-set-key (kbd "M-[") 'evil-window-decrease-width)
(global-set-key (kbd "M-]") 'evil-window-increase-width)
(global-set-key (kbd "M-{") 'evil-window-decrease-height)
(global-set-key (kbd "M-}") 'evil-window-increase-height)
;; Window switching
(global-unset-key (kbd "M-k"))
(global-unset-key (kbd "M-j"))
(global-unset-key (kbd "M-h"))
(global-unset-key (kbd "M-l"))
(define-key evil-normal-state-map (kbd "M-k") 'evil-window-up)
(define-key evil-normal-state-map (kbd "M-j") 'evil-window-down)
(define-key evil-normal-state-map (kbd "M-h") 'evil-window-left)
(define-key evil-normal-state-map (kbd "M-l") 'evil-window-right)
;; Window swapping
(define-key evil-normal-state-map (kbd "M-K") 'evil-window-move-very-top)
(define-key evil-normal-state-map (kbd "M-J") 'evil-window-move-very-bottom)
(define-key evil-normal-state-map (kbd "M-H") 'evil-window-move-far-left)
(define-key evil-normal-state-map (kbd "M-L") 'evil-window-move-far-right)
;; Workspace switching
(define-key eyebrowse-mode-map (kbd "M-1") 'eyebrowse-switch-to-window-config-1)
(define-key eyebrowse-mode-map (kbd "M-2") 'eyebrowse-switch-to-window-config-2)
(define-key eyebrowse-mode-map (kbd "M-3") 'eyebrowse-switch-to-window-config-3)
(define-key eyebrowse-mode-map (kbd "M-4") 'eyebrowse-switch-to-window-config-4)
(define-key eyebrowse-mode-map (kbd "M-5") 'eyebrowse-switch-to-window-config-5)
(define-key eyebrowse-mode-map (kbd "M-6") 'eyebrowse-switch-to-window-config-6)
(define-key eyebrowse-mode-map (kbd "M-7") 'eyebrowse-switch-to-window-config-7)
(define-key eyebrowse-mode-map (kbd "M-8") 'eyebrowse-switch-to-window-config-8)
(define-key eyebrowse-mode-map (kbd "M-9") 'eyebrowse-switch-to-window-config-9)
;; General bindings
(define-key evil-normal-state-map (kbd "M-q") 'evil-quit)
(define-key evil-normal-state-map (kbd "M-b") 'switch-to-buffer)
(define-key evil-normal-state-map (kbd "M-s") 'switch-to-last-buffer)
(define-key evil-normal-state-map (kbd "M-f") 'find-file)

;; Quickly edit config file
(global-set-key (kbd "C-c e") (lambda () (interactive) (find-file "~/.emacs.d/init.el")))

;; Re-create scratch buffer if it's killed
(defun prepare-scratch-for-kill ()
  (save-excursion
    (set-buffer (get-buffer-create "*scratch*"))
    (add-hook 'kill-buffer-query-functions 'kill-scratch-buffer t)))

(defun kill-scratch-buffer ()
  (let (kill-buffer-query-functions)
    (kill-buffer (current-buffer)))
  ;; no way, *scratch* shall live
  (prepare-scratch-for-kill)
  ;; Since we "killed" it, don't let caller try too
  nil)

;; Stop Emacs daemon
(defun server-shutdown ()
  "Save buffers, Quit, and Shutdown (kill) server"
  (interactive)
  (save-some-buffers)
  (kill-emacs))

;; Restart Emacs Daemon
(defun server-restart()
  (interactive)
  (server-force-delete)
  (server-start))

;; Garbage collection hack
(setq gc-cons-threshold (* 2 1000 1000))
;(load "~/.emacs.d/exwm/exwm.el")
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(edwina dashboard evil-escape eshell-prompt-extras ws-butler sudo-edit exwm GCMH ts plz dmenu dired-hide-dotfiles dired-open dired-single elfeed quick-yes mini-frame marginalia vertico which-key vterm vscode-dark-plus-theme undo-tree undo-fu simpleclip rainbow-delimiters quelpa-use-package powershell pdf-tools mini-modeline mentor matrix-client general fzf eyebrowse evil-collection ergoemacs-status epc ement doom-themes doom-modeline counsel company-web company-shell company-php company-org-block company-nginx company-go)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
