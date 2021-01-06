/**
 * Jira: Yosi:FinalProject
 * API rest service to find today's sunset Time.
 *
 * Author: natali.cutic 
 *
 * @since: 12/15/2020
 * @class: GetSunsetTimeService
 *
 */

public with sharing class GetSunsetTimeService {

    public static Time sunsetTime { get; set; }
    public static String sunsetCrone { get; set; }
    private SunsetResultJason result;
    private My_metadata__mdt mdt;
    private Boolean isTomorrow;
    private HttpResponse res;
    private Boolean isSuccessful = true;

    public GetSunsetTimeService(Boolean isTomorrow){
        this.isTomorrow = isTomorrow;
        getSunsetTime();
        fromTimeToCron();
    }

    /**
     * Send GET request - try 3 times if fails reports an error.
     */
    private void getSunsetTime(){
        //get information about current location
        this.mdt = [SELECT latitude__c,longitude__c,dif_from_UTC__c FROM My_metadata__mdt WHERE Label='currentLocation' LIMIT 1];

        //set url
        String url = 'https://api.sunrise-sunset.org/json?lat='+this.mdt.latitude__c+'&lng='+this.mdt.longitude__c+'&formatted=0';
        if(this.isTomorrow){
            url += '&date='+String.valueOf(System.today().addDays(1));
        }

        //send request
        for(Integer i=0; i<3; i++){
            send(url);
            if(this.res.getStatusCode() == 200){
                break;
            }
        }
        if(this.res.getStatusCode() != 200){
            ErrorReport err = new ErrorReport();
            err.reportError('Can not access Sunset Api pls check Api, Will try to run again in 30min');
            this.isSuccessful = false;
        }
    }

    /**
    * send method.
    * @param url where to send.
    */
    private void send(String url){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        Http http = new Http();
        HttpResponse response = new HttpResponse();
        this.res = http.send(req);
        System.debug('>>>response body' + response.getBody());

    }

    /**
     * Takes Jason Result, deserializing, converts received time to cron expression.
     * If fails to convert sets null values.
     */
    private void fromTimeToCron(){
        if(this.isSuccessful) {
            try {
                //deserializing
                this.result = (SunsetResultJason) System.JSON.deserialize(this.res.getBody(), SunsetResultJason.class);

                //get String hour minute month day and year from response
                String hourString = this.result.results.sunset.substring(11, 13);
                String minuteString = this.result.results.sunset.substring(14, 16);
                String monthString = this.result.results.sunset.substring(5, 7);
                String dayString = this.result.results.sunset.substring(8, 10);
                String yearString = this.result.results.sunset.substring(0, 4);

                //Convert From UTC to current time zone
                GetSunsetTimeService.sunsetTime = Time.newInstance(Integer.valueOf(hourString), Integer.valueOf(minuteString), 0, 0);
                GetSunsetTimeService.sunsetTime = GetSunsetTimeService.sunsetTime.addHours((Integer) this.mdt.dif_from_UTC__c);
                hourString = String.valueOf(GetSunsetTimeService.sunsetTime.hour());

                //Set Cron expression
                GetSunsetTimeService.sunsetCrone = '0 ' + minuteString + ' ' + hourString + ' ' + dayString + ' ' + monthString + ' ? ' + yearString;
                System.debug('>>>Cron String ' + GetSunsetTimeService.sunsetCrone);

            }catch(JSONException e){
                ErrorReport err = new ErrorReport();
                err.reportError('JSON.deserialize in GetSunsetTimeService class has failed, Will try to run again in 30min');
                GetSunsetTimeService.sunsetTime = null;
                GetSunsetTimeService.sunsetCrone = null;
            }catch(StringException e){
                ErrorReport err = new ErrorReport();
                err.reportError('String.substring in GetSunsetTimeService class has failed, Will try to run again in 30min');
                GetSunsetTimeService.sunsetTime = null;
                GetSunsetTimeService.sunsetCrone = null;
            }catch(TypeException e){
                ErrorReport err = new ErrorReport();
                err.reportError('Integer.valueOf in GetSunsetTimeService class has failed, Will try to run again in 30min');
                GetSunsetTimeService.sunsetTime = null;
                GetSunsetTimeService.sunsetCrone = null;
            }
        }else {
            GetSunsetTimeService.sunsetTime = null;
            GetSunsetTimeService.sunsetCrone = null;
        }
    }

    /**
    * deserialize class from jason response
    */
    private class SunsetResultJason {
        private cls_results results;
        private String status;    //OK
    }
    class cls_results {
        private String sunrise;	//7:27:02 AM
        private String sunset;	//5:05:55 PM
        private String solar_noon;	//12:16:28 PM
        private String day_length;	//9:38:53
        private String civil_twilight_begin;	//6:58:14 AM
        private String civil_twilight_end;	//5:34:43 PM
        private String nautical_twilight_begin;	//6:25:47 AM
        private String nautical_twilight_end;	//6:07:10 PM
        private String astronomical_twilight_begin;	//5:54:14 AM
        private String astronomical_twilight_end;	//6:38:43 PM
    }

    public class SunsetServiceException extends Exception {}

}
