# org-blog

```emacs-lisp
(setq dotemacs-org-blog-dir "/path/to/org-blog/")
```

Generate RSS and minify CSS/JavaScript/HTML after publishing:

```emacs-lisp
(defun +org-generate-rss (project &optional force async)
  (let ((default-directory dotemacs-org-blog-dir))
    (dotemacs-call-process "python" "rss.py")
    (dotemacs-call-process "npm" "run" "minify")))
(advice-add 'org-publish-project :after #+org-generate-rss)
```
