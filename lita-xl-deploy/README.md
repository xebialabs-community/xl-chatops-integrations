# lita-xl-deploy

ChatOps bot for [XL Deploy](https://xebialabs.com/products/xl-deploy/).

The lita-xl-deploy bot is a bot based on the [Lita](https://www.lita.io/) chat bot framework written in Ruby.

This bot makes XL Deploy an active part of your DevOps communication. Include XL Deploy in your chat room and collaborate with your team on planning, performing and troubleshooting deployments.

## Installation

See the [Lita installation documentation](https://docs.lita.io/getting-started/installation/) for instructions on how to setup a Lita bot.

Add lita-xl-deploy handler to your bot by adding it to your Lita instance's Gemfile:

``` ruby
gem "lita-xl-deploy"
```

Or, if you run it directly from source:

``` ruby
gem "lita-xl-deploy", :path => "/path/to/lita-xl-deploy"
```

## Configuration

### Required attributes

* `xld_url` (String) - The URL to your XL Deploy instance. Default: `nil`.
* `xld_username` (String) - The username to connecto to your XL Deploy instance. Default: `nil`.
* `xld_password` (String) - The password to connect to your XL Deploy instance. Default: `nil`.
* `context_storage_timeout` (int) - The duration for which to keep conversation context, in seconds. Default: `nil`.

### Optional attributes

None.

### Example

``` ruby
Lita.configure do |config|
  # The name your robot will use.
  config.robot.name = "My Bot"

  # The locale code for the language to use.
  # config.robot.locale = :en

  # The severity of messages to log. Options are:
  # :debug, :info, :warn, :error, :fatal
  # Messages at the selected level and above will be logged.
  config.robot.log_level = :info

  # An array of user IDs that are considered administrators. These users
  # the ability to add and remove other users from authorization groups.
  # What is considered a user ID will change depending on which adapter you use.
  # config.robot.admins = ["1", "2"]

  # The adapter you want to connect with. Make sure you've added the
  # appropriate gem to the Gemfile.
  config.robot.adapter = :hipchat
  config.adapters.hipchat.jid = "123456_123456@chat.hipchat.com"
  config.adapters.hipchat.password = "secret"
  config.adapters.hipchat.debug = false
  config.adapters.hipchat.rooms = [ "123456_sandbox" ]

  ## Example: Set options for the chosen adapter.
  # config.adapter.username = "myname"
  # config.adapter.password = "secret"

  ## Example: Set options for the Redis connection.
  # config.redis.host = "127.0.0.1"
  # config.redis.port = 1234

  ## Example: Set configuration for any loaded handlers. See the handler's
  ## documentation for options.
  # config.handlers.some_handler.some_config_key = "value"

  config.handlers.xl_deploy.xld_url = "http://localhost:4516/deployit"
  config.handlers.xl_deploy.xld_username = "admin"
  config.handlers.xl_deploy.xld_password = "secret"
  config.handlers.xl_deploy.context_storage_timeout = "3600"

end
```

## Usage

```
 [You] applications
[Lita] List of applications:
       - Applications/PetClinic-ear
       - Applications/PetClinic-war
       - Applications/PetZoo

 [You] environments
[Lita] List of environments:
       - Environments/DEV
       - Environments/TEST

 [You] versions petzoo
[Lita] List of PetZoo versions:
       - Applications/PetZoo/1.0

 [You] deployments
[Lita] List of deployments:
       - [STOPPED] PetClinic-war/1.0 to TEST [fd5hr]

 [You] log fd5hr
[Lita] Showing log of task fd5hr
       fd5hr> Uploading file stop-tc.sh to working directory.
       fd5hr> Executing /var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/ot-20160312T203457416/generic_plugin.tmp/stop-tc.sh on host Infrastructure/localhost
       fd5hr> [ERROR]: /var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/ot-20160312T203457416/generic_plugin.tmp/stop-tc.sh: line 1: cd: /opt/tomcat: No such file or directory
       fd5hr> [ERROR]: /var/folders/zz/zyxvpxvq6csfxvn_n0000000000000/T/ot-20160312T203457416/generic_plugin.tmp/stop-tc.sh: line 2: bin/stop.sh: No such file or directory
       fd5hr> [ERROR]: Execution failed with return code 127

 [You] start
[Lita] (using task fd5hr)
       Starting task fd5hr
       [fd5hr] started
 
 [You] deploy war 1.0 to test
[Lita] Starting deployment of PetClinic-war-1.0 to TEST [i6tj7]
```

## License

[MIT](http://opensource.org/licenses/MIT)
