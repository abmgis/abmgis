package kibera;

import java.util.TreeMap;

import org.jfree.data.category.DefaultCategoryDataset;

import kibera.Resident.Employment;
import kibera.Resident.Goal;
import kibera.Resident.Identity;

import sim.engine.SimState;
import sim.engine.Steppable;
import sim.field.continuous.Continuous2D;
import sim.field.geo.GeomVectorField;
import sim.field.grid.IntGrid2D;
import sim.field.grid.ObjectGrid2D;
import sim.field.grid.SparseGrid2D;
import sim.field.network.Network;
import sim.util.Bag;

public class Kibera extends SimState {

	private static final long serialVersionUID = 1L;
	public ObjectGrid2D landGrid; // The model environment - holds parcels
	public Continuous2D world;
	public SparseGrid2D householdGrid;
	public IntGrid2D roadGrid; // road in grid- for navigation
	public SparseGrid2D facilityGrid;// facilities: schools, health center, borehol etc
	public SparseGrid2D healthFacilityGrid;
	public SparseGrid2D religiousFacilityGrid;
	public SparseGrid2D waterGrid;
	public SparseGrid2D sanitationGrid;
	public SparseGrid2D businessGrid;
	public SparseGrid2D houseGrid;
	
	private int width;
	private int height;
	public int getWidth() { return width; }
	public void setWidth(int val) { width = val; }
	public int getHeight() { return height; }
	public void setHeight(int val) { height = val; }
	
	public GeomVectorField roadLinks;
	
	public SparseGrid2D nodes;
	public ObjectGrid2D closestNodes; // the road nodes closest to each of the locations
	Network roadNetwork = new Network();	
	Network socialNetwork = new Network(false);
	
	public Continuous2D testPathField = new Continuous2D(1.0, 343, 204);
	public Network testPathNetwork = new Network();
	
	public Bag parcels;
	public Bag residents;
	public Bag households;
	public Bag structures;
	public Bag homes;
	
	public Bag allStructureLocations;
	public Bag allBusinessLocations;
	public Bag allHomeLocations;
	public TreeMap <Integer, Neighborhood> allNeighborhoods = new TreeMap <Integer, Neighborhood>();
	
	public Bag allSchoolLocations;
	public Bag allHealthFacilityLocations;
	public Bag allReligiousFacilityLocations;
	public Bag allWaterPoints;
	public Bag allSanitationLocations;
	
	public Bag availableParcels;
	
	//store households together that share same ethnicity
	public Bag kikuyu;
	public Bag luhya;
	public Bag luo;
	public Bag kalinjin;
	public Bag kamba;
	public Bag kisii;
	public Bag meru;
	public Bag mijikenda;
	public Bag maasai;
	public Bag turkana;
	public Bag embu;
	public Bag other;
        
        //keep dynamic list of homes that are still available
        public Bag allHomesAvailable;
	
	public double preferenceforLivingNearLikeNeighbors = .5;
	public double probabilityOfLosingEmployment = .01;
	
	public int neighborhood = 1; //a neighborhood of 1 is equivalent to the Moore neighborhood
	public int schoolVision = 35;
	public int employmentVision = 70;
	public double threshold = 3;
	
	/** Max number of structures on a parcel */
	private int maxStructuresPerParcel = 1;    
	public int getMaxStructuresPerParcel() { return maxStructuresPerParcel; }
	public void setMaxStructuresPerParcel(int val) { maxStructuresPerParcel = val;}
	
	/** Total number of residents initialized in the model */ 
	public int numResidents = 235000;
	public int getNumResidents() { return numResidents; }
	public void setNumResidents(int val) { numResidents = val; }
	
	private double avgHouseholdSize = 3.25;
	public double getAvgHouseholdSize() { return avgHouseholdSize; }
	public void setAvgHouseholdSize(double val) { avgHouseholdSize = val; }
	
	/** The probability that a household will have certain amenities, including water, electricity, and sanitation */
	private double probabilityWater = 0.014;
	public double getProbabilityWater() { return probabilityWater; }
	public void setProbabilityWater(double val) { probabilityWater = val; }
	
	private double probabilityElectricity = 0.6329;
	public double getProbabilityElectricity() { return probabilityElectricity; }
	public void setProbabilityElectricity(double val) { probabilityElectricity = val; }
	
	private double probabilitySanitation = 0.0274;
	public double getProbabilitySanitation() { return probabilitySanitation; }
	public void setProbabilitySanitation(double val) { probabilitySanitation = val; }
	
	private double maleDistribution = 0.613;
	public double getMaleDistribution() { return maleDistribution; }
	public void setMaleDistribution(double val) { maleDistribution = val; }
		
	private double[] ethnicDistribution = {.21, .14, .12, .12, .12, .06, .05, .05, .02, .01, .01, .09};
	public double[] getEthnicDistribution() { return ethnicDistribution; }	
	public double getEthnicDistribution(int i) { return ethnicDistribution[i]; }
	public void setEthnicDistribution(double[] val) { ethnicDistribution = val;	}
	
	private String[] ethnicities = {"kikuyu", "luhya", "luo", "kalinjin", "kamba", "kisii", "meru", "mijikenda", "maasai", "turkana", "embu", "other"};
	public String[] getEthnicities() { return ethnicities; }
	public void setEthnicities(String[] val) { this.ethnicities = val; }
	public String getEthnicities(int i) { return ethnicities[i]; }
	
	private double[] rentDistribution = {0.0089, .0644, .1733, .1867, .2022, .1033, .0867, .0344, .0233, .0178, .0133, .0089, .0067, .0022, .0122, .0033, .0011, .0033, .0011, .0022, .0011, .0011, .0011, .0011, .0011, .0392};
	public double[] getRentDistribution() { return rentDistribution; }
	public double getRentDistribution(int i) { return rentDistribution[i]; }
	public void setRentDistribution(double[] val) { rentDistribution = val; }
	
	private double[] rent = {200, 400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000, 2200, 2400, 2600, 2800, 3000, 3200, 3400, 3600, 3800, 4000, 4200, 4400, 4600, 4800, 5000, 5200};
	public double[] getRent() { return rent; }
	public void setRent(double[] val) { rent = val; }
	public double getRent(int i) { return rent[i]; }
	
        /** The threshold a resident's aggression must be under in order for the resident to aggress or rebel */
	public double aggressionThreshold = 0.6;
	public double getAggressionThrehold() { return aggressionThreshold; }
	public void setAggressionThreshold(double val) { aggressionThreshold = val; }
        
        /** Aggression rate impacts the shape of the logistic curve. This can be either specified and kept the same for all agents,
         *  or each agent can be assigned its own rate */
        public double aggressionRate = 0.6;
        public double getAggressionRate() { return aggressionRate; }
        public void setAggressionRate(double val) { aggressionRate = val; }
        
        /** Identifies whether to assign all all agents the same aggression rate */
        public boolean uniformAggressionRate = true;
        public void uniformAggressionRate(boolean val) { uniformAggressionRate = val; }
        public boolean uniformAggressionRate() { return uniformAggressionRate; }
	
	public int MAX_WATER_REQ = 20; // 15 liter per day per person -  for all uses
	public int MIN_WATER_REQ  = 4;
	
	public int getMaxWaterRequirement() { return MAX_WATER_REQ; }
	public void setMaxWaterRequirement(int val) { MAX_WATER_REQ = val; }
	
	public int getMinWaterRequirement() { return MIN_WATER_REQ; }
	public void setMinWaterRequirement(int val) { MIN_WATER_REQ = val; }
	
	/** The minimum cost of a 20 liter barrel of water (one person consumes approximately 20 litres of water per day) */
	public double minWaterCost = 5;
	public double getMinWaterCost() { return minWaterCost; }
	public void setMinWaterCost(double val) { minWaterCost = val; }
	
	/** The maximum cost of 20 liter barrel of water */
	public double maxWaterCost = 10;
	public double getMaxWaterCost() { return maxWaterCost; }
	public void setMaxWaterCost(double val) { maxWaterCost = val; }
	
	/** Minimum electric cost per home for one month (if house has electricity) */
	public double minElectricCost = 200;
	public double getMinElectricCost() { return minElectricCost; }
	public void setMinElectricCost(double val) { minElectricCost = val; }
	
	/** Maximum electric cost per home for one month (if house has electricity) */
	public double maxElectricCost = 400;
	public double getMaxElectricCost() { return maxElectricCost; }
	public void setMaxElectricCost(double val) { maxElectricCost = val; }
	
	/** Expected cost of water if the house has running water */
	public double waterCost;
	public double getWaterCost() { return waterCost; }
	public void setWaterCost(double val) { waterCost = val; }
	
	/** Cost of using public sanitation (one visit) */
	public double sanitationCost = 5;
	public double getSanitationCost() { return sanitationCost; }
	public void setSanitationCost(double val) { sanitationCost = val; }
	
	/** Cost of charcoal (one days worth) */
	public double charcoalCost = 10;
	public double getCharcoalCost() { return charcoalCost; }
	public void setCharcoalCost(double val) { charcoalCost = val; }
	
	/** Cost of one meal per person */
	public double foodCost = 30;
	public double getFoodCost() { return foodCost; }
	public void setFoodCost(double val) { foodCost = val; }
        
        /** Opinion threshold -- max difference between my final opinion and other, that would make me be influenced by other */
        public double opinionThreshold = 0.2;
	
	/** Age distribution */
	public double ageAdult = .25; //this is the percentage of total residents (excluding head of households) that are adults
	public double ageChildrenUnder6 = .32; //the percentage of total residents (excluding head of households) under 6
	public double percentOfResidentsUnder6 = .21; //the percentage of total residents that are under 6 and thus cannot be employed
	public double percentOfResidentsUnder19 = .45;	//the percentage of total residents 18 and younger (source - Kianda survey)
	
	/** Informality index - the proportion of jobs in the informal sector (versus formal sector)
	** in africa, informal sector employs 60% of urban labor force, pp. 103 (UN, Challenge of Slums) */
	public double informalityIndex = 0.6;
	public double getInformalityIndex() { return informalityIndex; }
	public void setInformatilityIndex(double val) { informalityIndex = val; }
	
	/** This is the capacity of students for each school */
	public int schoolCapacity = (int)(.0007 * numResidents);
	
	/** This is the capacity of employees at a business. Formal businesses in Kibera include hospitals, schools,
	 ** and religious facilities. The average number of employees at schools in Kibera are 13.
	 ** Informal businesses include selling goods on the street, small restaurants, and markets.
	 ** Accoriding to UN (Challenge of slums) a maximum of 5 to 10 employees is used to define enterprises as informal
	 */
	public int formalBusinessCapacity = (int)(.00006 * numResidents);
	public int informalBusinessCapacity = (int)(.00002 * numResidents);
	
	public KiberaObserver kObserver;
	
	private int[] totalAction;
	public void setTotalAction(int[] val) { totalAction = val; }
	public int[] getTotalAction() { return totalAction; }
	
	private int[] totalIdentity;
	public void setTotalIdentity(int[] val) { totalIdentity = val; }
	public int[] getTotalIdentity() { return totalIdentity; }
	
	private int[] totalWorking;
	public void setTotalWorking(int[] val) { totalWorking = val; }
	public int[] getTotalWorking() { return totalWorking; }
	
	public int[] allResidents;
	public void setAllResidents(int[] val) { allResidents = val; }
	public int[] getAllResidents() { return allResidents; }
	
	
	/** True if an exogenous rumor is heard by one or more residents */
	/*public boolean isExogenousRumor;
	public boolean isExogenousRumor() { return isExogenousRumor; }
	public void isExogenousRumor(boolean val) { isExogenousRumor = val; }*/
	
	/** The number of random residents that hear the rumor initially */
	public int numResidentsHearRumor = (int) (numResidents * .1);
	public int getNumResidentsHearRumor() { return numResidentsHearRumor; }
	public void setNumResidentsHearRumor(int val) { numResidentsHearRumor = val; }
        
        /** The initial proportion of residents that heard the rumor that rebel */
	public double proportionInitialResidentsRebel = .5;
        
	
	/** Percent of income spent on rent */
	public double percentIncomeforRent = .8;
	public double getPercentIncomeforRent() { return percentIncomeforRent; }
	public void setPercentInformeforRent(double val) { percentIncomeforRent = val; }
	
	DefaultCategoryDataset dataset = new DefaultCategoryDataset(); //
	
	public Kibera (long seed)
	{	
		super(seed);
	}
	
	@Override
	public void start() 
	{
		super.start();
		
		parcels = new Bag(); //the set of all parcels
		residents = new Bag(); //the set of all residents
		households = new Bag(); //the set of all households
		structures = new Bag(); //the set of all structures
		homes = new Bag(); //the set of all homes
		
		availableParcels = new Bag();
		
		allStructureLocations = new Bag(); //the parcel locations of all structures
		//allSchools = new ArrayList<School>();
		allHealthFacilityLocations = new Bag(); //the parcel locations of all health facilities
		allReligiousFacilityLocations = new Bag(); //the parcel locations of all religious facilities (churches/mosques)
		allBusinessLocations = new Bag(); //the parcel locations of all businesses
		allHomeLocations = new Bag(); //the parcel locations of all homes
		allWaterPoints = new Bag(); //the parcel location of all water points
		allSanitationLocations = new Bag(); //the parcel location of all public sanitation locations
		
		allSchoolLocations = new Bag();
		
		kikuyu = new Bag();
		luhya = new Bag();
		luo = new Bag();
		kalinjin = new Bag();
		kamba = new Bag();
		kisii = new Bag();
		meru = new Bag();
		mijikenda = new Bag();
		maasai = new Bag();
		turkana = new Bag();
		embu = new Bag();
		other = new Bag();
                
                allHomesAvailable = new Bag();
		
		KiberaBuilder.createWorld("data/kibera.txt", "data/roads_cost_distance.txt", "data/schools.txt", "data/health.txt", "data/religion.txt", "data/watsan.txt", this);	
		
		kObserver = new KiberaObserver(this);
                schedule.scheduleRepeating(kObserver, KiberaObserver.ORDERING, 1.0);
        
                Steppable chartUpdater = new Steppable() {
        	public void step(SimState state) {
        	
        		int[] sumActions = {0, 0, 0, 0, 0, 0, 0, 0};
        		int[] sumIdentities = {0, 0, 0, 0};
        		int[] sumWorking = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
        		//int[] sumResidents = {0, 0, 0, 0, 0, 0, 0};
        		
        		for (int i = 0; i < residents.numObjs; i++) {
        			Resident r = (Resident)residents.objs[i];
        			
        			if (r.getCurrentGoal() == Goal.Stay_Home) {
        				sumActions[0] += 1;
        			}      			
        			if (r.getCurrentGoal() == Goal.Go_to_Work) {
        				sumActions[1] += 1;
        			}
        			if (r.getCurrentGoal() == Goal.Find_Employment) {
        				sumActions[2] += 1;
        			}
        			if (r.getCurrentGoal() == Goal.Get_An_Education) {
        				sumActions[3] += 1;
        			}
        			if (r.getCurrentGoal() == Goal.Socialize) {
        				sumActions[4] += 1;
        			}
        			if (r.getCurrentGoal() == Goal.Go_to_Church) {
        				sumActions[5] += 1;
        			}       
        			if (r.getCurrentGoal() == Goal.Get_Water) {
        				sumActions[6] += 1;
        			}
        			if (r.getCurrentGoal() == Goal.Rebel) {
        				sumActions[7] += 1;
        			}
        			
        			if (r.getCurrentIdentity() == Identity.Domestic_Activities) {
        				sumIdentities[0] += 1;
        			}
        			if (r.getCurrentIdentity() == Identity.Employer) {
        				sumIdentities[1] += 1;
        			}
        			if (r.getCurrentIdentity() == Identity.Student) {
        				sumIdentities[2] += 1;
        			}
        			if (r.getCurrentIdentity() == Identity.Rebel) {
        				sumIdentities[3] += 1;
        			}
        			
        			if (r.getMyBusinessEmployer() != null) {
        				sumWorking[0] += 1;
        			}
        			if (r.getMySchoolEmployer() != null) {
        				sumWorking[1] += 1;
        			}
        			if (r.getMyHealthFacilityEmployer() != null) {
        				sumWorking[2] += 1;
        			}
        			if (r.getMyReligiousFacilityEmployer() != null) {
        				sumWorking[3] += 1;
        			}
        			if (r.getCurrentEmploymentStatus() == Employment.Formal) {
        				sumWorking[4] += 1;
        			}
        			if (r.getCurrentEmploymentStatus() == Employment.Informal) {
        				sumWorking[5] += 1;
        			}
        			if (r.getCurrentEmploymentStatus() == Employment.Searching) {
        				sumWorking[6] += 1;
        			}
        			if (r.getCurrentEmploymentStatus() == Employment.Inactive) {
        				sumWorking[7] += 1;
        			}
        			if (r.getCurrentEmploymentStatus() == Employment.Formal && (r.getMyBusinessEmployer() == null
        					&& r.getMyHealthFacilityEmployer() == null && r.getMyReligiousFacilityEmployer() == null 
        					&& r.getMySchoolEmployer() == null)) {
        				sumWorking[8] += 1;
        			}
        			if (r.getCurrentEmploymentStatus() == Employment.Informal && r.getMyBusinessEmployer() == null) {
        				sumWorking[9] += 1;
        			}
        		}
        		setTotalAction(sumActions);
        		setTotalIdentity(sumIdentities);
        		setTotalWorking(sumWorking);
        		//setAllResidents(sumResidents);
        		
        		String actTitle = "Activity"; // row key - activity
                String [] activities = new String[]{"At Home", "Work", "Searhing for Work", "School", "Socialize", "Church", "Water", "Rebel"}; 
                
                
                int sum = sumActions.length;
                
                // percentage - agent activity by type
                for ( int i=0; i< sumActions.length; i++){
                  dataset.setValue(sumActions[i] * 100/world.getAllObjects().numObjs, actTitle, activities[i]); 
                  //dataset.setValue(sumActions[i] * 100/residents.numObjs, actTitle, activities[i]); 
                }       		       		
        	}        	
        };
        schedule.scheduleRepeating(chartUpdater);			
	}
	
	
	

    public static void main(String[] args)
    {    	
    	doLoop(Kibera.class, args);
        System.exit(0); 
    }


    
	
}
