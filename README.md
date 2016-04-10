This repository contains a bot to integrate [XebiaLabs](https://www.xebialabs.com) tools into your ChatOps initiative.

# Introduction

Communication is the centerpiece of a successful DevOps strategy. Today's IT organisation is often distributed, causing widespread use of chat tools for persistent, real-time communication. Tools such as HipChat and Slack are gaining a wide following.

Collaborating with your team via a chat tool is useful, but there is a piece of the conversation missing: the tools you use to do your job. Leading DevOps teams have started including their tools in the conversation by connecting them to their chat tool of choice. In the resulting conversation, in addition to coordination and information exchange, team members work together to get their job done -- right from within the chat room!

This pattern is known as _ChatOps_ and is a highly effective way of organising your DevOps team.

We at XebiaLabs practice this pattern internally and have started using our own tools in the same manner. Here you will find a connector that allows XL Deploy to become part of a DevOps conversation.

Give it a shot & let us know what you think!

# Contents

This repository contains the following:

* [lita-xl-deploy](lita-xl-deploy): a handler to communicate with [XL Deploy](https://www.xebialabs.com/products/xl-deploy) from your chat room, written for the [Lita](http://www.lita.io) bot framework
* [xld-lita-bot-notifier](xld-lita-bot-notifier): a plugin for [XL Deploy](https://www.xebialabs.com/products/xl-deploy) that pushes status information out to the bot
* [sample-bot](sample-bot): a sample bot configuration

# Running the sample bot

To try the sample bot, see further instructions in the [sample-bot](sample-bot) project.

# Feedback

If you have any feedback regarding this software or suggestions for improvements, please log them in the [XL Deploy forum](https://support.xebialabs.com/hc/en-us/community/topics/200267485-XL-Deploy).

Regards,
The XebiaLabs team
