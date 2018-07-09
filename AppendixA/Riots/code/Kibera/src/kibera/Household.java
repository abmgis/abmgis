package kibera;

import kibera.Resident.Identity;
import sim.engine.SimState;
import sim.engine.Steppable;
import sim.util.Bag;

/*
 * Households will settle into a final location based on their happiness level. Households will
 * seek neighbors "like" them. This behavior is based on the Schelling segregation model.
 */
public class Household implements Steppable {

	/** The residents living within the same household */
	private Bag householdMembers;
	public Bag getHouseholdMembers() { return householdMembers; }
	public void addHouseholdMembers(Resident val) { householdMembers.add(val); }
	public void removeHouseholdMember(Resident val) { householdMembers.remove(val); }
	public void setHouseholdMembers(Bag val) { householdMembers = val; }

	/** The home a household is located within */
	private Home home;
	public Home getHome() { return home; }
	public void setHome(Home val) { home = val; }
	
	/** Total expenditures for household */
	private double dailyHouseholdExpenditures;
	public double getDailyHouseholdExpenditures() { return dailyHouseholdExpenditures; }
	public void setDailyHouseholdExpenditures(double val) { dailyHouseholdExpenditures = val; }
	
	/** Total monthly income for the household */
	private double householdIncome;
	public double getHouseholdIncome() { return householdIncome; }
	public void setHouseholdIncome(double val) { householdIncome = val; }
	
	/** The discrepancy between a household's income and its expenditures on a daily basis */
	private double dailyHouseholdDiscrepancy;
	public double getDailyHouseholdDiscrepancy() { return dailyHouseholdDiscrepancy; }
	public void setDailyHouseholdDiscrepancy(double val) { dailyHouseholdDiscrepancy = val; }
	
	/** Amount of water remaining in household */
	private double remainingWater;
	public double getRemainingWater() { return remainingWater; }
	public void setRemainingWater(double val) { remainingWater = val; }
	
	/** The daily household income */
	private double dailyHouseholdIncome;
	public double getDailyHouseholdIncome() { return dailyHouseholdIncome; }
	public void setDailyHouseholdIncome(double val) { dailyHouseholdIncome = val; }
	
	/** The daily household cost for charcoal */
	private double charcoalCost;
	public double getDailyCharcoalCost() { return charcoalCost; }	
	public void setDailyCharcoalCost(double val) { charcoalCost = val; }	
	
	/** The daily household cost for food */
	private double foodCost;
	public void setDailyFoodCost(double val) { foodCost = val; }
	public double getDailyFoodCost() { return foodCost; }
        
        private double desiredFoodCost;
        public void setDesiredFoodCost(double val) { desiredFoodCost = val; }
        public double getDesiredFoodCost() { return desiredFoodCost; }
		
	/** The daily household cost for water */
	private double waterCost;
	public void setDailyWaterCost(double val) { waterCost = val; }
	public double getDailyWaterCost() { return waterCost; }
		
	/** The average daily cost of electricity */
	private double electricCost;
	public void setDailyElectricCost(double val) { electricCost = val / 30; }
	public double getDailyElectricCost() { return electricCost; }
	
	/** The daily household cost of sanitation */
	private double sanitationCost;
	public void setDailySanitationCost(double val) { sanitationCost = val; }
	public double getDailySanitationCost() { return sanitationCost; }
        
        private double desiredSanitationCost;
        public void setDesiredSanitationCost(double val) { desiredSanitationCost = val; }
        public double getDesiredSanitationCost() { return desiredSanitationCost; }
	
	/** This identifies whether a household had to adjust expenses due to insufficient income */
	public enum AdjustedHouseholdExpenditures { Decreased, Increased, Same};
        Household.AdjustedHouseholdExpenditures adjustedHouseholdExpenditures;
	public Household.AdjustedHouseholdExpenditures getAdjustedHouseholdExpenditures() { return adjustedHouseholdExpenditures; }
	public void setAdjustedHouseholdExpenditures(Household.AdjustedHouseholdExpenditures val) { adjustedHouseholdExpenditures = val; }
        
        /** Identifies whether had to remove a household member from school to help pay expenses */
        private boolean removedStudentFromSchool;
        public boolean removedStudentFromSchool() { return removedStudentFromSchool; }
        public void removedStudentFromSchool(boolean val) { removedStudentFromSchool = val; }
        
        private int timeLeftSchool;
        public int getTimeLeftSchool() { return timeLeftSchool; }
        public void setTimeLeftSchool(int val) { timeLeftSchool = val; }
	
	/** The current time step in the simulation */
	private int cStep;
	public int getCStep() { return cStep; }
	public void setCStep(int val) { cStep = val; }
	
	/** The current minute in the day (one day is 1440 minutes or time steps) */
	private int minuteInDay;
	public int getMinuteInDay() { return minuteInDay; }
	public void setMinuteInDay(int val) { minuteInDay = val; }
	
	Kibera kibera;
		
	public Household(Home h) {
		this.home = h;
		householdMembers = new Bag();
	}
	
	public Household() {
		householdMembers = new Bag();
	}
	
	@Override
	public void step(SimState state) {
		
		kibera = (Kibera)state;
		
		cStep = (int) kibera.schedule.getSteps();
        
		if(cStep < 1440) { minuteInDay = cStep; }
		else { minuteInDay = cStep % 1440; }
                
                if (cStep == 0) {
                    this.calculateDailyFoodCost(kibera);
                    this.calculateDailyHouseholdIncome();
                    
                    this.setDesiredFoodCost(this.getDailyFoodCost());
                    this.setDesiredSanitationCost(this.getDailySanitationCost());
                }
		
		if (minuteInDay == 0) {
                    this.calculateDailyHouseholdExpenditures(kibera);
                    this.calculateDailyHouseholdIncome();
                    this.calculateDailyHouseholdDiscrepancy(kibera);

                    this.adjustHouseholdExpenditures(kibera);	
		}            
	}
	
	public String getHouseholdEthnicity() {
		//Bag householdEthnicity = new Bag();
		String residentEthnicity = null;
		
		for (int i = 0; i < householdMembers.numObjs; i++) {
			Resident r = (Resident) householdMembers.objs[i];
			residentEthnicity = r.getEthnicity();
			//householdEthnicity.add(residentEthnicity);
		}	
		return residentEthnicity;
	}
	
	public void calculateDailyCharcoalCost(Kibera kibera) {
		double charcoal = kibera.getCharcoalCost();
		
		this.setDailyCharcoalCost(charcoal);
	}
	
	public void calculateDailySanitationCost(Kibera kibera) {
		double sanitation = 0;		
		double residentSanitationCost = 0;
		
		if(!home.hasSanitation()) {
			for (int i = 0; i < householdMembers.numObjs; i++) {
				residentSanitationCost = kibera.random.nextInt((int)kibera.getSanitationCost() * 5);
			}
			sanitation = sanitation + residentSanitationCost;
		}
		
		this.setDailySanitationCost(sanitation);
	}
	
	public void calculateDailyFoodCost(Kibera kibera) {
		double cost = 0;
		double foodCost = 0;
	
		for (int i = 0; i < householdMembers.numObjs; i++) {
			Resident r = (Resident) householdMembers.get(i);
			//if the resident is a student, they get lunch free at school
			if (r.currentIdentity == Identity.Student) {
				cost = kibera.getFoodCost() * 2;
			}
			else {
				cost = kibera.getFoodCost() * 3;
			}
		
			foodCost = foodCost + cost;
		}
		
		this.setDailyFoodCost(foodCost);
	}
	
	public void calculateDailyWaterCost(Kibera kibera) {
		//run this at the beginning of each day (time 0)
		double water = kibera.getMinWaterCost() + kibera.random.nextInt((int)kibera.getMaxWaterCost() - (int)kibera.getMinWaterCost());
		
		this.setDailyWaterCost(water);
	}
	
	public void calculateDailyHouseholdExpenditures(Kibera kibera) {
		//run this at the beginning of each day (time 0)
		//calculate daily expenditures
		double rent = home.getHouseRent() / 30;
		this.calculateDailyFoodCost(kibera);
		this.calculateDailySanitationCost(kibera);
		this.calculateDailyWaterCost(kibera);
		this.calculateDailyCharcoalCost(kibera);
	
		double expenditures = rent + this.getDailyWaterCost() + this.getDailyElectricCost() + this.getDailySanitationCost()
				+ this.getDailyCharcoalCost() + this.getDailyFoodCost();
		
		this.setDailyHouseholdExpenditures(expenditures);
	}
	
	public boolean needWater(Kibera kibera) {

		if (!home.hasWater() && ((kibera.getMinWaterRequirement() * householdMembers.numObjs) > remainingWater)) {
			return true;
		}
		else {
			return false;
		}
	}
	
	public void calculateHouseholdIncome() {
		double income = 0;
		
		for (int i = 0; i < householdMembers.numObjs; i++) {
			Resident r = (Resident) householdMembers.get(i);
			income = income + r.getResidentIncome();
		}
		
		this.setHouseholdIncome(income);
	}
	
	public void calculateDailyHouseholdDiscrepancy(Kibera kibera) {
		
		int discrepancy = (int) (this.getDailyHouseholdIncome() - this.getDailyHouseholdExpenditures());
		
		this.setDailyHouseholdDiscrepancy(discrepancy);
	}
	
	public void calculateDailyHouseholdIncome() {
		this.calculateHouseholdIncome();
		double income = getHouseholdIncome() / 30;
		
		if (income <= 1) { income = 1; }

		this.setDailyHouseholdIncome(income);
	}
	
	//if daily expenditures exceeds income, adjust some of the expenditures
	public void adjustHouseholdExpenditures(Kibera kibera) {
            
            //if there are students in the household, pull them for school and have them search for employment
            //give resident one day to find employment before adjusting other expenses
            if (!this.removedStudentFromSchool() && getDailyHouseholdDiscrepancy() < 0) {
                for (int i = 0; i < householdMembers.numObjs; i++) {
                    Resident r = (Resident) householdMembers.get(i);
                    //if the resident is a student, have them stay home
                    if (r.currentIdentity == Identity.Student) {
                        r.setMySchool(null);
                        r.leftSchool(true);
                        this.setTimeLeftSchool(this.getCStep());
                        this.removedStudentFromSchool(true);
                    }
                }					
            }
            
            //if former student has had enough time to search for employment but household discrepancy still exists
            if (this.removedStudentFromSchool() && (this.getCStep() - this.getTimeLeftSchool() == 1440) && this.getDailyHouseholdDiscrepancy() < 0) {
                if (!home.hasSanitation()) {
                    double sanitationCost = 0;
                    if (getDailyHouseholdDiscrepancy() <= (-1 * getDailySanitationCost())) {
                        sanitationCost = 0;
                    }
                    else {
                        //sanitationCost = getDailySanitationCost() - (int) (((-1*getDailyHouseholdDiscrepancy()) / kibera.getSanitationCost()) * kibera.getSanitationCost());
                        sanitationCost = getDailySanitationCost() - (int) (-1*this.getDailyHouseholdDiscrepancy());
                    }
                    setDailySanitationCost(sanitationCost);
                    this.adjustedHouseholdExpenditures = AdjustedHouseholdExpenditures.Decreased;
                }
		
                //lower food costs if sanitation is not enough
                this.setDailyHouseholdExpenditures(this.getDailyCharcoalCost() + this.getDailyElectricCost() + this.getDailyFoodCost()
                        + this.getDailySanitationCost() + this.getDailyWaterCost() + this.getHome().getHouseRent() / 30);

                //re-calculate household discrepancy
                this.calculateDailyHouseholdDiscrepancy(kibera);

                if (getDailyHouseholdDiscrepancy() < 0) {
                    //first try removing lunch cost
                    double currentFoodCost = getDailyFoodCost();

                    //amount saved if forego one meal/day
                    double foodSavings = currentFoodCost - householdMembers.numObjs * kibera.getFoodCost() * 2;

                    if ((-1*getDailyHouseholdDiscrepancy()) <= foodSavings ) {
                            setDailyFoodCost(householdMembers.numObjs * kibera.getFoodCost() * 2);
                    }
                    else { //family will have to skip 2 meals per day
                            setDailyFoodCost(householdMembers.numObjs * kibera.getFoodCost());
                    }

                    this.setDailyHouseholdExpenditures(this.getDailyCharcoalCost() + this.getDailyElectricCost() + this.getDailyFoodCost()
                            + this.getDailySanitationCost() + this.getDailyWaterCost() + this.getHome().getHouseRent() / 30);

                    //this.calculateDailyHouseholdExpenditures(kibera);
                    //re-calculate household discrepancy after expenditures have been adjusted
                    this.calculateDailyHouseholdDiscrepancy(kibera);
                    this.adjustedHouseholdExpenditures = AdjustedHouseholdExpenditures.Decreased;

                }
                
                
                    
            }
            
            //if have more than enough income
            if (this.getDailyHouseholdDiscrepancy() > 0) {
                //if removed sanitation costs previously, add those back
                if (!home.hasSanitation() && (this.getDailySanitationCost() < this.getDesiredSanitationCost())) {
                    double sanitationCost = 0;
                    if (getDailyHouseholdDiscrepancy() > this.getDesiredSanitationCost()) {
                        sanitationCost = this.getDesiredFoodCost();
                    }
                    else {
                        //sanitationCost = getDailySanitationCost() - (int) (((-1*getDailyHouseholdDiscrepancy()) / kibera.getSanitationCost()) * kibera.getSanitationCost());
                        sanitationCost = this.getDesiredSanitationCost() - (this.getDailyHouseholdDiscrepancy());
                    }
                    setDailySanitationCost(sanitationCost);
                    this.adjustedHouseholdExpenditures = AdjustedHouseholdExpenditures.Increased;
                }
                
                //increase food costs if still enough income
                this.setDailyHouseholdExpenditures(this.getDailyCharcoalCost() + this.getDailyElectricCost() + this.getDailyFoodCost()
                        + this.getDailySanitationCost() + this.getDailyWaterCost() + this.getHome().getHouseRent() / 30);

                //re-calculate household discrepancy
                this.calculateDailyHouseholdDiscrepancy(kibera);

                if (getDailyHouseholdDiscrepancy() > 0) {
                    if (this.getDailyFoodCost() < this.getDesiredFoodCost()) {
                        double food = 0;
                        if (this.getDailyHouseholdDiscrepancy() > this.getDesiredFoodCost()) {
                            food = this.getDesiredFoodCost();
                        }
                        else {
                            food = this.getDesiredFoodCost() - (int) (this.getDailyHouseholdDiscrepancy());
                        }
                        this.setDailyFoodCost(food);
                        this.adjustedHouseholdExpenditures = AdjustedHouseholdExpenditures.Increased;
                    }

                    this.setDailyHouseholdExpenditures(this.getDailyCharcoalCost() + this.getDailyElectricCost() + this.getDailyFoodCost()
                            + this.getDailySanitationCost() + this.getDailyWaterCost() + this.getHome().getHouseRent() / 30);

                    //this.calculateDailyHouseholdExpenditures(kibera);
                    //re-calculate household discrepancy after expenditures have been adjusted
                    this.calculateDailyHouseholdDiscrepancy(kibera);

                }	
                
            }
  
	}
	
	public int householdHappiness(Kibera kibera) {
		//is household able to pay for all expenditures?
		//if head of household, want employment if not employed
		//if able to pay all expenditures without cutting any costs, then happy
		//if able to pay expendtiures after cutting some costs, then semi-happy
		//if not able to pay expenditures even after cutting costs where possible, then unhappy
		
		int happinessLevel = 0; //0 = not happy, 1 = somewhat happy, 2 = happy
		
		//If household is able to pay for all expenditures without cutting any costs, then the household is happy
		if (getDailyHouseholdDiscrepancy() >= 0 && (this.adjustedHouseholdExpenditures == AdjustedHouseholdExpenditures.Same
                        || this.adjustedHouseholdExpenditures == AdjustedHouseholdExpenditures.Increased)) {
                    happinessLevel = 2;
		}
		//Otherwise, household will need to cut costs
		else if (getDailyHouseholdDiscrepancy() >= 0 && this.adjustedHouseholdExpenditures == AdjustedHouseholdExpenditures.Decreased) {
                    happinessLevel = 1;
                }
		//If household is unable to pay for necessary expenditures after cutting costs, then household is unhappy
		else {
                    happinessLevel = 0;
		}
	
		return happinessLevel;
	}
	
	
	public String toString() {
		return home.getStructure().getParcel().toString();
	}	
}
