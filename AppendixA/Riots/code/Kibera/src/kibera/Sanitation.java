package kibera;

public class Sanitation {

	/** The parcel the sanitation location resides on */
	private Parcel sanitationLocation;
	public Parcel getParcel() { return sanitationLocation; }
	public void setParcel(Parcel val) { sanitationLocation = val; }
	
	public Sanitation(Parcel p) {
		sanitationLocation = p;
	}
	
}
