# org-blog

Build site:

```emacs-lisp
emacs -Q --script build-site.el
```

Generate `index.json` and minify CSS/JavaScript/HTML after publishing:

```bash
npm run index
npm run minify
```

Add org capture template:

```emacs-lisp
(defun +org-capture-org-blog ()
  (let* ((dir (completing-read "Select subdirectory: " '("posts")))
         (title (read-from-minibuffer "New file TITLE: "))
         (filename (downcase (string-trim (replace-regexp-in-string "[^A-Za-z0-9]+" "-" title) "-" "-"))))
    (expand-file-name
     (format "org/%s/%s-%s.org" dir (format-time-string "%Y-%m-%d") filename)
     "/path/to/org-blog/")))
(add-to-list 'org-capture-templates
             '("o" "Org Blog" plain
               (file +org-capture-org-blog)
               "#+TITLE: \n#+AUTHOR: \n#+DESCRIPTION: \n#+KEYWORDS: \n#+DATE: %T\n" :jump-to-captured t)
             t)
```
