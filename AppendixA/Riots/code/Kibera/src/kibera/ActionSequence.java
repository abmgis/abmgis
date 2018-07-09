package kibera;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.TreeMap;

import kibera.Resident.Employment;
import kibera.Resident.Goal;
import kibera.Resident.Religion;
import sim.field.network.Edge;
import sim.util.Bag;
import sim.util.Double2D;

public class ActionSequence {

	/*
	 * Activities:
	 * Stay home
	 * Go to school
	 * Go to work -- certain % go to work within slum, if so, go to nearest business, otherwise leave slum to go to work
	 * Other - Go to market, health facility, church
	 * Go visit friends/relatives
	 * Go to latrine
	 * 
	 * each activity is related with location. agent go to each activity 
	 * 
	 */
       
    public static Parcel bestActivityLocation(Resident resident, Parcel position, Goal goal, Kibera kibera) {
    	Parcel home = resident.getHousehold().getHome().getStructure().getParcel();
    	
    	if (goal == Goal.Stay_Home) { return home; }   
    	
    	else if (goal == Goal.Get_An_Education) { 
    		//assign school on the parcel to the resident, so that resident returns to same school each day
    		//if there are multiple schools on the same parcel, randomly pick a school to assign to the resident
    		
    		//if student has already been assigned a school, then keep going to that school
    		if (resident.getMySchool() != null) {
    			Parcel p = resident.getMySchool().getStructure().getParcel();
    			return p;
    		}
    		
    		else { //otherwise, find an available school for the student to attend
	    		Parcel p = bestLocation (home, findSchools(resident, kibera),kibera);
	    		Bag schools = new Bag();
	    		
	    		for(int i = 0; i < p.getStructure().size(); i++) {
	    			Structure s = p.getStructure().get(i);
	    			for (int j = 0; j < s.getSchools().size(); j++) {
	    				School school = s.getSchools().get(j);
	    				schools.add(school);
	    			}
	    		}
	    		
	    		int numSchools = schools.size();
	    		int pickSchool = kibera.random.nextInt(numSchools) + 1;
	    		for (int i = 1; i <= numSchools; i++) {
	    			if (i == pickSchool) {
	    				School mySchool = (School) schools.get(i-1);
	    				resident.setMySchool(mySchool);
	    				mySchool.addStudents(resident);
	    			}
	    		}
	    		
	    		return p;
    		}
    	
    	}
    	else if (goal == Goal.Find_Employment) { 
    		//if the resident has already been assigned a job, keeping going there   		
    		Parcel p = bestLocation (home, findPotentialEmployment(resident, kibera), kibera);
	    	Bag employers = new Bag();
	    		
	    	//If no parcel is found, a potential employer with availability was not found, this resident will stay home	    		
	    	if (p == null) { 
	    		p = resident.getHousehold().getHome().getStructure().getParcel();
	    		//resident.setCurrentGoal(Goal.Stay_Home);
	    		return p;
	    	}
	    	
	    	//otherwise find all potential employers on that parcel
	    	if (resident.currentEmploymentStatus == Employment.Formal) {
	    		for(int i = 0; i < p.getStructure().size(); i++) {
	    			Structure s = p.getStructure().get(i);
	    			for (int j = 0; j < s.getSchools().size(); j++) {
		    			School school = (School) s.getSchools().get(j);
		    			employers.add(school);
		    		}
		    		for (int j = 0; j < s.getHealthFacilities().size(); j++) {
		    			HealthFacility healthFacility = (HealthFacility) s.getHealthFacilities().get(j);
		    			employers.add(healthFacility);
		    		}
		    		for (int j = 0; j < s.getReligiousFacilities().size(); j++) {
		    			ReligiousFacility religiousFacility = (ReligiousFacility) s.getReligiousFacilities().get(j);
		    			employers.add(religiousFacility);
		    		}
	    		}
	    	}
	    	
	    	if (resident.currentEmploymentStatus == Employment.Informal) {
	    	   	for(int i = 0; i < p.getStructure().size(); i++) {
		    		Structure s = p.getStructure().get(i);
		    		for (int j = 0; j < s.getBusinesses().size(); j++) {
		    			Business business = (Business) s.getBusinesses().get(j);
		    			employers.add(business);
		    		}
	    	   	}
	    	}
                
                if (resident.currentEmploymentStatus == Employment.Searching) {
                    for(int i = 0; i < p.getStructure().size(); i++) {
	    			Structure s = p.getStructure().get(i);
	    			for (int j = 0; j < s.getSchools().size(); j++) {
		    			School school = (School) s.getSchools().get(j);
		    			employers.add(school);
		    		}
		    		for (int j = 0; j < s.getHealthFacilities().size(); j++) {
		    			HealthFacility healthFacility = (HealthFacility) s.getHealthFacilities().get(j);
		    			employers.add(healthFacility);
		    		}
		    		for (int j = 0; j < s.getReligiousFacilities().size(); j++) {
		    			ReligiousFacility religiousFacility = (ReligiousFacility) s.getReligiousFacilities().get(j);
		    			employers.add(religiousFacility);
		    		}
                                for (int j = 0; j < s.getBusinesses().size(); j++) {
		    			Business business = (Business) s.getBusinesses().get(j);
		    			employers.add(business);
		    		}
	    		}
                }
	    		    	
	    	//if no employers were found is because formal/informal employment was not found within kibera
	    	//this resident will work outside of the slum, but for model purposes they will stay home
	    	if (employers.isEmpty()) {
	    		employers.add(resident.getHousehold().getHome());
	    	}
	    	
	    	int numEmployers = employers.size();    	
	    	int pickEmployer = kibera.random.nextInt(numEmployers) + 1;
	    	
	    	for (int i = 1; i <= numEmployers; i++) {
	    	
	    		if (i == pickEmployer) {
	    			Object o = (Object) employers.get(i-1);
                                if (o instanceof Business) {
                                    Business myEmployer = (Business) employers.get(i-1);
                                    resident.setMyBusinessEmployer(myEmployer);
                                    myEmployer.addEmployee(resident);
	    			}
                                else if (o instanceof School) {
                                    School myEmployer = (School) employers.get(i-1);
                                    resident.setMySchoolEmployer(myEmployer);
                                    myEmployer.addEmployee(resident);
	    			}
                                else if (o instanceof HealthFacility) {
                                    HealthFacility myEmployer = (HealthFacility) employers.get(i-1);
                                    resident.setMyHealthFacilityEmployer(myEmployer);
                                    myEmployer.addEmployee(resident);
	    			}
                                else if (o instanceof ReligiousFacility ){ //else the employer is a religious facility
                                    ReligiousFacility myEmployer = (ReligiousFacility) employers.get(i-1);
                                    resident.setMyReligiousFacilityEmployer(myEmployer);
                                    myEmployer.addEmployee(resident);
	    			}
                                else {
                                    //found employment outside of kibera
                                }
	    			
	    		}
	    	}
	    	
    		if (resident.getCurrentEmploymentStatus() == Employment.Searching) {
    			if (resident.getMyBusinessEmployer() != null) {
    				resident.setCurrentEmploymentStatus(Employment.Informal);
    			}
    			else if (resident.getMyHealthFacilityEmployer() != null) {
    				resident.setCurrentEmploymentStatus(Employment.Formal);
    			}
    			else if (resident.getMyReligiousFacilityEmployer() != null) {
    				resident.setCurrentEmploymentStatus(Employment.Formal);
    			}
    			else if (resident.getMySchoolEmployer() != null) { //else the resident found a job at a school
    				resident.setCurrentEmploymentStatus(Employment.Formal);
    			}
    			else { //else the resident found employment outside of kibera
    				resident.setCurrentEmploymentStatus(Employment.Formal);
    			}
    			resident.setResidentIncome(WealthDistribution.determineIncome(resident.getCurrentEmploymentStatus(), kibera));
    		}
    		
    		//Resident found employment so is no longer laid off 
    		resident.isLaidOff(false);
    
        	return p; 
    	}
    	
    	else if (goal == Goal.Go_to_Work ) { //go to job that resident has been assigned to
    		
    		Parcel p = null;
    		if (resident.getMyBusinessEmployer() != null) {
                    p = resident.getMyBusinessEmployer().getStructure().getParcel();
    		}
    		else if (resident.getMyHealthFacilityEmployer() != null) {
                    p = resident.getMyHealthFacilityEmployer().getStructure().getParcel();
    		}
    		else if (resident.getMySchoolEmployer() != null) {
                    p = resident.getMySchoolEmployer().getStructure().getParcel();
    		}
    		else if (resident.getMyReligiousFacilityEmployer() != null) { //else resident is employed at religious facility
                    p = resident.getMyReligiousFacilityEmployer().getStructure().getParcel();
    		}
    		else { //resident works outside of slum, but for now just stays home
                    p = resident.getHousehold().getHome().getStructure().getParcel();
    		}
    		  		
    		return p; 
    	}
    	
    	else if (goal == Goal.Socialize) { 
    		return determineWhereToSociolize(resident, kibera); 
    	}
    	
    	else if (goal == Goal.Go_to_Church) { 
    		Bag churches = new Bag();
    		Bag mosques = new Bag();
    		
    		for (int i = 0; i < kibera.allReligiousFacilityLocations.size(); i++) {
    			//ReligiousFacility r = (ReligiousFacility) kibera.allReligiousFacilities.get(i);
    			Parcel p = (Parcel) kibera.allReligiousFacilityLocations.get(i);
    			
    			for(int j = 0; j < p.getStructure().size(); j++) {
    				Structure s = p.getStructure().get(j);
    				for(int k = 0; k < s.getReligiousFacilities().size(); k++) {
    					ReligiousFacility r = (ReligiousFacility) s.getReligiousFacilities().get(k);
    					if (r.getFacilityType() == 1) {
    	    				churches.add(p);
    	    			}
    	    			else if (r.getFacilityType() == 2) {
    	    				mosques.add(p);
    	    			}
    				}
    			}    			
    		}
    		
    		if (resident.getReligion() == Religion.Christian) {
    			return bestLocation(home, churches, kibera);
    		}
    		else {
    			return bestLocation(home, mosques, kibera);
    		}
    	}
    	
    	else if (goal == Goal.Get_Water) {
    		//go to water, wait in queue, add water amount to water in house, increase hh expenditures
    		Parcel p = bestLocation (home, kibera.allWaterPoints, kibera);
    		
    		double currentWaterLevel = resident.getHousehold().getRemainingWater();
    		
    		resident.getHousehold().setRemainingWater(currentWaterLevel + 20);
    		
    		//Add water to household expenditure
    		//resident.getHome().waterCost(kibera);
    		resident.getHousehold().getDailyWaterCost();
    		    		
    		return p;  		
    	}
    	
    	else if (goal == Goal.Rebel) {
    		//turn red

    		//the point where rebels will congregate
    		int xCenter = 170;
    		int yCenter = 100;
    		
    		int jitterX = kibera.random.nextInt(20);
			int jitterY = kibera.random.nextInt(20);
    		
    		Parcel parcel = (Parcel)kibera.landGrid.get(xCenter + jitterX, yCenter + jitterY);
   		   		
    		return parcel;
    	}
    		
    	
    	else { return position; }
    }
    
    private static Parcel bestLocation (Parcel parcel, Bag fieldBag, Kibera kibera) {
        Bag newLocation = new Bag();
    
        double bestScoreSoFar = Double.POSITIVE_INFINITY;
        for (int i = 0; i < fieldBag.numObjs; i++) {
            Parcel positionLocation = ((Parcel) fieldBag.objs[i]);

            double fScore = parcel.distanceTo(positionLocation);
            if (fScore > bestScoreSoFar) {
                continue;
            }

            if (fScore <= bestScoreSoFar) {
                bestScoreSoFar = fScore;
                newLocation.clear();
            }
            newLocation.add(positionLocation);
        }
        
        Parcel p = null;
        if (newLocation != null) {
            int winningIndex = 0;
            if (newLocation.numObjs >= 1) {
                winningIndex = kibera.random.nextInt(newLocation.numObjs);
            }

        p = (Parcel) newLocation.objs[winningIndex];

        }
        return p;
    }

    
    // Haiti project
    public static Parcel getNextTile(Kibera kibera, Parcel subgoal, Parcel position) {

    	//can we change this so agent can move in diagonal???
        
    	// move in which direction?
        int moveX = 0, moveY = 0;
 
        int dx = subgoal.getXLocation() - position.getXLocation();
        int dy = subgoal.getYLocation() - position.getYLocation();
        
        if (dx < 0) { moveX = -1; }     
        else if (dx > 0) { moveX = 1; }    
        
        if (dy < 0) { moveY = -1; }  
        else if (dy > 0) { moveY = 1; }

        // can either move in Y direction or X direction: see which is better
        Parcel xmove = ((Parcel) kibera.landGrid.field[position.getXLocation() + moveX][position.getYLocation()]);
        Parcel ymove = ((Parcel) kibera.landGrid.field[position.getXLocation()][position.getYLocation() + moveY]);

        boolean xmoveToRoad = ((Integer) kibera.roadGrid.get(xmove.getXLocation(), xmove.getYLocation())) > 0;       
        boolean ymoveToRoad = ((Integer) kibera.roadGrid.get(ymove.getXLocation(), ymove.getYLocation())) > 0;

        // we are ON the subgoal, so don't move at all!       
        if (moveX == 0 && moveY == 0) { return xmove; } // both are the same result, so just return the xmove (which is identical)      
        else if (moveX == 0) { return ymove; } // this means that moving in the x direction is not a valid move: it's +0                  
        else if (moveY == 0) { return xmove;} // this means that moving in the y direction is not a valid move: it's +0                  
        else if (xmoveToRoad == ymoveToRoad) { //equally good moves: pick randomly between them
            if (kibera.random.nextBoolean()) { return xmove; }
            else { return ymove; }
        }
        
        else if (xmoveToRoad && moveX != 0) { return xmove; } // x is a road: pick it        	      
        else if (ymoveToRoad && moveY != 0) { return ymove; } // y is a road: pick it                    
        else if (moveX != 0) { return xmove; } // move in the better direction       
        else if (moveY != 0) { return ymove; } // yes                  
        else { return ymove; } // no justification
    }
    
	public static Parcel determineWhereToSociolize(Resident me, Kibera kibera) {
		// Go through my friends (colleagues, co-workers, family) and determine how much I want 
		// to be near them
		//force is based on weight of edge between the two residents as well as the distance between
		//their home locations
		
		//grab all residents linked to myself (with the exception of those living in the same household as myself)
		//determine the weight of the link and the physical distance of each pair
		//calculate overall likelihood of socializing with another resident based on weight and distance
		//determine residents with highest likelihoods
		//randomly select a resident of the highest likelihoods
		
		Bag myFriends = new Bag(kibera.socialNetwork.getEdgesOut(me));
		double sumWeight = 0;
		double sumDistance = 0;
		Resident socializeFriend = null; //this is the friend I will socialize with
		
		//remove anyone living in the same parcel
		for(int i = 0; i < myFriends.size(); i++) {
			Edge e = (Edge)(myFriends.get(i));
			//Get the resident linked to me
			Resident friend = (Resident) e.getOtherNode(me);
			if (friend.getHousehold().getHome().getStructure().getParcel() == me.getHousehold().getHome().getStructure().getParcel()) {
				myFriends.remove(i);
			}
		}
		myFriends.resize(myFriends.size());
		
		HashMap<Resident, Double> socialize = new HashMap<Resident, Double>();
		ValueComparator bvc = new ValueComparator(socialize);
		TreeMap<Resident, Double> socialize_sorted = new TreeMap<Resident, Double>(bvc);
		
		//my location
		double x = me.getHousehold().getHome().getStructure().getParcel().getXLocation();
		double y = me.getHousehold().getHome().getStructure().getParcel().getYLocation();
		
		if (myFriends != null) {
			for(int i = 0; i < myFriends.size(); i++) {
				Edge e = (Edge)(myFriends.get(i));
				//Get the resident linked to me
				Resident friend = (Resident) e.getOtherNode(me);
				Double2D friendLocation = kibera.world.getObjectLocation(friend);
				
				double weight = ((Double)(e.info)).doubleValue();								
				sumWeight = sumWeight + weight;
				
				double dx = friendLocation.x - x;
				double dy = friendLocation.y - y;
				double distance = Math.sqrt(dx*dx + dy*dy);
				
				sumDistance = distance + sumDistance;
			}
			
			for(int i = 0; i < myFriends.size(); i++) {
				Edge e = (Edge)(myFriends.get(i));
				//Get the resident linked to me
				Resident friend = (Resident) e.getOtherNode(me);
				Double2D friendLocation = kibera.world.getObjectLocation(friend);
				
				double weight = ((Double)(e.info)).doubleValue();
				double weightStandardize = weight / sumWeight;
				
				double dx = friendLocation.x - x;
				double dy = friendLocation.y - y;
				double distance = Math.sqrt(dx*dx + dy*dy);
				double distanceStandardize = distance / sumDistance;
								
				if (sumDistance == 0) { distanceStandardize = 0; }
				else { distanceStandardize = 1 - distanceStandardize; } //take the inverse
				
				double socializeLikelihood = 0.5 * weightStandardize + 0.5 * distanceStandardize;
				
				socialize.put(friend, socializeLikelihood);
			}
		}
		//for some reason the size of the array decreases from myFriends to socialize????
		socialize_sorted.putAll(socialize);
			
		if (socialize != null) {
			int numFriends = socialize.size();
			int numPotentialFriendstoSocialize = (int)(numFriends * 0.1);
			
			if (numPotentialFriendstoSocialize <= 0) {
				numPotentialFriendstoSocialize = 1;
			}
			
			//pick a random number between 0 and the total number of potential friends I could socialize with
			int friendToSocialize = kibera.random.nextInt(numPotentialFriendstoSocialize);
			//get the friend the resident will socialize with
			//socialize_sorted.get(friendToSocialize);
			int i = 0;
			for(Map.Entry<Resident, Double> s : socialize_sorted.entrySet()) {
				if (friendToSocialize == i) {
					socializeFriend = s.getKey();
				}
				i++;
			}
		}
	
		Parcel myHome = me.getHousehold().getHome().getStructure().getParcel();
		
		if (socializeFriend == null) { //no friends to socialize with
			return myHome;
		}
		
		Parcel friendLocation = socializeFriend.getHousehold().getHome().getStructure().getParcel();
			
		//if the friend is not home, then don't go to their house, stay home instead
		if (socializeFriend.getCurrentGoal() != Goal.Stay_Home) {
			return myHome;
		}
		else {
			return friendLocation;
		}
				
	}
	
    
    //When agents reach their goal location, they will interact with those at the same location
    public static void performAction(Parcel parcel, Resident me, Kibera kibera) {
  
    	//determine if there are other agents who are at their goal location and on the same parcel
    	//if so, add one "link" between the two agents, if link already exists, increase value of link by one
    	//keep track of all links and their values in the Network object
  
        ArrayList <Resident> neighbors = new ArrayList <Resident>();
        neighbors = parcel.getResidents();
        double weight = 0;
        double oldWeight = 0;

        //Bag myFriends = new Bag(kibera.socialNetwork.getEdgesOut(me));
        double stayingPeriod = me.getStayingPeriod() - me.getCStep();
        
        if (stayingPeriod == 0) { stayingPeriod = 1; }
        
        double s = me.getStayingPeriod();
        double c = me.getCStep();
        
        //if there are other residents at this location other than myself and those resident(s) are also at 
        //their goal location, then create a link between me and the other resident
        //if (neighbors.size() > 1 && action != Action.Stay_Home) {
        if (neighbors.size() > 0) {
            for ( Resident r : neighbors ) {
                if ( r != me && r.getGoalLocation() == parcel) {
                    //check if edge already exists between the two residents
                    //if edge exists, increment weight of edge
                    //if edge does not exist, create a new edge
                    //EdgeFunctions.doesEdgeExist(me, r, kibera);
                    Edge e = EdgeFunctions.getEdge(me, r, kibera);
                    //if (EdgeFunctions.doesEdgeExist(me, r, kibera)) {
                    
                    if (e != null) {
                        //Edge e = EdgeFunctions.getEdge(me, r, kibera);
                        weight = (.5) * (stayingPeriod / 1440); //multiply by 1/2 because weight is added twice since these are bi-directional edges
                        oldWeight = ((Double)(e.info)).doubleValue();
                        weight = oldWeight + weight;
                        kibera.socialNetwork.updateEdge(e, me, r, weight);
                    }
                    else { //if an edge does not already exist between the two residents
                        weight = stayingPeriod / 1440;
                        Edge edge = new Edge(me, r, weight);
                        boolean t = edge.getDirected();
                        kibera.socialNetwork.addEdge(edge); //create a new edge
                    }
                }									
            }
        }

    }
    
    public static boolean shouldResidentStayAtActivity (Resident me) {
       boolean isStay = false;
       
        if (me.getCStep() < me.getStayingPeriod()) {
            isStay = true;
        } 
        
        return isStay;
    }
    
    @SuppressWarnings("incomplete-switch")
	public static int stayingPeriodAtActivity(Resident me, Goal goal, Kibera kibera) {
        int period = 0;
        int curMin = me.getCStep();
        
        switch(goal) {
            case Go_to_Work:
                period = 6 * 60 + kibera.random.nextInt(6*60);
                break;
            case Find_Employment:
            	period = 6 * 60 + kibera.random.nextInt(6*60);
            	break;
            case Get_Water:
            	period = 10 + kibera.random.nextInt(60);
            case Get_An_Education:
            	// time at school max until 4;00pm
                if((curMin + 300) > (16 * 60)){
                   period = 20;
                }
                period = 7 * 60;
                break;
            case Socialize:
            	period = 2 * 60 + kibera.random.nextInt(60 * 2);
            	break;
            case Stay_Home:
            	if (me.isLaidOff() || me.leftSchool()) {
                    period = 1440;
            	}
            	else {
            		//period = 0;
                    period = 1;
            	}
            	break;
            case Go_to_Church:
                if (me.getReligion() == Religion.Muslim) {
	            	if ((curMin + 180) > (16*60)){
	                    period = 20;
	                 }
	                 else {
	                	 period = 20  + kibera.random.nextInt(180);
	                 }
                }
                else {
                	period = 60 + kibera.random.nextInt(60);
                }
            case Rebel:
            	period = 60 + kibera.random.nextInt(360);
        }
        
        return (period + curMin);
    }
    
	public static Bag findSchools(Resident me, Kibera kibera) {
		
		//determine if any schools within vision (vision in this case is the average size of a neighborhood in Kibera)
		//have available space
		//if so, attend school nearest to home
		
		//the approximate size of a neighborhood (assuming 15 total neighborhoods) is 15 x 15 parcels
		//this was calculated by summing all the parcels in kibera.txt that were part of kibera and dividing by 15
		
		int x = me.getHousehold().getHome().getStructure().getParcel().getXLocation();
		int y = me.getHousehold().getHome().getStructure().getParcel().getYLocation();
		
		Bag schoolsInNeighborhood = new Bag();
		kibera.landGrid.getNeighborsMaxDistance(x,y,kibera.schoolVision,false,schoolsInNeighborhood, null, null);
		
		Bag schoolParcelLocations = new Bag();
		
		for(Object o: schoolsInNeighborhood){
			Parcel p = (Parcel) o;
			for(int i = 0; i < p.getStructure().size(); i++) {
    			Structure s = (Structure) p.getStructure().get(i);
    			if (s.getSchools().size() > 0) {
    				for(int j = 0; j < s.getSchools().size(); j++) {
    					School school = (School) s.getSchools().get(j);
    					//if (school.getFacilityID() == 1 && !school.isCapacityReached()) {
    					if (!school.isStudentCapacityReached()) {
    						schoolParcelLocations.add(p); }
    				}
    			}
			}
		}
		
		me.searchedForSchool(true);
		return schoolParcelLocations;
		
	}
	
    
	public static Bag findPotentialEmployment(Resident me, Kibera kibera) {
		int x = me.getHousehold().getHome().getStructure().getParcel().getXLocation();
		int y = me.getHousehold().getHome().getStructure().getParcel().getYLocation();
		
		Bag potentialEmployers = new Bag();
		kibera.landGrid.getNeighborsMaxDistance(x,y,kibera.employmentVision,false,potentialEmployers, null, null);
		
		Bag employerParcelLocations = new Bag();
		
		//If employed in formal market (based on initialization) search for available position in school, health facility, 
		//or religious facility
		if (me.getCurrentEmploymentStatus() == Employment.Formal) {
		
			for(Object o: potentialEmployers){
				Parcel p = (Parcel) o;
				for(int i = 0; i < p.getStructure().size(); i++) {
	    			Structure s = (Structure) p.getStructure().get(i);
	    			if (s.getHealthFacilities().size() > 0) {
	    				for(int j = 0; j < s.getHealthFacilities().size(); j++) {
	    					HealthFacility healthFacility = (HealthFacility) s.getHealthFacilities().get(j);
	    					if (!healthFacility.isEmployeeCapacityReached()) {
	    						employerParcelLocations.add(p);
	    					}
	    				}
	    			}
	    			if (s.getReligiousFacilities().size() > 0) {
	    				for(int j = 0; j < s.getReligiousFacilities().size(); j++) {
	    					ReligiousFacility religiousFacility = (ReligiousFacility) s.getReligiousFacilities().get(j);
	    					if (!religiousFacility.isEmployeeCapacityReached()) {
	    						employerParcelLocations.add(p);
	    					}
	    				}
	    			}
	    			if (s.getSchools().size() > 0) {
	    				for(int j = 0; j < s.getSchools().size(); j++) {
	    					School school = (School) s.getSchools().get(j);
	    					if (!school.isEmployeeCapacityReached()) {
	    						employerParcelLocations.add(p);
	    					}
	    				}
	    			}    			    			
				}
			}
			
			//if no formal employment was found, go to the city for employment (for now, agent will just stay home but
			//employment status will stay formal
			if (employerParcelLocations.size() == 0) {
				employerParcelLocations.add(me.getHousehold().getHome().getStructure().getParcel());
			}
				
		}
		
		//if employed in informal market (based on initialization) search for job in informal businesses
		else if (me.getCurrentEmploymentStatus() == Employment.Informal) {
			
			for(Object o: potentialEmployers){
				Parcel p = (Parcel) o;
				for(int i = 0; i < p.getStructure().size(); i++) {
	    			Structure s = (Structure) p.getStructure().get(i);
	    			if (s.getBusinesses().size() > 0) {
	    				for(int j = 0; j < s.getBusinesses().size(); j++) {
	    					Business business = (Business) s.getBusinesses().get(j);
	    					if (!business.isEmployeeCapacityReached()) {
	    						employerParcelLocations.add(p);
	    					}
	    				}
	    			}
				}
			}
			if (employerParcelLocations.size() == 0) {
				employerParcelLocations.add(me.getHousehold().getHome().getStructure().getParcel());
			}
		}
		
		//if unemployed (searching for employment) search for available employment in formal or informal market
		else {
			
			for(Object o: potentialEmployers) {
				Parcel p = (Parcel) o;
				for(int i = 0; i < p.getStructure().size(); i++) {
	    			Structure s = (Structure) p.getStructure().get(i);
	    			if (s.getBusinesses().size() > 0) {
	    				for(int j = 0; j < s.getBusinesses().size(); j++) {
	    					Business business = (Business) s.getBusinesses().get(j);
	    					if (!business.isEmployeeCapacityReached()) {
	    						employerParcelLocations.add(p);
	    					}
	    				}
	    			}
	    			if (s.getHealthFacilities().size() > 0) {
	    				for(int j = 0; j < s.getHealthFacilities().size(); j++) {
	    					HealthFacility healthFacility = (HealthFacility) s.getHealthFacilities().get(j);
	    					if (!healthFacility.isEmployeeCapacityReached()) {
	    						employerParcelLocations.add(p);
	    					}
	    				}
	    			}
	    			if (s.getReligiousFacilities().size() > 0) {
	    				for(int j = 0; j < s.getReligiousFacilities().size(); j++) {
	    					ReligiousFacility religiousFacility = (ReligiousFacility) s.getReligiousFacilities().get(j);
	    					if (!religiousFacility.isEmployeeCapacityReached()) {
	    						employerParcelLocations.add(p);
	    					}
	    				}
	    			}
	    			if (s.getSchools().size() > 0) {
	    				for(int j = 0; j < s.getSchools().size(); j++) {
	    					School school = (School) s.getSchools().get(j);
	    					if (!school.isEmployeeCapacityReached()) {
	    						employerParcelLocations.add(p);
	    					}
	    				}
	    			}    			    			
				}
			}
		}
			
		return employerParcelLocations;	
	}
	
	public static void utilizeWater(Resident me, Kibera kibera) {
		double dailyUse = kibera.MIN_WATER_REQ + kibera.random.nextInt(kibera.MAX_WATER_REQ - kibera.MIN_WATER_REQ); // randomly

        double WaterUsed = 0;
        double remainingWater = me.getHousehold().getRemainingWater();
        
        // only uses from family bucket
        if (dailyUse >= remainingWater) { // if the water is not enough, utilize all
            WaterUsed = remainingWater; // tell that there is no water in the house
        } 
        else {
            WaterUsed = dailyUse; // if plenty of water in the house, only use what you want
        }
        
        me.getHousehold().setRemainingWater(remainingWater - WaterUsed);
	}
	
	/*public static void rumorPropogation() {
		
	}*/
    
}
