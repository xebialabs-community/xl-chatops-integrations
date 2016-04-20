package com.xebialabs.xlrelease.notifier;

import java.util.List;
import java.util.Properties;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.mashape.unirest.http.HttpResponse;
import com.mashape.unirest.http.Unirest;
import com.mashape.unirest.http.exceptions.UnirestException;
import com.xebialabs.deployit.engine.spi.command.CreateCiCommand;
import com.xebialabs.deployit.engine.spi.command.CreateCisCommand;
import com.xebialabs.deployit.engine.spi.event.CiBaseEvent;
import com.xebialabs.deployit.engine.spi.event.DeployitEventListener;
import com.xebialabs.deployit.event.EventBusHolder;
import com.xebialabs.deployit.plugin.api.udm.ConfigurationItem;
import com.xebialabs.xlrelease.api.XLReleaseServiceHolder;
import com.xebialabs.xlrelease.domain.ActivityLogEntry;
import com.xebialabs.xlrelease.domain.Release;

import nl.javadude.t2bus.Subscribe;

/**
 * This class is a plugin for XL Release that posts activity updates to a REST endpoint, such
 * as the endpoint included in the XebiaLabs lita bot. 
 */
@DeployitEventListener
public class XlrBotNotifier {
	
	private static final String TASK_STARTED_ACTIVITY_TYPE = "TASK_STARTED";

	private static final String TASK_TASK_TEAM_UPDATED_ACTIVITY_TYPE = "TASK_TASK_TEAM_UPDATED";

	private static final String TASK_OWNER_UPDATED_ACTIVITY_TYPE = "TASK_OWNER_UPDATED";

	private static final Logger LOG = LoggerFactory.getLogger(XlrBotNotifier.class);
	
	private static String DEFAULT_BOT_URL = "http://localhost:8080";
	private String botURL = DEFAULT_BOT_URL;
	
	public XlrBotNotifier() {
		try {
			Properties props = new Properties();
			props.load(ClassLoader.getSystemResourceAsStream("xlr-bot.conf"));
			botURL = props.getProperty("bot.url", DEFAULT_BOT_URL);
		} catch(Exception e) {
			// ignore
		}
		LOG.debug("Using bot URL " + botURL);
		
		EventBusHolder.register(this);
	}

    @Subscribe
    public void createCi(CreateCiCommand command) throws UnirestException {
    	final ConfigurationItem ci = command.getCi();
    	notifyForCiCreation(ci);
    }

	private void notifyForCiCreation(final ConfigurationItem ci) {
		if (ci.getType().getName().equals("ActivityLogEntry")) {
    		ActivityLogEntry ale = (ActivityLogEntry) ci;
    		if (shouldPostNotification(ale)) {
	    		LOG.debug("Posting notification for ALE with id " + ci.getId() + ", type " + ale.getActivityType() + ", message " + ale.getMessage());
	    		String taskId = getTaskId(ale.getId());
	    		if (taskId != null) {
	    			postNotification(ale.getId(), ale.getActivityType(), ale.getMessage(), taskId);
	    		} else {
	        		LOG.debug("Unable to determine task id, skipping notification");
	    		}
    		} else {
        		LOG.debug("Ignoring ALE of type " + ale.getActivityType());
    		}
    	} else {
    		LOG.debug("Ignoring creation of CI type " + ci.getType().getName());
    	}
	}

	private String getTaskId(String aleId) {
		try {
			String[] parts = aleId.split("/");
			String releaseId = "Applications/" + parts[2];
			Release release = XLReleaseServiceHolder.getReleaseApi().getRelease(releaseId);
			return release.getCurrentTask().getId();
		} catch(Exception e) {
			return null;
		}
	}

    private boolean shouldPostNotification(ActivityLogEntry ale) {
		String activityType = ale.getActivityType();
		return 	activityType.equals(TASK_OWNER_UPDATED_ACTIVITY_TYPE) ||
				activityType.equals(TASK_TASK_TEAM_UPDATED_ACTIVITY_TYPE) ||
				activityType.equals(TASK_STARTED_ACTIVITY_TYPE);
	}

	@Subscribe
    public void createCis(CreateCisCommand command) {
    	List<ConfigurationItem> list = command.getCis();
    	for (ConfigurationItem ci : list) {
			notifyForCiCreation(ci);
		}
    }

    @Subscribe
    public void createCis(CiBaseEvent command) {
    	List<ConfigurationItem> list = command.getCis();
    	for (ConfigurationItem ci : list) {
			notifyForCiCreation(ci);
		}
    }
	
	private void postNotification(String id, String type, String message, String taskId) {
		try {
			HttpResponse<String> jsonResponse = Unirest.post(botURL + "/activity")
					  .header("Content-type", "application/json")
					  .body("{ \"id\": \"" + id + "\", \"type\": \"" + type 
							  + "\", \"message\": \"" + message + "\", \"taskId\": \"" + taskId + "\" }")
					  .asString();
			if (jsonResponse.getStatus() != 200) {
				LOG.debug("Failed to push event to bot, status code " + jsonResponse.getStatusText());
			}
		} catch(UnirestException e) {
			// fail silently
			LOG.debug("Failed to push event to bot", e);
		}
	}
}
