package kibera;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.net.URL;
import java.util.ArrayList;
import java.util.logging.Level;
import java.util.logging.Logger;

import kibera.Resident.Employment;
import kibera.Resident.Gender;
import kibera.Resident.Identity;
import kibera.Resident.Religion;

import com.vividsolutions.jts.geom.CoordinateSequence;
import com.vividsolutions.jts.geom.Envelope;
import com.vividsolutions.jts.geom.LineString;
import com.vividsolutions.jts.geom.MultiLineString;


import sim.field.continuous.Continuous2D;
import sim.field.geo.GeomVectorField;
import sim.field.grid.DoubleGrid2D;
import sim.field.grid.IntGrid2D;
import sim.field.grid.ObjectGrid2D;
import sim.field.grid.SparseGrid2D;
import sim.field.network.Edge;
import sim.io.geo.ShapeFileImporter;
import sim.util.Bag;
import sim.util.Double2D;
import sim.util.Int2D;
import sim.util.IntBag;
import sim.util.geo.MasonGeometry;


public class KiberaBuilder extends Stats {

	//Create a world based on GIS data
	static int gridWidth = 0;
	static int gridHeight = 0;
	
	static int intNumNeighborhoods = 15;
	
	public static void createWorld(String landFile, String roadFile, String facilityFile, String healthFile, String religionFile, String watsanFile, Kibera kibera)
	{
		kibera.parcels.clear();
		kibera.households.clear();
	    kibera.residents.clear();
	    kibera.structures.clear();
	    kibera.homes.clear();
	    kibera.availableParcels.clear();
	    kibera.allStructureLocations.clear();
	    kibera.allBusinessLocations.clear();
	    kibera.allHomeLocations.clear();
	    
	    kibera.kikuyu.clear();
	    kibera.luhya.clear();
	    kibera.luo.clear();
	    kibera.kalinjin.clear();
	    kibera.kamba.clear();
	    kibera.kisii.clear();
	    kibera.meru.clear();
	    kibera.mijikenda.clear();
	    kibera.maasai.clear();
	    kibera.turkana.clear();
	    kibera.embu.clear();
	    kibera.other.clear();
	    
	    createLand(landFile, kibera);
	    createRoads(roadFile, kibera);
	    	    
		kibera.schedule.clear();
		
		addStructures(kibera);
                
    
                            
		addHouseholds(kibera);	
		
		addFacilities(facilityFile, healthFile, religionFile, kibera);
		addWatsan(watsanFile, kibera);
		
		rumorPropogation(kibera);
	}
	
	private static void createLand(String landFile, Kibera kibera)
	{		
		try
		{
			// buffer reader - read ascii file
			BufferedReader land = new BufferedReader(new FileReader(landFile));
			String line;

			// first read the dimensions
			line = land.readLine(); // read line for width
			String[] tokens = line.split("\\s+");
			int width = Integer.parseInt(tokens[1]);
			gridWidth = width;

			line = land.readLine();
			tokens = line.split("\\s+");
			int height = Integer.parseInt(tokens[1]);
			gridHeight = height;
			
			kibera.setWidth(width);
			kibera.setHeight(height);

			createGrids(kibera, width, height);

			// skip the next four lines as they contain irrelevant metadata
			for (int i = 0; i < 4; ++i) 
			{
				line = land.readLine();
			}
    
			Neighborhood neighborhood = null;
    
			//Create the neighborhoods in Kibera
			for (int i = 1; i <= intNumNeighborhoods; ++i) {
				neighborhood = new Neighborhood();
				kibera.allNeighborhoods.put(i, neighborhood);
				neighborhood.setNeighborhoodID(i);
			}
    
			for (int curr_row = 0; curr_row < height; ++curr_row) {
				line = land.readLine();
        
				tokens = line.split("\\s+");
        
				//Column 0 is blank in file, so have to adjust for blank column
				for (int curr_col = 0; curr_col < width; ++curr_col) {
					int neighborhoodID = Integer.parseInt(tokens[curr_col]);
            
					Parcel parcel = null;
        
					if (neighborhoodID < 100) {                   	
						Int2D parcelLocation = new Int2D(curr_col, curr_row);
						parcel = new Parcel(parcelLocation);
                
						kibera.parcels.add(parcel);     
                
						parcel.setParcelID(neighborhoodID);
                                                                                                      
						neighborhood = kibera.allNeighborhoods.get(neighborhoodID);
                                      
						neighborhood.addParcel(parcel);
						parcel.setNeighborhood(neighborhood);
                                                              
						kibera.landGrid.set(curr_col, curr_row, parcel);                           
					}
					else {
						Int2D parcelLocation = new Int2D(curr_col, curr_row);
						parcel = new Parcel(parcelLocation);
						parcel.setParcelID(0);
						kibera.landGrid.set(curr_col, curr_row, parcel); 
					}
				}              
			}
			land.close();		
			}
		catch (IOException ex) {
            Logger.getLogger(KiberaBuilder.class.getName()).log(Level.SEVERE, null, ex);
		}
	}
	
	public static void addFacilities(String facilityFile, String healthFile, String religionFile, Kibera kibera) {
            try {
                // buffer reader - read ascii file
                BufferedReader facilities = new BufferedReader(new FileReader(facilityFile));
                String line;

                BufferedReader healthFacilities = new BufferedReader(new FileReader(healthFile));
                String healthLine;

                BufferedReader religiousFacilities = new BufferedReader(new FileReader(religionFile));
                String religiousLine;

                // first read the dimensions
                line = facilities.readLine(); // read line for width
                String[] tokens = line.split("\\s+");
                int width = Integer.parseInt(tokens[1]);
                gridWidth = width;

                line = facilities.readLine();
                tokens = line.split("\\s+");
                int height = Integer.parseInt(tokens[1]);
                gridHeight = height;

                int numCapacitySchool = 0;
                int numCapacityHealth = 0;
                int numCapacityReligion = 0;

                int numSchools = 0;
                int numHealth = 0;
                int numReligion = 0;

                //Add the health facilities
                for (int i = 0; i < 6; ++i) {
                    healthLine = healthFacilities.readLine();
                }

                HealthFacility healthFacility = null;
    
                for (int curr_row = 0; curr_row < height; ++curr_row) {
                    healthLine = healthFacilities.readLine();

                    tokens = healthLine.split("\\s+");

                    for (int curr_col = 0; curr_col < width; ++curr_col) {
                        int healthFacilityType = Integer.parseInt(tokens[curr_col]);

                        Parcel parcel = null;
        
                        if (healthFacilityType < 100) {                    	
                            Int2D parcelLocation = new Int2D(curr_col, curr_row);						

                            parcel = (Parcel) kibera.landGrid.get(curr_col, curr_row);
                            int numStructuresOnParcel = parcel.getStructure().size();
						
                            if (numStructuresOnParcel == 0) {
                                Structure s = new Structure(parcel);
                                kibera.structures.add(s);
                                healthFacility = new HealthFacility(s, healthFacilityType);
                                s.setParcel(parcel);
                                parcel.addStructure(s);

                                numHealth += 1;
                            }
                            else {
                                int rn = 1 + kibera.random.nextInt(numStructuresOnParcel);

                                ArrayList <Structure> structures = parcel.getStructure();

                                int i = 0;
                                for(Structure s : structures) {
                                    i++;
								
                                    if (i == rn) {
                                        healthFacility = new HealthFacility(s, healthFacilityType);
                                        s.addHealthFacility(healthFacility);
                                        healthFacility.setStructure(s);
                                        healthFacility.setFacilityID(healthFacilityType);

                                        numHealth += 1;

                                        int employeeCapacity = 0;
                                        //Determine capacity of employees of business
                                        if (kibera.formalBusinessCapacity == 0) {
                                            //employeeCapacity = kibera.random.nextInt(1);
                                            employeeCapacity = 1;
                                        }
                                        else {
                                            employeeCapacity = 1 + kibera.random.nextInt(kibera.formalBusinessCapacity);
                                        }

                                        healthFacility.setEmployeeCapacity(employeeCapacity);

                                        numCapacityHealth += employeeCapacity;
                                    }
                                }
                            }
                            kibera.allHealthFacilityLocations.add(parcelLocation);
                            //kibera.allHealthFacilities.add(healthFacility);
                            kibera.healthFacilityGrid.setObjectLocation(healthFacility, parcelLocation);   
                        }					
                    }
                }
			
                //Add the religious facilities (church/mosque)
                for (int i = 0; i < 6; ++i) {
                    religiousLine = religiousFacilities.readLine();
                }

                ReligiousFacility religiousFacility = null;
    
                for (int curr_row = 0; curr_row < height; ++curr_row) {
                    religiousLine = religiousFacilities.readLine();

                    tokens = religiousLine.split("\\s+");
        
                    for (int curr_col = 0; curr_col < width; ++curr_col) {
                        int religiousFacilityType = Integer.parseInt(tokens[curr_col]);

                        Parcel parcel = null;

                        if (religiousFacilityType < 100) {                    	
                                Int2D parcelLocation = new Int2D(curr_col, curr_row);						

                                parcel = (Parcel) kibera.landGrid.get(curr_col, curr_row);
                                int numStructuresOnParcel = parcel.getStructure().size();

                                if (numStructuresOnParcel == 0) {
                                    Structure s = new Structure(parcel);
                                    kibera.structures.add(s);
                                    religiousFacility = new ReligiousFacility(s, religiousFacilityType);
                                    s.setParcel(parcel);
                                    parcel.addStructure(s);

                                    numReligion += 1;
                                }
                                else {
                                    int rn = 1 + kibera.random.nextInt(numStructuresOnParcel);

                                    ArrayList <Structure> structures = parcel.getStructure();

                                    int i = 0;
                                    for(Structure s : structures) {
                                        i++;
								
                                        if (i == rn) {
                                            religiousFacility = new ReligiousFacility(s, religiousFacilityType);
                                            s.addReligiousFacility(religiousFacility);
                                            religiousFacility.setStructure(s);
                                            religiousFacility.setFacilityType(religiousFacilityType);

                                            numReligion += 1;

                                            int employeeCapacity = 0;
                                            //Determine capacity of employees of business
                                            if (kibera.formalBusinessCapacity == 0) {
                                                    //employeeCapacity = kibera.random.nextInt(1);
                                                    employeeCapacity = 1;
                                            }
                                            else {
                                                    employeeCapacity = 1 + kibera.random.nextInt(kibera.formalBusinessCapacity);
                                            }
                                            religiousFacility.setEmployeeCapacity(employeeCapacity);

                                            numCapacityReligion += employeeCapacity;
                                        }
                                    }
                                }
                                kibera.allReligiousFacilityLocations.add(parcel);
                                kibera.religiousFacilityGrid.setObjectLocation(religiousFacility, parcelLocation);   
                        }					
                    }
                }
			
                //Add all the schools
                //skip the next four lines as they contain irrelevant metadata
                for (int j = 0; j < 4; ++j) {
                    line = facilities.readLine();
                }

                School school = null;

                for (int curr_row = 0; curr_row < height; ++curr_row) {
                    line = facilities.readLine();

                    tokens = line.split("\\s+");

                    for (int curr_col = 0; curr_col < width; ++curr_col) {
                        int facilityID = Integer.parseInt(tokens[curr_col]);

                        Parcel parcel = null;

                        if (facilityID < 100) {                    	
                            Int2D parcelLocation = new Int2D(curr_col, curr_row);						

                            parcel = (Parcel) kibera.landGrid.get(curr_col, curr_row);
                            int numStructuresOnParcel = parcel.getStructure().size();

                            if (numStructuresOnParcel == 0) {
                                    Structure s = new Structure(parcel);
                                    kibera.structures.add(s);
                                    school = new School(s, facilityID);
                                    s.setParcel(parcel);
                                    parcel.addStructure(s);

                                    numSchools += 1;
                            }

                        else {
                            int rn = 1 + kibera.random.nextInt(numStructuresOnParcel);

                            ArrayList <Structure> structures = parcel.getStructure();

                            int j = 0;
                            for(Structure s : structures) {
                                j++;

                                if (j == rn) {
                                    school = new School(s, facilityID);
                                    s.addSchool(school);
                                    school.setStructure(s);
                                    school.setFacilityID(facilityID);

                                    numSchools += 1;
                                }
                            }
                        }

                        if (facilityID == 1) {
                            kibera.allSchoolLocations.add(parcel);
                            int capacity = kibera.schoolCapacity;
                            if (capacity == 0) { capacity = 1; }
                            school.setSchoolCapacity(capacity);

                            int employeeCapacity = 0;
                            //Determine capacity of employees of business
                            if (kibera.formalBusinessCapacity == 0) {
                                //employeeCapacity = kibera.random.nextInt(1);
                                employeeCapacity = 1;
                            }
                            else {
                                employeeCapacity = 1 + kibera.random.nextInt(kibera.formalBusinessCapacity);
                            }
                            school.setEmployeeCapacity(employeeCapacity);

                            numCapacitySchool += employeeCapacity;

                        }

                        kibera.facilityGrid.setObjectLocation(school, parcelLocation);                     
                        }
                    }              
                }

                System.out.println("Number Schools = " + numSchools);
                System.out.println("Number Health = " + numHealth);
                System.out.println("Number Religion = " + numReligion);

                System.out.println("Capacity Schools = " + numCapacitySchool);
                System.out.println("Capacity Health = " + numCapacityHealth);
                System.out.println("Capacity Religion = " + numCapacityReligion);

                facilities.close();		
                healthFacilities.close();
                religiousFacilities.close();
            }
            catch (IOException ex) {
                Logger.getLogger(KiberaBuilder.class.getName()).log(Level.SEVERE, null, ex);
            }
        }

        public static void addWatsan(String watsanFile, Kibera kibera) {
            try {
                // buffer reader - read ascii file
                BufferedReader waterSanitation = new BufferedReader(new FileReader(watsanFile));
                String line;

                // first read the dimensions
                line = waterSanitation.readLine(); // read line for width
                String[] tokens = line.split("\\s+");
                int width = Integer.parseInt(tokens[1]);
                gridWidth = width;

                line = waterSanitation.readLine();
                tokens = line.split("\\s+");
                int height = Integer.parseInt(tokens[1]);
                gridHeight = height;

                //Add the water and sanitation points
                for (int i = 0; i < 4; ++i) {
                    line = waterSanitation.readLine();
                }

                    WaterPoint waterPoint = null;
                    Sanitation sanitation = null;

                    for (int curr_row = 0; curr_row < height; ++curr_row) {
                            line = waterSanitation.readLine();

                            tokens = line.split("\\s+");

                            for (int curr_col = 0; curr_col < width; ++curr_col) {
                                    int id = Integer.parseInt(tokens[curr_col]);

                                    Parcel parcel = null;

                                    Int2D parcelLocation = new Int2D(curr_col, curr_row);	
                                    parcel = (Parcel) kibera.landGrid.get(curr_col, curr_row);

                                    if (id == 1) {                    																			
                                            waterPoint = new WaterPoint(parcel);
                                            waterPoint.setParcel(parcel);
                                            parcel.addWaterPoint(waterPoint);

                                            kibera.allWaterPoints.add(parcel);
                                            kibera.waterGrid.setObjectLocation(waterPoint, parcelLocation);
                                    }

                                    if (id == 2 || id == 6 || id == 8) {
                                            sanitation = new Sanitation(parcel);
                                            parcel.addSanitation(sanitation);
                                            sanitation.setParcel(parcel);

                                            kibera.allSanitationLocations.add(parcel);
                                            kibera.sanitationGrid.setObjectLocation(sanitation, parcelLocation);
                                    }

                            }              
                    }
			waterSanitation.close();		
		}
		catch (IOException ex) {
            Logger.getLogger(KiberaBuilder.class.getName()).log(Level.SEVERE, null, ex);
		}
	}
	

	public static void addStructures(Kibera kibera) {
		//add structures while there is still place to put them
		Parcel residingParcel = null;
		
		int numBusinesses = 0;
		int numStructures = 0;
		int numHomes = 0;
		
		for(int i = 0; i < kibera.parcels.numObjs; i++) {
			Parcel p = (Parcel) kibera.parcels.objs[i];
			int id = p.getParcelID();
			if (p.isParcelOccupied(kibera) == false && id > 0) 
			{
				residingParcel = p;
				Structure s = new Structure(residingParcel);
				
				numStructures += 1;
				
				s.setParcel(residingParcel);
				residingParcel.addStructure(s);
				//determine capacity of each structure
		   		double shouldAddHouses = kibera.random.nextDouble();
				//int numberOfHouses = 1 + kibera.random.nextInt(5); //placeholder - change this to distribution
                                int numberOfHouses = 5;
			
				double shouldAddBusinesses = kibera.random.nextDouble();
				//int numberOfBusinesses = 1 + kibera.random.nextInt(2); //placeholder - change this to distribution
                                int numberOfBusinesses = 3; //placeholder - change this to distribution
				
				int homeCapacity = 0;
				int businessCapacity = 0;
				
		   		if (shouldAddHouses < 0.86) { //add household(s) to structure
					homeCapacity = numberOfHouses;
					for (int j = 0; j < numberOfHouses; j++) {
						addHomes(kibera, s, s.getParcel());
						
						numHomes += 1;
					}
				}
				    		
				if (shouldAddBusinesses < 0.13) { //add business(es) to structure			
					businessCapacity = numberOfBusinesses;
					for (int k = 0; k < numberOfBusinesses; k++) {
						addBusiness(kibera, s, s.getParcel());
						
						numBusinesses += 1;
					}
				}
						
				//placeholder for capacity of each structure
				s.setStructureCapacity(homeCapacity, businessCapacity);
				//int c = s.getHomeCapacity();
				
				kibera.allStructureLocations.add(residingParcel);
				kibera.structures.add(s);
			}
			
		}
		System.out.println("Number Homes = " + numHomes);
		System.out.println("Number Businesses = " + numBusinesses);	
		System.out.println("Number Structures = " + numStructures);
	}
	

	public static void addHouseholds(Kibera kibera) {				
            int totalResidents = kibera.getNumResidents();
            int i = 0;
            boolean isHeadOfHousehold = false;
            int residentID = 0;

            int totalhh = 0;	
            int countSearching = 0;
            int countInactive = 0;
            int countStudentEligible = 0;
            int countFormal = 0;
            int countInformal = 0;
            int countHeadofHH = 0;
            int countMale = 0;
            int countFemale = 0;
            int countAdults = 0;
            int countChildren = 0;
            int countResidents = 0;
            int countFemaleFormal = 0;
            int countFemaleInformal = 0;
            int countFemaleSearching = 0;
            int countFemaleInactive = 0;
            int countMaleFormal = 0;
            int countMaleInformal = 0;
            int countMaleSearching = 0;
            int countMaleInactive = 0;
            int countYoungChildren = 0;

            //minimum amount of income needed to afford the cheapest rent in kibera
            int minAffordability = (int)(kibera.getRent(0) / kibera.percentIncomeforRent);
                        
                        
			
            //Initialize household 
            while (i < totalResidents) {   
	                	
	        double mean = 3.55;	        	
	        double stdev = 1.61;
	        	
	        double x = Stats.normalToLognormal(Stats.calcLognormalMu(mean, stdev), Stats.calcLognormalSigma(mean, stdev), kibera.random.nextGaussian());
	        int householdSize = (int) x;
	        //int householdSize = kibera.numResidents;
	        	
	        //determine household attributes  	
	        String hhEthnicity = determineHouseholdEthnicity(kibera);
	        	
	        //calculate total income for household
	        double expectedHouseholdIncome = 0;
	        	
	        //determine household religion
                double rnReligion = kibera.random.nextDouble();
                Resident.Religion religion;
                	
                //source - CIA factbook
                if (rnReligion < .825) { religion = Religion.Christian; }
                else if (rnReligion < .825 + 111) { religion = Religion.Muslim; }
                else { religion = Religion.Other; }

	        Household hh = new Household();
		kibera.households.add(hh);
	        	
		totalhh = totalhh + 1;
                
                //if there are still households searching for a home but all homes are occupied, no more households should be added to simulation
                if (kibera.allHomesAvailable.isEmpty()) {
                    break;
                    
                }
	        	
	        	for (int j = 0; j < householdSize; j++) {            
                            Resident.Employment employmentStatus = null;
	        		
                            if (j == 0) { isHeadOfHousehold = true; }
	                	
                            int residentAge = determineResidentAge(kibera, isHeadOfHousehold);
                            Resident.Gender gender = determineResidentGender(kibera);	                	                	  
                            employmentStatus = determineEmploymentStatus(residentAge, gender, kibera);
                            boolean isSchoolEligible = determineStudentStatus(residentAge, employmentStatus, kibera);   
	                
                            //not all that are school eligible will go to school, many will work in informal sector
                            //assume some that are school eligible will work
                            double income = 0;
                            double rn = kibera.random.nextDouble();
                            double expectedIncome = 0;
	                
                            if (isSchoolEligible && gender == Gender.female) {
	                	if (rn < (0.41 * kibera.getInformalityIndex())) {
	                		employmentStatus = Employment.Informal;
	                		expectedIncome = WealthDistribution.determineIncome(employmentStatus, kibera);
	                		employmentStatus = Employment.Inactive;
	                	}
                            }
	                
                            if (isSchoolEligible && gender == Gender.male) {
	                	if (rn < (0.6 * kibera.getInformalityIndex())) {
	                		employmentStatus = Employment.Informal;
	                		expectedIncome = WealthDistribution.determineIncome(employmentStatus, kibera);
	                		employmentStatus = Employment.Inactive;
	                	}
                            }
	                
                            income = WealthDistribution.determineIncome(employmentStatus, kibera);
	                
                            expectedHouseholdIncome = expectedHouseholdIncome + expectedIncome + income;
	                	                            	         
                            addResidents(kibera, residentID, hh, hhEthnicity, residentAge, gender, religion, isHeadOfHousehold, employmentStatus, isSchoolEligible, income);
                            residentID += 1;
	                
                            if (isHeadOfHousehold) {
	                	countHeadofHH = countHeadofHH + 1;
                            }
	                
                            isHeadOfHousehold = false;
	                	                	                
	                //count residents
	                if (employmentStatus == Employment.Formal) { countFormal = countFormal + 1;}
	                if (employmentStatus == Employment.Informal) { countInformal = countInformal + 1;}
	                if (employmentStatus == Employment.Inactive) { countInactive = countInactive + 1;}
	                if (employmentStatus == Employment.Searching) { countSearching = countSearching + 1;}
	                if (employmentStatus == Employment.Formal && gender == Gender.female) { countFemaleFormal = countFemaleFormal + 1;}
	                if (employmentStatus == Employment.Informal && gender == Gender.female) { countFemaleInformal = countFemaleInformal + 1;}
	                if (employmentStatus == Employment.Formal && gender == Gender.male) { countMaleFormal = countMaleFormal + 1;}
	                if (employmentStatus == Employment.Informal && gender == Gender.male) { countMaleInformal = countMaleInformal + 1;}
	                if (employmentStatus == Employment.Searching && gender == Gender.female) { countFemaleSearching = countFemaleSearching + 1;}
	                if (employmentStatus == Employment.Searching && gender == Gender.male) { countMaleSearching = countMaleSearching + 1;}
	                if (employmentStatus == Employment.Inactive && gender == Gender.female) { countFemaleInactive = countFemaleInactive + 1;}
	                if (employmentStatus == Employment.Inactive && gender == Gender.male) { countMaleInactive = countMaleInactive + 1;}
	                             
	                if (gender == Gender.female) { countFemale = countFemale + 1;}
	                if (gender == Gender.male) { countMale = countMale + 1;}
	                if (isSchoolEligible) { countStudentEligible = countStudentEligible + 1;}
	                if (residentAge < 18) { countChildren = countChildren + 1;}
	                if (residentAge >= 18) { countAdults = countAdults + 1;}
	                if (residentAge <= 5) { countYoungChildren = countYoungChildren + 1;}
	                countResidents = countResidents + 1;
	                	                
	        	}
	        	//if no one in the household is employed, then move into min rent home (adjust expected household income for this)
	        	if (expectedHouseholdIncome == 0) {	        		
	        		expectedHouseholdIncome = minAffordability;
	        	}
	        
		        Home residingHouse = findHometoPlaceHousehold(kibera, hh, hhEthnicity, expectedHouseholdIncome);
		        
		        hh.setHome(residingHouse);
		        residingHouse.setHousehold(hh);
                        
                        hh.removedStudentFromSchool(false);
		     
                        hh.setAdjustedHouseholdExpenditures(Household.AdjustedHouseholdExpenditures.Same);
		        
		        //set initial position of residents in household
		        
		        for (int j = 0; j < hh.getHouseholdMembers().size(); j++) {
		 
		        	Resident r = (Resident) hh.getHouseholdMembers().get(j);        	
		        	Parcel initialPosition = residingHouse.getStructure().getParcel();
		        	r.setPosition(initialPosition);
		        	
		        	r.setGoalLocation(hh.getHome().getStructure().getParcel());
		        			        			        	
		        	double jitterX = kibera.random.nextDouble();
		    		double jitterY = kibera.random.nextDouble();
		        	
		        	kibera.world.setObjectLocation(r, new Double2D(initialPosition.getXLocation() + jitterX, initialPosition.getYLocation() + jitterY));
		        	kibera.schedule.scheduleRepeating(r);
		        }
		        
		        kibera.schedule.scheduleRepeating(hh);
		        		     
	        	//create edges between residents in the same household
	        	//addEdgestoHouseholdMembers(hh, kibera);        	
	        	//addEdgestoResidentsOfSameStructure(hh.getHome().getStructure(), kibera);
	        	
	        	i = i + householdSize;        
	          }
	        
	        System.out.println("total hh = " + totalhh);
	        System.out.println("searching = " + countSearching);
	        System.out.println("inactive = " + countInactive);
	        System.out.println("student eligible = " + countStudentEligible);
	        System.out.println("formal = " + countFormal);
	        System.out.println("informal = " + countInformal);
	        System.out.println("head of hh = " + countHeadofHH);
	        System.out.println("male = " + countMale);
	        System.out.println("female = " + countFemale);
	        System.out.println("adults = " + countAdults);
	        System.out.println("children = " + countChildren);
	        System.out.println("residents = " + countResidents);
	        System.out.println("female formal = " + countFemaleFormal);
	        System.out.println("female informal = " + countFemaleInformal);
	        System.out.println("female searching = " + countFemaleSearching);
	        System.out.println("female inactive = " + countFemaleInactive);
	        System.out.println("male formal = " + countMaleFormal);
	        System.out.println("male informal = " + countMaleInformal);
	        System.out.println("male searching = " + countMaleSearching);
	        System.out.println("male inactive = " + countMaleInactive);
	        System.out.println("young children = " + countYoungChildren);
     		 		
		}
		
	
	public static void addBusiness(Kibera kibera, Structure structure, Parcel parcel)
	{		
		kibera.allBusinessLocations.add(parcel);
		
		Business b = new Business(structure);
		structure.addBusinesses(b);
		b.setStructure(structure);
		
		int businessCapacity = 0;
		
		//Determine capacity of employees of business
		if (kibera.informalBusinessCapacity == 0) {
			//businessCapacity = kibera.random.nextInt(1);
			businessCapacity = 1;
		}
		else {
			businessCapacity = 1 + kibera.random.nextInt(kibera.informalBusinessCapacity);
		}
		
		b.setEmployeeCapacity(businessCapacity);
		
		kibera.businessGrid.setObjectLocation(structure, parcel.getLocation());
	}
	
	public static void addHomes(Kibera kibera, Structure structure, Parcel parcel) {		
		kibera.allHomeLocations.add(parcel);
		
		Home h = new Home(structure);
		kibera.homes.add(h);
		structure.addHome(h);
		h.setStructure(structure);
		
		//Determine the household expenditures related to each home
		
		//Determine the rent of the house
		h.setHouseRent(determineHouseholdRent(kibera));
		
		//Determine if house comes with running water, electricity, and/or sanitation
                double rnWater = kibera.random.nextDouble();
                double rnElectric = kibera.random.nextDouble();
                double rnSanitation = kibera.random.nextDouble();
    	
                boolean hasWater = false;
                boolean hasElectricity = false;
                boolean hasSanitation = false;
    	
                if (rnWater < kibera.getProbabilityWater()) hasWater = true;
                if (rnElectric < kibera.getProbabilityElectricity()) hasElectricity = true;
                if (rnSanitation < kibera.getProbabilitySanitation()) hasSanitation = true;
    		        	        	
                //determine household expenditures
                double monthlyElectricCost = 0;
		 	
                if (hasElectricity) {
			monthlyElectricCost = kibera.getMinElectricCost() + kibera.random.nextInt((int)kibera.getMaxElectricCost() - (int)kibera.getMinElectricCost());
		}
    		
		h.hasWater(hasWater);
		h.hasElectricity(hasElectricity);
		h.hasSanitation(hasSanitation);
		
		h.setExpectedElectricityCost(monthlyElectricCost);
		h.setExpectedRunningWaterCost(kibera.getWaterCost());
                
                kibera.allHomesAvailable.add(h);
		
		kibera.houseGrid.setObjectLocation(structure, parcel.getLocation());
		
	}
    
	private static String determineHouseholdEthnicity(Kibera kibera) {
		String householdEthnicity = null;
		
		double rn = kibera.random.nextDouble();
		double distCumulative = 0;
	
		for (int i = 0; i < kibera.getEthnicDistribution().length; i++) {
			distCumulative = distCumulative + kibera.getEthnicDistribution(i);
			
			if (rn <= distCumulative && householdEthnicity == null) householdEthnicity = kibera.getEthnicities(i);			
		}
		
		return householdEthnicity;
	}
	
	private static double determineHouseholdRent(Kibera kibera) {
		double householdRent = 0;
		
		double rn = kibera.random.nextDouble();
		double distCumulative = 0;
	
		for (int i = 0; i < kibera.getRentDistribution().length; i++) {
			distCumulative = distCumulative + kibera.getRentDistribution(i);
			
			if (rn <= distCumulative && householdRent == 0) {
				householdRent = kibera.getRent(i) + kibera.random.nextInt((int)(kibera.getRent(i)));
			}
		}
		
		return householdRent;
		
	}
	
	private static int determineResidentAge(Kibera kibera, boolean isHeadOfHousehold)
	{
		double rn = kibera.random.nextDouble();
        int age = 0;
        
        if (isHeadOfHousehold) {
        	age = 18 + kibera.random.nextInt(42); // 18-59      	
        }
            
        else {               
        	if (rn <= kibera.ageAdult) { age = 18 + kibera.random.nextInt(62); } // adult (over 18)
        	else if (rn <= (kibera.ageAdult + kibera.ageChildrenUnder6)) { age = kibera.random.nextInt(6); } // child under 6
            else { age = 6 + kibera.random.nextInt(12); }  // child (6-17)
        }
        
        return age;
	}
	
	private static Resident.Gender determineResidentGender(Kibera kibera) {
		if (kibera.random.nextDouble() < kibera.getMaleDistribution()) 
        	return Resident.Gender.male;
        else 
        	return Resident.Gender.female;   
	}
	
	private static Employment determineEmploymentStatus(int age, Resident.Gender gender, Kibera kibera) {
		double random = kibera.random.nextDouble();
		
		double femaleWorking = .41; // 41% of females are employed
		double femaleSearching = .096; // 9.6% of females are seeking work
		double femaleInactive = .431; //43.1% of females are economically inactive
		double femaleUnknown = .063;
		
		//adjust for all under 6 being inactive
		femaleInactive = femaleInactive - kibera.percentOfResidentsUnder6;
		
		//adjust so all categories sum to 100%
		double femaleTotal = femaleWorking + femaleSearching + femaleInactive + femaleUnknown;
		femaleWorking = femaleWorking / femaleTotal;
		femaleSearching = femaleSearching / femaleTotal;
		femaleInactive = femaleInactive / femaleTotal;
	
		double maleWorking = 0.6; // 60% of males are employed in formal market
		double maleSearching = .079; // 7.9% of males are seeking work
		double maleInactive = .271; // 27.1% of males are economically inactive
		double maleUnknown = .05;
		
		//adjust for all under 6 being inactive
		maleInactive = maleInactive - kibera.percentOfResidentsUnder6;
		
		//adjust so all categories sum to 100%
		double maleTotal = maleWorking + maleSearching + maleInactive + maleUnknown;
		maleWorking = maleWorking / maleTotal;
		maleSearching = maleSearching / maleTotal;
		maleInactive = maleInactive / maleTotal;
	
		double femaleInformal = femaleWorking * kibera.getInformalityIndex();
		double femaleFormal = femaleWorking - femaleInformal;
		
		double maleInformal = maleWorking * kibera.getInformalityIndex();
		double maleFormal = maleWorking - maleInformal;
		
		//too young to work or go to school, or if school age will search for school first
		if (age <= 18) {
			return Employment.Inactive;
		}
						
		else if (gender == Resident.Gender.female) {
			if (random < femaleFormal) { return Employment.Formal; }
			else if (random < (femaleFormal + femaleInformal)) { return Employment.Informal; }
			else if (random < (femaleFormal + femaleInformal + femaleSearching)) { return Employment.Searching; }
			else if (random < (femaleFormal + femaleInformal + femaleSearching + femaleInactive)) { return Employment.Inactive; }
			else { return Employment.Inactive; } //the employment status of 6.3% of females is unknown	
		}
		
		else { //if age > 5 and the resident is male
			if (random < maleFormal) { return Employment.Formal; }
			else if (random < (maleFormal + maleInformal)) { return Employment.Informal; }
			else if (random < (maleFormal + maleInformal + maleSearching)) { return Employment.Searching; }
			else if (random < (maleFormal + maleInformal + maleSearching + maleInactive)) { return Employment.Inactive; }
			else { return Employment.Inactive; } //the employment status of 5% of males is unknown	
		}
			
		//8.5% of men over 18 have no occupation (IFRA-Keyobs Field Survey, 2009)
		//45% of employed are self-employed or get work on a day-day basis
		//in africa, informal sector employs 60% of urban labor force, pp. 103 (UN, Challenge of Slums)		
		
	}
	
	private static boolean determineStudentStatus(int age, Resident.Employment employmentStatus, Kibera kibera) {
		
		//approximately 23% of youth (ages 3-18) go to school (based on the average enrollment of schools
		//in kibera and the total population of children
		
		//remove this, students will search for school that hasn't met capacity in the action sequence object
		
		if (age >= 3 && age <= 18) { 
			//if ( employmentStatus == Employment.Formal || employmentStatus == Employment.Informal) {
			//	return false; 
			//}
			//else { return true; }	
			return true;
		}
		else { return false; }		
	}
	
	
	private static void addResidents(Kibera kibera, int residentID, Household hh, String ethnicity, int age, Resident.Gender gender, Resident.Religion religion, boolean isHeadOfHousehold, Resident.Employment employmentStatus, boolean isSchoolEligible, double income) {    	
		Resident r = new Resident(hh);
	
		kibera.residents.add(r);
		
		r.setHousehold(hh);
		hh.addHouseholdMembers(r);
		
		if (employmentStatus == Employment.Formal || employmentStatus == Employment.Informal) {
			isSchoolEligible = false;
		}
		
		r.setResidentID(residentID);
                r.setAge(age);       
                r.gender = gender;
		r.setEthnicity(ethnicity);	
		r.isHeadOfHousehold(isHeadOfHousehold);
		r.currentEmploymentStatus = employmentStatus;
		r.isSchoolEligible(isSchoolEligible);
		
		
		r.setReligion(religion);
		r.setCurrentIdentity(Identity.Domestic_Activities);
		r.heardRumor(false);
		r.isLaidOff(false);
                r.leftSchool(false);
                r.attendedReligiousFacility(false);
                r.changedGoal(true);
                r.isInitialRebel(false);
                
                if (kibera.uniformAggressionRate) {
                    r.setAggressionRate(kibera.getAggressionRate());
                }
                else {
                    r.setAggressionRate(kibera.random.nextDouble());
                }
                
                r.setEnergy(100);
		
		//Give each resident in formal or informal sector a salary
		r.setResidentIncome(income);
		
		//add each resident to the network of residents
		kibera.socialNetwork.addNode(r);
	
	}
	
	private static void addEdgestoHouseholdMembers(Household hh, Kibera kibera) {
		
		//loop through each household, link residents in the same household together
		Bag family = new Bag();
		family = hh.getHouseholdMembers();
		int familySize = family.size();
				
		double edgeValue = 1;
		
		int i = 0;
		int j = 0;
		
		for (i = 0; i < familySize; i++) {
			for (j = 0; j < familySize; j++) {
				if (i != j) { 
					Edge e = new Edge(family.objs[i], family.objs[j], edgeValue);
					kibera.socialNetwork.addEdge(e); 
					
				}
			}
		}
	}
	
	private static void addEdgestoResidentsOfSameStructure(Structure s, Kibera kibera) {
		Bag hhInStructure = new Bag();
		Bag housesInStructure = new Bag();
		housesInStructure = s.getHomes();
	
		Bag residentsInStructure = new Bag();
		
		int numhouses = housesInStructure.size();
		
		for (int j = 0; j < numhouses; j++) {
			Household hh = ((Home) housesInStructure.get(j)).getHousehold();
			if (hh != null) {
				hhInStructure.add(hh);
			}
		}
		
		int numhh = hhInStructure.size();
		
		double edgeValue = 1;
		
		for (int i = 0; i < numhh; i++) {
			Household hh = (Household)hhInStructure.get(i);
			Bag residentsInhh = new Bag();
			residentsInhh = hh.getHouseholdMembers();
			residentsInStructure.addAll(residentsInhh);
		}
		
		int numResidents = residentsInStructure.size();
		
		for(int i = 0; i < numResidents; i++) {
			for(int j = 0; j < numResidents; j++) {
				Edge e = new Edge(residentsInStructure.objs[i], residentsInStructure.objs[j], edgeValue);
				//if an edge does not yet exist between the two residents, create one
				if (e.getWeight() == 0) { 
					kibera.socialNetwork.addEdge(e);
				}
			}
		}
		
	}
	
	private static void addEdgestoEthnicGroups(Kibera kibera) {

            int i = 0;
            int j = 0;

            Bag nodes = kibera.socialNetwork.getAllNodes();
            int numNodes = kibera.socialNetwork.getAllNodes().size();
            double edgeValue = 1;

            for (i = 0; i < numNodes; i++) {
                Resident r1 = (Resident) nodes.get(i);
                for (j = 0; j < numNodes; j++) {
                    Resident r2 = (Resident) nodes.get(j);
                    if ( r1 != r2 && r1.getEthnicity() == r2.getEthnicity() ) {
                            Edge e = new Edge(r1, r2, edgeValue);
                            kibera.socialNetwork.addEdge(r1, r2, edgeValue);
                    }
                }
            }				
	}
	
	
	private static Home findHometoPlaceHousehold(Kibera kibera, Household hh, String hhEthnicity, double householdIncome) {
            
            int i = 0;
            int j = 0;
            IntBag neighborsX = new IntBag(9);
            IntBag neighborsY = new IntBag(9);

            Home home = null;

            //first check if there are any homes available that I can afford
            //if not, I will pick a home with my ethnic preference that I cannot yet afford (income will be adjusted to attempt and meet the expenses later in simulation)
            Bag allAvailableAffordableHomes = new Bag();

            Bag allAvailableSameEthnicity = new Bag(); //Available home near a neighbor of my same ethnicity
            Bag availableNotAffordableButMeetsEthnicDistribution = new Bag();


            //place all homes that I can afford and still available in a bag
            for (int c = 0; c < kibera.allHomesAvailable.numObjs; c++) {
                 if ((householdIncome * kibera.getPercentIncomeforRent()) < ((Home) kibera.homes.objs[c]).getTotalExpectedHousingCost()) {
                     allAvailableAffordableHomes.add((Home) kibera.homes.objs[c]);
                 }
            }

            //if your the first household, randomly select a structure
            if (kibera.households.numObjs == 1) {

                j = kibera.random.nextInt(kibera.homes.numObjs);

                while (((Home) kibera.homes.objs[j]).isHomeOccupied(kibera) && (householdIncome * kibera.getPercentIncomeforRent()) < ((Home) kibera.homes.objs[j]).getTotalExpectedHousingCost()) {
                        j = kibera.random.nextInt(kibera.homes.numObjs);			
                }

                home = (Home) kibera.homes.objs[j];
            }


            //find first household that has my ethnicity	
            else {

                Bag allSameEthnicity = new Bag(); //Households with my same ethnicity

                if (hhEthnicity == "kikuyu") { allSameEthnicity.addAll(kibera.kikuyu); }
                else if (hhEthnicity == "luhya") { allSameEthnicity.addAll(kibera.luhya); }
                else if (hhEthnicity == "luo") { allSameEthnicity.addAll(kibera.luo); }
                else if (hhEthnicity == "kalinjin") { allSameEthnicity.addAll(kibera.kalinjin); }
                else if (hhEthnicity == "kamba") { allSameEthnicity.addAll(kibera.kamba); }
                else if (hhEthnicity == "kisii") { allSameEthnicity.addAll(kibera.kisii); }
                else if (hhEthnicity == "meru") { allSameEthnicity.addAll(kibera.meru); }
                else if (hhEthnicity == "mijikenda") { allSameEthnicity.addAll(kibera.mijikenda); }
                else if (hhEthnicity == "maasai") { allSameEthnicity.addAll(kibera.maasai); }
                else if (hhEthnicity == "turkana") { allSameEthnicity.addAll(kibera.turkana); }
                else if (hhEthnicity == "embu") { allSameEthnicity.addAll(kibera.embu); }
                else if (hhEthnicity == "other") { allSameEthnicity.addAll(kibera.other); }


                //if I do not have any preference for living near like neighbors (i.e. preference = 0), find first home I can afford
                if (kibera.preferenceforLivingNearLikeNeighbors == 0) {
                    Bag availableAffordableHomes = new Bag();

                    for(int b = 0; b < kibera.allHomesAvailable.numObjs; b++) {
                        Home house = (Home) kibera.allHomesAvailable.get(b);
                        double expectedHomeCosts = house.getTotalExpectedHousingCost();
                        double homeAffordability = householdIncome * kibera.getPercentIncomeforRent();

                        if (!house.isHomeOccupied(kibera) && (homeAffordability >= expectedHomeCosts)) { 
                            availableAffordableHomes.add(house); 
                        }
                    }

                    if (!availableAffordableHomes.isEmpty()) {
                        int c = kibera.random.nextInt(availableAffordableHomes.size());
                        Home house = (Home) kibera.allHomesAvailable.get(c);
                        home = house;
                    }

                    else {
                        int c = kibera.random.nextInt(kibera.allHomesAvailable.size());
                        Home house = (Home) kibera.allHomesAvailable.get(c);
                        home = house;    
                    }

                }


                //if there are other households in the environment with the same ethnicity and I prefer to live near like neighbors
                else if (allSameEthnicity.size() > 0) {
                    
                    //pick a random household of same ethnicity, if have picked all and still don't have a match, move on (home will equal null)
                    Bag notSearchedSameEthnicity = new Bag(); //store the households of same ethnicity that we have not searched yet
                    notSearchedSameEthnicity.addAll(allSameEthnicity);                                     
                   
                    while (!notSearchedSameEthnicity.isEmpty() && home == null) {
                        if (home != null) { break; }
                    
                        int rn = kibera.random.nextInt(notSearchedSameEthnicity.size());                    

                        Household randomHH = (Household) notSearchedSameEthnicity.get(rn);
                        Home randomHome = randomHH.getHome();

                        int jitterX = kibera.random.nextInt(5);
                        int jitterY = kibera.random.nextInt(5);

                        int x = randomHome.getStructure().getParcel().getLocation().x + jitterX;
                        int y = randomHome.getStructure().getParcel().getLocation().y + jitterY;

                        //find available parcels/structures within neighborhood
                        // get all the places I can go.  This will be slow as we have to rely on grabbing neighbors.
                        kibera.landGrid.getNeighborsMaxDistance(x,y,kibera.neighborhood,false,neighborsX,neighborsY);

                        int len = neighborsX.size();
                        boolean meetsEthnicityPreference = false;
                        
                        Bag availableAffordableHomes = new Bag();
                        Bag availableHomes = new Bag();

                        for(int a = 0; a < len; a++) {

                            if (home != null) { break; }

                            int neighborX = neighborsX.get(a);
                            int neighborY = neighborsY.get(a);

                            Parcel neighborParcel = (Parcel)kibera.landGrid.get(neighborX, neighborY);
                            int id = neighborParcel.getParcelID();

                            double numNeighbors = 1; //include randomhh home
                            double numNeighborsSameEthnicity = 1; //include randomhh home
                            double ethnicDistribution = 0.0;

                            if (id > 0) {
                                int z = neighborParcel.getStructure().size();

                                

                                for(int h = 0; h < neighborParcel.getStructure().size(); h++) {
                                    Structure s = (Structure) neighborParcel.getStructure().get(h);

                                    int u = s.getHomes().size();

                                    for(int l = 0; l < s.getHomes().size(); l++) {
                                        Home house = (Home) s.getHomes().get(l);
                                        //add empty homes to a bag
                                        double expectedHomeCosts = house.getTotalExpectedHousingCost();
                                        double homeAffordability = householdIncome * kibera.getPercentIncomeforRent();

                                        numNeighbors = numNeighbors + 1;

                                        if (house.isHomeOccupied(kibera)) {
                                            //numNeighbors = numNeighbors + 1;
                                            if (house.getHousehold().getHouseholdEthnicity() == hhEthnicity) {
                                                numNeighborsSameEthnicity = numNeighborsSameEthnicity + 1;
                                            }
                                        }

                                        if (!house.isHomeOccupied(kibera) && (homeAffordability >= expectedHomeCosts)) { 
                                            availableAffordableHomes.add(house); 
                                        }

                                        if (!house.isHomeOccupied(kibera)) {
                                            availableHomes.add(house);
                                            allAvailableSameEthnicity.add(house);
                                        }
                                    }

                                    
                                    ethnicDistribution = numNeighborsSameEthnicity / numNeighbors;

                                    if (ethnicDistribution >= kibera.preferenceforLivingNearLikeNeighbors) {
                                        meetsEthnicityPreference = true;
                                   }                                                                                                                                  
                                }				        				        		
                            }			        	
                        }
                        
                        //If this household has no surrounding available homes, remove them from the bag as there is no need to search around this household again in the futre
                        if (availableHomes.isEmpty()) {

                            if (hhEthnicity == "kikuyu") { kibera.kikuyu.remove(randomHH); }
                            else if (hhEthnicity == "luhya") { kibera.luhya.remove(randomHH); }
                            else if (hhEthnicity == "luo") { kibera.luo.remove(randomHH); }
                            else if (hhEthnicity == "kalinjin") { kibera.kalinjin.remove(randomHH); }
                            else if (hhEthnicity == "kamba") { kibera.kamba.remove(randomHH); }
                            else if (hhEthnicity == "kisii") { kibera.kisii.remove(randomHH); }
                            else if (hhEthnicity == "meru") { kibera.meru.remove(randomHH); }
                            else if (hhEthnicity == "mijikenda") { kibera.mijikenda.remove(randomHH); }
                            else if (hhEthnicity == "maasai") { kibera.maasai.remove(randomHH); }
                            else if (hhEthnicity == "turkana") { kibera.turkana.remove(randomHH); }
                            else if (hhEthnicity == "embu") { kibera.embu.remove(randomHH); }
                            else { kibera.other.remove(randomHH); }
                        }
                        
                        
                        if (meetsEthnicityPreference) {
                        
                            //the ethnic distribution is adequate, so lets check if an affordable home exists in this neighborhood
                            if (!availableHomes.isEmpty()) {

                                //no affordable homes exists but happy with ethnic distribution
                                if (availableAffordableHomes.isEmpty()) {

                                    availableNotAffordableButMeetsEthnicDistribution.addAll(availableHomes);
                                    break;

                                }

                                else {

                                    int b = kibera.random.nextInt(availableAffordableHomes.size());
                                    home = (Home) availableAffordableHomes.objs[b];
                                    break;
                                }
                            }
                        }
                        notSearchedSameEthnicity.remove(randomHH);
                        
                        availableHomes.clear();                       
                        availableAffordableHomes.clear();
                    }
                    
                    
                }

                //no one of my ethnicity lives on the landscape yet, so randomly pick a home that I can afford
                else {

                    //if there are no affordable homes available, then randomly pick an available home
                    if (allAvailableAffordableHomes.isEmpty()) {
                        int b = kibera.random.nextInt(kibera.allHomesAvailable.numObjs);
                        home = (Home) kibera.allHomesAvailable.objs[b];
                    }

                    //other randomly pick a home that is affordable
                    else {
                        int b = kibera.random.nextInt(allAvailableAffordableHomes.numObjs);
                        home = (Home) allAvailableAffordableHomes.objs[b];
                    }
                }	
            }

            //there are no households with my ethnicity preference that are affordable
            if (home == null) {

                Bag availableAffordableHomes = new Bag();

                //check to see if any home that I can afford are still available
                for (int c = 0; c < kibera.allHomesAvailable.numObjs; c++) {
                     if ((householdIncome * kibera.getPercentIncomeforRent()) < ((Home) kibera.homes.objs[c]).getTotalExpectedHousingCost()) {
                         availableAffordableHomes.add((Home) kibera.homes.objs[c]);
                     }
                }

                //first see if there were homes that fit my ethnic distribution preference, but were not affordable
                if (!availableNotAffordableButMeetsEthnicDistribution.isEmpty()) {
                    int b = kibera.random.nextInt(availableNotAffordableButMeetsEthnicDistribution.size());
                    home = (Home) availableNotAffordableButMeetsEthnicDistribution.objs[b];

                }


                //if there are no affordable homes available but there are home of the same ethnicity, then randomly pick an available home near a neighbor of same ethnicity
                else if (availableAffordableHomes.isEmpty() && !allAvailableSameEthnicity.isEmpty()) {

                    int b = kibera.random.nextInt(allAvailableSameEthnicity.size());                            
                    Home house = (Home) allAvailableSameEthnicity.get(b);                         
                    home = house;

                }

                //other randomly pick a home that is affordable
                else if (!availableAffordableHomes.isEmpty()) {
                    int b = kibera.random.nextInt(availableAffordableHomes.numObjs);
                    home = (Home) availableAffordableHomes.objs[b];
                }

                //else, if there are no affordable homes and no homes near someone of my ethnicity, randomly pick an available home
                else {
                    int b = kibera.random.nextInt(kibera.allHomesAvailable.numObjs);
                    home = (Home) kibera.allHomesAvailable.objs[b];
                }

            }

            //Add household to correct ethnicity bag
            if (hhEthnicity == "kikuyu") { kibera.kikuyu.add(hh); }
            else if (hhEthnicity == "luhya") { kibera.luhya.add(hh); }
            else if (hhEthnicity == "luo") { kibera.luo.add(hh); }
            else if (hhEthnicity == "kalinjin") { kibera.kalinjin.add(hh); }
            else if (hhEthnicity == "kamba") { kibera.kamba.add(hh); }
            else if (hhEthnicity == "kisii") { kibera.kisii.add(hh); }
            else if (hhEthnicity == "meru") { kibera.meru.add(hh); }
            else if (hhEthnicity == "mijikenda") { kibera.mijikenda.add(hh); }
            else if (hhEthnicity == "maasai") { kibera.maasai.add(hh); }
            else if (hhEthnicity == "turkana") { kibera.turkana.add(hh); }
            else if (hhEthnicity == "embu") { kibera.embu.add(hh); }
            else { kibera.other.add(hh); }
            
            kibera.allHomesAvailable.remove(home);

            return home;
    }


    /** An initial number of agents hear the rumor */
    private static void rumorPropogation(Kibera kibera) {
            //pick a random resident(s) to hear the rumor
            int totalResidents = kibera.residents.numObjs;		
            int num = kibera.getNumResidentsHearRumor();
            
            double numRebel = kibera.proportionInitialResidentsRebel * (double) kibera.getNumResidentsHearRumor();
            numRebel = (int) numRebel;
           
            int i = 0;
            
            while (i < num) {
                    int ranResident = kibera.random.nextInt(totalResidents);		
                    Resident r = (Resident) kibera.residents.get(ranResident);
                    r.heardRumor(true);
                    
                    if (i<numRebel) {
                        //can't rebel if under 6, find next resident
                        if (r.getAge() < 6) {
                            if (numRebel <= num) {
                                numRebel = numRebel + 1;
                            }
                        }
                        else {
                            r.setCurrentGoal(Resident.Goal.Rebel);
                            r.isInitialRebel(true);
                        }
                    }
                    
                    i++;		
            }

	}
	
	private static void createRoads(String roadFile, Kibera kibera) {
		try {
	        // now read road grid
            BufferedReader roads = new BufferedReader(new FileReader(roadFile));
			String line;

			// first read the dimensions
			line = roads.readLine(); // read line for width
			String[] tokens = line.split("\\s+");
			int width = Integer.parseInt(tokens[1]);
			gridWidth = width;

			line = roads.readLine();
			tokens = line.split("\\s+");
			int height = Integer.parseInt(tokens[1]);
			gridHeight = height;

            // skip the irrelevant metadata
            for (int i = 0; i < 4; i++) {
                line = roads.readLine();
            }
            
            for (int curr_row = 0; curr_row < height; ++curr_row) {
                line = roads.readLine();
                
	            tokens = line.split("\\s+");

                for (int curr_col = 0; curr_col < width; ++curr_col) {                    
                	int roadID = Integer.parseInt(tokens[curr_col]);
                	
                    if (roadID >= 0) {
                    	Parcel parcel = (Parcel) kibera.landGrid.get(curr_col, curr_row);
                    	parcel.setRoadID(roadID);
                        kibera.roadGrid.set(curr_col, curr_row, roadID);
                        //kibera.landGrid.set(curr_col, curr_row, roadID);
                    }                   					
                }
            }
                
            //Import road shapefile
            Bag roadImporter = new Bag();
            roadImporter.add("Type");
               
            File file=new File("data/Road_Export.shp");
            URL roadShapeUL = file.toURL();
               
            ShapeFileImporter.read(roadShapeUL, kibera.roadLinks, roadImporter);
               
            extractFromRoadLinks(kibera.roadLinks, kibera); //construct a newtork of roads
               
            kibera.closestNodes = setupNearestNodes(kibera);

			roads.close();
		}
		catch (IOException ex) {
			Logger.getLogger(KiberaBuilder.class.getName()).log(Level.SEVERE, null, ex);
		}
	}
	
	///  raod network methods from haiti project
    static void extractFromRoadLinks(GeomVectorField roadLinks, Kibera kibera) {
        Bag geoms = roadLinks.getGeometries();
        Envelope e = roadLinks.getMBR();
        double xmin = e.getMinX(), ymin = e.getMinY(), xmax = e.getMaxX(), ymax = e.getMaxY();
        int xcols = gridWidth - 1, ycols = gridHeight - 1;
          
        // extract each edge
        for (Object o : geoms) {
            MasonGeometry gm = (MasonGeometry) o;
            if (gm.getGeometry() instanceof LineString) {
                readLineString((LineString) gm.getGeometry(), xcols, ycols, xmin, ymin, xmax, ymax, kibera);
            } else if (gm.getGeometry() instanceof MultiLineString) {
                MultiLineString mls = (MultiLineString) gm.getGeometry();
                for (int i = 0; i < mls.getNumGeometries(); i++) {
                    readLineString((LineString) mls.getGeometryN(i), xcols, ycols, xmin, ymin, xmax, ymax, kibera);
                }
            }
        }
    }
    
    /**
     * Converts an individual linestring into a series of links and nodes in the
     * network
     * int width, int height, Dadaab dadaab
     * @param geometry
     * @param xcols - number of columns in the field
     * @param ycols - number of rows in the field
     * @param xmin - minimum x value in shapefile
     * @param ymin - minimum y value in shapefile
     * @param xmax - maximum x value in shapefile
     * @param ymax - maximum y value in shapefile
     */
    static void readLineString(LineString geometry, int xcols, int ycols, double xmin,
            double ymin, double xmax, double ymax, Kibera kibera) {

        CoordinateSequence cs = geometry.getCoordinateSequence();

        // iterate over each pair of coordinates and establish a link between
        // them
        Node oldNode = null; // used to keep track of the last node referenced
        for (int i = 0; i < cs.size(); i++) {

            // calculate the location of the node in question
            double x = cs.getX(i), y = cs.getY(i);
            int xint = (int) Math.floor(xcols * (x - xmin) / (xmax - xmin)), yint = (int) (ycols - Math.floor(ycols * (y - ymin) / (ymax - ymin))); // REMEMBER TO FLIP THE Y VALUE

            if (xint >= gridWidth) {
                continue;
            } else if (yint >= gridHeight) {
                continue;
            }

            // find that node or establish it if it doesn't yet exist
            Bag ns = kibera.nodes.getObjectsAtLocation(xint, yint);
            Node n;
            if (ns == null) {
            	
            	Int2D parcelLocation = new Int2D((xint), yint);
                n = new Node(new Parcel(parcelLocation));
                kibera.nodes.setObjectLocation(n, xint, yint);
            } else {
                n = (Node) ns.get(0);
            }

            if (oldNode == n) // don't link a node to itself
            {
                continue;
            }

            // attach the node to the previous node in the chain (or continue if
            // this is the first node in the chain of links)

            if (i == 0) { // can't connect previous link to anything
                oldNode = n; // save this node for reference in the next link
                continue;
            }
           
            int weight = (int) n.location.distanceTo(oldNode.location); // weight is just
            // distance

            // create the new link and save it
            Edge e = new Edge(oldNode, n, weight);
            kibera.roadNetwork.addEdge(e);
            oldNode.links.add(e);
            n.links.add(e);

            oldNode = n; // save this node for reference in the next link
        }
    }

    
    static class Node {

        Parcel location;
        ArrayList<Edge> links;

        public Node(Parcel l) {
            location = l;
            links = new ArrayList<Edge>();
        }
    }

    /**
     * Used to find the nearest node for each space
     * 
     */
    static class Crawler {

        Node node;
        Parcel location;

        public Crawler(Node n, Parcel l) {
            node = n;
            location = l;
        }
    }

    /**
     * Calculate the nodes nearest to each location and store the information
     * 
     * @param closestNodes
     *            - the field to populate
     */
    static ObjectGrid2D setupNearestNodes(Kibera kibera) {
         
        ObjectGrid2D closestNodes = new ObjectGrid2D(gridWidth, gridHeight);
        ArrayList<Crawler> crawlers = new ArrayList<Crawler>();

        for (Object o : kibera.roadNetwork.allNodes) {
            Node n = (Node) o;
            Crawler c = new Crawler(n, n.location);
            crawlers.add(c);
        }

        // while there is unexplored space, continue!
        while (crawlers.size() > 0) {
            ArrayList<Crawler> nextGeneration = new ArrayList<Crawler>();

            // randomize the order in which cralwers are considered
            int size = crawlers.size();
            
            for (int i = 0; i < size; i++) {

                // randomly pick a remaining crawler
                int index = kibera.random.nextInt(crawlers.size());
                Crawler c = crawlers.remove(index);
              
                // check if the location has already been claimed
                Node n = (Node) closestNodes.get(c.location.getXLocation(), c.location.getYLocation());
                        

                if (n == null) { // found something new! Mark it and reproduce

                    // set it
                    closestNodes.set(c.location.getXLocation(), c.location.getYLocation(), c.node);

                    // reproduce
                    Bag neighbors = new Bag();

                    kibera.landGrid.getNeighborsHamiltonianDistance(c.location.getXLocation(), c.location.getYLocation(),
                            1, false, neighbors, null, null);

                    for (Object o : neighbors) {
                        Parcel l = (Parcel) o;
                        if (l == c.location) {
                            continue;
                        }
                        Crawler newc = new Crawler(c.node, l);
                        nextGeneration.add(newc);
                    }
                }
                // otherwise just die
            }
            crawlers = nextGeneration;
        }
        return closestNodes;
    }
    
	
	private static void createGrids(Kibera kibera, int width, int height)
	{
		kibera.landGrid = new ObjectGrid2D(width, height);
		kibera.world = new Continuous2D(0.1, width, height);
		kibera.facilityGrid = new SparseGrid2D(width, height);
		kibera.healthFacilityGrid = new SparseGrid2D(width, height);
		kibera.religiousFacilityGrid = new SparseGrid2D(width, height);
		kibera.waterGrid = new SparseGrid2D(width, height);
		kibera.sanitationGrid = new SparseGrid2D(width, height);
		kibera.businessGrid = new SparseGrid2D(width, height);
		kibera.houseGrid = new SparseGrid2D(width, height);
		
		kibera.roadGrid = new IntGrid2D(width, height);
        kibera.nodes = new SparseGrid2D(width, height);
        kibera.closestNodes = new ObjectGrid2D(width, height);
        kibera.roadLinks =  new GeomVectorField(width, height);
	}
	
}
