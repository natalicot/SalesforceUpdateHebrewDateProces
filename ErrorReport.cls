/**
 * Jira: Yosi:FinalProject
 * Error reporting class
 *
 * Author: natali.cutic 
 *
 * @since: 12/30/2020
 * @class: ErrorReport
 *
 */

public with sharing class ErrorReport {

    public ErrorReport(){}

    /**
     * Sends email to Natali and prints debug error
     * @param errorMessage String of error message
     */
    public void reportError(String errorMessage){
        System.debug(LoggingLevel.ERROR,errorMessage);
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        semail.setSubject('Error occurred');
        String[] sendTo = new String[]{'natali.cutic@allcloud.io'};
        semail.setToAddresses(sendTo);
        semail.setPlainTextBody(errorMessage);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});

    }

}