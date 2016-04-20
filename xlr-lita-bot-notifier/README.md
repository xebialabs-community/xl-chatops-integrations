This is an [XL Release](https://www.xebialabs.com/products/xl-release) plugin that posts notifications of task activity to a bot.

# Configuration

The notifier requires the URL to the bot to run. This URL can be configured via a file called `xlr-bot.conf` in the XL Release `conf` directory.

Here is a sample:

```
bot.url=http://bot.xebialabs.com:8080
```

If the configuration file is not found, the notifier defaults to using `http://localhost:8080`.

# Requirements

The notifier has been tested with XL Release 4.8.x.

# Installation

Install the notifier as a regular plugin by copying the JAR file into the XL Release installation's _plugins_ folder. Restart XL Release to enable the plugin.
