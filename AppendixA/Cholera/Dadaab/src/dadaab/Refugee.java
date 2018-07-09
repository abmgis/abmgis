/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package dadaab;

/**
 *
 * @author gmu
 */
import sim.util.*;
import java.util.*;
import sim.engine.*;
import sim.engine.Steppable;
import sim.engine.Stoppable;
import sim.field.continuous.Continuous2D;
import java.lang.Math.*;
import ec.util.MersenneTwisterFast;
import dadaab.CampBuilder.Node;

public class Refugee implements Steppable, Valuable, java.io.Serializable {
    // refugee - age, sex, activity, householdID, Household ResponID

    private int age;
    private int sex;
    private int studyID; // 0 = not enrolled 1 = enrolled, 
    private double waterDemand = 0.0;
    private FieldUnit position; // current position
    private FieldUnit home;// home 
    private FieldUnit goal; // location of the goal
//    private FieldUnit latrine; // location of open latrine
    public int cStep;
    private double jitterX; // Visualization 
    private double jitterY;
    private int healthStatus;//health status -  susceptable - 1, exposed - 2, infected-3, recovered - 4
    private int prevHealthStatus; // monitors health status of agent in the previous step - to capture the change in each day
    //   private int frequencyLaterine; // once in a day for health agent- infected agent may go up to 10 times more
    // Nochola et al - symptomic patient may lose 1 litre/hour floud for 2-3 weeks - but asymptomic - 1l/day
    Family hh;
    private int currentAct;
    private int latUse; // laterine use // 1-2 per day is health up to 10 if infected
    
   // private int[] activityAccomplished = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    // if accomplsh0 if not 1
    
    public static final int ORDERING = 2;
    protected Stoppable stopper;
    // cholera info
    public boolean isrecieveTreatment=false;
    public int stayingTime;
    private double bodyResistance;// after infection how long stay alive- depreciate as cholera progress
    private int infectionPerdiod; // time after first infection to show syptom
    private int recoveryPeriod;
    
    private int symtomaticType; // either sympmatic==1 or asymptomatic =2
//    private double protectiveImmunity; // after recovery agent will not likely infected immediately
    // but immunity will decay over time 
    Dadaab d;
    // 
    public int minuteInDay;
    //
    TimeManager tm;// time contorler-identify the hour, day, week
    ArrayList<FieldUnit> path = null; // the agent's current path to its current goal
    MersenneTwisterFast randomN ;

    public Refugee(int age, int sex, Family hh, FieldUnit home, FieldUnit position, MersenneTwisterFast random, Continuous2D allRefugees) {
        this.setAge(age);
        this.setSex(sex);
        this.setFamily(hh);
        this.setHome(home);
        this.setGoal(home);
        this.jitterX = random.nextDouble();
        this.jitterY = random.nextDouble();
        this.setPosition(position);
        this.setLaterineUse(0);
        this.setPrevHealthStatus(1);
        tm = new TimeManager();
        latUse =1;
        d = null;
        cStep = 0;
        infectionPerdiod = 0;
        recoveryPeriod =0;
        minuteInDay = 0;
        randomN = random;
        
//        stayingTime = 0;

        //   frequencyLaterine = 1;
        
        allRefugees.setObjectLocation(this, new Double2D(hh.getCampLocation().getX() + jitterX, hh.getCampLocation().getY() + jitterY));
    }

    private void setPosition(FieldUnit position) {
        this.position = position;

    }

    public FieldUnit getPosition() {
        return position;
    }

    // goal position - where to go
    public void setGoal(FieldUnit position) {
        this.goal = position;

    }

    public FieldUnit getGoal() {
        return goal;
    }

    // home location   
    public void setHome(FieldUnit home) {
        this.home = home;

    }

    public FieldUnit getHome() {
        return home;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public int getAge() {
        return age;
    }

    public void setSex(int sex) {
        this.sex = sex;
    }

    public int getSex() {
        return sex;
    }

    // education status- student or not
    public void setStudyID(int id) {
        this.studyID = id;
    }

    public int getStudyID() {
        return studyID;
    }

    // faimly memeber
    public void setFamily(Family hh) {
        this.hh = hh;
    }

    public Family getFamily() {
        return hh;
    }

    public void setLaterineUse(int l){
        this.latUse =l;
    }
    
    public int getLaterineUse(){
        return latUse;
    }
    // health status
    public void setHealthStatus(int status) {
        this.healthStatus = status;
    }

    public int getHealthStatus() {
        return healthStatus;
    }
    
     public void setPrevHealthStatus(int status) {
        this.prevHealthStatus = status;
    }

    public int getPrevHealthStatus() {
        return prevHealthStatus;
    }

    public void setSymtomaticType(int im) {
        this.symtomaticType = im;

    }

    public int getSymtomaticType() {
        return symtomaticType;
    }
    // water level
    
    public void setWaterLevel(double w) {
        this.waterDemand = w;
    }

    public double getWaterLevel() {
        return waterDemand;
    }

    //current activity
    public void setCurrentActivity(int a) {
        this.currentAct = a;
    }

    public int getCurrentActivity() {
        return currentAct;
    }

    // resistance to show symptom after infection -
    public void setBodyResistance(double r) {
        this.bodyResistance = r;
    }

    public double getBodyResistance() {
        return bodyResistance;
    }

    // counts time after infection
    public void setInfectionPeriod(int inf) {
        this.infectionPerdiod = inf;
    }

    public int getInfectionPeriod() {
        return infectionPerdiod;
    }
    
    public void setRecoveryPeriod(int inf) {
        this.recoveryPeriod = inf;
    }

    public int getRecoveryPeriod() {
        return recoveryPeriod;
    }
    
    public void setIsrecieveTreatment(boolean tr){
        isrecieveTreatment = tr;
    }
    
    public boolean getIsrecieveTreatment(){
        return isrecieveTreatment;
    }
    // counts time after infection
    public void setStayingTime(int sty) {
        this.stayingTime = sty;
    }

    public int getStayingTime() {
        return stayingTime;
    }
    

//    public void setProtectiveImmunity(double pImm) {
//        this.protectiveImmunity = pImm;
//    }
//
//    public double getProtectiveImmunity() {
//        return protectiveImmunity;
//    }
    public void healthDepretiation() {

        if (this.getHealthStatus() == 3) {
            // childern may die sooner than old people
            this.setBodyResistance(this.getBodyResistance() - (d.params.global.getHealthDepreciation() * (1/ Math.pow(this.age,2))));
        }
    }

    public void infected() {

        // now you are officially infected - will show sympom
         if(this.getHealthStatus() == 2 ){
        
           if (cStep == this.getInfectionPeriod()) {
           
              if (this.getSymtomaticType() == 2) { // asymtomatic paitient
                 this.setHealthStatus(4);// recovered
                 this.setInfectionPeriod(0);
//              
              } else {
                this.setHealthStatus(3); // immediately infected
                this.setInfectionPeriod(0);
             }  
            }
        
        }


    }

    // assign the best goal 
    public void calcGoal() {

     if (this.getPosition().equals(this.getHome()) == true) {
            int cAct = actSelect();   //   select the best goal 
            Activity act = new Activity();
            this.setGoal(act.bestActivityLocation(this, this.getHome(), cAct, d)); // search the best location of your selected activity
            this.setCurrentActivity(cAct);   // track current activity - for the visualization     
            this.setStayingTime(stayingPeriod(this.getCurrentActivity()));
            
            return;

        } // from goal to home             
      else if (this.getPosition().equals(this.getGoal()) == true && this.getGoal().equals(this.getHome()) != true) {
            
            this.setGoal(this.getHome());
            this.setStayingTime(stayingPeriod(0));
            this.setCurrentActivity(0);
            return;
            //
        } // incase 
        else {
            this.setGoal(this.getHome());
            this.setCurrentActivity(0);

            return;
        }
    }
    
    

    // where to move
    public void move(int steps) {

        // if you do not have goal- return
        if (this.getGoal() == null) {
            //this.setGoal(this.getHome());
            return;
        } 
        else if (this.getPosition().equals(this.getGoal()) == true && this.getGoal().equals(this.getHome()) != true && isStay() == true) {
            return;
        }
        // at your goal- do activity and recalulate goal  
        else if (this.getPosition().equals(this.getGoal()) == true) {
            
                doActivity(this.getGoal(), this.getCurrentActivity());
              if(steps % 1440 < 17){
                  if(randomN.nextDouble() > 0.3){
                      calcGoal();
                  }
              }
              else{
                  calcGoal();
              }
                
//            if (steps%15 == 0) {
//                doActivity(this.getGoal(), this.getCurrentActivity());
//                calcGoal();
//            }
        } // else move to your goal
        else {

//                           make sure we have a path to the goal!
            if (path == null || path.size() == 0) {
                path = AStar.astarPath(d,
                        (Node) d.closestNodes.get(this.getPosition().getX(), this.getPosition().getY()),
                        (Node) d.closestNodes.get(this.getGoal().getX(), this.getGoal().yLoc));
                if (path != null) {
                    path.add(this.getGoal());
                }
            }


            // determine the best location to immediately move *toward*
            FieldUnit subgoal;

            // It's possible that the agent isn't close to a node that can take it to the center. 
            // In that case, the A* will return null. If this is so the agent should move toward 
            // the goal until such a node is found.
            if (path == null) {
                subgoal = this.getGoal();
            } // Otherwise we have a path and should continue to move along it
            else {
                // have we reached the end of an edge? If so, move to the next edge
                if (path.get(0).equals(this.getPosition())) {
                    path.remove(0);
                }

                // our current subgoal is the end of the current edge
                if (path.size() > 0) {
                    subgoal = path.get(0);
                } else {
                    subgoal = this.getGoal();
                }
            }




            Activity current = new Activity();
            FieldUnit loc = current.getNextTile(d, subgoal, this.getPosition());

            // if next tile is croweded, return back

//            if (loc.getRefugee().numObjs > d.CROWED_LEVEL_THRESHOLD) {
//                return;
//            }

            FieldUnit oldLoc = this.getPosition();
            oldLoc.removeRefugee(this);

            this.setPosition(loc);
            loc.addRefugee(this);

            // only on facility
//            double jx = 0;
//            double jy = 0;
//            if (loc.getFacility() != null || loc.equals(this.getHome()) != true) {
//                jx = this.jitterX;
//                jy = this.jitterY;
//            } else {
//
//                jx = 0;
//                jy = 0;
//            }

            d.allRefugees.setObjectLocation(this, new Double2D(loc.getX() + this.jitterX, loc.getY() + jitterY));

        }

    }

    //<editor-fold defaultstate="collapsed" desc="Activity Weights">
    private double schoolActivityWeight()
    {
        boolean isSchoolDay = (tm.currentDayInWeek(cStep) < 5); // school only open from monday to friday ( day 1 to 5 of the week)

        // if student second priority is school
        if (this.getStudyID() == 1 && isSchoolDay) {
            return 0.8 + 0.2 * randomN.nextDouble();
        }
        else{
             return 0;
        }
    }

    private double healthActivityWeight() {
        double wHealthC;
        if (this.getHealthStatus() == 3 && this.getIsrecieveTreatment()==false) {
            wHealthC = 0.8 + 0.2 * randomN.nextDouble();
            
        }
        else if (randomN.nextDouble() < 0.05){
            wHealthC = 0.5 + 0.5 * randomN.nextDouble();
        }
        else {
            wHealthC = randomN.nextDouble()*(0.1 +  0.2 * randomN.nextDouble());
        }
        return wHealthC;
    }

    private double foodActivityWeight() {
        
         // food distibution will take third
        // because ration is given on scheduled time, agent give priority for food at tat day
     
        
        double wFoodDist;
        int foodDate = 1 + (tm.dayCount(cStep) % 9);
        int dummyFood = (foodDate == this.getFamily().getRationDate()) ? 1 : 0; // if the day is not a ration day, agent will not go to food center
        if(dummyFood == 1 && this.getAge()  > 15){
               wFoodDist = 0.6  + 0.3 * randomN.nextDouble();
      
        }
        else{
            wFoodDist =0.1 +  0.2 * randomN.nextDouble();
        }
        return wFoodDist * randomN.nextDouble();
    }
    
    private double collectWaterActivityWeight() {
        double wBorehole = 0;
        // not enough water at home
        if (this.getAge() > 10 ){
            if (this.getFamily().getWaterAtHome() < (d.params.global.getMinimumWaterRequirement() * (this.getFamily().getMembers().numObjs ))){
                wBorehole = 0.7 *Math.sin(this.getAge()) + 0.2 * randomN.nextDouble();
            }
            else{
                wBorehole = 0.2 +  0.2 * randomN.nextDouble();
            }
        }
        
        return wBorehole * randomN.nextDouble();
    }

    private double marketActivityWeight() {
        double wMarket;
        //
        if( this.getAge() > 15 && minuteInDay < (16 * 60)) {
                    wMarket = 0.7 *Math.sin(this.getAge()) + 0.2 * randomN.nextDouble();
                 }
       else {
                    wMarket =0;
            }
        return wMarket * randomN.nextDouble();
    }

    private double mosqueActivityWeight() {
        // worship time
        double wMosque = 0.0;
        if (this.getAge() > 10 ) {
            
            if (minuteInDay > (60 * 5) && minuteInDay < (60 * 6) || minuteInDay > (60 * 12) && minuteInDay < (60 * 14)
                    || minuteInDay > (60 * 15) && minuteInDay < (60 * 17)) {
                
              if(this.getHome().getCampID() ==1 && minuteInDay > 60 * 14){
                  wMosque = 0.4 * (this.getAge()/150.0) +  0.2 * randomN.nextDouble() ;
              }  
              else  wMosque = 0.5 * (this.getAge()/150.0) +  0.4 * randomN.nextDouble() ;
            }
        }
        else {
            wMosque =0.0;
        }
        // visiting other camp should be in the monring only - if it afternoon - agent will get late to return??
        return wMosque * randomN.nextDouble();
    }
    // </editor-fold>
    
    // check the crowded level on the road or at your goal location
    // this method is taken from Haiti project   
 /*
     * activity selection currently is made by simple assumption that consider age, sex, need and time in most cases
     * based on these each activity is given some weight and the best of all will e selected
     */
    public int actSelect() {
        int alpha = (60 * 6) + randomN.nextInt(60 * 3); // in minute - working hour start 
        int beta = (60 * 17) + randomN.nextInt(120); // in minute working hour end
        boolean isDayTime = minuteInDay >= alpha && minuteInDay <= beta;
        if (!isDayTime) {
            double wHealth = 0;
            if(this.getHealthStatus() ==3){
                wHealth = healthActivityWeight();
            }
            else{
                wHealth = 0;
            }
            return (wHealth < 0.3) ? Activity.STAY_HOME : Activity.HEALTH_CENTER;
        } else {
            double[] activityPriortyWeight = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
            activityPriortyWeight[1] = schoolActivityWeight();//0.08;
            activityPriortyWeight[2] = collectWaterActivityWeight();//0.15;
            activityPriortyWeight[3] = mosqueActivityWeight();//0.1;
            activityPriortyWeight[4] = marketActivityWeight();//0.07;
            activityPriortyWeight[5] = foodActivityWeight();
            activityPriortyWeight[6] = healthActivityWeight();//0.16;;//0.12;
            activityPriortyWeight[7] = visitRelativeActivityWeight();//0.09;
            activityPriortyWeight[8] = socialVisitActivityWeight();//0.08;
            activityPriortyWeight[9] = visitLatrineActivityWeight();//0.1;

            int curAct = 0;

            // Find the activity with the heighest weight
            double maximum = activityPriortyWeight[0];   // start with the first value
            for (int i = 1; i < 10; i++) {
                if (activityPriortyWeight[i] > maximum) {
                    maximum = activityPriortyWeight[i];   // new maximum
                    curAct = i;
                }
            }
            
            // Maximum weight must be > 0.3, else stay home
            if (activityPriortyWeight[curAct] < 0.3) {
                curAct = Activity.STAY_HOME;
            }

            return curAct;
        }


    }

    private double visitLatrineActivityWeight() {
        double wLatrine;
        //        wLatrine = Math.sin(this.getAge()) * (1.0- (1.0 / (1+Math.pow(this.getLaterineUse(), 3))));
        //       //
        //
        //
        if(this.getLaterineUse() > 0){ 
             wLatrine = 0.3 + 0.5 *randomN.nextDouble();//
        }
        else {
            wLatrine =0.1 +  0.2 * randomN.nextDouble();
        }
        return wLatrine* randomN.nextDouble();
    }

    private double visitRelativeActivityWeight() {
        double wSocialRel;
        //
        if( this.getAge() > 10 && minuteInDay < (16 * 60)) {
                    wSocialRel =  0.3 * Math.sin(this.getAge()) + 0.4 * randomN.nextDouble();
                 }
        else {
                    wSocialRel =0;
                }
        return wSocialRel* randomN.nextDouble();
    }

    private double socialVisitActivityWeight() {
        double wVisitSoc;
        if( this.getAge() > 18 && minuteInDay < (16 * 60)) {
                    wVisitSoc =  0.3 * (this.getAge()/100.0) +  0.4 * randomN.nextDouble() ;
                 }
        else {
                    wVisitSoc =0;
                }
        return wVisitSoc * randomN.nextDouble();
    }

    

    // collect water from borehole or rain
    public void featchWater(FieldUnit f) {
        
        double waterReq = 2 * d.params.global.getMaximumWaterRequirement() + (2 * randomN.nextDouble() * d.params.global.getMaximumWaterRequirement()); // how many litres you can collect?
        double waterFetched = 0.0;
        double concentration = 0.0; // cholera virus
         // check the contamination level of the water you fetch
       
        if(f.getWater() ==0){
            concentration = 0.0;
        }
       
        else{
            //concentration = f.getVibrioCholerae() / (f.getWater());
            concentration = f.getVibrioCholerae();
        }
        // water from borehole
        if(f.getWater()<=0){
             waterFetched = 0;
             f.setWater(0);
             
        }
        
        else if (waterReq >= f.getWater()) {  // if you collect all water, water level will be 0
            waterFetched = f.getWater();
           
            f.setWater(0);

        } else {
            waterFetched = waterReq;
            
            f.setWater(f.getWater() - waterFetched); // water level will lower by the amount you take

        }
     
        double currentWater = this.getFamily().getWaterAtHome() + waterFetched;   // add water to your family bucket


        this.getFamily().setWaterAtHome(currentWater);


        if (currentWater <= 0) {
            this.getFamily().setWaterBacteriaLevel(0);
        } //          
        else {
            this.getFamily().setWaterBacteriaLevel(concentration*waterFetched + this.getFamily().getWaterrBacteriaLevel()); // update the contamination level
        }

    }
    //int per = cStep;
    //int curMin = minuteInDay;
    
    // utilization of water
//    private void transimissionCholera(Dadaab d){
//        if(d.random.nextDouble() < d.params.global.getProbabilityGuestContaminationRate() * this.getFamily().numberOfInfectedFamilyMembers() && this.getHealthStatus()==1){
//            
//            this.setHealthStatus(2);
//            
//            int duration = 60 *(d.params.global.getcholeraInfectionDurationMAX()- d.params.global.getcholeraInfectionDurationMIN()); // hours to minute
//            this.setInfectionPeriod(cStep + (d.params.global.getcholeraInfectionDurationMIN() * 60) + randomN.nextInt(duration));
//        }
//    }

    private void utilizeWater() {
       
        // agent need to take water in daily bases
        // the amount of water not fixed- between min and max
        
        if (this.getWaterLevel() >= d.params.global.getMaximumWaterRequirement()){
            return;
        }
        double dailyUse = 1.2 *(d.params.global.getMaximumWaterRequirement()  - this.getWaterLevel()) * randomN.nextDouble() ; // randomly
        if(dailyUse < 0){
            dailyUse =0;
            return;
        }
        
        
        
        double WaterUsed = 0;
        // only uses from family bucket
//        if(this.getFamily().getWaterAtHome() <=0){
//            WaterUsed =0;
//        }
//        if (dailyUse >= this.getFamily().getWaterAtHome()) { // if the water is not enough, utilize all
//            WaterUsed = this.getFamily().getWaterAtHome(); // tell that there is no water in the house
//        } else {
//            WaterUsed = dailyUse; // if plenty of water in the house, only use what you want
//        }
        
        
        
        
                
        if(this.getFamily().getWaterAtHome() <  dailyUse){
            WaterUsed = this.getFamily().getWaterAtHome();
        }
        else{
            WaterUsed = this.getFamily().getWaterAtHome() - dailyUse;
        }
        double maxWateruse  = this.getWaterLevel() + WaterUsed;
        
        this.setWaterLevel(maxWateruse);
        double wateratHome= this.getFamily().getWaterAtHome() - WaterUsed;
        this.getFamily().setWaterAtHome(wateratHome); // update the water level of the family bucket
        

        // if the water is polluted,  you get cholera at time -
        
        // bacteria level in the water is in litre/ the contamination level is per ml. so need to divid the amount nby 1000
        if ((this.getFamily().getWaterrBacteriaLevel()/1000) > d.params.global.getWaterContaminationThreshold() && this.getHealthStatus()==1) {
            
            
            this.setHealthStatus(2);

           
            // childer will show symptom after infection sooner than old people
            // after infection symptom will show after after 12-17 hours on average 
  
            int duration = 60 *(d.params.global.getcholeraInfectionDurationMAX()- d.params.global.getcholeraInfectionDurationMIN()); // hours to minute
            
            if (this.getAge() < 5) {
                duration = 60 *(d.params.global.getcholeraInfectionDurationMAX()- 3 *d.params.global.getcholeraInfectionDurationMIN()); // hours to minute
            } else if (this.getAge() >= 5 && this.getAge() < 15) {
                duration = 60 *(d.params.global.getcholeraInfectionDurationMAX()- 2 * d.params.global.getcholeraInfectionDurationMIN()); // hours to minute
            } else {
                duration = 60 *(d.params.global.getcholeraInfectionDurationMAX()- d.params.global.getcholeraInfectionDurationMIN()); // hours to minute
            }
            
            this.setInfectionPeriod(cStep + (d.params.global.getcholeraInfectionDurationMIN() * 60) + randomN.nextInt(duration));

            
        }

    }

    /*
     * agent may do some actiity on some location
     * if it is water source, agent will collect water
     * if it is school they attend school
     * if it is health center, they get treatment
     * they also use laterine
     */
    public void doActivity(FieldUnit f, int activ) {

        switch (activ)
        {
            default:
            case Activity.STAY_HOME:
                break;
                
            case Activity.BOREHOLE_OR_RIVER:
                
                featchWater(f);
//                double w = f.getWater();
//                // collect water
//                if (w > d.params.global.getMinimumWaterRequirement()) {
//                    featchWater(f);
//                } else {
//                    Activity act = new Activity();
//                    this.setGoal(act.nearestWaterSource(f, d));
//
//                }
                // incase no water at the location, go to other water location
                break;
                
            case Activity.HEALTH_CENTER:
                recieveTreatment(f, d);
                break;
                
            case Activity.SOCIAL_RELATIVES:
                
                 if(randomN.nextDouble()< d.params.global.getProbabilityGuestContaminationRate()){
                     additionalWater(f);
                 }
                 break;
            case Activity.VISIT_SOCIAL:
                if(randomN.nextDouble() < d.params.global.getProbabilityGuestContaminationRate()){
                     additionalWater(f);
                 }
                break;
                
            case Activity.VISIT_LATRINE:
                useLatrine(f);
                this.setLaterineUse(this.getLaterineUse()-1);

                if(this.getLaterineUse() <=0){
                    this.setLaterineUse(0);
                }
                break;
        }
    }
    
    public int stayingPeriod(int act){
        int period =0;
        int minStay =20; // minumum time to stay in any facility
        int maxStay =180; // three hour
        int curMin = minuteInDay;
        
        switch(act){
            case 0:
                period = maxStay;
                break;
            case 1:
                 // time at school max until 4;00pm
                if(curMin + maxStay + 120 >(17*60)){
                   period = minStay;
                }
                else period = maxStay + 120 ;
                
               
                break;
            case 2: 
                // time borehole max 20 minute
                
                period = minStay+20;
               
                break;
            case 3:
                 // time staying at mosq max 80 minute
                
                if(curMin + maxStay >(16*60)){
                   period = minStay;
                }
                else period = minStay  + randomN.nextInt(maxStay) ;
                
                break;
            case 4:
                // time at the market max 5 hour
                if(curMin + maxStay >(12*60)){
                   period = minStay;
                }
                else period = minStay  + randomN.nextInt(maxStay) ;
                
                break;
            case 5:
                 // time at  food dist  max 5 hour
                if(curMin + maxStay >(15*60)){
                   period = minStay;
                }
                else period = minStay  + randomN.nextInt(maxStay) ;
               
                break;
            case 6:
                // depend on time quee
                period = 0;
//                if(curMin + maxStay >(18*60)){
//                   period = minStay;
//                }
//                else period = minStay  + random.nextInt(maxStay) ;
//                
                break;
            case 7: 
                // time for social max until 5;00pm
                
                if(curMin + maxStay >(12*60)){
                   period = minStay;
                }
                else period = minStay  + randomN.nextInt(maxStay) ;
                
                break;
                
            case 8:
                  // time vist  camp 2 hour 
                
                if(curMin + maxStay >(12*60)){
                   period = minStay;
                }
                else period = minStay  + randomN.nextInt(maxStay-60) ;
                
                break;
                
            case 9:
                  // time laterine max until 4;00pm
                period = minStay;
                break;
//                
//            default:
//                  // minimum time to stay at any location
//                period = minStay;
//                break;
//                      
        }
        
       
        return (period + curMin);
    }

    // how long agent need to stay at location
    public boolean isStay() {

        //TimeManager tm = new TimeManager();

        boolean isStay = false;
        
        if (minuteInDay < this.getStayingTime()){
            isStay = true;
        } 
        else isStay = false;
        
        return isStay;

    }

    public void useLatrine(FieldUnit f) {

        double current = f.getVibrioCholerae();
        double minQuant =  10; // min amount of feces in day ml/day -- 0.4kg
        double sdQuant  = 100; // - range 0.1 to 1.5 l/day 
        double quantFeces = minQuant + (sdQuant * d.random.nextDouble()) * (this.getFamily().getWaterrBacteriaLevel() / d.params.global.getWaterContaminationThreshold());
        // if you use VIP, the possibility of causing infection to the field is low
        if (this.getFamily().getHasLaterine() == true || f.getFieldID()!=0) {
            // count number of inc
//            this.transimissionCholera(d);// may be get contaminated -due to contaminated laterine
            f.setVibrioCholerae(0);
        } else {
            // if you use open laterine, your feces will contibute for the contamination
            if (this.getHealthStatus() == 3) {
                // if you are infected, you pollute significantly
                f.setVibrioCholerae(current + (d.params.global.getvibrioCholeraePerInfectedPerson()* quantFeces));
               
                
            } // if you are health, you still are carrier of the bacteria and will cause some contamiantion
            else if (this.getHealthStatus() == 2){
                f.setVibrioCholerae(current + (d.params.global.getvibrioCholeraePerExposedPerson() * quantFeces));
            }
            
            else {
                f.setVibrioCholerae(current + (d.params.global.getvibrioCholeraePerHealthyPerson() * quantFeces));
            }
        }

    }

    // here the idea is to force agent to utilize water each day, they loose some amout every time
    // as they are more dehydrated, they intend to use more water
    public void dehydrate() {

        double dailyUse = this.getWaterLevel() - 0.01; // every minute they loose 0.01* 24 * 60 = 15 liter/day
           if (dailyUse <= 0) {
               this.setWaterLevel(0);

           } else {
            this.setWaterLevel(dailyUse);
            }

    }

    // incase agent get thrusty on on the road, they may get water from their current goal location
    // currently only from relatives or friends house
    
//  
    public void additionalWater(FieldUnit f) {
              
        //from household infection
      
          double cv = 0.0;
          
          
        // if you visit other camp or friends, drking some water from there
            if(f.getRefugeeHH().isEmpty() == true){
                return;
            }
            else {
                int r = randomN.nextInt(f.getRefugeeHH().numObjs);
                
                if ( ((Family) f.getRefugeeHH().objs[r]).getWaterAtHome() > 2) {
                
                cv = ((Family) f.getRefugeeHH().objs[r]).getWaterrBacteriaLevel()/1000;
                double water = ((Family) f.getRefugeeHH().objs[r]).getWaterAtHome();
//                System.out.println("cv: - "+ cv);
                ((Family) f.getRefugeeHH().objs[r]).setWaterAtHome(water - 2);
                     
                double w = this.getWaterLevel();
                this.setWaterLevel(w + 2);
                if(this.getHealthStatus()==1 && cv > d.params.global.getWaterContaminationThreshold()){
                   this.setHealthStatus(2);
                   int  duration = 60 *(d.params.global.getcholeraInfectionDurationMAX()- d.params.global.getcholeraInfectionDurationMIN()); // hours to minute
                   this.setInfectionPeriod(cStep + (d.params.global.getcholeraInfectionDurationMIN() * 60) + randomN.nextInt(duration));
            
                }
                

            }
               
            }
            

        
    }

    public void recieveTreatment(FieldUnit f, Dadaab d) {
        // based on the capacity of the
        
        if (this.getHealthStatus() == 3 && f.getFacility().isReachedCapacity(f,d) == false) {
           f.setPatientCounter(f.getPatientCounter() + 1);
            if(randomN.nextDouble() < d.params.global.getprobabilityOfEffectiveNessofmedicine()){
            int recovery = cStep + (400 + randomN.nextInt(1440));
            this.setIsrecieveTreatment(true);
            this.setRecoveryPeriod(recovery);
            this.setBodyResistance(1.0);
            }
           
            
        }
    }

//    public void setLatrineField(FieldUnit l) {
//        this.latrine = l;
//    }
//
//    public FieldUnit getLaterineField() {
//        return latrine;
//    }

    public void step(SimState state) {

        d = (Dadaab) state;

        cStep = (int) d.schedule.getSteps();
        
        if(cStep < 1440){
            minuteInDay = cStep;
        }
       else {
            minuteInDay = cStep % 1440;
            
        }
        
        
      
        if (this.getWaterLevel() < (d.params.global.getMinimumWaterRequirement())) {
           utilizeWater();
         
        }
        
        
        this.setPrevHealthStatus(this.getHealthStatus()); // update prveois
        if (this.getHealthStatus()==2) {
            infected();
            
        }
        if(this.getHealthStatus()==3){
             if(this.getRecoveryPeriod() ==cStep && this.getIsrecieveTreatment()==true ){
                this.setHealthStatus(4);
                this.setRecoveryPeriod(0);
                this.setBodyResistance(1.0);
                this.setIsrecieveTreatment(false);
            }
            
           
        }
        
        if (randomN.nextDouble() < d.params.global.getProbRecoveryToSuscebtable() && this.getHealthStatus() == 4) {
            this.setHealthStatus(1);
        }

        healthDepretiation();

        // death
        if (this.getBodyResistance() <= 0) {
            d.killrefugee(this);
        }

        dehydrate();

        move(cStep);
        
          // before the day started - laterine use
        if (cStep % 1440 == 2) {//minuteInDay == 1440
            
            
            if(this.getHealthStatus()==3){
                this.setLaterineUse(1 + randomN.nextInt(6));
            }
            else {
                this.setLaterineUse(randomN.nextInt(3));
                
            }
        }
        


    }

    public void setStoppable(Stoppable stopp) {

        stopper = stopp;
    }

    public void stop() {

        stopper.stop();
    }

    public double doubleValue() {

        return this.getHealthStatus();


    }
}
