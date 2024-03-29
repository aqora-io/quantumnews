# typed: false

SitemapGenerator::Sitemap.default_host = "https://news.aqora.io"

check_hourly = 4.days.ago
check_daily = 2.weeks.ago
top_score = Story.all.maximum("score")

SitemapGenerator::Sitemap.create do
  %w[/about].each do |path|
    add path, changefreq: "monthly", lastmod: nil
  end

  add recent_path, changefreq: "always", priority: 1
  add newest_path, changefreq: "always", priority: 1
  add comments_path, changefreq: "always", priority: 1

  Story.order("id desc").find_each do |story|
    last_comment = story.comments.order("id desc").first

    lastmod = story.created_at
    lastmod = last_comment.updated_at if last_comment && last_comment.updated_at > lastmod

    changefreq = "monthly"
    changefreq = "daily" if lastmod >= check_daily
    changefreq = "hourly" if lastmod >= check_hourly

    # Calculate priority and ensure it is not negative
    priority = [1.0 * story.score / top_score, 0].max

    add story.comments_path, lastmod: lastmod, changefreq: changefreq, priority: priority
  end
end
