package kibera;

public class TimeManager {

	   final int HOURTIME= 60; // minute 
	   final int DURATION = 24; // 1 day is 24 hours
	   final int WEEKDURATION = 7; // 1 day = 24 hour, 1 week = 7 day =  7 * 24
	   
	   public int currentHour(int currentStep ){
		   int h = 1;
		   int t = ((int)currentStep) %HOURTIME;
		   int m = ((int)currentStep - (t)) / HOURTIME;
	         
		   if(m <= DURATION){
			   h = m;
		   }
	        
		   else h = (int) m % DURATION;
	        
		   return h;
	   }
	    
	   public int currentDayInWeek(int currentStep){
	        
		   int t = (int)currentStep  % (HOURTIME * DURATION);
		   int da =   ((int)currentStep  - (t))/(HOURTIME * DURATION);
		   int w =0;
		   if(da <= WEEKDURATION){
			   w =da;
		   }
		   else 
	        	w = (int)da % WEEKDURATION;
                   
		   return w;
	   }
	    // continous day count
	   public int dayCount(int currentStep){
	     
		  // int h = this.currentHour(currentStep);
	        
		   int t = (int)currentStep  % (HOURTIME * DURATION);
		   int da =   ((int)currentStep  - (t))/(HOURTIME * DURATION);
	 
		   return da;
	   }
}
