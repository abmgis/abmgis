package haiti;

import java.util.ArrayList;
import java.util.HashMap;

import sim.engine.SimState;
import sim.engine.Steppable;
import sim.field.grid.IntGrid2D;
import sim.field.grid.ObjectGrid2D;
import sim.field.grid.SparseGrid2D;
import sim.util.Bag;

/**
 * Used to propagate information about food availability
 *
 */
public class RumorMill implements Steppable {

	int gridWidth;
	int gridHeight;
	
	int rumorDist = 1;
	int neighborhoodType = 1; // 0 = von Neumann, 1 = Moore
	
	
	
	IntGrid2D assembleInfo(SparseGrid2D population){
		IntGrid2D info = new IntGrid2D( gridWidth, gridHeight );
		
		// assemble info for each tile
		for( int i = 0; i < gridWidth; i++){
			for( int j = 0; j < gridHeight; j++){
				
				int tileinfo = 0;
				// comprehensive info for this tile
				
				// check with all agents
				Bag agents = population.getObjectsAtLocation(i, j);
				if( agents != null)
					for( Object o: agents ){
						Agent a = (Agent) o;
						tileinfo = (a.centerInfo | tileinfo);
					}
				
				info.set(i, j, tileinfo);
			}
		}
		return info;
	}
	
	@SuppressWarnings("unchecked")
	IntGrid2D assembleInfoFromNeighbors(IntGrid2D info, ObjectGrid2D locations){
		
		IntGrid2D infoFromNeighbors = new IntGrid2D( gridWidth, gridHeight);
				
		for( int i = 0; i < gridWidth; i++){
			for( int j = 0; j < gridHeight; j++){
				
				// comprehensive info for this tile
				int tileinfo = 0;
			
				Bag neighbors = new Bag();
				if(neighborhoodType == 0)
					locations.getNeighborsHamiltonianDistance(i, j, rumorDist, false, neighbors, null, null);
				else if(neighborhoodType == 1)
					locations.getNeighborsMaxDistance(i, j, rumorDist, false, neighbors, null, null);

				for(Object o: neighbors){
					Location l = (Location) o;

					if (l.x == i && l.y == j)
						continue; // don't exchange info with self

					// get the information from the neighbor tile
					int infoNeighboringTile = info.get(l.x, l.y);
					tileinfo = (tileinfo | infoNeighboringTile);
					
				}
				
				infoFromNeighbors.set(i,j,tileinfo);
			}
		}
		
		return infoFromNeighbors;
	}
	
	IntGrid2D distributeInfo(SparseGrid2D population, IntGrid2D oldInfo, 
			IntGrid2D neighborInfo){
		
		// assemble info for each tile
		for( int i = 0; i < gridWidth; i++){
			for( int j = 0; j < gridHeight; j++){
				
				// comprehensive info for this tile
				int neighborInfoTile = neighborInfo.get(i,j);
				neighborInfoTile = (neighborInfoTile | oldInfo.get(i, j));
								
				Bag agents = population.getObjectsAtLocation(i, j);
				if( agents != null)
					for(Object o: agents){
						((Agent)o).centerInfo = neighborInfoTile;
					}
			}
		}
		return neighborInfo;
	}
	@Override
	public void step(SimState state) {
		
		SparseGrid2D population = ((HaitiFood)state).population;

		System.out.println("RUMOR: " + state.schedule.getSteps());
		
		// TODO: want a Moore vs von Neumann neighborhood? change it in these functions!
		System.out.println("assemble info...");
		IntGrid2D info = assembleInfo(population);
		System.out.println("info assembled");

		System.out.println("consult neighbors...");
		IntGrid2D infoFromNeighbors = assembleInfoFromNeighbors( info, ((HaitiFood)state).locations );
		System.out.println("neighbors consulted");

		System.out.println("redistribute info...");
		distributeInfo(population, info, infoFromNeighbors);
		System.out.println("info redistributed");

	}

}