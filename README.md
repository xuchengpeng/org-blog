# org-blog

```emacs-lisp
(setq dotemacs-org-blog-dir "/path/to/org-blog/")
```

Generate RSS, minify CSS and JavaScript automatically:

```emacs-lisp
(with-eval-after-load 'ox-publish
  (defun +org-generate-rss (project &optional force async)
    (let ((default-directory dotemacs-org-blog-dir))
      (dotemacs-call-process "python" "rss.py")
      (dotemacs-call-process "npm" "run" "minify"))
    (message "dotemacs generate rss in %s" dotemacs-org-blog-dir))
  (advice-add 'org-publish-project :after #+org-generate-rss))
```
