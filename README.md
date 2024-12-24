# org-blog

```elisp
(setq dotemacs-org-blog-dir "d:/github/org-site/"
      dotemacs-org-html-head "
<link rel=\"apple-touch-icon\" sizes=\"180x180\" href=\"/apple-touch-icon.png\">
<link rel=\"icon\" type=\"image/png\" sizes=\"32x32\" href=\"/favicon-32x32.png\">
<link rel=\"icon\" type=\"image/png\" sizes=\"16x16\" href=\"/favicon-16x16.png\">
<link rel=\"manifest\" href=\"/site.webmanifest\">
<link rel=\"stylesheet\" type=\"text/css\" href=\"/css/style.css\">
<script src=\"/js/copycode.js\"></script>
<script src=\"https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js\"></script>"
      dotemacs-org-html-preamble-format
      '(("en" "
<div class=\"header-wrapper\">
  <div class=\"site-header\">
  <a class=\"site-title\" href=\"/\">Chuck</a>
  <div class=\"site-nav\">
    <a class=\"nav-link\" href=\"/posts/\">Posts</a>
    <a class=\"nav-link\" href=\"/search/\">Search</a>
    <a class=\"nav-link\" href=\"/about/\">About</a>
  </div>
  </div>
</div>"))
      dotemacs-org-html-postamble-format
      '(("en" "
<div class=\"nav-btn\"><a href=\"/\">Home</a></div>
  <div class=\"top-btn\"><a href=\"#top\">Top</a></div>
  <div class=\"footer-wrapper\">
  <div class=\"site-footer\">&copy xuchengpeng. <a href=\"/feed.xml\">RSS Feed</a></div>
</div>")))
```

Generate rss automatically:

``` elisp
(with-eval-after-load 'ox-publish
  (defun dotemacs-generate-rss (project &optional force async)
    (let ((default-directory dotemacs-org-blog-dir))
      (dotemacs-call-process "python" "rss.py"))
    (message "dotemacs generate rss in %s" dotemacs-org-blog-dir))
  (advice-add 'org-publish-project :after #'dotemacs-generate-rss))
```
