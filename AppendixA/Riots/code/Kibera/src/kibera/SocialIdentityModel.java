package kibera;

import sim.field.network.Edge;
import sim.util.Bag;
import sim.util.Double2D;
import kibera.Resident.Employment;
import kibera.Resident.Goal;
import kibera.Resident.Identity;
import sim.field.network.stats.DegreeStatistics;

public class SocialIdentityModel {
	/*
	 * Identity salience is a function of:
	 * (1) Embeddedness of the individual in a social structure (commitment) -- student/employee
	 * (2) The fit of the identity with situational stimuli (the action the agent takes)
	 * (3) Characteristics of the identity such as its accessibility
	 * 
	 * Connectedness increases the salience of the identity, making it more likely that the identity will 
	 * be activated in a given situation; persons occupying densely connected positions and holding 
	 * related roles will have identities associated with those position and roles that are more salient
	 * 
	 * Persons have as many identities as distinct networks of relationships
	 * 
	 * The action determines who the agent interacts with
 	 * Each interaction increases the connectness of the interacting agents
	 * This influences the identities salient to each agent
	 */
	
	//Determine which identity is salient
	//compare salient identity to individual's identity standard via the Comparator (Perceptions are 
	//compared to the identity standard)
	//Output can impact an agents emotions -- self-esteem, self-efficacy, stress

	/*
	 * Salience is the probability of activating an identity in a situation
	 * 
	 * Hierarchy of identities:
	 * Three levels: a superordinate level such as human, an intermediate level such as american,
	 * and a subordinate level such as southerner.
	 * 
	 * A particular identity becomes salient/activated as a function of the interaction between the 
	 * characteristics of the perceiver and the situation
	 * Individual perceives herself as like one set of persons and different from another set of persons 
	 * in a situation
	 * This is the perception of intra-class similarities and inter-class differences
	 * 
	 * Identity salience implies that person are more likely to define situations they enter in ways 
	 * that make a highly salient identity relevant; this process enables them to enact that identity
	 * 
	 * If the identity confirmation process is successful, the salience of the identity will be 
	 * reinforced; if the process is unsuccessful, the salience of the identity is likely to diminish
	 * 
	 * If competing or conflicting identities reflect greatly different commitments and consequently 
	 * differ greatly in salience, the identity based on greater commitments and higher salience will be 
	 * reflected (in situations where alternative identities can be invoked) in the operative identity 
	 * standard and perceived self-meanings
	 */
	
	/*
	 * Identities:
	 * Superordinate: Human -- don't need to model
	 * Intermediate -- Kenyan, Employee, Student
	 * Subordinate -- Ethnicity, Employee of xx company, Student of xx school, Head of household
	 * 
	 * creation of ingroup vs outgroup
	 * happens has salience for ethnic identity becomes more pronounced
	 *  	
	 * 
	 * how connected a resident is with those with similar ethnicity, will increase the salience of 
	 * their ethnic identity -- both within the slum and outside (family in other regions of the country)
	 * but residents who have more commitments -- student/employee -- less likely to see that salience increase
	 * 
	 * residents will seek to meet employee and student identities
	 * if student age, will look to go to school
	 * 
	 * go to school:
	 * primary is free, secondary is not
	 * families will prioritize sending sons over daughters to secondary school (http://www.huffingtonpost.com/wendy-cross/a-community-response-to-g_b_914841.html)
	 * 
	 * children of primary and secondary school age will search for a school that has not reached capacity
	 * if household has boy and girl of school age, then boy will search first
	 * 
	 * 
	 */
	
	public static void determineIdentityStandard(Resident me, double aggressionRate, Kibera kibera) {
		
            boolean isIdentityStandardMet;
            double aggressValue;

            //if the resident is a very young child, he/she is happy being inactive and staying home
            if (me.getAge() < 6) {
                me.setCurrentIdentity(Identity.Domestic_Activities);
                isIdentityStandardMet = true;
            }
            
            else if (me.isInitialRebel()) {
                me.setCurrentIdentity(Identity.Rebel);
                isIdentityStandardMet = true;
            }

            //Is employee identity standard met
            else if (me.getCurrentEmploymentStatus() == Employment.Formal || me.getCurrentEmploymentStatus() == Employment.Informal) {
                me.setCurrentIdentity(Identity.Employer);
                isIdentityStandardMet = true;
            }

            //Is student identity standard met
            else if (me.getMySchool() != null) {
                me.setCurrentIdentity(Identity.Student);
                isIdentityStandardMet = true;
            }

            //If I want to go to school, but could not find an available school, identity standard is not met
            else if (me.searchedForSchool() && me.getMySchool() == null) {

                if (me.getCurrentEmploymentStatus() == Employment.Formal || me.getCurrentEmploymentStatus() == Employment.Informal) {
                    isIdentityStandardMet = true;
                    me.setCurrentIdentity(Identity.Employer);
                }
                else {
                    isIdentityStandardMet = false;
                    me.setCurrentIdentity(Identity.Domestic_Activities);
                }
            }

            //If I want to be employed, but could not find employment, identity standard is not met
            //else if (me.getCurrentEmploymentStatus() == Employment.Formal || me.getCurrentEmploymentStatus() == Employment.Informal) {
            else if (me.getCurrentEmploymentStatus() == Employment.Searching) {
                isIdentityStandardMet = false;
                me.setCurrentIdentity(Identity.Domestic_Activities);
            }

            //Is domestic activities identity standard met
            else if (me.getCurrentEmploymentStatus() == Employment.Inactive) {
                me.setCurrentIdentity(Identity.Domestic_Activities);
                isIdentityStandardMet = true;
            }            

            //otherwise, resident would like to go to school or work, but has not searched for school or employment yet, so still happy
            else {	
                isIdentityStandardMet = true;
            }

            //if energy is low, stress increases
            //high stress and high aggression may cause resident to go to violence
            //if ethnic identity is salient and aggression above threshold, then rebel

            //amount of energy to increase/decrease
            //double rnEnergyChange = kibera.random.nextDouble();
            int rnEnergyChange = kibera.random.nextInt(10);

            //do this everytime there is a change in the agents activity
            if (!isIdentityStandardMet) {
                if (me.getEnergy() - rnEnergyChange <= 0) { me.setEnergy(0); }                                  
                else { me.setEnergy(me.getEnergy() - rnEnergyChange); }            
            }
            
            else {
                if (me.getEnergy() + rnEnergyChange >= 100) { me.setEnergy(100); }
                else { me.setEnergy(me.getEnergy() + rnEnergyChange); }                               
            }
            

            if (me.heardRumor()) {
                //determine residents susceptibility to influence -- their indegree centrality (source: Friedkin, 2001)
                //determine direct interpersonal effects -- their density (total existing ties / total possible ties) (source: Friedkin, 2001)
                //initial position on issue is related to the structural equivalence of each resident in the network (source: Friedkin, 2001)
                    //use hierarchical clustering - graph distance and euclidean distance (function of edge weight and physical distance between residents)
                //the full set of residents/ties can be split into subgroups - social identity theory, ingroup vs outgroup (source: Situating social influence processes, Mason, Conrey and Smith, 2008)

                //if a resident hears the rumor, whether the resident will act on the rumor depends on its final opinion on the issue and its aggression
                aggressValue = Energy.calculateAggression(me.getEnergy(), aggressionRate, me, kibera);				
                //assign current aggression value to resident
                me.setAggressionValue(aggressValue);	
                
                //check if there is anyone in my network that can influence me to rebel
                boolean hasRebelFriend = false;            

                if (aggressValue < kibera.getAggressionThrehold() && me.getAge() > 5 && 
                    me.getCurrentIdentity() != Identity.Rebel) {
                    
                    Bag myConnections = new Bag(kibera.socialNetwork.getEdgesOut(me));
                    
                    if (!myConnections.isEmpty()) {
                        for(int i = 0; i < myConnections.size(); i++) {
                            Edge e = (Edge)(myConnections.get(i));
                            //Get the resident linked to me
                            Resident connection = (Resident) e.getOtherNode(me);
                                                   
                            if (connection.getCurrentIdentity() == Identity.Rebel) {
                                hasRebelFriend = true;
                                break;
                            }
                        }
                    }
                    
                    if (hasRebelFriend) {
                        boolean isInfluencedtoRebel = determineMyInfluencers(me, myConnections, kibera);
                        if (isInfluencedtoRebel) {
                            me.setCurrentIdentity(Identity.Rebel);
                            me.currentGoal = Goal.Rebel;
                        }
                    }                  
                }
            }				
	}
        
        /** According to Friedkin (1999 and 2001), y(final) = (I - AW)^-1 * (I - A) * y(1)
         *  where, y(1) = initial opinion on an issue (a measure is structural equivalence - the a like the networks of residents are, the 
         *  more likely they are to have a similar opinion)
         *  A = person's susceptibility to influence (measure of susceptibility is indegree centrality
         *  W = relative interpersonal influence, which is based on the communication/interaction network between residents (measure is density - total
         *  total actual edge weight between existing connections (with those of same ethnicity) / total possible edge weight between existing connections
         *  I = the Identity matrix (diagonal of 1s, rest of matrix is 0s)
         * 
         */
        public static boolean determineMyInfluencers(Resident me, Bag myConnections, Kibera kibera) {
            //determine y(t) = opinion on issue at time t (measure is structural equivalence)
            //get number of ties between myself and connection that are like mine and divide by total number of ties between myself and connection
            //get distance between myself and connection
            //take the average of the two (number of ties and distance)

            double yt[] = new double[myConnections.size()+1]; //the size of the array is equal to the number of residents I'm connected to plus myself
            double W[] = new double[myConnections.size()+1];
   
            int totalTies = myConnections.size();
            double myDegreeCentrality = (double) totalTies;
            double meanDegreeCentrality = DegreeStatistics.getMeanInDegree(kibera.socialNetwork);
 
            double alpha = 0;
            
            if (!myConnections.isEmpty()) {
       
                //my similarity to myself
                double mySimilarity = 1;
                yt[0] = mySimilarity;
                  
                double myStudentIdentity = 0;
                double myEmployeeIdentity = 0;
                double myDomesticIdentity = 0;
                double myRebelIdentity = 0;  
                double myEthnicityIdentity = 0;
                
                for (int i = 0; i < myConnections.size(); i++) {
                    
                    //Get the resident linked to me
                    Edge myEdge = (Edge)(myConnections.get(i));
                    Resident myConnection = (Resident) myEdge.getOtherNode(me);
                    
                    if (myConnection.getCurrentIdentity() == Identity.Student) {
                        myStudentIdentity = myStudentIdentity + 1;
                    }
                    else if (myConnection.getCurrentIdentity() == Identity.Employer) {
                        myEmployeeIdentity = myEmployeeIdentity + 1;
                    }
                    else if (myConnection.getCurrentIdentity() == Identity.Domestic_Activities) {
                        myDomesticIdentity = myDomesticIdentity + 1;
                    }
                    else {
                        myRebelIdentity = myRebelIdentity + 1;
                    }
                    
                    if (myConnection.getEthnicity().equals(me.getEthnicity())) {
                        myEthnicityIdentity = myEthnicityIdentity + 1;
                    }
                }
                    
                //now compare to my connection's connections 
                for (int i = 0; i < myConnections.size(); i++) {
                    
                    //Get the resident linked to me
                    Edge myEdge = (Edge)(myConnections.get(i));
                    Resident myConnection = (Resident) myEdge.getOtherNode(me);
                    Bag othersConnections = new Bag(kibera.socialNetwork.getEdgesOut(myConnection));

                    double cStudentIdentity = 0;
                    double cEmployeeIdentity = 0;
                    double cDomesticIdentity = 0;
                    double cRebelIdentity = 0;  
                    double cEthnicityIdentity = 0;
                
                    for (int j = 0; j < othersConnections.size(); j++) {
                        Edge cEdge = (Edge)(othersConnections.get(j));
                        Resident cConnection = (Resident) cEdge.getOtherNode(myConnection);
                    
                        if (cConnection.getCurrentIdentity() == Identity.Student) {
                            cStudentIdentity = cStudentIdentity + 1;
                        }
                        else if (cConnection.getCurrentIdentity() == Identity.Employer) {
                            cEmployeeIdentity = cEmployeeIdentity + 1;
                        }
                        else if (cConnection.getCurrentIdentity() == Identity.Domestic_Activities) {
                            cDomesticIdentity = cDomesticIdentity + 1;
                        }
                        else {
                            cRebelIdentity = cRebelIdentity + 1;
                        }
                        
                        if (cConnection.getEthnicity().equals(myConnection.getEthnicity())) {
                            cEthnicityIdentity = cEthnicityIdentity + 1;
                        }
                        
                    }
                    
                    //determine similarity between me and my connection
                    myStudentIdentity = myStudentIdentity / myConnections.size();
                    myEmployeeIdentity = myEmployeeIdentity / myConnections.size();
                    myDomesticIdentity = myDomesticIdentity / myConnections.size();
                    myRebelIdentity = myRebelIdentity / myConnections.size();
                    
                    cStudentIdentity = cStudentIdentity / othersConnections.size();
                    cEmployeeIdentity = cEmployeeIdentity / othersConnections.size();
                    cDomesticIdentity = cDomesticIdentity / othersConnections.size();
                    cRebelIdentity = cRebelIdentity / othersConnections.size();                  
                    
                    double schoolSimilarity = 0;
                    double employeeSimilarity = 0;
                    double domesticSimilarity = 0;
                    double rebelSimilarity = 0;
                    
                    if (Math.max(myStudentIdentity, cStudentIdentity) > 0) { schoolSimilarity = Math.abs(myStudentIdentity - cStudentIdentity) / Math.max(myStudentIdentity, cStudentIdentity); }                   
                    if (Math.max(myEmployeeIdentity, cEmployeeIdentity) > 0) { employeeSimilarity = Math.abs(myEmployeeIdentity - cEmployeeIdentity) / Math.max(myEmployeeIdentity, cEmployeeIdentity); }     
                    if (Math.max(myDomesticIdentity, cDomesticIdentity) > 0) { domesticSimilarity = Math.abs(myDomesticIdentity - cDomesticIdentity) / Math.max(myDomesticIdentity, cDomesticIdentity); }                    
                    if (Math.max(myRebelIdentity, cRebelIdentity) > 0) { rebelSimilarity = Math.abs(myRebelIdentity - cRebelIdentity) / Math.max(myRebelIdentity, cRebelIdentity); }
                    
                    schoolSimilarity = 1 - schoolSimilarity;
                    employeeSimilarity = 1 - employeeSimilarity;
                    domesticSimilarity = 1 - domesticSimilarity;
                    rebelSimilarity = 1 - rebelSimilarity;
                    
                    schoolSimilarity = schoolSimilarity / 4.;
                    employeeSimilarity = employeeSimilarity / 4.;
                    domesticSimilarity = domesticSimilarity / 4.;
                    rebelSimilarity = rebelSimilarity / 4.;
                    
                    double totalIdentitySimilarity = schoolSimilarity + employeeSimilarity + domesticSimilarity + rebelSimilarity;
                                      
                    myEthnicityIdentity = myEthnicityIdentity / myConnections.size();
                    cEthnicityIdentity = cEthnicityIdentity / othersConnections.size();
                    
                    double ethnicSimilarity = 0;
                    
                    if (Math.max(myEthnicityIdentity, cEthnicityIdentity) > 0) { ethnicSimilarity = Math.abs(myEthnicityIdentity - cEthnicityIdentity) / Math.max(myEthnicityIdentity, cEthnicityIdentity); }
                    
                    ethnicSimilarity = 1 - ethnicSimilarity;
                    
                    yt[i+1] = 0.5 * totalIdentitySimilarity + 0.5 * ethnicSimilarity;
                    
                    //calculate alpha for all my connections
                    double degreeCentrality = (double) othersConnections.size();    
             
                    double a = 0;     
                    a = Math.exp(-(degreeCentrality - 2*meanDegreeCentrality));
                    a = 1 / (1 + a);
                    a = 1 - a;
                    a = Math.pow(a, .5);
                                      
                    W[i+1] = a;
                    
                    alpha = alpha + a;
                   
                    
                    
                }
            }

            //calculate a=alpha (residents susceptiblity to influence)
            double a = 0;     
            a = Math.exp(-(myDegreeCentrality - 2*meanDegreeCentrality));
            a = 1 / (1 + a);
            a = 1 - a;
            a = Math.pow(a, .5);
            
            W[0] = 1-a;
     
            //normalize W so that the row sums to 1
            //the sum of Ws (not including myself) is the same as alpha
            double sumW = alpha;
            
            for(int i = 1; i<W.length; i++) {
               W[i] = (W[i] / sumW) * (1-W[0]);
            }
            
            //multiply updated W (or V) by yt to get final y
            double y_final = 0;
            for (int i = 0; i < W.length; i++) {
                y_final = y_final + (W[i] * yt[i]);               
            }
            
            //determine who of my connections my opinion is most similar to
            double[] difference = new double[yt.length];
            for (int i = 0; i < yt.length; i++) {                
                difference[i]=Math.abs(y_final - yt[i]);
            }
            
            for (int i = 1; i < difference.length; i++) {
                if (difference[i] <= kibera.opinionThreshold) {
                    Edge e = (Edge)(myConnections.get(i-1));
                    Resident influencer = (Resident) e.getOtherNode(me);
                    if (influencer.heardRumor()) {
                        if (influencer.currentIdentity == Identity.Rebel) {
                            return true;
                        }
                    }
                }
            }
            
            return false;                                                                                                                         
        }
	
	public static void determineEthnicSalience(Resident me, double aggressValue, Kibera kibera) {
		
		Bag myFriends = new Bag(kibera.socialNetwork.getEdgesOut(me));
                
		double ethnicityWeight = 0;
		double otherWeight = 0;
		double totalWeight = 0;
		double ethnicityWeightProportion = 0;
		double ethnicityDistance = 0;
		double otherDistance = 0;
		double totalDistance = 0;
		double ethnicityDistanceProportion = 0;
		
		if (myFriends != null) {
			//check weight of all those resident is connected to
			//compare weight of those with same ethnicity to those of different ethnicity
			
			//loop through each friend
			//compare friend ethnicity to me ethnicity
			//add weights of friends with same ethnicity
			//add weights of friends with different ethnicity
			//calculate the proportion of total weight for friends with same ethnicity
			
			//are many friends of same ethnicity at the same place at the same time?
			//increased salience based on shorter distance to those with same ethnicity
			
			//my location
			int x = me.getHousehold().getHome().getStructure().getParcel().getXLocation();
			int y = me.getHousehold().getHome().getStructure().getParcel().getYLocation();
			
			for(int i = 0; i < myFriends.size(); i++) {
				Edge e = (Edge)(myFriends.get(i));
				//Get the resident linked to me
				Resident friend = (Resident) e.getOtherNode(me);
				Double2D friendLocation = kibera.world.getObjectLocation(friend);
				
				double weight = ((Double)(e.info)).doubleValue();
				
				double dx = friendLocation.x - x;
				double dy = friendLocation.y - y;
				double distance = Math.sqrt(dx*dx + dy*dy);
				
				//calculate ethnic salience (probability that ethnicity is the salient identity)
				//determine if those with similar ethnicity are within Moore neighborhood
				//if majority of similar ethnicity and random number is below ethnicity weight proportion, then
				//ethnic identity is salient
				
				if (me.getEthnicity().equals(friend.getEthnicity())) {
					ethnicityWeight = ethnicityWeight + weight;				
					ethnicityDistance = ethnicityDistance + distance;
				}
				else {
					otherWeight = otherWeight + weight;		
					otherDistance = otherDistance + distance;
				}
				
				totalWeight = ethnicityWeight + otherWeight;
				totalDistance = ethnicityDistance + otherDistance;				
			}
			ethnicityWeightProportion = ethnicityWeight / totalWeight;
			ethnicityDistanceProportion = 1 - (ethnicityDistance / totalDistance);
			
			double ethnicityLikelihood = 0.5 * ethnicityWeightProportion + 0.5 * ethnicityDistanceProportion;
			double random = kibera.random.nextDouble();
			
			if (ethnicityLikelihood > random) {
				
				if (aggressValue < kibera.getAggressionThrehold()) {
					me.setCurrentIdentity(Identity.Rebel);
					me.currentGoal = Goal.Rebel;
				}
			}			
		}		
	}
	
}
