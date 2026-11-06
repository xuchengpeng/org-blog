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

(defun +org-html-stable-ids-extract-value (datum)
  "Extract raw-value from a DATUM."
  (let ((value (or (org-element-property :raw-value datum)
                   (org-element-property-raw :value datum))))
    (unless (org-element-deferred-p value)
      value)))

(defun +org-html-stable-ids-extract-id (datum)
  "Extract a reference from a DATUM.

Return DATUM's `:CUSTOM_ID` if set, or generate a reference from its
`:raw-value` property.  If the DATUM does not have either, return
nil."
  (or
   (org-element-property :CUSTOM_ID datum)
   (let ((value (+org-html-stable-ids-extract-value datum)))
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
  "Default site map, as a string.
TITLE is the title of the site map.  LIST is an internal
representation for the files to include, as returned by
`org-list-to-lisp'.  PROJECT is the current project."
  (concat "#+TITLE: " title "\n"
          "#+OPTIONS: toc:nil date:nil\n\n"
          (org-list-to-org list)))

(defun +org-publish-sitemap-format-entry (entry style project)
  "Default format for site map ENTRY, as a string.
ENTRY is a file name.  STYLE is the style of the sitemap.
PROJECT is the current project."
  (cond ((not (directory-name-p entry))
         (format "[[file:%s][%s %s]]"
                 entry
                 (format-time-string "%Y-%m-%d" (org-publish-find-date entry project))
                 (org-publish-find-title entry project)))
        ((eq style 'tree)
         ;; Return only last subdir.
         (file-name-nondirectory (directory-file-name entry)))
        (t entry)))

(defun +org-list-to-tags-org (list)
  "Convert LIST into an Org plain list, grouped by tags."
  (let ((table (make-hash-table :test #'equal))
        res)
    (dolist (e (cdr list))
      (let* ((fields (split-string (car e) "|"))
             (tags (split-string (car fields) ":" t " +")))
        (dolist (tag tags)
          (puthash tag (cons (cdr fields) (gethash tag table)) table))))
    (maphash
     (lambda (tag entries)
       (push (concat
              (format "\n* %s\n\n" tag)
              (mapconcat
               (lambda (p)
                 (format "- [[file:posts/%s][%s %s]]\n"
                         (nth 0 p) (nth 1 p) (nth 2 p)))
               (nreverse entries) ""))
             res))
     table)
    (apply #'concat (nreverse res))))

(defun +org-publish-tags (title list)
  "Default tags page, as a string.
TITLE is the title of the tags page.  LIST is an internal
representation for the files to include, as returned by
`org-list-to-lisp'.  PROJECT is the current project."
  (concat "#+TITLE: " title "\n"
          "#+OPTIONS: toc:nil date:nil\n\n"
          (+org-list-to-tags-org list)))

(defun +org-publish-tags-format-entry (entry style project)
  "Default format for tags ENTRY, as a string.
ENTRY is a file name.  STYLE is the style of the sitemap.
PROJECT is the current project."
  (cond ((not (directory-name-p entry))
         (format "%s|%s|%s|%s"
                 (let ((tags (org-publish-find-property entry :filetags project)))
                   (if tags (string-join tags ":") "Untagged"))
                 entry
                 (format-time-string "%Y-%m-%d" (org-publish-find-date entry project))
                 (org-publish-find-title entry project)))
        (t entry)))

(defun +org-html-publish-tags-to-html (plist filename pub-dir)
  "Publish an org file to HTML.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (when (equal "tags.org" (file-name-nondirectory filename))
    (+org-html-publish-to-html plist filename pub-dir)))

(defun +org-blog-file-contents (file)
  (with-temp-buffer
    (insert-file-contents file)
    (buffer-string)))

(defvar +org-html-head (+org-blog-file-contents "html/head.html"))
(defvar +org-html-header (+org-blog-file-contents "html/header.html"))
(defvar +org-html-footer (+org-blog-file-contents "html/footer.html"))

(org-export-define-derived-backend
 '+org-html 'html
 :translate-alist '((template . +org-html-template)
                    (inner-template . +org-html-inner-template)))

(defun +org-html-template (contents info)
  "Return complete document string after HTML conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (concat
   "<!DOCTYPE html>\n"
   "<html lang=\"en\" class=\"scroll-smooth\">\n"
   "<head>\n"
   "<meta charset=\"utf-8\">\n"
   "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
   (format "<title>%s</title>\n" (org-export-data (plist-get info :title) info))
   (format "<meta name=\"description\" content=\"%s\"/>\n" (org-export-data (plist-get info :description) info))
   (format "<meta name=\"keywords\" content=\"%s\"/>\n" (org-export-data (plist-get info :filetags) info))
   +org-html-head
   (when (and (memq (plist-get info :with-latex) '(mathjax t))
              (org-element-map (plist-get info :parse-tree)
                  '(latex-fragment latex-environment) #'identity info t nil t))
     "<script id=\"MathJax-script\" async src=\"https://cdn.jsdelivr.net/npm/mathjax@4/tex-mml-chtml.js\"></script>\n")
   "</head>\n"
   "<body>\n"
   "<header class=\"header\">\n"
   +org-html-header
   "</header>\n"
   contents
   "<footer class=\"footer\">\n"
   +org-html-footer
   "</footer>\n"
   "</body>\n"
   "</html>"))

(defun +org-html-inner-template (contents info)
  "Return body of document string after HTML conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (concat
   "<main class=\"main\">\n"
   "<article class=\"article\">\n"
   (when (plist-get info :with-title)
     (concat
      "<div class=\"article-header\">\n"
      (format "<h1 class=\"article-title\">%s</h1>\n" (org-export-data (plist-get info :title) info))
      (when-let* ((meta (concat
                         (when (plist-get info :with-date)
                           (format "<span>%s</span>\n" (org-export-data (org-export-get-date info "%Y-%m-%d") info)))
                         (when-let* ((tags (plist-get info :filetags)))
                           (mapconcat
                            #'(lambda (key)
                                (format "<a href=\"/tags.html#%s\">#%s</a>\n" (+org-html-stable-ids-to-kebab-case key) key))
                            tags)))))
        (when (org-string-nw-p meta)
          (format "<div class=\"article-meta\">%s</div>\n" meta)))
      "</div>\n"))
   "<div class=\"article-content\">\n"
   (when-let* ((depth (plist-get info :with-toc))
               (toc (org-html-toc depth info)))
     (format "<div class=\"table-of-contents\"><div class=\"toc\">%s</div></div>\n" toc))
   "<div class=\"content\">\n"
   contents
   (org-html-footnote-section info)
   "</div>\n"
   "</div>\n"
   "</article>\n"
   "</main>\n"))

(defun +org-html-publish-to-html (plist filename pub-dir)
  "Publish an org file to HTML.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (org-publish-org-to '+org-html filename
		              (concat (when (> (length org-html-extension) 0) ".")
			                  (or (plist-get plist :html-extension)
				                  org-html-extension
				                  "html"))
		              plist pub-dir))

(setq org-publish-project-alist
      `(("blog-tags"
         :base-directory "./org/posts/"
         :base-extension "org"
         :recursive t
         :exclude ,(rx (seq line-start "index.org"))
         :publishing-function +org-html-publish-tags-to-html
         :publishing-directory "./public"
         :auto-sitemap t
         :sitemap-filename "tags.org"
         :sitemap-title "Tags"
         :sitemap-format-entry +org-publish-tags-format-entry
         :sitemap-function +org-publish-tags
         :sitemap-sort-files anti-chronologically)
        ("blog-posts"
         :base-directory "./org/posts"
         :base-extension "org"
         :recursive t
         :exclude ,(rx (seq line-start "tags.org"))
         :publishing-function +org-html-publish-to-html
         :publishing-directory "./public/posts"
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
         :publishing-function +org-html-publish-to-html
         :publishing-directory "./public"
         :auto-sitemap nil)
        ("blog-static"
         :base-directory "./org"
         :base-extension "js\\|css\\|jpg\\|png\\|svg\\|gif\\|webp\\|ico\\|txt\\|webmanifest\\|woff2"
         :recursive t
         :publishing-function org-publish-attachment
         :publishing-directory "./public")
        ("blog" :components ("blog-tags" "blog-posts" "blog-pages" "blog-static"))))

(org-publish "blog" t)
