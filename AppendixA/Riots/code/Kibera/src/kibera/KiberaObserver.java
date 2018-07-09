package kibera;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

import kibera.Resident.Employment;
import kibera.Resident.Goal;
import kibera.Resident.Identity;
import net.sf.csv4j.CSVWriter;
import sim.engine.SimState;
import sim.engine.Steppable;
import sim.field.network.stats.DegreeStatistics;
import sim.field.network.stats.NetworkStatistics;

// based on riftland worldobserver class
// thanks goes to mcoletti and jbasset

public class KiberaObserver implements Steppable{
	    
	private BufferedWriter dataFileBuffer_action; // output file buffer for dataCSVFile_
	private CSVWriter dataCSVFile_action; // CSV file that contains run data
	private BufferedWriter dataFileBuffer_identity; // output file buffer for dataCSVFile_
	private CSVWriter dataCSVFile_identity; // CSV file that contains run data
	private BufferedWriter dataFileBuffer_degreestats; // output file buffer for dataCSVFile_
	private CSVWriter dataCSVFile_degreestats; // CSV file that contains run data
	
	private BufferedWriter dataFileBuffer_network; // output file buffer for dataCSVFile_
	private CSVWriter dataCSVFile_network; // CSV file that contains run data
	
	private BufferedWriter dataFileBuffer_working; // output file buffer for dataCSVFile_
	private CSVWriter dataCSVFile_working; // CSV file that contains run data
	
	private BufferedWriter dataFileBuffer_residents;
	private CSVWriter dataCSVFile_residents;
	
	int cStep;
	int minuteInDay;
	
	
	Kibera kibera;
	    
	public final static int ORDERING = 3;
	private int step = 0;
	private boolean writeGrid =false;
	
	KiberaObserver(Kibera kibera) {
		//<GCB>: you may want to adjust the number of columns based on these flags.
		// both in createLogFile, and step
		kibera = null;
		startLogFile();
	}

	KiberaObserver() {
		startLogFile();
	}
	
	        
	private void startLogFile() {
		// Create a CSV file to capture data for this run.
		try {
                createLogFile();
                // First line of file contains field names
                String [] header = new String [] {"Job", "Step", "Total Residents", "Domestic", "Employed", "Student", "Rebel"};
                dataCSVFile_identity.writeLine(header);
	            
			// activity
	        String [] header_actions = new String [] {"Job","Step","total residents", "At Home", "Work", "Searching for Work",
	                                              		"School", "Socialiazing", "Church", "Getting Water", "Rebel"};
	       
	        dataCSVFile_action.writeLine(header_actions);
	        
	        String [] header_network = new String [] {"Job", "Step", "node1", "node2", "weight"};
	        dataCSVFile_network.writeLine(header_network);
	        
	        String [] header_working = new String [] {"Job", "Step", "Business", "School", "Health Facility", "Religious Facility", "Formal", "Informal", "Searching", "Inactive", "Formal at home", "Informal at home"};
	        dataCSVFile_working.writeLine(header_working);
	        
	        String[] header_residents = new String [] {"Job", "Step", "Resident", "Age", "Employment status", "Action", "Identity", "Is initial rebel", "Heard rumor", "Energy", "Current Aggression", "Aggression Rate", "Has School", "Has formal employer", "Has informal Employer", "Household Income", "Formal income", "Informal income", "Searching income", "Inactive income", "Household expenditures", "Rent cost", "Water cost", "Electric cost", "Sanitation cost", "Charcoal cost", "Food cost", "Discrepancy"};
	        dataCSVFile_residents.writeLine(header_residents);
	        
	        String [] header_degreestats = new String [] {"Job", "Step", "max degree", "min degree", "mean degree", "sum degree"};
	        dataCSVFile_degreestats.writeLine(header_degreestats);
	        	 
	        }
		
	        catch (IOException ex) {
	            Logger.getLogger(Kibera.class.getName()).log(Level.SEVERE, null, ex);
	        }
	    }
	  
	    int count = 0;
	    
	    public void step(SimState state) {
	        kibera  = (Kibera)state;
	        
	        cStep = (int) kibera.schedule.getSteps();
	        
	        if(cStep < 1440){
	            minuteInDay = cStep;
	        }
	       else {
	            minuteInDay = cStep % 1440;	            
	        }
	        
	        String job = Long.toString(state.job());	        	
	        
	        String totalResidents = Integer.toString(kibera.residents.numObjs);
	        String numAtHome = Integer.toString(kibera.getTotalAction()[0]);
	        String numAtWork = Integer.toString(kibera.getTotalAction()[1]);
	        String numSearchingforWork = Integer.toString(kibera.getTotalAction()[2]);
	        String numAtSchool = Integer.toString(kibera.getTotalAction()[3]);
	        String numAtFriendsHouse = Integer.toString(kibera.getTotalAction()[4]);
	        String numAtChurch = Integer.toString(kibera.getTotalAction()[5]);
	        String numAtWater = Integer.toString(kibera.getTotalAction()[6]);
	        String numRebelling = Integer.toString(kibera.getTotalAction()[7]);
	        
	        String numDomestic = Integer.toString(kibera.getTotalIdentity()[0]);
	        String numEmployed = Integer.toString(kibera.getTotalIdentity()[1]);
	        String numStudent = Integer.toString(kibera.getTotalIdentity()[2]);
	        String numRebel = Integer.toString(kibera.getTotalIdentity()[3]);
	        
	        String maxDegree = Integer.toString(DegreeStatistics.getMaxOutDegree(kibera.socialNetwork));
	        String minDegree = Integer.toString(DegreeStatistics.getMinOutDegree(kibera.socialNetwork));
	        String meanDegree = Double.toString(DegreeStatistics.getMeanOutDegree(kibera.socialNetwork));
	        String sumDegrees = Integer.toString(DegreeStatistics.getSumOfDegrees(kibera.socialNetwork));
                
                
	        
	        String numWorkingBusiness = Integer.toString(kibera.getTotalWorking()[0]);
	        String numWorkingSchool = Integer.toString(kibera.getTotalWorking()[1]);
	        String numWorkingHealthFacility = Integer.toString(kibera.getTotalWorking()[2]);
	        String numWorkingReligiousFacility = Integer.toString(kibera.getTotalWorking()[3]);
	        String numWorkingFormal = Integer.toString(kibera.getTotalWorking()[4]);
	        String numWorkingInformal = Integer.toString(kibera.getTotalWorking()[5]);
	        String numWorkingSearching = Integer.toString(kibera.getTotalWorking()[6]);
	        String numWorkingInactive = Integer.toString(kibera.getTotalWorking()[7]);
	        String numWorkingFormalHome = Integer.toString(kibera.getTotalWorking()[8]);
	        String numWorkingInformalHome = Integer.toString(kibera.getTotalWorking()[9]);
	        
	        NetworkStatistics.getDensity(kibera.socialNetwork);
	        	        
	        // when to export raster;- everyday at midnight
	        writeGrid =true;
	        if(kibera.schedule.getSteps() % 1440 == 5){
	           writeGrid =true;
	        }
	        if (kibera.schedule.getSteps() % 1440 == 1) {
	        	writeGrid = true;
	        }
	        else {
	            writeGrid =false;
	        }
	        
	        String [] data_network = null;
	        //DO NOT DELETE -- this creates the adjacency matrix for SNA analysis
	        /*if (minuteInDay == 0) {
		        String matrix = "";
		        Edge[][] edges = kibera.socialNetwork.getAdjacencyMatrix();
		        for(int i = 0; i < edges.length; i++){
		        	for(int j = i+1; j < edges[0].length; j++){
		        		if(edges[i][j] == null)
		        			continue; // don't write it out, it doesn't exist
		        		matrix += i + ", " + j + ", " + edges[i][j].info + "\n";
		        		String node1 = Integer.toString(i);
		        		String node2 = Integer.toString(j);
		        		String edgeWeight = Double.toString((Double) edges[i][j].info);
		        		data_network = new String [] {job, Integer.toString(this.step), node1, node2, edgeWeight};
		        		
		        		try {
		        			this.dataCSVFile_network.writeLine(data_network);
		        			
		        		}
		        		catch (IOException ex) {
		    	            Logger.getLogger(KiberaObserver.class.getName()).log(Level.SEVERE, null, ex);
		    	        }
		    	        
		        	}
		        	//if(i%100 == 0) System.out.print(".");
		        }
		        //System.out.println(matrix);		        
	        }*/
	        
	        String [] data_residents = null;
	        
	        if (minuteInDay == 1) {
	        	for (int i = 0; i < kibera.residents.numObjs; i++) {
	        		Resident r = (Resident) kibera.residents.get(i);
	        		String residents = Integer.toString(r.getResidentID());
	        		String age = Integer.toString(r.getAge());
	        		
	        		String hhExpenditures = Double.toString(r.getHousehold().getDailyHouseholdExpenditures());
	        		String hhIncome = Double.toString(r.getHousehold().getDailyHouseholdIncome());
	        		String hhDiscrepancy = Double.toString(r.getHousehold().getDailyHouseholdDiscrepancy());
	        		
	        		String residentIncome = Double.toString((r.getResidentIncome() / 30));
	        		String formalIncome = "0";
	        		String informalIncome = "0";
	        		String searchingIncome = "0";
	        		String inactiveIncome = "0";
	        		
	        		String status = "0";
	        		
	        		String hasSchool = "0";
	        		String hasFormalEmployer = "0";
	        		String hasInformalEmployer = "0";
	        		
	        		String hhWaterCost = Double.toString(r.getHousehold().getDailyWaterCost());
	        		String hhElectricCost = Double.toString(r.getHousehold().getDailyElectricCost());
	        		String hhSanitationCost = Double.toString(r.getHousehold().getDailySanitationCost());
	        		String hhCharcoalCost = Double.toString(r.getHousehold().getDailyCharcoalCost());
	        		String hhFoodCost = Double.toString(r.getHousehold().getDailyFoodCost());
	        		String hhRentCost = Double.toString(r.getHousehold().getHome().getHouseRent() / 30);
	        		
	        		String identity = "";
	        		String action = "";
	        		
	        		String rumor = "False";
	        		String energy = Double.toString(r.getEnergy());
	        		String aggression = Double.toString(r.getAggressionValue());
	        		String aggressionRate = Double.toString(r.getAggressionRate());
                                
                                String isInitialRebel = Boolean.toString(r.isInitialRebel());
	        			        		
	        		if (r.getCurrentEmploymentStatus() == Employment.Formal) { 
	        			formalIncome = residentIncome; 
	        			status = "Formal";
	        		}
	        		if (r.getCurrentEmploymentStatus() == Employment.Informal) { 
	        			informalIncome = residentIncome;
	        			status = "Informal";
	        		}	
	        		if (r.getCurrentEmploymentStatus() == Employment.Searching) { 
	        			searchingIncome = residentIncome; 
	        			status = "Searching";
	        		}	
	        		if (r.getCurrentEmploymentStatus() == Employment.Inactive) { 
	        			inactiveIncome = residentIncome; 
	        			status = "Inactive";
	        		}
	        		
	        		if (r.getMySchool() != null) { hasSchool = "1"; }
	        		if (r.getMyReligiousFacilityEmployer() != null || r.getMyHealthFacilityEmployer() != null || r.getMySchoolEmployer() != null) { hasFormalEmployer = "1"; }
	        		if (r.getMyBusinessEmployer() != null) { hasInformalEmployer = "1"; }
	        		
	        		if (r.getCurrentGoal() == Goal.Find_Employment) { action = "Find_Employment"; }
	        		if (r.getCurrentGoal() == Goal.Get_An_Education) { action = "Go_to_School"; }
	        		if (r.getCurrentGoal() == Goal.Get_Water) { action = "Get_Water"; }
	        		if (r.getCurrentGoal() == Goal.Go_to_Church) { action = "Go_to_Church"; }
	        		if (r.getCurrentGoal() == Goal.Go_to_Work) { action = "Go_to_Work"; }
	        		if (r.getCurrentGoal() == Goal.Rebel) { action = "Rebel"; }
	        		if (r.getCurrentGoal() == Goal.Socialize) { action = "Socialize"; }
	        		if (r.getCurrentGoal() == Goal.Stay_Home) { action = "Stay_Home"; }
	        		
	    
	        		if (r.getCurrentIdentity() == Identity.Domestic_Activities) { identity = "Domestic_Activities"; }
	        		if (r.getCurrentIdentity() == Identity.Employer) { identity = "Employee"; }
	        		if (r.getCurrentIdentity() == Identity.Student) { identity = "Student"; }
	        		if (r.getCurrentIdentity() == Identity.Rebel) { identity = "Rebel"; }
	        		
	        		if (r.heardRumor()) { rumor = "True"; }
	        		        				        		        		
	        		data_residents = new String [] {job, Integer.toString(this.step), residents, age, status, action, identity, isInitialRebel, rumor, energy, aggression, aggressionRate, hasSchool, hasFormalEmployer, hasInformalEmployer, hhIncome, formalIncome, informalIncome, searchingIncome, inactiveIncome, hhExpenditures, hhRentCost, hhWaterCost, hhElectricCost, hhSanitationCost, hhCharcoalCost, hhFoodCost, hhDiscrepancy };
	        		
	        		try {
	        			this.dataCSVFile_residents.writeLine(data_residents);
	        		}
	        		catch (IOException ex) {
	    	            Logger.getLogger(KiberaObserver.class.getName()).log(Level.SEVERE, null, ex);
	    	        }
	        	}
	        }
	        
	        String [] data_actions = new String [] {job, Integer.toString(this.step), totalResidents, numAtHome, numAtWork, numSearchingforWork, numAtSchool, numAtFriendsHouse, numAtChurch, numAtWater, numRebelling};
	        String [] data_identities = new String [] {job, Integer.toString(this.step), totalResidents, numDomestic, numEmployed, numStudent, numRebel };
	        String [] data_degreestats = new String [] {job, Integer.toString(this.step), maxDegree, minDegree, meanDegree, sumDegrees};
	        String [] data_working = new String [] {job, Integer.toString(this.step), numWorkingBusiness, numWorkingSchool, numWorkingHealthFacility, numWorkingReligiousFacility, numWorkingFormal, numWorkingInformal, numWorkingSearching, numWorkingInactive, numWorkingFormalHome, numWorkingInformalHome };
	        //String [] data_residents = new String[] {job, Integer.toString(this.step), residents, hhExpenditures, hhIncome, formalIncome, informalIncome, searchingIncome, inactiveIncome };
	        
	        try
	        {	            
	            this.dataCSVFile_action.writeLine(data_actions);	            
	            this.dataCSVFile_identity.writeLine(data_identities);
	            this.dataCSVFile_degreestats.writeLine(data_degreestats);  
	            this.dataCSVFile_working.writeLine(data_working);  
	            //this.dataCSVFile_residents.writeLine(data_residents);
	            	            	         
	        }
	        catch (IOException ex) {
	            Logger.getLogger(KiberaObserver.class.getName()).log(Level.SEVERE, null, ex);
	        }
	        
	        this.step++;
	    }
	    
	     void finish()
	    {
	        try {
	            this.dataFileBuffer_action.close();
	            this.dataFileBuffer_identity.close();
	            this.dataFileBuffer_degreestats.close();
	            this.dataFileBuffer_network.close();
	            this.dataFileBuffer_working.close();
	            this.dataFileBuffer_residents.close();
	       
	        }
	        catch (IOException ex) {
	            Logger.getLogger(KiberaObserver.class.getName()).log(Level.SEVERE, null, ex);
	        }
	    }

	    
	    private void createLogFile() throws IOException
	    {
	        long now = System.currentTimeMillis();

	        String filename_action = String.format("%ty%tm%td%tH%tM%tS", now, now, now, now, now, now, now)
	            + "k_actions.csv";
	        
	        String filename_identity = String.format("%ty%tm%td%tH%tM%tS", now, now, now, now, now, now)
		            + "k_identity.csv";
	        
	        String filename_degreestats = String.format("%ty%tm%td%tH%tM%tS", now, now, now, now, now, now)
		            + "k_degreestats.csv";
	        
	        String filename_network = String.format("%ty%tm%td%tH%tM%tS", now, now, now, now, now, now)
		            + "k_network.csv";
	        
	        String filename_working = String.format("%ty%tm%td%tH%tM%tS", now, now, now, now, now, now, now, now, now, now, now, now)
		            + "k_working.csv";
	        
	        String filename_residents = String.format("%ty%tm%td%tH%tM%tS", now, now, now, now, now, now, now, now, now, now, now, now, now, now, now, now, now, now, now, now, now, now, now, now, now)
		            + "k_residents.csv";
	        
	        // activity
	        this.dataFileBuffer_action = new BufferedWriter(new FileWriter(filename_action));
	        this.dataCSVFile_action = new CSVWriter(dataFileBuffer_action);
	        
	        this.dataFileBuffer_identity = new BufferedWriter(new FileWriter(filename_identity));
	        this.dataCSVFile_identity = new CSVWriter(dataFileBuffer_identity);
	        
	        this.dataFileBuffer_degreestats = new BufferedWriter(new FileWriter(filename_degreestats));
	        this.dataCSVFile_degreestats = new CSVWriter(dataFileBuffer_degreestats);
	        
	        this.dataFileBuffer_network = new BufferedWriter(new FileWriter(filename_network));
	        this.dataCSVFile_network = new CSVWriter(dataFileBuffer_network);  
	        
	        this.dataFileBuffer_working = new BufferedWriter(new FileWriter(filename_working));
	        this.dataCSVFile_working = new CSVWriter(dataFileBuffer_working);  
	        
	       this.dataFileBuffer_residents = new BufferedWriter(new FileWriter(filename_residents));
	       this.dataCSVFile_residents = new CSVWriter(dataFileBuffer_residents);  
	    }

	    private void writeObject(java.io.ObjectOutputStream out)
	        throws IOException {
	        out.writeInt(step);

	    }


	    private void readObject(java.io.ObjectInputStream in)
	        throws IOException, ClassNotFoundException {
	        step = in.readInt();
	         
	        startLogFile();
	    }
	    

	}
