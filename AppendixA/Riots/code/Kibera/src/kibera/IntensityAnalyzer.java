package kibera;

import kibera.Resident.Employment;
import kibera.Resident.Goal;
import kibera.Resident.Religion;

public class IntensityAnalyzer {

	/**This is the intensity analyzer
	 * Intensity Function (T) = f(N, E, X)
	 * where, N = set of needs driving the behavior
	 * 		  E = set of environmental influences, and
	 *     	  X = set of other influences
	 * 
	 * The intensity analyzer determines which motivation is strongest, and thus the action-guiding motive
	 * Residents currently have two motives (N): (1) Need to provide shelter, food, and other basic necessities 
	 * for household and (2) knowledge acquisition
	 * 
	 */

    public static Goal runIntensityAnalyzer(Resident me, Kibera kibera) {
		
        //Set the work start and end times
        double workTime = 0; // working hours
        double searchTime = 0;
        int workStart = 60 * 8 + kibera.random.nextInt(60 * 3); // in minute - working hour start
        int workEnd = 60 * 17 + kibera.random.nextInt(60 * 2); // in minute working hour end

		//Set the school start and end times
        double schoolTime = 0; //hours students can be at school
        int schoolStart = (60 * 7) + kibera.random.nextInt(60 * 2);
        
        double waterTime = 0;
        int waterStart = (60 * 7);
        int waterEnd = 60 * 18;

        //Set the times residents can socialize
        double socializeTime = 0;
        int socializeStart = 60 * 19 + kibera.random.nextInt(60 * 2);
        int socializeEnd = 60 * 21 + kibera.random.nextInt(60 * 2);
        
        double dummyTime = 0;
		
        double wSchool = 0;
        double wWork = 0;
        double wHome = 0;
        double wSocialize = 0;
        double wSearch = 0;
        double wReligion = 0;
        double wWater = 0;
        double wRebel = 0;
        
        //Store the resident's current activity
        Resident.Goal oldGoal = me.currentGoal;
             
        
        //Determine if its working time and if resident should go to work
        if (me.getMinuteInDay() >= workStart && me.getMinuteInDay() <= workEnd) { //if time is working hours
            workTime = 1;
        } 

        //Determine if can start searching for employment (this starts the second day to give time for those employed to find
        //available employment first
        if (me.getCStep() >=1441 && workTime == 1) {
        	searchTime = 1;
        }
        
        //determine if can get water (during the day only)
        if (me.getMinuteInDay() >= waterStart && me.getMinuteInDay() <= waterEnd) {
            waterTime = 1;
        }
        
        if (me.currentEmploymentStatus == Employment.Inactive && (me.isLaidOff() || me.leftSchool()) && searchTime == 1) {
        	//change status to searching for employment
        	
        	me.setCurrentEmploymentStatus(Employment.Searching);
        	wSearch = 1;
        }
        
        if ((me.currentEmploymentStatus == Employment.Formal || me.currentEmploymentStatus == Employment.Informal) && workTime == 1) { 
        	
        	if (me.getMyBusinessEmployer() != null || me.getMyHealthFacilityEmployer() != null || me.getMyReligiousFacilityEmployer() != null || me.getMySchoolEmployer() != null) {
        		wWork = 0.8 + 0.2 * kibera.random.nextDouble();
        		
        		//there is a certain probability that the resident might lose his job, which will leave an opening for others
        		//searching and will require that the resident search for another job
        		if (kibera.random.nextDouble() < kibera.probabilityOfLosingEmployment) {
        			//remove resident from employer
        			if (me.getMyBusinessEmployer() != null) {
        				me.setMyBusinessEmployer(null);
        			}
        			else if (me.getMyHealthFacilityEmployer() != null) {
        				me.setMyHealthFacilityEmployer(null);
        			}
        			else if (me.getMyReligiousFacilityEmployer() != null) {
        				me.setMyReligiousFacilityEmployer(null);
        			}
        			else {
        				me.setMySchoolEmployer(null);
        			}
        			
        			//change employment status to inactive for one day, then resident will start searching for job
        			me.setCurrentEmploymentStatus(Employment.Inactive);
        			me.setResidentIncome(0);        			
        			me.isLaidOff(true);
        			
        			//stay home for now, start searching for a new job after one day
        			wHome = 1;
        		}
        	}
        	else { //if the resident has not been assigned an employer, search for available employer
        		wSearch = 1;
        	}
        }
   
        if (me.currentEmploymentStatus == Employment.Searching && searchTime == 1) {
        	wSearch = 1; 
        }
        
        //Determine if its school time and school day and if resident should go to school
        if (me.getMinuteInDay() == schoolStart && me.currentGoal != Goal.Get_An_Education) {
        	schoolTime = 1;
        }
        
        int schoolDay = (me.getTimeManager().currentDayInWeek(me.getCStep()) < 6) ? 1 : 0; // school only open from monday to friday ( day 1 to 5 of the week)
        double householdNeed = me.getHousehold().getDailyHouseholdDiscrepancy();
        
        if (me.isSchoolEligible() && schoolDay == 1 && schoolTime == 1 && 
                (me.getCurrentEmploymentStatus() != Employment.Formal || me.getCurrentEmploymentStatus() != Employment.Informal)) {
        	if (me.getMySchool() != null) { //if the student has already been assigned to a school
        		
        		wSchool = 0.8 + 0.2 * kibera.random.nextDouble();
        	}
        	else if (!me.searchedForSchool()) {
 
	        	if (ActionSequence.findSchools(me, kibera).isEmpty()) { //if there are no schools with available capacity, then resident does not go to school
	        		
	        		//wSchool = 0;
	        		//me.isSchoolEligible(false);
	        		
	        		//some residents that searched for school and did not find availability will stay home
	    			double rn = kibera.random.nextDouble();
	    			
	    			//System.out.println("household need = " + householdNeed);
	    			//The household income is high enough, resident does not search for employment
	    			if (householdNeed > 0 || me.getAge() < 6) {
	    				wHome = 1;
	    			}
	    			else {
	    				me.setCurrentEmploymentStatus(Employment.Searching);
	    				wSearch = 0.8 + 0.2 * kibera.random.nextDouble(); //since no school is available, resident will search for employment
	    			}
	        	}
	        	else {
	        		wSchool = 0.8 + 0.2 * kibera.random.nextDouble();
	        	}
        	}
        	else { //otherwise the resident did not find a school in the past and may need to search for a job if the household income is not sufficient for daily expenses
                    
                    //check if a spot may have opened up at a school, if so try to go to school if household income allows it
                    if (ActionSequence.findSchools(me, kibera).size() > 0 && householdNeed > 0) {
                        wSchool = 0.8 + 0.2 * kibera.random.nextDouble();
                    }
                    
                    //otherwise search for employment
                    if (householdNeed < 0 && me.getAge() > 5) {
                        me.setCurrentEmploymentStatus(Employment.Searching);
                        wSearch = 0.8 + 0.2 * kibera.random.nextDouble(); //resident will continue searching for employment
                    }
        	}
        }
        
        //Determine if its time to go to church or mosque        
        //christians go to church on sundays
        //80% of christians and 91% of muslims attend church/mosque weekly
        int churchDay = (me.getTimeManager().currentDayInWeek(me.getCStep()) == 7) ? 1 : 0;

        if (kibera.random.nextDouble() < 0.8 && me.religion == Religion.Christian && churchDay == 1 && !me.attendedReligiousFacility()) {
            wReligion = .6 + .4 * kibera.random.nextDouble();
            me.attendedReligiousFacility(true);
        }
       
           
       if (me.religion == Religion.Muslim && kibera.random.nextDouble() > .91 && !me.attendedReligiousFacility()) {
            if (me.getMinuteInDay() > (60 * 5) && me.getMinuteInDay() < (60 * 6) || me.getMinuteInDay() > (60 * 12) && me.getMinuteInDay() < (60 * 14)
                || me.getMinuteInDay() > (60 * 15) && me.getMinuteInDay() < (60 * 17)) {

                wReligion = .6 + .4 * kibera.random.nextDouble();
                me.attendedReligiousFacility(true);
            }
        }
                    
        //Determine if its time to socialize and if resident should socialize
        if (me.getMinuteInDay() >= socializeStart && me.getMinuteInDay() <= socializeEnd) {
        	socializeTime = 1;
        }
        else { socializeTime = 0; }
        
        if (me.getAge() > 5 && socializeTime == 1 && kibera.random.nextDouble() < .5) { wSocialize = 1; }
        else { wSocialize = 0; }
        
        if (wSchool == 0 && wWork == 0 && wSocialize == 0 & wReligion == 0 && wSearch == 0) { wHome = 1; }
        else { wHome = 0; }
        
        //Determine if household needs water. If so, resident will get water if he/she is home
        
        if (me.getHousehold().needWater(kibera) && me.getCurrentGoal() == Goal.Stay_Home && me.getAge() > 15 && waterTime == 1) {
        	//if over 15 and stays home, will get water
        	//if no one, then the student or worker will go after work/school
  
                   
            
            
        	wWater = 1.0;
        }
        else {
        	wWater = 0;
        }
        
       
        //Determine which motive has the highest priority
        double[] activ = new double[7];
        for (int i = 0; i < 7; i++) {
            activ[i] =  kibera.random.nextDouble();// the random value will be less than the above assigned value
        }

        // randomize the index
        for (int i = 0; i < 7; i++) {
            int swapId = kibera.random.nextInt(7);
            if (swapId != i) {
                double temp = activ[i];
                activ[i] = activ[swapId];
                activ[swapId] = temp;
            }
        }
               
        double[] motivePriorityWeight = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
        
        motivePriorityWeight[1] = wSchool * schoolTime;
        motivePriorityWeight[2] = wWork * activ [2]* workTime;
        motivePriorityWeight[3] = wSocialize * activ [3] * socializeTime;
        motivePriorityWeight[4] = wSearch * activ [4] * workTime;
        motivePriorityWeight[5] = wReligion * activ [5] * dummyTime; //change to religion time later
        motivePriorityWeight[6] = wWater * activ [6];
        //motivePriorityWeight[7] = wRebel * activ [7];
             
        int curMotive = 0;
        
        double maximum = motivePriorityWeight[0];   // start with the first value
      
        for (int i=1; i<motivePriorityWeight.length; i++) {
           if (motivePriorityWeight[i] > maximum) {
             maximum = motivePriorityWeight[i];   // new maximum
              curMotive =i;
            }
        }
        
        if (wHome == 1) { curMotive = 0; }
        
        //Assign the goal the resident will execute
        if (curMotive == 1) { me.currentGoal = Goal.Get_An_Education; }
        else if (curMotive == 2) { me.currentGoal = Goal.Go_to_Work; }
        else if (curMotive == 3) { me.currentGoal = Goal.Socialize; }
        else if (curMotive == 4) { 
        	me.currentGoal = Goal.Find_Employment; }
        else if (curMotive == 5) { 
        	me.currentGoal = Goal.Go_to_Church; }
        else if (curMotive == 6) { 
            if (me.getCurrentGoal()==Goal.Find_Employment) {
                System.out.println();
            }
            me.currentGoal = Goal.Get_Water; }
        else { me.currentGoal = Goal.Stay_Home; }
        
        
        if (me.currentGoal != oldGoal) {
            me.changedGoal(true);
        }
        else {
            me.changedGoal(false);
        }
        
        
        return me.currentGoal;
	}
}
