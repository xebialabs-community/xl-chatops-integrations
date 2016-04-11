This is an [XL Deploy](https://www.xebialabs.com/products/xl-deploy) plugin that posts notifications of task activity to a bot.

# Configuration

The notifier requires the URL to the bot to run. This URL can be configured via a file called `xld-bot.conf` in the XL Deploy `conf` directory.

Here is a sample:

```
bot.url=http://bot.xebialabs.com:8080
```

If the configuration file is not found, the notifier defaults to using `http://localhost:8080`.

# Requirements

The notifier has been tested with XL Deploy 5.1.x.

# Installation

Install the notifier as a regular plugin by copying the JAR file into the XL Deploy installation's _plugins_ folder. Restart XL Deploy to enable the plugin.
