/**
 * Jira: Yosi:FinalProject
 * API rest service to find today's hebrew date.
 *
 * Author: natali.cutic 
 *
 * @since: 12/15/2020
 * @class: GetHebrewDateService
 *
 */

public with sharing class GetHebrewDateService {

    private HttpResponse res;
    private JasonHebrewDate todayDate = new JasonHebrewDate();
    private Boolean isAfterSunset;
    private Boolean isSuccessful = true;

    public GetHebrewDateService(Boolean isAfterSunset) {
        this.isAfterSunset = isAfterSunset;
        setDate();
        sendRequest();
    }

    /**
     * Convert today's date into Strings
     */
    private void setDate(){
        this.todayDate.gy = System.Today().year();
        this.todayDate.gm = System.today().month();
        this.todayDate.gd = System.today().day();
        system.debug(this.todayDate);
    }

    /**
     * Send GET request - try 3 times if fails reports an error
     */
    private void sendRequest() {

        //set url
        String url = 'https://www.hebcal.com/converter?cfg=json&gy='+this.todayDate.gy+'&gm='+this.todayDate.gm+'&gd='+this.todayDate.gd+'&g2h=1';
        if(this.isAfterSunset){
            url += '&gs=on';
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
            err.reportError('Can not access Hebrew Date Api pls check Api, Will try to run again in 30min');
            this.isSuccessful = false;
        }
    }

    /**
     * send method
     * @param url where to send
     */
    private void send(String url){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        Http http = new Http();
        this.res = http.send(req);
        System.debug(res.getBody());
    }

    /**
     * @return String today's hebrew date
     */
    public String getHebrewDate(){
        if(this.isSuccessful) {
            try {
                JasonHebrewDate dateObject = (JasonHebrewDate) System.JSON.deserialize(this.res.getBody(), JasonHebrewDate.class);
                return dateObject.hebrew;
            }catch (JSONException e){
                ErrorReport err = new ErrorReport();
                err.reportError('JSON.deserialize in GetHebrewDateService has failed, Will try to run again in 30min');
                return null;
            }
        }else{
            return null;
        }
    }

    /**
     * deserialize class from jason response
     */
    public class JasonHebrewDate{
        public Integer gy;	//2011
        public Integer gm;	//6
        public Integer gd;	//2
        public boolean afterSunset;
        public Integer hy;	//5771
        public String hm;	//Iyyar
        public Integer hd;	//29
        public String hebrew;	//כ״ט בְּאִיָיר תשע״א
    }

}