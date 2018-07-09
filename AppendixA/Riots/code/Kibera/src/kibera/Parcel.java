package kibera;

import java.util.ArrayList;

import sim.util.Bag;
import sim.util.Int2D;


public class Parcel {

	/** The ID of each parcel */
	private int parcelID;
	public int getParcelID() { return parcelID; }
	public void setParcelID(int val) { this.parcelID = val; }
	
	/** The location (x, y) coordinates on the grid of the parcel */
	private Int2D location;
	public Int2D getLocation() { return location; }
	public void setLocation(Int2D val) { location = val;}
	public int getXLocation() { return location.x; }
	public int getYLocation() { return location.y; }
	
	/** The ID of the roads within a parcel */
	private double roadID;
	public double getRoadID() { return roadID; }
	public void setRoadID(double val) { roadID = val; }
	
	/** The set of structures residing on the parcel */
	private ArrayList<Structure> structures;
	public void addStructure(Structure val) { structures.add(val); }
	public void removeStructure(Structure val) { this.structures.remove(val); }
	public ArrayList<Structure> getStructure() { return structures;}
	
	/** The set of residents currently located on a parcel */
	private ArrayList<Resident> residents;
	public void addResident(Resident val) { residents.add(val); }
	public void removeResident(Resident val) { residents.remove(val); }
	public ArrayList<Resident> getResidents() { return residents; }
	
	/** The neighborhood a parcel is located on */
	private Neighborhood neighborhood;
	public Neighborhood getNeighborhood() { return neighborhood; }
	public void setNeighborhood(Neighborhood val) { neighborhood = val; }
	
	/** The water points located on a parcel */
	private ArrayList<WaterPoint> waterPoints;
	public void addWaterPoint(WaterPoint val) { waterPoints.add(val); }
	public void removeWaterPoint(WaterPoint val) { waterPoints.remove(val); }
	public ArrayList<WaterPoint> getWaterPoint() { return waterPoints;}
	
	/** The sanitation points located on a parcel */	
	private ArrayList<Sanitation> sanitation;
	public void addSanitation(Sanitation val) { sanitation.add(val); }
	public void removeSanitation(Sanitation val) { sanitation.remove(val); }
	public ArrayList<Sanitation> getSanitation() { return sanitation;}
	
	public Parcel(Int2D location) {
		this.setLocation(location);
		structures = new ArrayList<Structure>();
		residents = new ArrayList<Resident>();
		waterPoints = new ArrayList<WaterPoint>();
		sanitation = new ArrayList<Sanitation>();
	}
	
	public boolean isParcelOccupied(Kibera kibera) {
		if (this.getStructure().size() > kibera.getMaxStructuresPerParcel())
			return true;
		else
			return false;
	}
	
	// calaculate distance 
    public double distanceTo(Parcel p) {
        return Math.sqrt(Math.pow(p.getXLocation() - this.getXLocation(), 2) + Math.pow(p.getYLocation() - this.getYLocation(), 2));
    }

    public double distanceTo(int xCoord, int yCoord) {
        return Math.sqrt(Math.pow(xCoord - this.getXLocation(), 2) + Math.pow(yCoord - this.getYLocation(), 2));
    }
	    
	public String toString() {
		return String.format("%d,%d", location.x, location.y);
	}

	@Override
	public boolean equals(Object obj) {
		if (obj == null) 				return false;
		if (!(obj instanceof Parcel)) 	return false;
		
		if (obj == this)				return true;
		
		Parcel p = (Parcel)obj;
		return (p.location.equals(this.location));
	}
	
}
