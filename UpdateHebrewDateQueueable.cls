/**
 * Jira: Yosi:FinalProject
 * Queueable runs from Schedulable: UpdateHebrewDateScheduler for allowing callouts
 *
 * Author: natali.cutic 
 *
 * @since: 12/28/2020
 * @class: UpdateHebrewDateQueueable
 *
 */

public class UpdateHebrewDateQueueable implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext context) {
        HebrewUpdateProcess prc = new HebrewUpdateProcess();
    }
}