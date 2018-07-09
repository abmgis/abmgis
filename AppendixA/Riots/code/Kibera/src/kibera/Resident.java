package kibera;

import java.util.ArrayList;
import kibera.KiberaBuilder.Node;
import sim.engine.SimState;
import sim.engine.Steppable;
import sim.field.network.Edge;
import sim.util.Double2D;
import sim.util.Valuable;
//import kibera.TimeManager;

/*
 * 
 * 
 * rebellion requires --- salient identity, ability to mobilize, opportunity, capacity, motivation, creation of enemy images
 */

public class Resident implements Steppable, Valuable, java.io.Serializable {
	
	/** The unique identifier of a resident */
	private int residentID;
	public int getResidentID() { return residentID; }
	public void setResidentID(int val) { residentID = val; }
	
	/** The household a resident belongs to */
	private Household household;
	public Household getHousehold() { return household; }
	public void setHousehold(Household val) { household = val; }
	
	/** The residents current age */
	private int age;
	public int getAge() { return age; }
	public void setAge(int val) { age = val; }
	
	/** The residents assigned ethnicity */
	private String ethnicity;
	public String getEthnicity() { return ethnicity; }
	public void setEthnicity(String val) { ethnicity = val; }
	
	/** Identifies whether the resident is head of his/her household */
	private boolean isHeadOfHousehold;
	public boolean isHeadOfHousehold() { return isHeadOfHousehold; }
	public void isHeadOfHousehold(boolean val) { isHeadOfHousehold = val; }
	
	/** The parcel a resident is currently on */
	private Parcel currentPosition;
	public Parcel getPosition() { return currentPosition; }
	public void setPosition(Parcel val) { currentPosition = val; }
	
	/** The parcel a resident is headed to in order to execute his/her goal */
	private Parcel goalLocation;
	public Parcel getGoalLocation() { return goalLocation; }
	public void setGoalLocation(Parcel val) { this.goalLocation = val; }
	
	/** Identifies whether a resident is eligible to be a student -- currently this just means they are the right age */
	private boolean isSchoolEligible;
	public boolean isSchoolEligible() { return isSchoolEligible; }
	public void isSchoolEligible(boolean val) { isSchoolEligible = val; }
	
	/** If resident has found a school, keep going to same school each school day */
	private School mySchool;
	public School getMySchool() { return mySchool; }
	public void setMySchool(School val) { mySchool = val; }
     
	
	/** Identity whether a resident searched for a school (the resident may or may not have found a school to attend) */
	private boolean searchedForSchool;
	public boolean searchedForSchool() { return searchedForSchool; }
	public void searchedForSchool(boolean val) { searchedForSchool = val; }
	
	/** If resident has found informal employment, keep going to business each day */
	private Business myBusinessEmployer;
	public Business getMyBusinessEmployer() { return myBusinessEmployer; }
	public void setMyBusinessEmployer(Business val) { myBusinessEmployer = val; }
	
	/** If resident found formal employment at a school, keep going to that school each day */
	private School mySchoolEmployer;
	public School getMySchoolEmployer() { return mySchoolEmployer; }
	public void setMySchoolEmployer(School val) { mySchoolEmployer = val; }
	
	/** If resident found formal employment at a health facility, keep going to that health facility each day */
	private HealthFacility myHealthFacilityEmployer;
	public HealthFacility getMyHealthFacilityEmployer() { return myHealthFacilityEmployer; }
	public void setMyHealthFacilityEmployer(HealthFacility val) { myHealthFacilityEmployer = val; }
	
	/** If resident found formal employment at a religious facility, keep going to that health facility each day */
	private ReligiousFacility myReligiousFacilityEmployer;
	public ReligiousFacility getMyReligiousFacilityEmployer() { return myReligiousFacilityEmployer; }
	public void setMyReligiousFacilityEmployer(ReligiousFacility val) { myReligiousFacilityEmployer = val; }
	
	/** Identity whether a resident searched for employment (the resident may or may not have found a school to attend) */
	/*private boolean searchedForEmployment;
	public boolean getSearchedForEmployment() { return searchedForEmployment; }
	public void setSearchedForEmployment(boolean val) { searchedForEmployment = val; }*/
	
	/** The resident's income */
	private double residentIncome;
	public double getResidentIncome() { return residentIncome; }
	public void setResidentIncome(double val) { residentIncome = val; }
	
	/** A resident's gender */
	public enum Gender { male, female };
	Gender gender;
	public Gender getGender() { return gender; }
	public void setGender(Gender val) { gender = val; }	
	
	/** The set of resident's potential goals */
	public enum Goal { Find_Employment, Go_to_Work, Get_An_Education, Stay_Home, Socialize, Go_to_Church, Get_Water, Rebel };
	Goal currentGoal = Goal.Stay_Home;
	public Goal getCurrentGoal() { return currentGoal; }
	public void setCurrentGoal(Goal val) { currentGoal = val; }
	
	/** The employment status of a resident */
	public enum Employment { Formal, Informal, Searching, Inactive };
	Employment currentEmploymentStatus;
	public Employment getCurrentEmploymentStatus() { return currentEmploymentStatus; }
	public void setCurrentEmploymentStatus(Employment val) { currentEmploymentStatus = val; }
	
	/** The set of potential identities a resident can have */
	public enum Identity { Student, Employer, Domestic_Activities, Rebel };
	Identity currentIdentity;
	public Identity getCurrentIdentity() { return currentIdentity; }
	public void setCurrentIdentity(Identity val) { currentIdentity = val; }
	
	/** The set of potential religions */
	public enum Religion { Christian, Muslim, Other };
	Religion religion;
	public Religion getReligion() { return religion; }
	public void setReligion(Religion val) { religion = val; }
	
	/** Residents energy reservoir, value from 1 to 100 */
	private double energy;
	public double getEnergy() { return energy; }
	public void setEnergy(double val) { energy = val; }
	
	/** Residents aggression threshold */
	/*private double aggression;
	public double getAggression() { return aggression; }
	public void setAggression(double val) { aggression = val; }*/
	
	/** Identifies if the resident was laid off from his/her job */
	private boolean isLaidOff;
	public boolean isLaidOff() { return isLaidOff; }
	public void isLaidOff(boolean val) { isLaidOff = val; }
        
        /** Identifies if the resident had to leave school to find employment */
        private boolean leftSchool;
        public boolean leftSchool() { return leftSchool; }
        public void leftSchool(boolean val) { leftSchool = val; }
        
        /** Identifies whether resident has attended church/mosque this week */
        private boolean attendedReligiousFacility;
        public boolean attendedReligiousFacility() { return attendedReligiousFacility; }
        public void attendedReligiousFacility(boolean val) { attendedReligiousFacility = val; }
	
	/** This is the rate of the logistic curve. The higher the rate, the slower someone is to aggress. */
	private double aggressionRate;
	public double getAggressionRate() { return aggressionRate; }
	public void setAggressionRate(double val) { aggressionRate = val; }
	
	/** This is the current aggression value of the resident. This is a function of the resident's energy reservoir */
	private double aggressionValue;
	public double getAggressionValue() { return aggressionValue; }
	public void setAggressionValue(double val) { aggressionValue = val; }

	/** the agent's current path to its current goal */
	ArrayList<Parcel> path = null;
	
	/** The current time step in the simulation */
	private int cStep;
	public int getCStep() { return cStep; }
	public void setCStep(int val) { cStep = val; }
	
	/** The current minute in the day (one day is 1440 minutes or time steps) */
	private int minuteInDay;
	public int getMinuteInDay() { return minuteInDay; }
	public void setMinuteInDay(int val) { minuteInDay = val; }
	
	Kibera kibera;
	
	/** The time controller-identifies the hour, day, week */
	//TimeManager timeManager;
	private TimeManager timeManager;
	public TimeManager getTimeManager() { return timeManager; }
	public void setTimeManager(TimeManager val) { timeManager = val; }
	
	/** The number of time steps an agent stays at a given activity/action */
	private int stayingPeriodAtActivity;
	public int getStayingPeriod() { return stayingPeriodAtActivity; }
	public void setStayingPeriod(int val) { stayingPeriodAtActivity = val; }
	
	/** Indicates whether the resident heard the rumor */
	private boolean heardRumor;
	public boolean heardRumor() { return heardRumor; }
	public void heardRumor(boolean val) { heardRumor = val; }
        
        private boolean changedGoal;
        public boolean changedGoal() { return changedGoal; }
        public void changedGoal(boolean val) { changedGoal = val; }
        
        /** Identifies if resident is an initial rebel */
        private boolean isInitialRebel;
        public boolean isInitialRebel() { return isInitialRebel; }
        public void isInitialRebel(boolean val) { isInitialRebel = val; }
	
	
	
	public Resident(Household h)
	{
            kibera = null;
            cStep = 0;
	    timeManager = new TimeManager();
	    
	    this.setCurrentGoal(Goal.Stay_Home);	
	}
	
	public Resident() {
            kibera = null;
            cStep = 0;
	    timeManager = new TimeManager();
	    
	    this.setCurrentGoal(Goal.Stay_Home);
	}
	
	@Override
	public void step(SimState state) {
		
		kibera = (Kibera)state;
		
		cStep = (int) kibera.schedule.getSteps();
        
		if(cStep < 1440) { minuteInDay = cStep; }
		else { minuteInDay = cStep % 1440; }
		
		if (minuteInDay == 0) {		
			if (this.getPosition() == this.getHousehold().getHome().getStructure().getParcel()) {
				ActionSequence.utilizeWater(this, kibera);
			}
		}
		
		move();
		
		if (heardRumor) {
			propogateRumor();
		}
                
                if (this.changedGoal() && this.getCStep() >= 1441) {
                //if (minuteInDay == 0) {
                    SocialIdentityModel.determineIdentityStandard(this, aggressionRate, kibera);
                }
                
                
                //at start of each week, return attended religious faciility to false
                if (this.getTimeManager().currentDayInWeek(cStep) == 1) {
                    this.attendedReligiousFacility(false);
                }
                
	}
	
	public void determineBehavior() {		
            Parcel home = this.getHousehold().getHome().getStructure().getParcel();

            if (this.getPosition().equals(home)) {
                
                if (this.getCurrentEmploymentStatus()==Employment.Searching && this.getCurrentGoal() == Goal.Find_Employment) {
                    System.out.println();
                }
                
                currentGoal = IntensityAnalyzer.runIntensityAnalyzer(this, kibera);                
                //SocialIdentityModel.determineIdentityStandard(this, aggressionRate, kibera);
                this.setGoalLocation(ActionSequence.bestActivityLocation(this, home, currentGoal, kibera));
                this.setStayingPeriod(ActionSequence.stayingPeriodAtActivity(this, currentGoal, kibera));               
     
                return;
            }
		
		//from goal to home
            if (this.getPosition().equals(this.getGoalLocation()) && !this.getGoalLocation().equals(home)) {
                this.setGoalLocation(home);
                this.setCurrentGoal(Goal.Stay_Home);
                //SocialIdentityModel.determineIdentityStandard(this, aggressionRate, kibera);
                this.setStayingPeriod(ActionSequence.stayingPeriodAtActivity(this, currentGoal, kibera));

                return;
	     }
			
            this.setGoalLocation(home);
					
	    return;
	}
	
	public void propogateRumor() {
		//see who is in same position
		//randomly pick one person to tell rumor to
		//compare random number to strength of tie to determine influence - determines if resident heard/adopted rumor
		
		Parcel myParcel = this.getHousehold().getHome().getStructure().getParcel();
	
		//get other residents in same location
		ArrayList <Resident> residents = new ArrayList <Resident>();
		residents = myParcel.getResidents();
		
		//randomly select a resident to hear the rumor
		//rumor has certain probability of spreading to those in social network -- spread likelihood is dependent on the 
		//strength of the tie between the resident and other
		//rumor can continue to spread through network
		
		//the highest strength link is someone who spends 100% of time with someone else
		//total time together / total time passed in simulation is influence
		//influence is from 0 to 1
		
		if (residents.size() > 0) {
			int randomResident = kibera.random.nextInt(residents.size());
				
			Resident r = residents.get(randomResident);
			//Edge e = EdgeFunctions.getEdge(this, r, kibera);
			//if (e != null) {
				//e = EdgeFunctions.getEdge(this, r, kibera);
				//double weight = ((Double)(e.info)).doubleValue();
				//double influenceProbability = weight / cStep;
				//double random = kibera.random.nextDouble();
				
				//if (random < influenceProbability) {
					r.heardRumor(true);
				//}
			//}			
		}
			
	}
	
	public void move() {
            
            
            boolean isStay = ActionSequence.shouldResidentStayAtActivity(this);

            if(goalLocation == null) { return; }
            
            else if ((currentPosition.equals(goalLocation) && isStay)) {
                    return; }

            // at your goal- do activity and recalculate goal  
            else if (currentPosition.equals(goalLocation)) {
                
                ActionSequence.performAction(goalLocation, this, kibera);
                determineBehavior();
               
                
                path = null;
                //kibera.testPathNetwork.clear();    
            }
        
            else {	
                // move to your goal		
                // make sure we have a path to the goal!
                if (path == null || path.size() == 0) {
                    AStar astar = new AStar();
                    int curX = currentPosition.getXLocation();
                    int curY = currentPosition.getYLocation();
                    int goalX = this.getGoalLocation().getXLocation();
                    int goalY = this.getGoalLocation().getYLocation();

                    path = astar.astarPath(kibera,
                    (Node) kibera.closestNodes.get(curX, curY),
                    (Node) kibera.closestNodes.get(goalX, goalY));

                    if (path != null) {
                            path.add(goalLocation);
                    }

                }
            }
    	
    	// determine the best location to immediately move *toward*
        Parcel subgoal = goalLocation;
        
        // It's possible that the agent isn't close to a node that can take it to the center. 
        // In that case, the A* will return null. If this is so the agent should move toward 
        // the goal until such a node is found.
 
        // If we have a path and should continue to move along it
        if (path != null)
        {
            // have we reached the end of an edge? If so, move to the next edge
            if (path.get(0).equals(currentPosition)) {
                path.remove(0);           
            }
            subgoal = path.get(0); 
        }
        
        // Now move!
        Parcel newLocation = ActionSequence.getNextTile(kibera, subgoal, currentPosition);
        
        Parcel oldLocation = currentPosition;
        oldLocation.removeResident(this);
        
        setPosition(newLocation);
        newLocation.addResident(this);
        
        //check that residents are being placed on grid and added to parcels
        kibera.world.setObjectLocation(this, new Double2D(newLocation.getXLocation(), newLocation.getYLocation()));          
	}
	@Override
	public double doubleValue() {
		// TODO Auto-generated method stub
		return 0;
	}
				
}
