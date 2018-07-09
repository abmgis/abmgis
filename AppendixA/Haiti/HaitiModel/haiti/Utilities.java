package haiti;

import java.util.ArrayList;
import java.util.PriorityQueue;

import sim.field.grid.IntGrid2D;
import sim.field.grid.ObjectGrid2D;
import sim.util.Bag;


public class Utilities {
	
	int maxCost = 10000;
	
	public IntGrid2D constructGradient( Center c, IntGrid2D roads, ObjectGrid2D locations,
			int gridWidth, int gridHeight ){
		
		// set up initially with everything as expensive as possible
		IntGrid2D result = new IntGrid2D( gridWidth, gridHeight, maxCost );

		Location center = c.loc;
		result.set( center.x, center.y, 0); // the origin!

		// initialize the mechanism to search
		PriorityQueue <TileWrapper> queue = new PriorityQueue <TileWrapper>();
		ArrayList <Location> doNotAdd = new ArrayList <Location> ();
		Bag neighbors = new Bag();
		
		// process neighbors of the original center
		locations.getNeighborsHamiltonianDistance(
				center.x, center.y, 1, false, neighbors, null, null);
		
		// we don't ever need to check the center again: we know its cost
		doNotAdd.add( center );
		
		// check the neighbors and start building the list of tiles to reset
		for(Object o: neighbors){
			
			Location l = (Location) o;
			if( l == center ) continue; // don't recheck the center

			int cost = roadCost(l, roads); // set up its cost
			result.set(l.x, l.y, cost);
			
			// the immediate neighbors of the center need never be checked
			doNotAdd.add( l ); 
			
			// ...but THEIR neighbors should be checked
			Bag neighborsNeighbors = new Bag();
			locations.getNeighborsHamiltonianDistance(
					l.x, l.y, 1, false, neighborsNeighbors, null, null);
			for(Object p: neighborsNeighbors){
				
				Location n = (Location) p;
				if( n == l ) continue; // don't recheck this tile!
				
				// if the location has already been found at this point, it's
				// either the center or one of its neighbors. Don't consider it.
				if( doNotAdd.contains( n )) continue;
				
				// otherwise establish its base cost and save it
				int nCost = cost + roadCost( n, roads );
				result.set(n.x, n.y, nCost);

				// insert it into the queue so that it gets considered again
				queue.add( new TileWrapper( n, nCost) );
				doNotAdd.add(n); // it's in the queue: don't have multiple copies there
			}

		}

		
		// start at center. Push out, expanding along the "cheapest" route
		while( queue.size() > 0 ){
			
			// take cheapest node in the queue and get its info
			TileWrapper t = queue.remove();
			int myCost = result.get(t.l.x, t.l.y);
			int myType = roadCost( t.l, roads );
			
			// check its neighbors: is there a cheaper path for it?
			neighbors = new Bag();
			locations.getNeighborsHamiltonianDistance(
					t.l.x, t.l.y, 1, false, neighbors, null, null);
			
			// ...find the CHEAPEST neighbor
			int bestCost = myCost;
			Location bestNeighbor = null;

			for(Object p: neighbors){
				Location n = (Location) p;
				if( n == t.l ) continue; // don't recheck!
				
				int hisCost = result.get(n.x, n.y);
			
				// if the neighbor offers a better path, take it!
				if( hisCost + myType < bestCost ){
					bestCost = hisCost + myType;
					bestNeighbor = n;
				}
			}
			
			// if there was such a cheapest neighbor, reset our cost!
			if( bestNeighbor != null ){ // we have found a better path
				result.set(t.l.x, t.l.y, bestCost);
				myCost = bestCost;
			}

			// check to see if any neighbors should route this THIS tile
			for(Object p: neighbors){
				Location n = (Location) p;
				if( n == t.l ) continue; // don't recheck!
				
				int hisCost = result.get(n.x, n.y);
				int hisType = roadCost( n, roads );
			
				// if this tile offers a better path for the neighbor, tell the neighbor
				// and submit it so it rechecks its neighbors and options
				if( myCost + hisType < hisCost ){
					int hisNewCost = bestCost + hisType;
					result.set( n.x, n.y, hisNewCost);
					if( ! doNotAdd.contains( n )){
						queue.add( new TileWrapper( n, hisNewCost ) );
						doNotAdd.add( n );
					}
						
				}
			}
			
		}
		
	
		return result;
	}
		
	
	int roadCost(Location l, IntGrid2D roads){
		if(roads.get(l.x, l.y) > 0) return (int)Agent.ENERGY_TO_WALK_PAVED;
		return (int) Agent.ENERGY_TO_WALK_UNPAVED;
	}
	
	class TileWrapper implements Comparable {
		Location l;
		int value;
		
		public TileWrapper( Location l, int value){
			this.l = l;
			this.value = value;
		}
		
		@Override
		public int compareTo(Object arg0) {
			TileWrapper t = (TileWrapper) arg0;
			if( value < t.value ) return 1;
			else if( value > t.value) return -1;
			return 0;
		}
	}
	
	
}


