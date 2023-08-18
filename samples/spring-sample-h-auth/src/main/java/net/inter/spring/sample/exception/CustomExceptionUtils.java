package net.inter.spring.sample.exception;

import net.inter.spring.sample.config.logger.LogConfig;
import net.inter.spring.sample.config.logger.dto.ErrorDetails;

import org.apache.commons.lang3.exception.ExceptionUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;

public class CustomExceptionUtils {

    private static final Logger logger = LoggerFactory.getLogger(LogConfig.class);

    public static void createNonStoppableErrorMessage(String message) {

        logger.error("[NON-STOPPABLE ERROR] : ");

        try {
            new LogConfig().endpointBefore(true, "");
        } catch (Exception ex2) {
            logger.error(ex2.getMessage());
        } finally {
            ErrorDetails errorDetails = new ErrorDetails(new Date(), message, "Without exception param " + " / Thread ID = " + Thread.currentThread().getId() + " / StackTrace",
                    message, "", "");

            logger.error(" / " + errorDetails.toString());
        }

    }

    public static void createNonStoppableErrorMessage(String message, Throwable ex) {

        logger.error("[NON-STOPPABLE ERROR] : ");

        try {
            new LogConfig().endpointBefore(true, "");
        } catch (Exception ex2) {
            logger.error(ex2.getMessage());
        } finally {
            ErrorDetails errorDetails = new ErrorDetails(new Date(), message, "Witho exception param " + " / Thread ID = " + Thread.currentThread().getId() + " / StackTrace",
                    message, CustomExceptionUtils.getAllStackTraces(ex), CustomExceptionUtils.getAllCauses(ex));

            logger.error(" / " + errorDetails.toString());
        }

    }

    public static String getAllCausesWithStartMessage(Throwable e, String causes) {
        if (e.getCause() == null) return causes;
        causes += e.getCause() + " / ";
        return getAllCausesWithStartMessage(e.getCause(), causes);
    }

    public static String getAllCauses(Throwable e) {
        String causes = "";
        return getAllCausesWithStartMessage(e, causes);
    }

    public static String getAllStackTraces(Throwable e) {
        return ExceptionUtils.getStackTrace(e);
    }
}
