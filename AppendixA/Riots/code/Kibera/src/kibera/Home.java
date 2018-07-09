package kibera;

import sim.util.Bag;


public class Home {
	
	
	/** The household (group of residents) living in the home */
	private Household household;
	public Household getHousehold() { return household; }
	public void setHousehold(Household val) { household = val; }
	
	/*private Bag household;
	public Bag getHousehold() { return household; }
	public void addHousehold(Household val) { household.add(val); }
	public void removeHousehold(Household val) { household.remove(val); }*/
	
	/** The structure the home is located in */
	private Structure structure;
	public Structure getStructure() { return structure; }
	public void setStructure(Structure val) { structure = val; }
	
	/** The monthly rental cost of the house */
	private double houseRent;
	public double getHouseRent() { return houseRent; }
	public void setHouseRent(double val) { houseRent = val; }
	
	/** Identifies whether the house has running water */
	private boolean hasWater;
	public boolean hasWater() { return hasWater; }
	public void hasWater(boolean val) { hasWater = val; }
	
	/** Identifies whether the house has electricity */
	private boolean hasElectricity;
	public boolean hasElectricity() { return hasElectricity; }
	public void hasElectricity(boolean val) { hasElectricity = val; }
	
	/** Identifies whether a house has a toilet */
	private boolean hasSanitation;
	public boolean hasSanitation() { return hasSanitation; }
	public void hasSanitation(boolean val) { hasSanitation = val; }
	
	/** The expected cost of electricity (if house has electricity) */
	private double expectedElectricityCost;
	public double getExpectedElectricityCost() { return expectedElectricityCost; }
	public void setExpectedElectricityCost(double val) { expectedElectricityCost = val; }
	
	/** The expected cost of running water (if house has water) */
	private double expectedRunningWaterCost;
	public double getExpectedRunningWaterCost() { return expectedRunningWaterCost; }
	public void setExpectedRunningWaterCost(double val) { expectedRunningWaterCost = val; }
	
	
	public Home(Structure s) {
		structure = s;
		//household = new Bag();
	}
	
	public boolean isHomeOccupied(Kibera kibera) {
		if (household == null) {
			return false;
		}
		else {
			return true;
		}
	}
	
	public double getTotalExpectedHousingCost() {
		double totalHousingCost = 0;
		totalHousingCost = houseRent + expectedElectricityCost + expectedRunningWaterCost;
		
		return totalHousingCost;
		
	}

	
}
