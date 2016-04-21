This is a sample [Lita](https://docs.lita.io/) bot that is configured to connect to an XL Deploy instance.

# Prerequisites

See the [top level README](../README.md#prerequisites) for general prerequisites.

In addition, ensure all Ruby libraries required by this bot are installed by executing the following command in this directory:

```
bundle
```

# Configure the bot

Before running the bot, you must tell it where your XL Deploy instance is located. Open the [lita_config.rb](lita_config.rb) file and enter the URL of your XL Deploy instance and the user name and password to use when connecting.

These sample values are included in the file:

```
  config.handlers.xl_deploy.xld_url = "http://localhost:4516/deployit"
  config.handlers.xl_deploy.xld_username = "admin"
  config.handlers.xl_deploy.xld_password = "admin1"
```

# Run the bot

Start the bot with the command:

```
lita
```

This will boot Lita and instantiate the bot. You can communicate with the bot via the command line.

# First steps

After the bot is running, you can start testing the connection to XL Deploy by looking at the installed applications:

```
 [You] applications
[Lita] List of applications:
       - Applications/PetClinic-ear
       - Applications/PetClinic-war
       - Applications/PetZoo
```

Note that the bot accesses XL Deploy as the user that is configured in the configuration file. The bot can only see the applications that are accessible to that user.

You can also check the available environments:

```
 [You] environments
[Lita] List of environments:
       - Environments/DEV
       - Environments/TEST
```

If this works, your connection to XL Deploy is configured correctly.

See the [usage documentation](../lita-xl-deploy#chatting-with-xl-deploy) for more information about what the bot can do.

# Connecting to HipChat

If you want to connect your bot to HipChat, change [lita_config.rb](lita_config.rb) by including the _hipchat_ adapter:

```
  config.robot.adapter = :hipchat
  config.adapters.hipchat.jid = "123456_123456@chat.hipchat.com"
  config.adapters.hipchat.password = "secret"
  config.adapters.hipchat.debug = false
  config.adapters.hipchat.rooms = [ "123456_sandbox" ]
```

Uncomment the line to include the lita-hipchat gem in the [Gemfile](Gemfile), ensure the gem is installed, and restart the bot.
