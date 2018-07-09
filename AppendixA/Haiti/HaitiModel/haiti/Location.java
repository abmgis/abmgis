package haiti;

class Location{
	int x;
	int y;
	public Location(int i, int j){ x = i; y = j; }
	boolean equals( Location b ){
		if( b.x == x && b.y == y) return true;
		else return false;
	}
	public boolean equals(int x, int y) {
		if(x == this.x && y == this.y)
			return true;
		return false;
	}
	double distanceTo(Location b){
		return Math.sqrt( Math.pow(b.x - x, 2) + Math.pow(b.y - y, 2));
	}
	double distanceTo(int xCoord, int yCoord){
		return Math.sqrt( Math.pow(xCoord - x, 2) + Math.pow(yCoord - y, 2));
	}
	
	Location copy(){
		Location l = new Location(x, y);
		return l;
	}
}
