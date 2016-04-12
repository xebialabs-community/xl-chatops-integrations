This repository contains a bot to integrate [XebiaLabs](https://www.xebialabs.com) tools into your ChatOps initiative.

# Introduction

Collaboration & team work are two of the cornerstones of how we work at XebiaLabs. Being a distributed team, this means using a chat tool to discuss and keep your team members up-to-date. More and more, we have been including our tools in the chat room as well -- JIRA, Zendesk, PagerDuty... as well as our own tools of course!

We've written an internal bot to connect XL Deploy to our chat room. This bot, based on the [Lita](http://www.lita.io) framework, allows communication to and from XL Deploy.

The source code is published here for you to try out. Give it a shot & let us know what you think!

# Contents

This repository contains the following:

* [lita-xl-deploy](lita-xl-deploy): a handler to communicate with [XL Deploy](https://www.xebialabs.com/products/xl-deploy) from your chat room, written for the [Lita](http://www.lita.io) bot framework
* [xld-lita-bot-notifier](xld-lita-bot-notifier): a plugin for [XL Deploy](https://www.xebialabs.com/products/xl-deploy) that pushes status information out to the bot
* [sample-bot](sample-bot): a sample bot configuration

# Quick start

The [sample-bot](sample-bot) project is the easiest way to get a bot up and running.

# Feedback

If you have any feedback regarding this software or suggestions for improvements, please log them in the [XL Deploy forum](https://support.xebialabs.com/hc/en-us/community/topics/200267485-XL-Deploy).

Regards,
The XebiaLabs team
