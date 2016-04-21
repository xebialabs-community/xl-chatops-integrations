This is an [XL Deploy](https://www.xebialabs.com/products/xl-deploy) plugin that posts notifications of task activity to a bot.

# Prerequisites

See the [top level README](../README.md#prerequisites) for general prerequisites.

The notifier requires the following libraries in XL Deploy:

* httpasyncclient-4.0.2.jar
* unirest-java-1.4.7.jar
* httpcore-nio-4.4.3.jar

These files are included in the [lib](lib) folder of this repository.

The notifier has been tested with XL Deploy 5.1.x.

# Installation

Install the libraries from this project's `lib` folder in your XL Deploy installation's `lib` folder:

```
cp lib/*.jar /path/to/xl-deploy/lib
```

Next, install the notifier as a regular plugin by copying the JAR file in the XL Deploy installation's _plugins_ folder. Restart XL Deploy to enable the plugin.

# Configuration

The notifier requires the URL to the bot to run. This URL can be configured via a file called `xld-bot.conf` in the XL Deploy `conf` directory.

Here is a sample:

```
bot.url=http://bot.xebialabs.com:8080
```

If the configuration file is not found, the notifier defaults to using `http://localhost:8080`.
