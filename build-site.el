;;; build-site.el --- Build site.  -*- lexical-binding: t -*-

(set-charset-priority 'unicode)
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8-unix)
(set-keyboard-coding-system 'utf-8-unix)
(set-terminal-coding-system 'utf-8-unix)
(setq-default buffer-file-coding-system 'utf-8-unix)
(setq default-process-coding-system '(utf-8-unix . utf-8-unix))
(setq default-input-method nil)
(setq system-time-locale "C")
(setq locale-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)

(require 'package)
(setq package-user-dir (expand-file-name ".elpa/")
      package-check-signature nil
      package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("melpa" . "https://melpa.org/packages/")))

(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

(unless (package-installed-p 'htmlize)
  (package-install 'htmlize))

(require 'ox-publish)

(setq org-publish-timestamp-directory (expand-file-name ".org-timestamps/")
      org-export-in-background t
      org-export-headline-levels 4
      org-export-with-section-numbers nil
      org-export-with-author nil
      org-export-with-priority t
      org-export-with-toc t
      org-export-time-stamp-file nil
      org-export-use-babel nil
      org-html-checkbox-type 'html
      org-html-container-element "section"
      org-html-divs '((preamble  "header" "preamble")
                      (content   "main" "content")
                      (postamble "footer" "postamble"))
      org-html-doctype "html5"
      org-html-html5-fancy t
      org-html-htmlize-output-type 'css
      org-html-head-include-default-style nil
      org-html-head-include-scripts nil
      org-html-validation-link nil)

(defun +org-html-stable-ids-extract-id (datum)
  "Extract a reference from a DATUM.

Return DATUM's `:CUSTOM_ID` if set, or generate a reference from its
`:raw-value` property.  If the DATUM does not have either, return
nil."
  (or
   (org-element-property :CUSTOM_ID datum)
   (let ((value (org-element-property :raw-value datum)))
     (when value
       (+org-html-stable-ids-to-kebab-case value)))))

(defun +org-html-stable-ids-to-kebab-case (string)
  "Convert STRING to kebab-case."
  (downcase
   (string-trim
    (replace-regexp-in-string "[^A-Za-z0-9\u4e00-\u9fa5]+" "-" string)
    "-" "-")))

(defun +org-export-stable-ids-get-reference (datum info)
  "Return a reference for DATUM with INFO.

    Raise an error if the ID was used in the document before."
  (let ((cache (plist-get info :internal-references))
	    (id (+org-html-stable-ids-extract-id datum)))
	(or (car (rassq datum cache))
	    (if (assoc id cache)
		    (user-error "Duplicate ID: %s" id)
	      (when id
		    (push (cons id datum) cache)
		    (plist-put info :internal-references cache)
		    id)))))

(defun +org-html-stable-ids-reference (datum info &optional named-only)
  "Call `org-export-get-reference` to get a reference for DATUM with INFO.

If `NAMED-ONLY` is non-nil, return nil."
  (unless named-only
    (org-export-get-reference datum info)))

(advice-add #'org-export-get-reference :override #'+org-export-stable-ids-get-reference)
(advice-add #'org-html--reference :override #'+org-html-stable-ids-reference)

(defun +org-publish-sitemap (title list)
  (concat "#+TITLE: " title "\n"
          "#+OPTIONS: toc:nil\n\n"
          (org-list-to-org list)))

(defun +org-publish-sitemap-format-entry (entry style project)
  (cond ((not (directory-name-p entry))
         (format "[[file:%s][%s - %s]]"
                 entry
                 (format-time-string "%b %d, %Y" (org-publish-find-date entry project))
                 (org-publish-find-title entry project)))
        ((eq style 'tree)
         ;; Return only last subdir.
         (file-name-nondirectory (directory-file-name entry)))
        (t entry)))

(defun +org-blog-file-contents (file)
  (with-temp-buffer
    (insert-file-contents file)
    (buffer-string)))

(defvar +org-html-head (+org-blog-file-contents "html/head.html"))
(defvar +org-html-header (+org-blog-file-contents "html/header.html"))
(defvar +org-html-footer (+org-blog-file-contents "html/footer.html"))

(setq org-publish-project-alist
      `(("blog-posts"
         :base-directory "./org/posts"
         :base-extension "org"
         :recursive t
         :publishing-function org-html-publish-to-html
         :publishing-directory "./public/posts"
         :html-head ,+org-html-head
         :html-preamble ,+org-html-header
         :html-postamble ,+org-html-footer
         :html-mathjax-options ((path "https://cdn.jsdelivr.net/npm/mathjax@4/tex-mml-chtml.js"))
         :html-mathjax-template "<script id=\"MathJax-script\" async src=\"%PATH\"></script>"
         :auto-sitemap t
         :sitemap-filename "index.org"
         :sitemap-title "Posts"
         :sitemap-format-entry +org-publish-sitemap-format-entry
         :sitemap-function +org-publish-sitemap
         :sitemap-sort-files anti-chronologically)
        ("blog-pages"
         :base-directory "./org"
         :base-extension "org"
         :recursive nil
         :publishing-function org-html-publish-to-html
         :publishing-directory "./public"
         :html-head ,+org-html-head
         :html-preamble ,+org-html-header
         :html-postamble ,+org-html-footer
         :html-mathjax-options ((path "https://cdn.jsdelivr.net/npm/mathjax@4/tex-mml-chtml.js"))
         :html-mathjax-template "<script id=\"MathJax-script\" async src=\"%PATH\"></script>"
         :auto-sitemap nil)
        ("blog-static"
         :base-directory "./org"
         :base-extension "js\\|css\\|jpg\\|png\\|svg\\|gif\\|ico\\|txt\\|webmanifest\\|woff2"
         :recursive t
         :publishing-function org-publish-attachment
         :publishing-directory "./public")
        ("blog" :components ("blog-posts" "blog-pages" "blog-static"))))

(org-publish "blog" t)
