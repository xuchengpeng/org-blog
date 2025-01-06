# org-blog

```elisp
(setq dotemacs-org-blog-dir "d:/github/org-blog/"
      dotemacs-org-html-head "
<link rel=\"apple-touch-icon\" sizes=\"180x180\" href=\"/apple-touch-icon.png\">
<link rel=\"icon\" type=\"image/png\" sizes=\"32x32\" href=\"/favicon-32x32.png\">
<link rel=\"icon\" type=\"image/png\" sizes=\"16x16\" href=\"/favicon-16x16.png\">
<link rel=\"manifest\" href=\"/site.webmanifest\">
<link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css?family=Open+Sans|Cousine&display=swap\">
<link rel=\"stylesheet\" type=\"text/css\" href=\"/css/style.css\">"
      dotemacs-org-html-preamble "
<div class=\"header-wrapper\">
  <div class=\"site-header\">
  <a class=\"site-title\" href=\"/\">Chuck</a>
  <div class=\"site-nav\">
    <a class=\"nav-link\" href=\"/posts/\">Posts</a>
    <a class=\"nav-link\" href=\"/about.html\">About</a>
    <a class=\"nav-link\" href=\"/search.html\">&#x1F50D;&#xFE0E;</a>
  </div>
  </div>
</div>"
      dotemacs-org-html-postamble "
<a href=\"#top\" class=\"top-link\" id=\"top-link\" style=\"visibility: hidden; opacity: 0;\">Top &#8593;</a>
<script async src=\"/js/scroll-to-top.js\"></script>
<div class=\"footer-wrapper\">
  <div class=\"site-footer\">&copy xuchengpeng. <a href=\"/feed.xml\">RSS Feed</a></div>
</div>")
```

Generate rss automatically:

``` elisp
(with-eval-after-load 'ox-publish
  (defun +org-generate-rss (project &optional force async)
    (let ((default-directory dotemacs-org-blog-dir))
      (dotemacs-call-process "python" "rss.py"))
    (message "dotemacs generate rss in %s" dotemacs-org-blog-dir))
  (advice-add 'org-publish-project :after #+org-generate-rss))
```
