/**
 * Jira: Yosi:FinalProject
 * Process for updating hebrew date filed every day at sunset and scheduling the process for the next day sunset.
 *
 * Author: natali.cutic 
 *
 * @since: 12/29/2020
 * @class: HebrewUpdateProcess
 *
 */

public with sharing class HebrewUpdateProcess {

    private Boolean isSuccessful = true;

    public HebrewUpdateProcess() {
        Boolean isFirstRun = !System.isQueueable();
        if (isFirstRun) {
            firstRun();
        } else {
            recurringRun();
        }
    }

    /**
     * first initial run of HebrewUpdateProcess.
     * If running before sunset - updates hebrew date field and schedules next run at today's sunset.
     * If running after sunset - calling recurringRun function.
     */
    private void firstRun() {

        //find if currently after sunset
        GetSunsetTimeService srv = new GetSunsetTimeService(false);
        Time currentTime = Time.newInstance(Integer.valueOf(System.now().hour()), Integer.valueOf(System.now().minute()), 0, 0);//function

        if (GetSunsetTimeService.sunsetTime == null) {
            ErrorReport err = new ErrorReport();
            err.reportError('Initial Run Has Failed Please check Sunset API Service');
            this.isSuccessful = false;
        }

        //if before sunset
        if (GetSunsetTimeService.sunsetTime > currentTime) {
            //get hebrew date
            GetHebrewDateService srvHebrewDate = new GetHebrewDateService(false);
            String hebrewDate = srvHebrewDate.getHebrewDate();
            if (hebrewDate == null) {
                ErrorReport err = new ErrorReport();
                err.reportError('Initial Run Has Failed Please check Hebrew Date API Service');
                this.isSuccessful = false;
            }

            //set next run for today's sunset
            UpdateHebrewDateScheduler upd = new UpdateHebrewDateScheduler();
            String whenString = GetSunsetTimeService.sunsetCrone;
            String jobName = 'Set Hebrew Date ' + String.valueOf(System.now());
            String JobId = System.schedule(jobName, whenString, upd);

            //update current hebrew date
            if(this.isSuccessful) {
                UpdateHebrewDateBatch updateBatch = new UpdateHebrewDateBatch(hebrewDate);
                ID batchProcessId = Database.executeBatch(updateBatch);
            }
        }
        //if after sunset
        else {
            recurringRun();
        }

    }

    /**
     * Recurring run HebrewUpdateProcess.
     * sets the nex run for tomorrow's sunset.
     * Updates hebrew date fields.
     */
    private void recurringRun() {

        //get tomorrow sunset and current hebrew date
        GetSunsetTimeService srvSun = new GetSunsetTimeService(true);
        GetHebrewDateService srv = new GetHebrewDateService(true);
        String hebrewDate = srv.getHebrewDate();

        //set next run for tomorrow at sunset
        UpdateHebrewDateScheduler upd = new UpdateHebrewDateScheduler();
        String cronString = GetSunsetTimeService.sunsetCrone;
        String jobName = 'Set Hebrew Date ' + String.valueOf(System.now());

        //if something went wrong - run again in 30min
        if (hebrewDate == null || GetSunsetTimeService.sunsetCrone == null) {
            cronString = getCron30minFromNow();
            this.isSuccessful = false;

        }

        String JobId = System.schedule(jobName, cronString, upd);

        //update hebrew date
        if (this.isSuccessful) {
            UpdateHebrewDateBatch updateBatch = new UpdateHebrewDateBatch(hebrewDate);
            ID batchProcessId = Database.executeBatch(updateBatch);
        }

        //delete all previous jobs
        List<CronTrigger> ctList = [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger WHERE NextFireTime = null AND CronJobDetail.Name LIKE 'Set Hebrew Date%'];
        for (CronTrigger ctItem : ctList) {
            System.abortJob(ctItem.Id);
        }

    }

    /**
     * @return Cron expression for current time + 30 min
     */
    private String getCron30minFromNow() {
        try {
            Time currentTime = Time.newInstance(Integer.valueOf(System.now().hour()), Integer.valueOf(System.now().minute()), 0, 0);
            currentTime = currentTime.addMinutes(30);
            String minuteString = String.valueOf(currentTime.minute());
            String hourString = String.valueOf(currentTime.hour());
            String monthString = String.valueOf(System.today().month());
            String dayString = String.valueOf(System.today().day());
            String YearString = String.valueOf(System.today().year());
            String cron = '0 ' + minuteString + ' ' + hourString + ' ' + dayString + ' ' + monthString + ' ? ' + YearString;
            return cron;
        } catch (StringException e) {
            ErrorReport err = new ErrorReport();
            err.reportError('String.substring in HebrewUpdateProcess class has failed,will try again');
            getCron30minFromNow();
        } catch (TypeException e) {
            ErrorReport err = new ErrorReport();
            err.reportError('Integer.valueOf in HebrewUpdateProcess class has failed, Will try again');
            getCron30minFromNow();
        }
        return null;
    }

}

