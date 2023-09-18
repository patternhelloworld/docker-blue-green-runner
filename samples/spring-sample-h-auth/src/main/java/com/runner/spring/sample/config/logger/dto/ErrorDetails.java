package com.runner.spring.sample.config.logger.dto;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonView;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;
import org.springframework.lang.Nullable;

import javax.persistence.Entity;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@ToString
public class ErrorDetails {
	private Date timestamp;

	// Never to be returned to clients, but must be logged.
	// @JsonIgnore
	private String message;
	private String details;
	private String userMessage;
	private Map<String, String> userValidationMessage;


	@JsonIgnore
	private String stackTrace;
	@JsonIgnore
	private String cause;

	public ErrorDetails(Date timestamp, String message, String details) {
		super();
		this.timestamp = timestamp;
		this.message = message;
		this.details = details;
	}


	public ErrorDetails(Date timestamp, String message, String details, String userMessage, String stackTrace) {
		super();
		this.timestamp = timestamp;
		this.message = message;
		this.details = details;
		this.userMessage = userMessage;
		this.stackTrace = stackTrace;
	}

	public ErrorDetails(Date timestamp, String message, String details, String userMessage, String stackTrace, String cause) {
		super();
		this.timestamp = timestamp;
		this.message = message;
		this.details = details;
		this.userMessage = userMessage;
		this.stackTrace = stackTrace;
		this.cause = cause;
	}

	public ErrorDetails(Date timestamp, String message, String details, String userMessage, Map<String, String> userValidationMessage,
							String stackTrace, String cause) {
		super();
		this.timestamp = timestamp;
		this.message = message;
		this.details = details;
		this.userMessage = userMessage;
		this.userValidationMessage = userValidationMessage;
		this.stackTrace = stackTrace;
		this.cause = cause;
	}

	public Date getTimestamp() {
		return timestamp;
	}

	public String getMessage() {
		return message;
	}

	public String getDetails() {
		return details;
	}

	public String getUserMessage() {
		return userMessage;
	}

	public String getStackTrace() {
		return stackTrace;
	}

	public String getCause() {
		return cause;
	}

	public Map<String, String> getUserValidationMessage() {
		return userValidationMessage;
	}
}
