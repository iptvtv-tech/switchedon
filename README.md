# Switched On – private preview

This is the Switched On site. It lives in the GitHub repo iptvtv-tech/switchedon, and GitHub Actions checks and publishes it (see Deploy). The site went live on 27 November 2026 with all 29 guides, and `preview_mode` is now off. Setting it back to true brings back the dark "Private preview" bar and tells search engines not to index the site (the runbook's way back). You can also run it on your PC (see View it on your PC).

## What's in it so far

- Homepage (popular questions in the green card; a guide shows there when it has `popular: true`), the five topic pages (each opens with two "Start here" cards, picked by hand in `_data/topics.yml` under `start_here:`; the whole card links to its guide, and the content checks fail if a pick isn't a guide in that topic), Ask a question, About, How we check guides, Contact, How we make money and Privacy
- Social cards in `assets/social/`: one for each guide, one for each topic page and a default for every other page. A card is the picture shown when someone shares a link on WhatsApp, X or Facebook. Each guide names its card with `image:` in its front matter, and the default is set in `_config.yml`. Link previews only show once the site is live
- Guide 12, "Your rights when tech is faulty in Ireland" (approved 23 Nov 2026)
- Guide 11, "Buying tech from a UK shop: VAT, customs and returns" (approved 23 Nov 2026)
- Guide 10, "Does Uber work in Ireland?", the first quick answer (approved 23 Nov 2026)
- Guide 9, "Setting up a verified MyGovID on your phone" (approved 23 Nov 2026)
- Guide 8, "Choosing a laptop for school or college in Ireland", the first buying guide, with two product cards from `_data/products.yml` (approved 23 Nov 2026)
- Guide 7, "Windows 10 support has ended: your options in Ireland" (approved 23 Nov 2026)
- Guide 6, "How to switch broadband provider in Ireland", the first Broadband and Wi-Fi guide (approved 23 Nov 2026)
- Guide 5, "Can I get fibre broadband at my address?" (approved 23 Nov 2026)
- Guide 4, "How to fix Wi-Fi dead spots at home" (approved 24 Nov 2026)
- Guide 3, "Will a phone bought abroad work in Ireland?", a quick answer and the first Phones and tablets guide (approved 24 Nov 2026)
- Guide 2, "How to keep your number when you switch mobile network" (approved 24 Nov 2026)
- Guide 1, "Switching to eSIM in Ireland: what to check first" (approved 24 Nov 2026)

All 12 launch guides are now in the preview, plus guides 13 (What does 'Likely Scam' mean on a text message?, approved 24 Nov 2026), 14 (Recycling an old phone, laptop or TV for free in Ireland, approved 25 Nov 2026), 15 (Does my Irish phone plan work in the UK?, approved 25 Nov 2026), 16 (Which Irish banks support Apple Pay and Google Pay?, approved 25 Nov 2026), 17 (Do new laptops have to charge by USB-C in Ireland?, approved 25 Nov 2026), 18 (Does Starlink work in Ireland?, approved 25 Nov 2026), 19 (Why am I being asked to verify my age online?, approved 25 Nov 2026), 20 (Which Irish networks support WiFi Calling?, approved 25 Nov 2026), 21 (Will my Irish phone work in the USA?, approved 25 Nov 2026), 22 (What is Ireland's Government Digital Wallet?, approved 25 Nov 2026), 23 (Is Apple Intelligence available in Ireland?, approved 25 Nov 2026), 24 (Buying a refurbished phone or laptop in Ireland, approved 25 Nov 2026), 25 (Lost or stolen phone in Ireland: what to do, approved 25 Nov 2026), 26 (Poor mobile signal at home? Your options in Ireland, approved 25 Nov 2026), 27 (Parental controls on Irish broadband and phones, approved 25 Nov 2026), 28 (Scam calls in Ireland: how to spot, block and report them, approved 25 Nov 2026) and 29 (5G home broadband in Ireland: how it works and what it costs, approved 26 Nov 2026) to publish after launch. New guides are added to `_guides/<topic>/` as each one is approved, each with its own social card.

## Content checks (24 Nov 2026)

`_tools/check_content.rb` checks the site against its hard rules. Run it from this folder:

```
ruby _tools/check_content.rb               # the source files
ruby _tools/check_content.rb --site _site  # also the built pages (while jekyll serve is running, or after jekyll build)
```

**Errors** break a rule, and the script ends with an error code so a deploy stops. **Warnings** are worth a look but don't stop anything.

It checks:
- **Every guide:** title (warning over 60 characters), description (error over 160), summary, topic, format, social card, approved date, and key points or a verdict.
- **Dates:** `last_modified_at` must equal `last_checked`. A warning appears once a guide is more than 100 days past its last check. Once `preview_mode` is off, every guide needs a `date:`.
- **Sources:** every guide has a dated sources list of plain https links. Tracking codes (utm_, tag=, ref=…) and affiliate networks are errors.
- **Wording:** no "we tested", "in our tests", "hands-on", VPNs or IPTV, anywhere a reader sees it.
- **Affiliate rules:**
  - no raw affiliate links in guides or pages
  - product cards only in buying guides, at most three, all from `_data/products.yml`
  - paid products need `affiliate: true`
  - no prices or shop images in the products file
  - no Amazon prices or images
  - no energy or gadget-insurance products
- **Templates that carry the rules:** the "Ad" label, "(paid link)" and rel="sponsored nofollow" on paid cards, the "Ad" disclosure box, the "Checked by … · Drafted with AI help" byline, the sources list, and Switched On (not a person) as author for search engines. No Google Analytics or other trackers.
- **Built pages** (with `--site`):
  - every internal link and file exists
  - every "(paid link)" carries rel="sponsored nofollow"
  - only GoatCounter may load an outside script; it must be on every page after launch and on none in the preview
  - no Google Fonts once they're self-hosted
  - every guide shows the byline, a Sources section and a social card, with Switched On as author in its structured data
  - nothing is set to noindex once preview mode is off

The deploy runs both commands and stops if either reports an error (see Deploy).

## Deploy (GitHub Actions, set up 26 Nov 2026)

`.github/workflows/deploy.yml` runs on every push to `main`:

1. checks the source files (`ruby _tools/check_content.rb`)
2. builds the site with the same gems GitHub Pages uses (`bundle exec jekyll build`)
3. checks the built pages (`--site _site`)
4. publishes to GitHub Pages, only if all three passed. A failed check stops the deploy, so the live site doesn't change

Pull requests run steps 1 to 3 and never publish. The Actions tab has a "Run workflow" button to run it again by hand.

Before the custom domain is set, GitHub serves the site at https://iptvtv-tech.github.io/switchedon/, under the base path `/switchedon`. The workflow takes the base path from GitHub (`actions/configure-pages`) and passes it to the build and to the checks (`--baseurl`), so every link works at either address; once switchedon.ie is set, the base path is empty. Every link in a template or guide goes through `relative_url` for this reason, and the built-page check fails a link without the base path.

Nothing is committed or pushed until John Paul has reviewed the change and said "push to main". `main` is protected against deletion and force pushes.

## Newsletter sign-up (set up 24 Nov 2026)

- Switched On has its own Brevo account (login hello@switchedon.ie). switchedon.ie is authenticated there, and "Switched On <hello@switchedon.ie>" is the sender.
- The Brevo form "Switched On newsletter sign-up (website)" puts people on the list "Switched On newsletter" only after they click the button in the confirmation email. That email is Switched On's own: the Brevo template "Switched On – confirm sign-up (double opt-in)", subject "Confirm your Switched On sign-up", tagged `optin`. Its source is `_brevo/confirm-email.html` (Jekyll doesn't publish that folder). To change it, edit that file and paste it into the template's HTML editor in Brevo. The button's link must stay `{{ doubleoptin }}`.
- The homepage form posts straight to that Brevo form (the address is `newsletter_form` in `_config.yml`). No Brevo scripts or styles load on the site. A hidden field catches spam bots.
- After signing up, people go to `/newsletter/check-your-email/`; after confirming, to `/newsletter/confirmed/`. Both pages are left out of search engines and the sitemap.
- While `preview_mode` is on, the form doesn't send anything.

## Search engines (set up 24 Nov 2026)

- Every page has its own title, description, canonical link and social card (jekyll-seo-tag), and every page is listed in `sitemap.xml` (jekyll-sitemap).
- Each guide's `last_modified_at` must match its `last_checked`: it's the "updated" date Google and the sitemap see. Change both together at each re-check.
- Guides also carry breadcrumb data (Home, topic, guide), and the homepage says who publishes the site, with its logo and the WhatsApp channel.
- Bylines read "Checked by John Paul Cunningham · Drafted with AI help" (24 Nov 2026). Search engines see Switched On, the site, as each guide's author, because the guides are drafted with AI help and checked by John Paul; his name and page are set as `editor` in `_config.yml`.
- While `preview_mode` is on, every page tells search engines not to index it and robots.txt blocks them.

## View it on your PC (Windows)

You only need to do steps 1 and 2 once.

1. **Install Ruby.** Go to rubyinstaller.org, download **Ruby+Devkit 3.3** (x64) and run it with the default options. On the last screen leave "Run 'ridk install'" ticked. When a black window asks which components to install, press **Enter**, then close it when it's finished.
2. **Install the site's tools.** Open a new Command Prompt and run:
   ```
   cd /d D:\PROJECTS\ACTIVE\switchedon
   gem install bundler
   bundle install
   ```
   The last step takes a few minutes the first time.
3. **Start the preview:**
   ```
   cd /d D:\PROJECTS\ACTIVE\switchedon
   bundle exec jekyll serve
   ```
4. Open **http://localhost:4000** in your browser.

Leave the Command Prompt window open while you look around. To stop, click in that window and press **Ctrl+C**. If you change a file, refresh the browser to see it; changes to `_config.yml` need a stop and start.

The fonts (Inter and Space Grotesk) are stored in the site itself, in `assets/fonts/`, so the preview looks right even without an internet connection.

## If something goes wrong

- **A "GitHub Metadata" warning** when the preview starts is normal (the site isn't on GitHub yet) and can be ignored.
- **"bundle is not recognized"**: close the Command Prompt, open a new one and try again (Ruby adds itself to the path when it installs).
- **An error in `bundle install`**: copy the last 20 lines and send them to Claude.
- **Port 4000 is busy**: run `bundle exec jekyll serve --port 4001` and open http://localhost:4001.


## Diagrams

Guides can carry diagrams drawn for the site (no stock photos, screenshots or logos). Each is an SVG in `_includes/diagrams/`, shown with
`{% include figure.html svg="diagrams/<name>.svg" alt="..." caption="..." %}`. The alt text says in words everything the diagram shows, and the caption says where it comes from. A drawing redrawn from someone else's files (the EU charger pictograms and label in the USB-C guide, from the European Commission under CC BY 4.0) also takes `licence="Licence: CC BY 4.0" licence_url="https://creativecommons.org/licenses/by/4.0/"`, which shows a link after the caption; don't type links into the caption itself. Every label must trace to the guide's sources, and each diagram is approved with the guide (in its notes doc).

**Every new guide is considered for a diagram (rule set 25 Nov 2026, changed the same evening by John Paul).** From 26 Nov 2026 on, each guide gets a diagram only if both are true:

- **It's warranted:** it shows something better than words do, such as steps in order, a choice with branches, a side-by-side of the options, or a label explained.
- **It's possible from the same sources:** every label can come from the guide's own sources. Nothing is drawn from general knowledge or from a source the guide doesn't use.

With a diagram: the notes doc's Outline has a **Diagram:** line (what it shows and where it sits), the Source check lists it label by label, and the draft John Paul approves includes the diagram, its alt text and its caption.

Without one: the notes doc's Outline says why, and the guide's front matter records it, approved with the guide, for example `no_diagram: "A two-line answer; nothing to show in steps or choices"`.

The checks fail a guide approved from 26 Nov 2026 on that has neither a figure nor a `no_diagram:` reason (at least 15 characters), so the decision is always made and written down.

The checks fail a figure without alt text or a caption, any other picture in a guide, and a diagram that uses colours or fonts outside the brand, has an `<image>` or a script, loads anything from outside, or has a blank line (it breaks the page). Diagrams are hidden from screen readers (`aria-hidden="true"`) because the figure gives them the alt text. Re-check each diagram's labels against the guide's sources at every re-check.

## Accessibility (checked 25 Nov 2026)

The site aims for WCAG 2.2 level AA, and the Accessibility page (`pages/accessibility.md`, linked in the footer) says what's been done, what isn't perfect and how to report a problem. Claude checks every page type with a script (headings, landmarks, skip link, link and button names, form labels, contrast, keyboard focus, target sizes, 320 px reflow and text spacing) before launch and after any change to a layout, include or the CSS, then updates the date on that page. On 25 Nov 2026 all 19 page types passed after one fix: the header now wraps if the Menu button doesn't fit.

## Dated prices (built 26 Nov 2026)

Every guide that quotes prices, fares or charges says when they were checked, in the same words and the same place: `{% include price-date.html %}` just above the prices, which prints "Prices on 25 November 2026." plus one sentence telling readers to check the provider's own page. The date comes from `prices_checked:` in the guide's front matter, so a re-check changes one line. Options: `what="Charges"` (or "Fares and fees") and `note="…"` for a different second sentence.

In use on 7 guides: 5G home broadband, Wi-Fi dead spots, Starlink, Irish phone in the USA, Uber, parental controls and UK shop charges. The checks fail a guide that uses the line without `prices_checked:`, or with a `prices_checked:` later than `last_checked`, and warn when prices are more than 60 days old (the January re-check clears the first warnings, due around 22 January 2027) or when a guide has the date but not the line.

## What changed note (built 26 Nov 2026)

When a re-check or a correction changes what a guide says, add an entry to `changes:` in its front matter:

```yaml
changes:
  - date: 2027-04-12
    what: "prices checked and Three's offer removed"
```

The newest entry shows under the byline at the top of the guide ("Updated 12 April 2027: prices checked and Three's offer removed. See all changes"), and every entry is listed in the box at the end of the guide, newest first; "See all changes" jumps there. A guide with no entries shows neither. Add an entry only when something a reader would notice has changed (a price, a step, an answer, a source swapped), never for a date-only re-check. Keep `what` short (120 characters at most), in lower case after the colon and with no full stop; the page adds it.

The checks fail a guide whose `changes:` isn't a list, an entry with no `date:` or no `what:`, a `what:` ending in a full stop, or a newest entry dated later than `last_checked` (a change means the guide was checked that day, so `last_checked` and `last_modified_at` move on with it). They warn when a `what:` is over 120 characters. Corrections readers send in also go on How we check guides' corrections log.

## Related guides (built 26 Nov 2026)

Every guide ends with a "Related guides" box, above Sources: up to three next reads, picked by hand and listed by address in the guide's front matter:

```yaml
related:
  - /phones/scam-calls/
  - /phones/likely-scam-texts/
```

`_includes/related.html` shows each guide's title as a link. A guide with no `related:` shows no box. Only Switched On guides go here: links to On Air Ireland stay in the text, where they help the reader. A new guide gets its `related:` picks in its notes doc's Outline, approved with the guide; when a new guide is added, look at whether it should replace a pick on one or two older guides.

The checks fail a guide whose `related:` isn't a list, lists more than three, lists the same guide twice, lists itself, or lists an address that isn't a guide.

## Topic groups (built 26 Nov 2026)

Once a topic has 8 or more guides, its "All guides" list can be split under headings, so readers find their question faster. The groups are listed, in the order they show, in `_data/topics.yml` (`groups:`), and each guide in that topic names its group in its front matter (`group: "Travelling"`). Within a group, guides keep the usual order (most recently checked first). A topic with fewer than 8 guides shows one list even if it has groups.

Only Phones is grouped so far (10 guides): Switching and setting up (eSIM, keep your number, phone bought abroad); Signal and calls (poor mobile signal, WiFi Calling); Travelling (UK, USA); Scams and security (Likely Scam texts, scam calls, lost or stolen phone). A new Phones guide needs a `group:` from that list; add a new group only when a guide doesn't fit any of them.

The checks fail a `groups:` that isn't a list or repeats a name, a guide in a grouped topic with no `group:` or one that isn't in the list, and a `group:` on a guide whose topic has no groups. They warn when a group has no guides, as its heading wouldn't show.

## Printing (built 26 Nov 2026)

Guides print as a clean article (the print rules are at the end of `assets/css/main.css`). Left out on paper: the site menu, footer, newsletter sign-up, preview bar, breadcrumb, the side rail (contents and About this guide) and the Related guides box. Kept: the logo, title, byline and dates, the answer, key points, tables, diagrams, the dated price line, Sources and the corrections box. Each source's web address is printed after its title, so a printout still shows where the facts came from. Diagrams, tables, key points and the price line aren't split across pages, a price line stays with its table, a line that leads into a list stays with the list, and a tall diagram is scaled to fit one page. Nothing changes on screen, so there are no checks for this. After a change to the layouts or CSS, print the lost phone, switch provider and 5G guides from Chrome (Print, Save as PDF) and look them over.

## Feed (built 26 Nov 2026)

`feed.xml` makes an Atom feed of the guides at /feed.xml, for feed readers. It's a plain Liquid template, not the jekyll-feed plugin, so it lists guides only (the plugin always adds an empty posts feed) and needs no `bundle install`. Each entry has the guide's title, its address and its description; never the whole guide. The newest guides come first. An entry's "updated" date is the guide's published date, or its newest `changes:` entry if that's later, so a date-only re-check doesn't make every guide look new again in people's feed readers.

In the preview the feed is built (so the checks can test it) but nothing links to it. Once `preview_mode` is false, every page's head has a feed link that feed readers find on their own, and the footer shows "RSS feed". After launch, paste https://switchedon.ie/feed.xml into the W3C feed validator (validator.w3.org/feed) once.

The checks fail a build with no feed.xml, a feed that isn't valid XML or doesn't start with `<?xml`, a guide missing or listed twice, an entry without a summary, or a link with a query string or tracking. After launch they also fail a page with no feed link in its head.

## Re-checks (plan written 25 Nov 2026)

Claude re-checks every guide's sources each quarter (January, April, July and October), and once more in the two weeks before launch. Only the changes come to John Paul to approve. After an approved change, `last_checked`, `last_modified_at` and each source's `checked:` all get the new date (the content checks fail if the first two differ). If readers would notice the change, add a `changes:` entry too (see What changed note).

The content checks also warn when a guide hasn't been checked for 100 days. All 29 guides were checked on 23–25 Nov 2026, so those warnings start around 3 March 2027, the planned launch week. The pre-launch re-check clears them.

Do these first, because they go stale fastest:

| Guide | What changes | How to check |
|---|---|---|
| Does my Irish phone plan work in the UK? | Each network's UK roaming terms (no law makes them include the UK) | Vodafone's page; Three's price guide and rate checker; eir's bill pay and prepay pages. Three's and eir's need a browser |
| Choosing a laptop for school or college | The Lenovo pick's Euronics price and stock (€889 on 23 Nov 2026, in a sale ending 29 Nov); Apple's MacBook Air specs; colleges' requirements for the next academic year | Euronics and Apple Ireland product pages; each college's laptop page |
| How to fix Wi-Fi dead spots | Booster prices at Virgin Media, Vodafone, eir and Sky | Each provider's booster page |
| Windows 10 support has ended | The free updates end date (12 Oct 2027; Microsoft has moved it once) and the US$30 option | Microsoft Ireland's two Windows 10 pages |
| Buying tech from a UK shop | VAT and customs charges (changed twice in 2026), An Post's and couriers' rules | Revenue, An Post |
| Does Uber work in Ireland? | Taxi Fixed Price, the €3 app booking fee, Bolt's coverage | Uber Ireland, TFI, Bolt |
| Does Starlink work in Ireland? | Plan names, prices, speeds and cancelling terms | Starlink's Irish contract summary, service plans page and complaints code. They need a browser |
| Why am I being asked to verify my age online? | Coimisiún na Meán's investigation into X (opened 8 Sep 2026) and its register of platforms; PlayStation's Irish checks; whether Microsoft adds Ireland to its Xbox age checks | Coimisiún na Meán's register, Online Safety Code page and news; PlayStation's Irish age verification FAQ; Microsoft's age verification page |
| Which Irish networks support WiFi Calling? | Each network's phone list and eligible plans; Vodafone's texts and roaming answers; eir's abroad charges; the iPhone menu path | Vodafone's network page and FAQ, Three's WiFi Calling page and terms, eir's WiFi Calling pages and terms, Sky Mobile's plans page. Vodafone's and eir's need a browser |
| Is Apple Intelligence available in Ireland? | Whether Siri AI comes to iPhone and iPad in the EU (no date on 25 Nov 2026); device lists, languages, storage; daily usage limits and the future fee | Apple Support (IE) pages 121115 and 127893, apple.com/ie/apple-intelligence |
| What is Ireland's Government Digital Wallet? | Whether the wider public release has happened (the guide's answer is "not yet"), which documents it holds, which phones it runs on, Irish language support. Check monthly until the release, then rewrite the answer, verdict and "When you can get it" for John Paul to approve | gov.ie/DigitalWallet and the Department of Public Expenditure's questions-answered page; guide 9's Digital Wallet section links here, so re-read it at the same time |
| Will my Irish phone work in the USA? | Vodafone's RED Roaming prices and allowances; Three's day, 3-day and 7-day pass prices; eir's US rates and 1GB add-on; the US 2G closures; ComReg's alert amounts | Vodafone's roaming page; Three's roaming page, price guides and pass terms; eir's roaming FAQ and bill pay and prepay pages; ComReg's two roaming pages. Vodafone's, Three's and eir's pages need a browser |
| Lost or stolen phone in Ireland | Each network's lost-phone numbers and steps; Find My and Find Hub steps; the Garda online declaration rules | Vodafone's lost or stolen page and Code of Practice, eir's mobile devices page, Virgin Media's replacement equipment and My Virgin Media pages, Tesco Mobile's lost or stolen page, Three's roaming page (customer care numbers), Apple Support (IE) 101593, Google's Android Help, garda.ie. eir's and Virgin Media's need a browser |
| Parental controls on Irish broadband and phones | Vodafone's Secure Net prices and modem list; whether Virgin Media's and Sky's controls are still free; Three's filter; Apple's and Google's steps | Each provider's page in the guide's sources; Apple Support (IE) 105121; Google's Family Link help; Coimisiún na Meán's parental controls page. eir's Smart Start page needs a browser |
| 5G home broadband in Ireland | Every price in the dated table (all are offers), the April rises, Vodafone's 14-day and Three's 30-day returns, eir's activation fee; update the date above the table | Vodafone's mobile broadband page, Three's broadband and existing-customer pages, eir's 5G broadband page, ComReg's broadband technology page |
| Scam calls in Ireland | ComReg's blocked-call figure and whether its Voice Firewall has gone live (left out until confirmed) | ComReg's Scam Calls & Texts page and its latest scam-call update; the Garda pages in the guide |
| What does 'Likely Scam' mean? | Whether ComReg has started blocking unregistered Sender IDs | comreg.ie/senderid |

Then the rest:

| Guide | What to watch |
|---|---|
| Setting up a verified MyGovID | The App Store's minimum iOS and the Digital Wallet section. mygovid.ie blocks automated reading, so button names need a screenshot from John Paul |
| Can I get fibre broadband at my address? | ComReg's network list (dated June 2024) and NBI's map |
| How to switch broadband provider | The planned right to leave a contract after an in-contract price rise, once it becomes law |
| Will a phone bought abroad work in Ireland? | 3G switch-off dates; Revenue's €430 allowance |
| Your rights when tech is faulty | CCPC pages carry no updated date, so re-read them in full |
| Recycling an old phone, laptop or TV | Apple's and Google's erase steps; the counties WEEE Ireland and ERP Ireland cover |
| Which Irish banks support Apple Pay and Google Pay? | Which cards each bank's Apple Pay and Google Pay pages cover; Apple's and Google's Irish lists (Google's needs a browser, and it left out Bank of Ireland, PTSB and An Post on 25 Nov 2026) |
| Do new laptops have to charge by USB-C in Ireland? | Whether the Commission's report due by 28 Dec 2026 changes the without-a-charger rule or extends it to cables; ComReg's and the Commission's common charger pages |
| Poor mobile signal at home? | ComReg's repeater rules (S.I. No. 86 of 2026) and its repeater page; the providers listed on the coverage map. Don't link coveragemap.comreg.ie without ComReg's written permission | ComReg's repeater, mobile service and coverage pages; eir's and Three's pages. The repeater FAQ needs a browser |
| Buying a refurbished phone or laptop | Apple's and Three's refurbished terms (warranty, batteries); Apple's pre-owned iPhone checks; CCPC pages carry no updated date, so re-read them in full |
| Switching to eSIM; How to keep your number | Networks' eSIM pages; ComReg's switching pages (both change rarely) |

## Before launch (not now)

These happen only after you say go, and nothing is pushed until you've reviewed it:

- ~~set `preview_mode: false` in `_config.yml`~~ done at launch, 27 Nov 2026
- ~~add `date:` with the launch day to each guide's front matter~~ done at launch: `date: 2026-11-27` on all 29 guides. It's the published date Google sees; a new guide gets the day it goes live
- add the site to Google Search Console and Bing Webmaster Tools and submit the sitemap. The Search Console ownership check is a TXT record at Blacknight, so it can be done before launch
- ~~hello@switchedon.ie~~ done 24 Nov 2026: a Proton Pass alias domain, the same as On Air Ireland's. MX, SPF, DKIM and DMARC records checked, the hello@ alias created and a test email sent and checked. Before the first newsletter, set up switchedon.ie in Brevo too (no second SPF record)
- GoatCounter is set up (site code `switchedon` in `_config.yml`, added 26 Nov 2026): the counter loads on every page only once `preview_mode` is false, and the checks fail a launched page without it or a preview page with it. At launch, open the site and check the visit shows at switchedon.goatcounter.com
- check the Privacy and How we make money pages still match how the site works, and update their "Last updated" dates
- the GitHub repo iptvtv-tech/switchedon, with the content checks running before every deploy (see Deploy; go given 26 Nov 2026, steps in the go-live checklist)
- once live, share one guide link in WhatsApp to check its card shows
- once live, test the newsletter: sign up on the homepage with your own email, check you land on "Check your email", that the confirmation email arrives from Switched On, and that its button takes you to "You're subscribed"
