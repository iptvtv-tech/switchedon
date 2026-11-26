#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Switched On content checks.
#
# Run from the site folder:
#   ruby _tools/check_content.rb               checks the source files (guides, pages, data, includes)
#   ruby _tools/check_content.rb --site _site  also checks the built pages (after jekyll build or serve)
#   ... --site _site --baseurl /switchedon     the same, for a build made with that base path (GitHub's
#                                              github.io address before the custom domain is set)
#
# ERROR = breaks a hard rule. The script ends with exit code 1, so a GitHub Actions deploy stops.
# WARN  = worth a look, but doesn't stop anything.
#
# Jekyll doesn't publish folders that start with "_", so this file never goes live.

require "yaml"
require "date"
require "uri"

ROOT = Dir.pwd
TODAY = Date.today

ERRORS = []
WARNINGS = []

def err(where, msg) = ERRORS << "#{where}: #{msg}"
def warn_(where, msg) = WARNINGS << "#{where}: #{msg}"

def read(path) = File.read(path, encoding: "UTF-8")

def load_yaml(text)
  YAML.safe_load(text, permitted_classes: [Date, Time], aliases: true) || {}
end

# Returns [front_matter_hash, body] or [nil, text] if the file has no front matter.
def split_front_matter(text)
  m = text.match(/\A---\s*\r?\n(.*?)\r?\n---\s*\r?\n(.*)\z/m)
  return [nil, text] unless m
  [load_yaml(m[1]), m[2]]
end

def date?(v) = v.is_a?(Date)

# ---------------------------------------------------------------- rules

TITLE_MAX = 60        # "under 60 characters where possible" -> warning
DESCRIPTION_MAX = 160 # "descriptions under 160" -> error
RECHECK_DAYS = 100    # quarterly re-checks: warn once a guide's last check is older than this
PRICE_DAYS = 60       # prices move faster: warn once a guide's prices_checked date is older than this
DIAGRAM_RULE_FROM = Date.new(2026, 11, 26)  # guides approved from this day on need a diagram or a no_diagram: reason (rule set 25 Nov 2026)
FORMATS = %w[guide quick-answer buying-guide].freeze

# Never on the site: first-hand testing claims, VPNs, unofficial IPTV.
BANNED = {
  /\bwe(?:'ve|’ve| have)? tested\b/i => "claims first-hand testing (\"we tested\")",
  /\bin our tests?\b/i => "claims first-hand testing (\"in our tests\")",
  /\bour testing\b/i => "claims first-hand testing (\"our testing\")",
  /\btested by us\b/i => "claims first-hand testing (\"tested by us\")",
  /\bhands[- ]on\b/i => "uses \"hands-on\" (implies first-hand testing)",
  /\bVPNs?\b/ => "mentions VPNs",
  /\bIPTV\b/i => "mentions IPTV"
}.freeze

# Links that are affiliate or tracked. Sources must be plain links, and affiliate
# links may only come from _data/products.yml through the product card includes.
AFFILIATE_HOSTS = %w[
  awin1.com awin.com anrdoezrs.net dpbolvw.net jdoqocy.com kqzyfj.com tkqlhce.com
  emjcd.com qksrv.net amzn.to amzn.eu go.skimresources.com redirect.viglink.com
  shareasale.com click.linksynergy.com prf.hn tradedoubler.com clkuk.tradedoubler.com
].freeze
TRACKING_PARAMS = /[?&](utm_[a-z]+|tag|ref|aff(?:iliate)?(?:_?id)?|awc|clickref|cjevent|irclickid|gclid|fbclid)=/i

def tracked_or_affiliate?(url)
  return "is a tracked link (#{url[TRACKING_PARAMS, 1]}=)" if url =~ TRACKING_PARAMS
  host = (URI.parse(url).host rescue nil).to_s.downcase.sub(/\Awww\./, "")
  return "goes through an affiliate network (#{host})" if AFFILIATE_HOSTS.any? { |h| host == h || host.end_with?(".#{h}") }
  nil
end

def links_in(text)
  md = text.scan(/\]\((\s*https?:\/\/[^)\s]+)/).flatten
  html = text.scan(/href=["'](https?:\/\/[^"']+)["']/i).flatten
  (md + html).map(&:strip)
end

def check_banned(where, text)
  BANNED.each { |re, why| err(where, "#{why}: \"#{text[re]}\"") if text =~ re }
  if text =~ /gadget insurance|energy (?:deal|supplier|switch)/i
    warn_(where, "mentions energy or gadget-insurance deals (\"Switched on\" trade marks belong to others there)")
  end
end

def check_amazon(where, text)
  text.each_line do |line|
    next unless line =~ /amazon\./i
    err(where, "shows a price next to an Amazon link") if line =~ /€\s?\d|EUR\s?\d|\d\s?euro/i
    err(where, "uses an Amazon product image") if line =~ /!\[[^\]]*\]\([^)]*amazon|<img[^>]+amazon/i
  end
end

# ---------------------------------------------------------------- data

config_path = File.join(ROOT, "_config.yml")
abort "Run this from the site folder (no _config.yml in #{ROOT})" unless File.exist?(config_path)
CONFIG = load_yaml(read(config_path))
PRODUCTS = File.exist?("_data/products.yml") ? load_yaml(read("_data/products.yml")) : {}
TOPICS = File.exist?("_data/topics.yml") ? load_yaml(read("_data/topics.yml")).map { |t| t["slug"] } : []
PREVIEW = CONFIG["preview_mode"] == true

# ---------------------------------------------------------------- guides

guides = Dir.glob("_guides/*/*.md").sort
used_diagrams = []
titles = Hash.new { |h, k| h[k] = [] }
descriptions = Hash.new { |h, k| h[k] = [] }

guides.each do |path|
  fm, body = split_front_matter(read(path))
  if fm.nil?
    err(path, "has no front matter")
    next
  end

  %w[title description summary topic format image last_checked last_modified_at approved sources].each do |key|
    err(path, "is missing #{key}:") if fm[key].nil? || fm[key].to_s.strip.empty?
  end

  title = fm["title"].to_s
  desc = fm["description"].to_s
  titles[title] << path unless title.empty?
  descriptions[desc] << path unless desc.empty?
  warn_(path, "title is #{title.length} characters (aim for under #{TITLE_MAX})") if title.length > TITLE_MAX
  err(path, "description is #{desc.length} characters (must be under #{DESCRIPTION_MAX})") if desc.length > DESCRIPTION_MAX

  folder = File.basename(File.dirname(path))
  if fm["topic"]
    err(path, "topic \"#{fm['topic']}\" isn't one of the five topics") unless TOPICS.include?(fm["topic"])
    err(path, "is in the #{folder}/ folder but has topic: #{fm['topic']}") if folder != fm["topic"]
  end
  err(path, "format \"#{fm['format']}\" isn't one of #{FORMATS.join(', ')}") if fm["format"] && !FORMATS.include?(fm["format"])

  # Dates
  lc = fm["last_checked"]
  lm = fm["last_modified_at"]
  err(path, "last_checked isn't a date (YYYY-MM-DD)") if lc && !date?(lc)
  err(path, "last_modified_at isn't a date (YYYY-MM-DD)") if lm && !date?(lm)
  err(path, "last_modified_at (#{lm}) must be the same as last_checked (#{lc})") if date?(lc) && date?(lm) && lc != lm
  err(path, "last_checked (#{lc}) is in the future") if date?(lc) && lc > TODAY
  warn_(path, "last checked #{(TODAY - lc).to_i} days ago: due for its quarterly re-check") if date?(lc) && (TODAY - lc).to_i > RECHECK_DAYS
  # Dated prices: the price-date include needs prices_checked:, no later than last_checked
  pc = fm["prices_checked"]
  uses_price_date = body =~ /\{%-?\s*include\s+price-date\.html/
  if uses_price_date && pc.nil?
    err(path, "uses price-date.html but has no prices_checked: date")
  elsif pc
    if !date?(pc)
      err(path, "prices_checked isn't a date (YYYY-MM-DD)")
    else
      err(path, "prices_checked (#{pc}) is later than last_checked (#{lc})") if date?(lc) && pc > lc
      warn_(path, "has prices_checked but no price-date.html line: add the line above its prices, or remove the date") unless uses_price_date
      warn_(path, "prices last checked #{(TODAY - pc).to_i} days ago: re-check them") if (TODAY - pc).to_i > PRICE_DAYS
    end
  end
  # What changed: each changes: entry needs a date and a short what; the newest can't be later than last_checked
  ch = fm["changes"]
  if fm.key?("changes")
    if !ch.is_a?(Array) || ch.empty?
      err(path, "changes: must be a list of entries, each with date: and what: (or leave changes: out)")
    else
      ch.each_with_index do |c, i|
        n = "changes entry #{i + 1}"
        unless c.is_a?(Hash)
          err(path, "#{n} needs date: and what:")
          next
        end
        err(path, "#{n} has no date: (YYYY-MM-DD)") unless date?(c["date"])
        w = c["what"].to_s.strip
        if w.empty?
          err(path, "#{n} has no what: (a few words on what changed)")
        else
          err(path, "#{n}'s what: ends with a full stop: leave it off, the page adds it") if w.end_with?(".")
          warn_(path, "#{n}'s what: is #{w.length} characters: keep it to 120 or fewer, it shows at the top of the guide") if w.length > 120
        end
      end
      newest = ch.select { |c| c.is_a?(Hash) && date?(c["date"]) }.map { |c| c["date"] }.max
      if newest && date?(lc) && newest > lc
        err(path, "newest change (#{newest}) is later than last_checked (#{lc}): a change means the guide was checked that day, so move last_checked and last_modified_at on too")
      end
    end
  end
  err(path, "approved isn't a date: nothing goes up without John Paul's approval") if fm.key?("approved") && !date?(fm["approved"])
  if !PREVIEW && !date?(fm["date"])
    err(path, "has no date: (the published date). Add the launch day before going live")
  end

  # Social card
  if fm["image"]
    img = fm["image"].is_a?(Hash) ? fm["image"]["path"] : fm["image"]
    err(path, "social card #{img} doesn't exist") unless File.exist?(File.join(ROOT, img.to_s.sub(%r{\A/}, "")))
  end

  # Key points or verdict
  if fm["format"] == "quick-answer"
    v = fm["verdict"]
    err(path, "is a quick answer but has no verdict: (answer and rows)") unless v.is_a?(Hash) && v["answer"] && v["rows"].is_a?(Array) && !v["rows"].empty?
    err(path, "has a verdict: but the body never shows it ({% include verdict.html %} is missing)") if v && !body.include?("include verdict.html")
  elsif fm["format"]
    err(path, "has no key_points:") unless fm["key_points"].is_a?(Array) && !fm["key_points"].empty?
  end

  # Sources: a dated list of plain links
  sources = fm["sources"]
  if sources.is_a?(Array) && !sources.empty?
    sources.each_with_index do |s, i|
      where = "#{path} source #{i + 1}"
      unless s.is_a?(Hash)
        err(where, "should have title, url and checked")
        next
      end
      err(where, "has no title") if s["title"].to_s.strip.empty?
      url = s["url"].to_s
      if url !~ %r{\Ahttps://}
        err(where, "url should start with https:// (#{url})")
      elsif (why = tracked_or_affiliate?(url))
        err(where, "#{why}. Sources must be plain links")
      end
      err(where, "has no checked: date") unless date?(s["checked"])
    end
  elsif fm.key?("sources")
    err(path, "sources: list is empty")
  end

  # Products: buying guides only, at most three, all from _data/products.yml
  uses_cards = body.match?(/include\s+product-cards?\.html/)
  if fm["format"] != "buying-guide"
    err(path, "has products: but isn't a buying guide") if fm["products"]
    err(path, "uses a product card include but isn't a buying guide") if uses_cards
  end
  if fm["products"]
    list = Array(fm["products"])
    err(path, "lists #{list.size} products (at most three)") if list.size > 3
    list.each { |id| err(path, "product \"#{id}\" isn't in _data/products.yml") unless PRODUCTS.key?(id) }
    paid = list.select { |id| PRODUCTS.dig(id, "paid") == true }
    err(path, "has paid products (#{paid.join(', ')}) but not affiliate: true, so the Ad box won't show") if paid.any? && fm["affiliate"] != true
    warn_(path, "has affiliate: true but none of its products is paid") if fm["affiliate"] == true && paid.empty?
  end
  err(path, "has affiliate: true but no products") if fm["affiliate"] == true && !fm["products"]

  # Links written into the guide itself must be plain
  links_in(body).each do |url|
    if (why = tracked_or_affiliate?(url))
      err(path, "link #{url} #{why}. Paid links only come from _data/products.yml")
    end
  end

  # Pictures: only diagrams drawn for the site, through figure.html, each with alt text and a caption
  body.scan(/\{%-?\s*include\s+figure\.html(.*?)-?%\}/m).each do |(args)|
    params = args.scan(/([\w-]+)\s*=\s*"([^"]*)"/).to_h
    svg = params["svg"].to_s
    if !svg.start_with?("diagrams/") || !svg.end_with?(".svg") || !File.file?(File.join("_includes", svg))
      err(path, "figure.html needs svg=\"diagrams/<name>.svg\", a file in _includes/diagrams/ (got #{svg.inspect})")
    end
    err(path, "figure #{svg} has no alt text: describe everything it shows, in words") if params["alt"].to_s.strip.length < 40
    err(path, "figure #{svg} has no caption") if params["caption"].to_s.strip.empty?
    err(path, "figure #{svg} has HTML in its caption: use licence= and licence_url= for a credit link") if params["caption"].to_s.include?("<")
    err(path, "figure #{svg} has a licence but no licence_url") if params["licence"] && !params["licence_url"].to_s.start_with?("https://")
    used_diagrams << svg
  end
  if body =~ /!\[[^\]]*\]\([^)]*\)|<img\b/i
    err(path, "has a picture outside figure.html: no stock photos or screenshots, and diagrams go through figure.html")
  end
  if date?(fm["approved"]) && fm["approved"] >= DIAGRAM_RULE_FROM
    has_figure = body =~ /\{%-?\s*include\s+figure\.html/
    reason = fm["no_diagram"].to_s.strip
    if has_figure && !reason.empty?
      err(path, "has a diagram and a no_diagram: reason: keep one")
    elsif !has_figure && reason.empty?
      err(path, "has no diagram and no no_diagram: reason: add a diagram if it's warranted and its labels come from the guide's own sources, or say why not (see Diagrams in the README)")
    elsif !has_figure && reason.length < 15
      err(path, "no_diagram: reason is too short to explain the decision (#{reason.length} characters, 15 or more)")
    end
  end

  # Wording, everywhere the reader sees it
  visible = [title, desc, fm["summary"], body, Array(fm["key_points"]).join("\n"),
             (fm["verdict"].to_s if fm["verdict"])].compact.join("\n")
  check_banned(path, visible)
  check_amazon(path, visible + "\n" + Array(sources).map(&:to_s).join("\n"))
  warn_(path, "says \"written by\": guides are checked by John Paul and drafted with AI help") if visible =~ /\bwritten by\b/i
end

titles.each { |t, paths| err(paths.join(", "), "share the title \"#{t}\"") if paths.size > 1 }
descriptions.each { |_, paths| warn_(paths.join(", "), "share the same description") if paths.size > 1 }

# ---------------------------------------------------------------- diagrams
# Drawn for the site in the brand colours and fonts. Nothing loads from outside.
DIAGRAM_COLOURS = %w[#0E7C5A #0A5C43 #E7F2EF #F2A900 #7A4F00 #14181F #3A424C #5B6470 #7C8682 #F3F5F4 #E3E7E5 #FFFFFF].freeze
Dir.glob("_includes/diagrams/*").sort.each do |path|
  rel = path.sub("_includes/", "")
  unless path.end_with?(".svg")
    err(path, "only .svg diagrams go in _includes/diagrams/")
    next
  end
  svg = read(path)
  err(path, "must be a single <svg> with a viewBox") unless svg.lstrip.start_with?("<svg") && svg.include?("viewBox=")
  err(path, "must have aria-hidden=\"true\": figure.html gives screen readers the alt text") unless svg.include?('aria-hidden="true"')
  err(path, "has an <image>: diagrams are drawn, never photos or screenshots") if svg =~ /<image\b/i
  err(path, "has a script") if svg =~ /<script\b/i
  err(path, "loads something from outside the site") if svg =~ /(?:href|src)=["']https?:/i || svg =~ /url\(\s*['"]?https?:/i
  err(path, "has a blank line, which breaks it inside a guide") if svg =~ /\n[ \t]*\n/
  err(path, "has Liquid code in it") if svg.include?("{{") || svg.include?("{%")
  svg.scan(/#\h{6}\b|#\h{3}\b/).uniq.each do |c|
    full = c.length == 4 ? "#" + c[1..].chars.map { |h| h * 2 }.join : c
    err(path, "uses the colour #{c}, which isn't one of the site's") unless DIAGRAM_COLOURS.include?(full.upcase)
  end
  svg.scan(/font-family="([^"]*)"/).flatten.uniq.each do |f|
    err(path, "uses the font #{f}: diagrams use Inter or Space Grotesk") unless f =~ /\A'?(Inter|Space Grotesk)'?,/
  end
  check_banned(path, svg.gsub(/<[^>]+>/, " "))
  warn_(path, "isn't used in any guide") unless used_diagrams.include?(rel)
end

# ---------------------------------------------------------------- pages and topics

pages = (Dir.glob("pages/**/*.md") + Dir.glob("topics/*.md") + ["index.html"]).select { |p| File.exist?(p) }.sort
pages.each do |path|
  fm, body = split_front_matter(read(path))
  next if fm.nil?
  title = fm["title"].to_s
  desc = fm["description"].to_s
  warn_(path, "title is #{title.length} characters (aim for under #{TITLE_MAX})") if title.length > TITLE_MAX
  err(path, "has no description:") if desc.empty?
  err(path, "description is #{desc.length} characters (must be under #{DESCRIPTION_MAX})") if desc.length > DESCRIPTION_MAX
  check_banned(path, [title, desc, body].join("\n"))
  links_in(body).each do |url|
    if (why = tracked_or_affiliate?(url))
      err(path, "link #{url} #{why}")
    end
  end
end

# Start here cards: picked by hand in _data/topics.yml, each must be a real guide in that topic
guide_urls = guides.map { |g| "/#{File.basename(File.dirname(g))}/#{File.basename(g, '.md')}/" }
(File.exist?("_data/topics.yml") ? load_yaml(read("_data/topics.yml")) : []).each do |t|
  picks = t["start_here"]
  where = "_data/topics.yml (#{t['slug']})"
  next if picks.nil?
  unless picks.is_a?(Array)
    err(where, "start_here should be a list of guide addresses")
    next
  end
  err(where, "start_here has #{picks.size} guides; the topic page shows two at most") if picks.size > 2
  err(where, "start_here lists the same guide twice") if picks.uniq.size != picks.size
  picks.each do |u|
    if !guide_urls.include?(u.to_s)
      err(where, "start_here #{u} isn't a guide (expected an address like /#{t['slug']}/guide-name/)")
    elsif !u.to_s.start_with?("/#{t['slug']}/")
      err(where, "start_here #{u} is a guide in another topic")
    end
  end
end

# Topic groups: optional headings on a topic page, in _data/topics.yml; each guide in a grouped topic names one with group:
topic_groups = {}
(File.exist?("_data/topics.yml") ? load_yaml(read("_data/topics.yml")) : []).each do |t|
  next unless t.key?("groups")
  where = "_data/topics.yml (#{t['slug']})"
  g = t["groups"]
  if !g.is_a?(Array) || g.empty? || g.any? { |x| x.to_s.strip.empty? }
    err(where, "groups should be a list of group names (or leave groups out)")
    next
  end
  err(where, "groups lists the same name twice") if g.map(&:to_s).uniq.size != g.size
  topic_groups[t["slug"]] = g.map(&:to_s)
end
group_counts = Hash.new(0)
guides.each do |path|
  fm, = split_front_matter(read(path))
  topic = fm["topic"].to_s
  grp = fm["group"]
  if topic_groups.key?(topic)
    if grp.nil? || grp.to_s.strip.empty?
      err(path, "has no group: (the #{topic} page is split into groups: #{topic_groups[topic].join(', ')})")
    elsif !topic_groups[topic].include?(grp.to_s)
      err(path, "group \"#{grp}\" isn't one of the #{topic} groups (#{topic_groups[topic].join(', ')})")
    else
      group_counts[[topic, grp.to_s]] += 1
    end
  elsif grp
    err(path, "has group: \"#{grp}\" but the #{topic} topic has no groups in _data/topics.yml")
  end
end
topic_groups.each do |topic, names|
  names.each { |n| warn_("_data/topics.yml (#{topic})", "group \"#{n}\" has no guides, so it won't show") if group_counts[[topic, n]].zero? }
end

# Related guides: up to three real guides by address, never the guide itself, no repeats
guides.each do |path|
  fm, = split_front_matter(read(path))
  next unless fm.key?("related")
  rel = fm["related"]
  unless rel.is_a?(Array) && !rel.empty?
    err(path, "related: must be a list of one to three guide addresses (or leave related: out)")
    next
  end
  own = "/#{File.basename(File.dirname(path))}/#{File.basename(path, '.md')}/"
  err(path, "related: has #{rel.size} guides; the box shows three at most") if rel.size > 3
  err(path, "related: lists the same guide twice") if rel.map(&:to_s).uniq.size != rel.size
  rel.each do |u|
    if u.to_s == own
      err(path, "related: lists the guide itself")
    elsif !guide_urls.include?(u.to_s)
      err(path, "related: #{u} isn't a guide (expected an address like /phones/guide-name/; links to On Air Ireland stay in the text)")
    end
  end
end

# ---------------------------------------------------------------- products data

PRODUCTS.each do |id, p|
  where = "_data/products.yml #{id}"
  unless p.is_a?(Hash)
    err(where, "should be a list of fields")
    next
  end
  %w[name kind why where url checked].each { |k| err(where, "is missing #{k}:") if p[k].to_s.strip.empty? }
  err(where, "has paid: #{p['paid'].inspect}; it must be true or false") unless [true, false].include?(p["paid"])
  %w[price image img picture photo].each { |k| err(where, "has #{k}: (no prices or shop images, ever)") if p.key?(k) }
  url = p["url"].to_s
  err(where, "url should start with https://") unless url.start_with?("https://")
  if p["paid"] == false && (why = tracked_or_affiliate?(url))
    err(where, "is paid: false but its link #{why}")
  end
  if url =~ /amazon\./i && p["paid"] == true
    warn_(where, "is an Amazon paid link: no prices or product images, and Amazon's wording on How we make money")
  end
  text = [p["name"], p["kind"], p["why"], p["note"], p["specs"]].compact.join("\n")
  check_banned(where, text)
  err(where, "is an energy or gadget-insurance product") if text =~ /insurance|energy (?:supplier|plan|tariff)/i
end

# ---------------------------------------------------------------- templates that carry the rules

def must_contain(path, needle, why)
  if !File.exist?(path)
    err(path, "is missing")
  elsif !read(path).include?(needle)
    err(path, "no longer contains #{needle.inspect} (#{why})")
  end
end

must_contain("_includes/product-card.html", 'rel="sponsored nofollow"', "paid links need it")
must_contain("_includes/product-card.html", "(paid link)", "every affiliate link says so")
must_contain("_includes/product-card.html", "tag-ad", "paid cards show \"Ad\"")
must_contain("_includes/product-cards.html", "limit: 3", "at most three cards")
must_contain("_includes/product-cards.html", 'page.format == "buying-guide"', "cards only in buying guides")
must_contain("_includes/disclosure.html", '<span class="tag tag-ad">Ad</span>', "the disclosure box starts with \"Ad\"")
must_contain("_includes/meta.html", "Checked by", "the byline")
must_contain("_includes/meta.html", "Drafted with AI help", "the byline")
must_contain("_layouts/guide.html", "include meta.html", "every guide shows the byline")
must_contain("_layouts/guide.html", "include sources.html", "every guide ends with its sources")
must_contain("_includes/sources.html", "Sources", "the dated sources list")
must_contain("_includes/figure.html", 'role="img" aria-label="{{ include.alt | escape }}"', "diagrams carry alt text")
must_contain("_includes/figure.html", "<figcaption>", "diagrams carry a caption")

author = (CONFIG["defaults"] || []).map { |d| d.dig("values", "author") }.compact.first
unless author.is_a?(Hash) && author["type"] == "Organization" && author["name"] == "Switched On"
  err("_config.yml", "search engines must see Switched On (type: Organization) as the author, not a person")
end
%w[google-analytics googletagmanager gtag( fbq( hotjar].each do |bad|
  Dir.glob("{_includes,_layouts}/*.html").each { |f| err(f, "loads #{bad}: the site has no cookies or trackers") if read(f).include?(bad) }
end

# ---------------------------------------------------------------- built site (optional)

site_dir = ARGV.include?("--site") ? ARGV[ARGV.index("--site") + 1] : nil
# --baseurl: the base path the site was built with ("" for switchedon.ie). Internal links must start with it.
base_path = ARGV.include?("--baseurl") ? ARGV[ARGV.index("--baseurl") + 1].to_s.chomp("/") : ""
built_pages = 0
if site_dir
  abort "No built site at #{site_dir}. Run bundle exec jekyll build first." unless Dir.exist?(site_dir)
  html_files = Dir.glob(File.join(site_dir, "**", "*.html")).sort
  built_pages = html_files.size

  exists = lambda do |href|
    path = href.split(/[?#]/).first.to_s
    unless base_path.empty?
      return false unless path == base_path || path.start_with?("#{base_path}/")
      path = path.delete_prefix(base_path)
      path = "/" if path.empty?
    end
    path = URI.decode_www_form_component(path) rescue path
    full = File.join(site_dir, path)
    File.file?(full) || File.file?(File.join(full, "index.html")) || File.file?("#{full}.html")
  end

  html_files.each do |file|
    rel = file.sub("#{site_dir}/", "")
    html = read(file)

    # Internal links and assets must exist
    html.scan(/(?:href|src)=["'](\/[^"'\/][^"']*|\/)["']/).flatten.uniq.each do |href|
      err(rel, "links to #{href}, which doesn't exist") unless exists.call(href)
    end

    # Paid links must be labelled and marked
    html.scan(/<a\b[^>]*>[^<]*\(paid link\)[^<]*<\/a>/i).each do |a|
      err(rel, "has a \"(paid link)\" without rel=\"sponsored nofollow\"") unless a.include?('rel="sponsored nofollow"')
    end

    # No trackers, and only GoatCounter as an outside script
    html.scan(/<script[^>]+src=["'](https?:)?\/\/([^\/"']+)/i).each do |_, host|
      err(rel, "loads a script from #{host}: only GoatCounter is allowed") unless host =~ /(\A|\.)goatcounter\.com\z|\Agc\.zgo\.at\z/
    end
    err(rel, "loads Google Fonts: fonts are self-hosted") if html.include?("fonts.googleapis.com") && CONFIG["preview_google_fonts"] != true
    if PREVIEW
      err(rel, "loads GoatCounter in the preview: it should only load once preview_mode is false") if html.include?("gc.zgo.at")
    elsif CONFIG["goatcounter"].to_s.strip != "" && !html.include?("data-goatcounter=\"https://#{CONFIG["goatcounter"]}.goatcounter.com/count\"")
      err(rel, "has no GoatCounter counter: every page counts visits after launch")
    end

    check_banned(rel, html.gsub(/<script.*?<\/script>|<style.*?<\/style>/m, "").gsub(/<[^>]+>/, " "))
  end

  guides.each do |path|
    topic, slug = path.match(%r{_guides/([^/]+)/([^/]+)\.md\z}).captures
    file = File.join(site_dir, topic, slug, "index.html")
    where = "#{topic}/#{slug}/"
    unless File.exist?(file)
      err(where, "wasn't built")
      next
    end
    html = read(file)
    err(where, "has no \"Checked by\" byline") unless html.include?("Checked by")
    err(where, "has no \"Drafted with AI help\" link") unless html.include?("Drafted with AI help")
    err(where, "has no Sources section") unless html =~ /<h2[^>]*>\s*Sources\s*</
    err(where, "has no social card (og:image)") unless html.include?('property="og:image"')
    html.scan(/<figure class="diagram">(.*?)<\/figure>/m).each do |(fig)|
      err(where, "has a diagram without alt text") unless fig =~ /role="img" aria-label="[^"]{40,}"/
      err(where, "has a diagram without a caption") unless fig =~ /<figcaption>\s*[^<\s]/
      err(where, "has a diagram that loads an image") if fig =~ /<(?:img|image)\b/i
    end
    if html =~ /"@type":"BlogPosting"/
      err(where, "structured data names a person as author") unless html =~ /"author":\{"@type":"Organization","name":"Switched On"/
    else
      warn_(where, "has no structured data (normal in a stand-in build; real Jekyll adds it)")
    end
    if !PREVIEW && html.include?("noindex")
      err(where, "tells search engines not to index it, but preview mode is off")
    end
  end

  # Feed: /feed.xml lists every guide once, as plain links; readers can find it once the site is live
  feed_file = File.join(site_dir, "feed.xml")
  if !File.exist?(feed_file)
    err("feed.xml", "wasn't built: the feed of guides is missing")
  else
    feed = read(feed_file)
    begin
      require "rexml/document"
      REXML::Document.new(feed)
      err("feed.xml", "doesn't start with <?xml: feed readers may reject it") unless feed.start_with?("<?xml")
    rescue REXML::ParseException => e
      err("feed.xml", "isn't valid XML (#{e.message.lines.first.to_s.strip})")
    end
    ids = feed.scan(%r{<entry>.*?<id>([^<]+)</id>}m).flatten
    guide_urls.each do |u|
      n = ids.count { |id| id.end_with?(u) }
      err("feed.xml", n.zero? ? "is missing #{u}" : "lists #{u} #{n} times") unless n == 1
    end
    err("feed.xml", "lists #{ids.size} entries but there are #{guide_urls.size} guides") if ids.size != guide_urls.size
    feed.scan(/href="([^"]+)"/).flatten.each do |href|
      if (why = tracked_or_affiliate?(href)) || href.include?("?")
        err("feed.xml", "link #{href} #{why || 'has a query string: feed links stay plain'}")
      end
    end
    err("feed.xml", "has an entry with no summary") if feed.scan(%r{<entry>.*?</entry>}m).any? { |e| e !~ %r{<summary>[^<]{20,}</summary>} }
  end
  unless PREVIEW
    html_files.each do |file|
      html = read(file)
      next unless html.include?("</head>")
      rel = file.sub("#{site_dir}/", "")
      err(rel, "has no feed link in its head: feed readers can't find the feed") unless html.include?('type="application/atom+xml"')
    end
  end
end

# ---------------------------------------------------------------- report

puts "Switched On content checks"
puts "  #{guides.size} guides, #{pages.size} pages, #{PRODUCTS.size} products#{site_dir ? ", #{built_pages} built pages in #{site_dir}" : ''}"
puts "  preview_mode is #{PREVIEW ? 'on' : 'OFF (launch rules apply)'}"
puts
ERRORS.each { |e| puts "ERROR  #{e}" }
WARNINGS.each { |w| puts "WARN   #{w}" }
puts if ERRORS.any? || WARNINGS.any?
puts "Result: #{ERRORS.size} error#{'s' unless ERRORS.size == 1}, #{WARNINGS.size} warning#{'s' unless WARNINGS.size == 1}"
puts(ERRORS.empty? ? "All rules pass." : "Fix the errors before anything goes live.")
exit(ERRORS.empty? ? 0 : 1)
