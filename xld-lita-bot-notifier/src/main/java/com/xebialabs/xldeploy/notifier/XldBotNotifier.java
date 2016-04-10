package com.xebialabs.xldeploy.notifier;

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

@DeployitEventListener
public class XldBotNotifier implements ExecutionStateListener {
	
	private static String BOT_URL = "http://localhost:8080";
	
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
		HttpResponse<String> jsonResponse = Unirest.post(BOT_URL + "/task/" + taskId + "/" + status)
				  .header("Content-type", "application/json")
				  .asString();
		if (jsonResponse.getStatus() != 200) {
			System.out.println("Error invoking bot: " + jsonResponse.getStatus());
		}
	}

	@Override
	public void stepStateChanged(StepExecutionStateEvent event) {
	}

	@Override
	public void taskStateChanged(TaskExecutionStateEvent event) {
		try {
			postNotification(event.task().getId(), event.currentState().toString());
		} catch (UnirestException e) {
			// Silently fail
		}
	}
}
