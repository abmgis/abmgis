package kibera;

public class WaterPoint {

	/** The parcel a water point resides on */
	private Parcel waterPointLocation;
	public Parcel getParcel() { return waterPointLocation; }
	public void setParcel(Parcel val) { waterPointLocation = val; }
	
	public WaterPoint(Parcel p) {
		waterPointLocation = p;
	}

}
