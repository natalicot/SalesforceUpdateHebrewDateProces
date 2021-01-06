/**
 * Jira: Yosi:FinalProject
 * Every day at sunset updates hebrew date filed
 *
 * Author: natali.cutic 
 *
 * @since: 12/15/2020
 * @class: UpdateHebrewDateScheduler
 *
 */

global class UpdateHebrewDateScheduler implements Schedulable{

    global UpdateHebrewDateScheduler(){}

    global void execute(SchedulableContext ctx) {
        System.enqueueJob(new UpdateHebrewDateQueueable());
    }
}