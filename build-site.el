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

(require 'subr-x)
(require 'json)
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

(defun +org-blog-pages-prepare (project)
  "Generate search index, posts and tags page for all posts.

PROJECT is the property list of the project being prepared."
  (message "Preparation for blog-pages")
  (let* ((pages-project (assoc "blog-pages" org-publish-project-alist))
         (base-dir (expand-file-name (plist-get project :base-directory)))
         (posts-dir (expand-file-name "posts" base-dir))
         (tags-dir (expand-file-name "tags" base-dir))
         (posts-page (expand-file-name "index.org" posts-dir))
         (table (make-hash-table :test #'equal))
         (posts (sort (seq-keep
                       (lambda (file)
                         (unless (equal posts-page file)
                           (list :tags (or (ensure-list
                                            (org-publish-find-property file :filetags pages-project))
                                           '("Untagged"))
                                 :description (or (org-publish-find-property file :description pages-project 'html) "")
                                 :file file
                                 :date (org-publish-find-date file pages-project)
                                 :title (org-publish-find-title file pages-project))))
                       (directory-files-recursively posts-dir "\\.org$"))
                      (lambda (a b)
                        (time-less-p (plist-get a :date) (plist-get b :date)))))
         (search-index nil))
    (dolist (post posts)
      (push (list :title (plist-get post :title)
                  :description (plist-get post :description)
                  :keywords (string-join (plist-get post :tags) ",")
                  :url (concat "/"
                               (file-name-sans-extension (file-relative-name (plist-get post :file)
                                                                             base-dir))
                               ".html"))
            search-index)
      (dolist (tag (plist-get post :tags))
        (push post (gethash tag table))))
    (message "Generating search index")
    (with-temp-file (expand-file-name "index.json" base-dir)
      (insert (json-encode (vconcat search-index))))
    (message "Generating posts page")
    (with-temp-file posts-page
      (insert "#+TITLE: Posts\n"
              "#+OPTIONS: toc:nil date:nil\n\n")
      (dolist (post (nreverse posts))
        (insert (format "- [[file:%s][%s %s]]\n"
                        (file-relative-name (plist-get post :file) posts-dir)
                        (format-time-string "%Y-%m-%d" (plist-get post :date))
                        (plist-get post :title)))))
    (message "Generating tags page")
    (dolist (tag (hash-table-keys table))
      (with-temp-file (expand-file-name
                       (format "%s.org" (+org-html-stable-ids-to-kebab-case tag))
                       tags-dir)
        (insert "#+TITLE: Tag: " tag "\n"
                "#+OPTIONS: toc:nil date:nil\n\n")
        (dolist (post (gethash tag table))
          (insert (format "- [[file:%s][%s %s]]\n"
                          (file-relative-name (plist-get post :file) tags-dir)
                          (format-time-string "%Y-%m-%d" (plist-get post :date))
                          (plist-get post :title))))))
    (with-temp-file (expand-file-name "index.org" tags-dir)
      (insert "#+TITLE: Tags\n"
              "#+OPTIONS: toc:nil date:nil\n\n")
      (dolist (tag (sort (hash-table-keys table) #'string<))
        (insert (format "- [[file:%s][%s]] /%d/\n"
                        (format "%s.org" (+org-html-stable-ids-to-kebab-case tag))
                        tag
                        (length (gethash tag table))))))))

(defun +org-blog-file-contents (file)
  (with-temp-buffer
    (insert-file-contents file)
    (buffer-string)))

(defvar +org-html-head (+org-blog-file-contents "html/head.html"))
(defvar +org-html-header (+org-blog-file-contents "html/header.html"))
(defvar +org-html-footer (+org-blog-file-contents "html/footer.html"))

(org-export-define-derived-backend '+org-html 'html
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
   (let ((description (plist-get info :description)))
     (when (org-string-nw-p description)
       (format "<meta name=\"description\" content=\"%s\"/>\n" description)))
   (when-let* ((keywords (plist-get info :filetags)))
     (format "<meta name=\"keywords\" content=\"%s\"/>\n" (string-join keywords ",")))
   +org-html-head
   (when (and (memq (plist-get info :with-latex) '(mathjax t))
              (org-element-map (plist-get info :parse-tree) '(latex-fragment latex-environment) #'identity info t nil t))
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
      (format "<h1 class=\"article-title\">%s</h1>\n"
              (org-export-data (plist-get info :title) info))
      (when-let* ((meta (concat
                         (when (plist-get info :with-date)
                           (format "<span>%s</span>\n"
                                   (org-export-data (org-export-get-date info "%Y-%m-%d") info)))
                         (when-let* ((tags (plist-get info :filetags)))
                           (mapconcat
                            #'(lambda (key)
                                (format "<a href=\"/tags/%s.html\">#%s</a>\n"
                                        (+org-html-stable-ids-to-kebab-case key)
                                        key))
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
  (org-publish-org-to '+org-html filename ".html" plist pub-dir))

(setq org-publish-project-alist
      `(("blog-pages"
         :base-directory "./org"
         :base-extension "org"
         :recursive t
         :preparation-function +org-blog-pages-prepare
         :publishing-function +org-html-publish-to-html
         :publishing-directory "./public"
         :auto-sitemap nil)
        ("blog-static"
         :base-directory "./org"
         :base-extension "js\\|css\\|jpg\\|png\\|svg\\|gif\\|webp\\|ico\\|txt\\|json\\|webmanifest\\|woff2"
         :recursive t
         :publishing-function org-publish-attachment
         :publishing-directory "./public")
        ("blog" :components ("blog-pages" "blog-static"))))

(org-publish "blog" t)
