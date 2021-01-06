/**
 * Jira: Yosi:FinalProject
 * Update hebrew date filed on all users in the system.
 *
 * Author: natali.cutic 
 *
 * @since: 12/29/2020
 * @class: UpdateHebrewDateBatch
 *
 */


global class UpdateHebrewDateBatch implements Database.Batchable<sObject>, Database.Stateful {

    global final String Query;
    global final String Field;
    global final String Value;
    global List<Database.SaveResult> errorResults = new List<Database.SaveResult>();

    global UpdateHebrewDateBatch(String hebrewDate) {
        this.Query = 'SELECT hebrew_date__c,ProfileId FROM User';
        this.Field = 'hebrew_date__c';
        this.Value = hebrewDate;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        //update all fileds
        for (sobject s : scope) {
            s.put(Field, Value);
        }
        List<Database.SaveResult> results = (Database.update(scope,false));

        //save failed results
        for(Database.SaveResult result : results){
            if(!result.isSuccess()){
                errorResults.add(result);
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        if(!errorResults.isEmpty()){
            ErrorReport err = new ErrorReport();
            err.reportError('Batchable update on few users failed, view the next exception: '+errorResults.toString());
        }
    }
}