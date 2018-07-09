package kibera;

import sim.util.Bag;

public class Neighborhood {
	
	/** The set of parcels within a given neighborhood */
	private Bag neighborhoodParcels;
	public void addParcel(Parcel val) { neighborhoodParcels.add(val); }
	public Bag getNeighborhoodParcels() { return neighborhoodParcels; }

	/** The ID of a neighborhood */
	private int neighborhoodID;
	public int getNeighborhoodID() { return neighborhoodID; }
	public void setNeighborhoodID(int val) { neighborhoodID = val; }
	
	public Neighborhood() {
		super();
		neighborhoodParcels = new Bag();
	}
}
