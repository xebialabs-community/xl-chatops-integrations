package com.xebialabs.xldeploy.notifier;

import java.util.Properties;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.mashape.unirest.http.HttpResponse;
import com.mashape.unirest.http.Unirest;
import com.mashape.unirest.http.exceptions.UnirestException;
import com.xebialabs.deployit.engine.spi.event.DeployitEventListener;
import com.xebialabs.deployit.engine.spi.event.TaskAbortedEvent;
import com.xebialabs.deployit.engine.spi.event.TaskArchivedEvent;
import com.xebialabs.deployit.engine.spi.event.TaskCancelledEvent;
import com.xebialabs.deployit.engine.spi.event.TaskScheduledEvent;
import com.xebialabs.deployit.engine.spi.event.TaskStartedEvent;
import com.xebialabs.deployit.engine.spi.event.TaskStoppedEvent;
import com.xebialabs.deployit.engine.spi.execution.ExecutionStateListener;
import com.xebialabs.deployit.engine.spi.execution.StepExecutionStateEvent;
import com.xebialabs.deployit.engine.spi.execution.TaskExecutionStateEvent;

import nl.javadude.t2bus.Subscribe;

/**
 * This class is a plugin for XL Deploy that posts task status updates to a REST endpoint, such
 * as the endpoint included in the XebiaLabs lita bot. 
 */
@DeployitEventListener
public class XldBotNotifier implements ExecutionStateListener {
	
	private static final Logger LOG = LoggerFactory.getLogger(XldBotNotifier.class);
	
	private static String DEFAULT_BOT_URL = "http://localhost:8080";
	private String botURL = DEFAULT_BOT_URL;
	
	public XldBotNotifier() {
		try {
			Properties props = new Properties();
			props.load(ClassLoader.getSystemResourceAsStream("xld-bot.conf"));
			botURL = props.getProperty("bot.url", DEFAULT_BOT_URL);
		} catch(Exception e) {
			// ignore
		}
		LOG.debug("Using bot URL " + botURL);
	}
	
	@Subscribe
	public void log(TaskStartedEvent event) throws UnirestException {
		postNotification(event.getTaskId(), "started");
	}

	@Subscribe
	public void log(TaskStoppedEvent event) throws UnirestException {
		postNotification(event.getTaskId(), "stopped");
	}

	@Subscribe
	public void log(TaskCancelledEvent event) throws UnirestException {
		postNotification(event.getTaskId(), "cancelled");
	}
	
	@Subscribe
	public void log(TaskAbortedEvent event) throws UnirestException {
		postNotification(event.getTaskId(), "aborted");
	}
	
	@Subscribe
	public void log(TaskArchivedEvent event) throws UnirestException {
		postNotification(event.getTaskId(), "archived");
	}
	
	@Subscribe
	public void log(TaskScheduledEvent event) throws UnirestException {
		postNotification(event.getTaskId(), "scheduled");
	}
	
	private void postNotification(String taskId, String status) throws UnirestException {
		HttpResponse<String> jsonResponse = Unirest.post(botURL + "/task/" + taskId + "/" + status)
				  .header("Content-type", "application/json")
				  .asString();
		if (jsonResponse.getStatus() != 200) {
			LOG.debug("Failed to push event to bot, status code " + jsonResponse.getStatusText());
		}
	}

	@Override
	public void stepStateChanged(StepExecutionStateEvent event) {
		try {
			LOG.debug("Task " + event.task().getId() + " step state changed, pushing event to bot URL " + botURL);
			postNotification(event.task().getId(), event.currentState().toString());
		} catch (UnirestException e) {
			// Silently fail
		}
	}

	@Override
	public void taskStateChanged(TaskExecutionStateEvent event) {
		try {
			LOG.debug("Task " + event.task().getId() + " state changed, pushing event to bot URL " + botURL);
			postNotification(event.task().getId(), event.currentState().toString());
		} catch (UnirestException e) {
			// Silently fail
		}
	}
}
