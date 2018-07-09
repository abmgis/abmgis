package kibera;

import java.util.ArrayList;

import sim.util.Bag;

/*
 * A structure is a building in the slum, it can contain households, businesses, and/or services
 */

public class Structure {
	
	/** The parcel a structure resides on */
	private Parcel structureLocation;
	public Parcel getParcel() { return structureLocation; }
	public void setParcel(Parcel val) { structureLocation = val; }
	
	/** The households residing in the structure */
	/*private Bag households;
	public Bag getHouseholds() { return households; }
	public void addHousehold(Household val) { households.add(val); }
	public void removeHouseholds(Household val) { households.remove(val); } */
	
	/** The homes residing in the structure */
	private Bag homes;
	public Bag getHomes() { return homes; }
	public void addHome(Home val) { homes.add(val); }
	public void removeHome(Home val) { homes.remove(val); }
	
	/** The businesses located in the structure */
	private Bag businesses;
	public Bag getBusinesses() { return businesses; }
	public void addBusinesses(Business val) { businesses.add(val); }
	public void removeBusinesses(Business val) { businesses.remove(val); }
	
	/** The health facilities located in the structure */
	private ArrayList<HealthFacility> healthFacilities;
	public ArrayList<HealthFacility> getHealthFacilities() { return healthFacilities; }
	public void getHealthFacilities(ArrayList<HealthFacility> val) { healthFacilities = val; }		
	public void addHealthFacility(HealthFacility val) { healthFacilities.add(val); }	
	
	/** The religious facilities (church/mosque) located in the structure */
	private ArrayList<ReligiousFacility> religiousFacilities;
	public ArrayList<ReligiousFacility> getReligiousFacilities() { return religiousFacilities; }
	public void getReligiousFacilities(ArrayList<ReligiousFacility> val) { religiousFacilities = val; }		
	public void addReligiousFacility(ReligiousFacility val) { religiousFacilities.add(val); }	

	/** The schools located in the structure */
	private ArrayList<School> schools;
	public ArrayList<School> getSchools() { return schools; }
	public void getSchools(ArrayList<School> val) { schools = val; }		
	public void addSchool(School val) { schools.add(val); }
	
	/** The capacity (number) of homes and businesses that can reside in the structure */
	private int homeCapacity;
	public int getHomeCapacity() { return homeCapacity; }	
	private int businessCapacity;
	public int getBusinessCapacity() { return businessCapacity; }
	public void setStructureCapacity(int maxNumberHH, int maxNumberBusiness) {
		this.homeCapacity = maxNumberHH;
		this.businessCapacity = maxNumberBusiness;
	}

	public Structure(Parcel p) {
		this.structureLocation = p;
		//households = new Bag();
		homes = new Bag();
		businesses = new Bag();
		schools = new ArrayList<School>();
		healthFacilities = new ArrayList<HealthFacility>();
		religiousFacilities = new ArrayList<ReligiousFacility>();
	}
	
	public Structure() {
		//households = new Bag();
		homes = new Bag();
		businesses = new Bag();
	}
	
	/*public boolean isStructureOccupied(Kibera kibera) {
		for (int i = 0; i < this.getHomeCapacity(); i++) {
			this.getHomes().get
		}
		
		if (this.getHomeCapacity() < this.getHomes().size()) { return true; }
		else { return false; }
	}*/

}
