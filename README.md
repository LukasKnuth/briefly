# Briefly ![GitHub Tag](https://img.shields.io/github/v/tag/LukasKnuth/briefly?label=latest)

A minimalist Atom/RSS reader that aims to be _calm_.
To achieve this, a few explicit design decisions where made:

**No "unread" counters.**
Let's not accumulate another list of things to eventually get to.
Briefly doesn't keep track of which entries you have read.
It just loads your feeds and shows you what was recently published.

**Go out and read.**
We do not download the article content, we just link to the source.
Many authors spend lots of time making their pages visually pleasing.
Grace them with your presence.

**A few curated feeds.**
The application is designed to follow many low-frequency feeds.
Like your favorite Bloggers you'd like to keep up-to-date with.
You can of course also add feeds from larger outlets - but those are rarely calm.

## Features

- Supports RSS and Atom type feeds
- Simple code
- Easy to host - just one Docker image, no database
- Well tested code [![Coverage Status](https://coveralls.io/repos/github/LukasKnuth/briefly/badge.svg?branch=main)](https://coveralls.io/github/LukasKnuth/briefly?branch=main)
- Free as in Freedom ![GitHub License](https://img.shields.io/github/license/LukasKnuth/briefly)

## Configuration and Hosting

A Docker image is available at `ghcr.io/lukasknuth/briefly` via [GitHub Packages](https://github.com/LukasKnuth/briefly/pkgs/container/briefly).
Here is an example `docker-compose.yml` file - all options are explained below.

```yml
services:
  briefly:
    image: "ghcr.io/lukasknuth/briefly:latest"
    volumes:
      - type: bind
        source: path/to/your/feeds.yml
        target: /etc/briefly/feeds.yml
    environment:
      TZ: "Europe/Berlin"
      CRON_REFRESH: "0 8 * * *" # daily at 8:00am
    ports:
      - "4000:4000"
```

### Environment Variables

| Name | Description | Default |
|------|-------------|---------|
| `TZ` | [Timezone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for displayed times and CRON refresh. | `Etc/UTC` |
| `CRON_REFRESH` | When to update feeds, in [CRON notation](https://crontab.guru/) - uses `TZ` timezone! | unset; **disables automatic refresh!** |
| `CONFIG_PATH` | Path to the YAML configuration file (see below). | `/etc/briefly/feeds.yml` |
| `HOME_ACTION` | Action that the `/` root route should render. This is the same as the parameter given to the `/since/:days` route! | `yesterday` |
| `PORT` | Port that the HTTP server listens on. | `4000` |

### Configuration File

The configuration file is a YAML file with the following format:

```yaml
feeds:
  - https://lknuth.dev/writings/index.xml
  - url: https://bytes.zone/index.xml
    feed: Renamed
  - url: https://feeds.bbci.co.uk/news/world/rss.xml
    group: News International
  - url:  https://www.tagesschau.de/ausland/index~rss2.xml
    group: News International
```

The root is an object with a single `feeds` array.
In the array, entries can have the following properties:

| Property | Description | Default |
|----------|-------------|---------|
| `url` (string) | Direct URL to the RSS/Atom feed. | No default; Required |
| `group` (string) | Group that this feed belongs to | `null` meaning "no group" |
| `feed` (string) | Overrides the feeds name on each item | The feeds `title` from RSS/Atom |

Notes:

- If multiple feeds have the same `group` value, their items will be listed in the same group.
- When only `url` is specified, the object can be replaced by just a string (see example above).
- If the URL contains UTF8 characters, it must be [Punycode encoded](https://en.wikipedia.org/wiki/Punycode)

## Shoutouts

This is heavily inspired by [the web-reader project by @capjamesg](https://github.com/capjamesg/web-reader).
This is basically a more integrated and easier to run version of this project.
