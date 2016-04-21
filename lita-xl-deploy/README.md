This is a handler for the [Lita](https://www.lita.io/) bot framework that connects to [XL Deploy](https://xebialabs.com/products/xl-deploy/).

Using this handler, you can make XL Deploy an active part of your DevOps communication. Include XL Deploy in your chat room and collaborate with your team on planning, performing, and troubleshooting deployments.

# Prerequisites

See the [top level README](../README.md#prerequisites) for prerequisites.

# Quick start

See the [sample-bot](../sample-bot) project for a complete and easy-to-use Lita bot setup.

# Features

## Chatting with XL Deploy

The bot makes it possible to "chat" with XL Deploy. The following interactions are possible:

* list applications / versions / environments / deployments
* start / stop / cancel / archive deployments
* inspect a task step log
* start a new deployment

## Connecting to XL Deploy

The bot connects to XL Deploy using a combination of a URL, user name, and password, all configured in the `lita_config.rb` file. The bot interacts with XL Deploy as this user and has all permissions associated with the user. For example, if you configure the bot to connect to XL Deploy as the admin user, then everyone in the chat room will be able to start deployments as the admin user.

We recommend you configure the bot to use a user with restricted permissions to prevent unintentional privilege escalation.

## Task IDs

In XL Deploy, tasks are referred to using globally unique identifiers (GUIDS). These IDs are long and cumbersome to use when communicating via a chat tool.

The bot generates a unique, five-character ID for each task GUID it encounters. These short IDs are used to communicate with chat room members about tasks. Each short id is remembered during the context storage period set in the `context_storage_timeout` configuration option. After this timeout expires, the short ID is purged from storage and is no longer accessible. The bot will generate a new short ID the next time it encounters the task GUID.

## Conversation context

The bot keeps track of the conversation it has with a user in a particular room. Specifically, the bot remembers the latest task, application, version, and environment that a user mentioned. This makes the following interaction possible:

```
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

```

Note that the bot inferred the user was talking about task `fd5hr` when giving the `start` command.

When a user lists available applications, environments, versions, or deployments, the conversation context for that user in that room is reset.

## Starting deployments

To start a deployment, use the following command:

```
 [You] deploy war 1.0 to test
[Lita] Starting deployment of PetClinic-war-1.0 to TEST [i6tj7]
```

The bot will search for each of the components of the command in XL Deploy. In the above example, the bot will search for an application called `%war%`. If found, it will search for a version `%1.0%` of the same application. Finally, it will search for an environment named `%test%`.

If multiple matches are found, the bot will show a comment such as the following:

```
  [You] deploy pet
 [Lita] Which application do you mean? (candidates: Applications/PetClinic-ear, Applications/PetClinic-war, Applications/PetZoo)
```

If you omit any of the components, the bot will attempt to retrieve the values from your conversation context:

```
  [You] deploy ear 1.0 to test
 [Lita] Starting deployment of PetClinic-ear-1.0 to TEST [1qov0]

  [You] deploy ear 2.0
 [Lita] (using env TEST)
        ...
```

## Configuration

### Required attributes

* `xld_url` (String): The URL of your XL Deploy instance. Default: `nil`.
* `xld_username` (String): The user name to use when connecting to your XL Deploy instance. Default: `nil`.
* `xld_password` (String): The password to use when connecting to your XL Deploy instance. Default: `nil`.
* `context_storage_timeout` (int): The duration for which to keep conversation context, in seconds. Default: `nil`.

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
