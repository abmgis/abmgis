package haiti;

import haiti.HaitiFood.Node;

import java.awt.Color;
import java.util.ArrayList;
import java.util.HashMap;

import sim.engine.SimState;
import sim.engine.Steppable;
import sim.engine.Stoppable;
import sim.util.Bag;

/**
 * AGENT
 * 
 * This class holds the attributes and behavior of the individuals who live in
 * the environment. They are motivated by their energy levels, seeking to
 * maximize their energy over the course of the simulation.
 * 
 * Agents can choose to move toward a food distribution center (based on their
 * knowledge of available centers) or to remain at home. Agents try to choose
 * the cheapest source of energy, preferring a closer center to a farther one.
 * If the agents project that getting the food will cost as much energy as the
 * food itself can provide, they will not move.
 * 
 * Agents expend energy to move, in quantities that vary based on the quality of
 * the agent's path and the activity of the crowd. E.g., a paved road "costs"
 * less than an unpaved road, and participating in a riot costs even more
 * energy. If an agent's energy level dips below 0, it dies.
 */
class Agent implements Steppable {

	// ATTRIBUTES
	double energyLevel;
	boolean hasFood = false; // whether the agent has received food
	int activity = ACTION_STAY_HOME; // updated so that the observer can tell what the agent is currently doing

	// info about centers and whether they have food
	int centerInfo = 0; // an efficient way to store information about all of the centers the agent believes 
		// are distributing food. The information is stored as bits, so that if an Agent knows about both 
		// Center 1 and Center 3 it sets its Center Info to the number defined by (Center 1 && Center 3), 
		// or (0001 && 0100) to get (0101) or a centerInfo of 5. This takes advantage of the convenience of 
		// bitwise operations and speeds up the simulation.
	int [] powers = {1, 2, 4, 8, 16, 32, 64, 128};
	

	// info about where the agent is, where it's going, and where its home is 
	Location position = null;
	Location home = null;
	Location goal = null;
	
	// the amount of time since the agent has confirmed that its course of 
	// action is the best available to it
	int timeSinceReevaluate = 0;
	int reevaluateInterval = 1;
	
	ArrayList<Location> path = null; // the agent's current path to its current goal

	// ENERGY PARAMTERS
	// the parameters that indicate how much energy is used every tick the agent
	// does one of these activities. If we want them to die faster, INCREASE THESE COSTS
	public static double ENERGY_TO_STAY = .1;
	public static double ENERGY_TO_WALK_PAVED = .5;
	public static double ENERGY_TO_WALK_UNPAVED = 1.;
	public static double ENERGY_TO_RIOT = 5.;

	// ACTIVITY OPTIONS
	public static int ACTION_STAY_HOME = 0;
	public static int ACTION_GO_TO_CENTER = 1;
	public static int ACTION_GO_HOME = 2;
	
	// OTHER
	public Stoppable stopper = null; // used to unschedule the agent

	/**
	 * @param home - the home location
	 * @param position - the initial position of the agent
	 * @param destruction - the level of destruction on the agent's home tile, which
 	 * impacts its initial energy levels
	 */
	public Agent(Location home, Location position, int destruction) {
		this.home = home;
		this.position = position;

		energyLevel = energyInitialization(destruction);
	}
	
	public Agent(Location home, Location position, int destruction, double enToStay, 
			double enWalkPaved, double enWalkUnpav, double enRiot, int interval) {
		this.home = home;
		this.position = position;
		energyLevel = energyInitialization(destruction);
		
		ENERGY_TO_STAY = enToStay;
		ENERGY_TO_WALK_PAVED = enWalkPaved;
		ENERGY_TO_WALK_UNPAVED = enWalkUnpav;
		ENERGY_TO_RIOT = enRiot;
		reevaluateInterval = interval;	
	}
	

	/**
	 * Calculates the energy level with which the agent should be initialized,
	 * given its destruction. IF WE WANT THEM TO DIE FASTER, SET THESE INITIAL
	 * ENERGIES LOWER
	 * 
	 * @param destruction - the destruction level at the agent's home location
	 * @return the amount of energy with which the agent begins
	 */
	double energyInitialization(int destruction) {

		// either no data / unclassified or no damage.
		if (destruction == 0 || destruction == 1)
			return 2000;

		else if (destruction == 2) // visible damage
			return 1600;
		else if (destruction == 3) // moderate damage
			return 1200;
		else if (destruction == 4) // significant damage
			return 1000;
		return 0;
	}

	/**
	 * Confirm that the Agent is pursuing the best course of action. Checks among
	 * the possible goals the agent might have and picks the best one, given 
	 * the agent's current food-holding status, location, and energy level 
	 * 
	 * ***MUCH MORE WORK CAN BE DONE HERE in terms of agent perception, estimation, etc. ***
	 */
	void checkGoal(HaitiFood state) {

		timeSinceReevaluate = 0; // we have checked just now!

		//
		// Check to see if we're on a course that shouldn't be interrupted
		//
		
		// we're home and fed. Don't go back out
		if (hasFood && position.equals(home)) { 
			activity = ACTION_STAY_HOME;
			goal = null;
			path = null;
			return;
		}

		// we're going home, so keep on keepin' on: we wouldn't be going home unless we'd 
		// gotten food or run out of energy
		else if( goal != null && goal.equals(home)){
			activity = ACTION_GO_HOME;
			return;
		}
		
		// the Agent has procured food, and needs to go home
		else if (hasFood && goal != null) { // it has food and it's not gotten home yet
			activity = ACTION_GO_HOME;
			goal = home;
			path = null;
			return;
		} 

		// we already have a plan and no new information
		else if( goal != null && centerInfo > 0){
			return; 			
		}
		
		if(centerInfo == 0){
			activity = ACTION_STAY_HOME;
			goal = null;
			return;
		}

		//
		// otherwise check for centers and go to the closest one
		//
		Location oldGoal = goal;
		goal = null;
		for(int i = 0; i < state.centersList.size(); i++){

			if( (centerInfo & powers[i]) == 0) continue; // don't know about that center yet!
			Center c = state.centersList.get(i);
			
			// if not going anywhere else, try it
			if (goal == null)
				goal = c.loc;

			// otherwise if it's closer than the current goal, go to it!
			else if (position.distanceTo(c.loc) < position.distanceTo(goal))
				goal = c.loc;
		}
		
		//
		// if the NEAREST POSSIBLE GOAL is not too far, go to it. Otherwise set goal
		// to null and GO HOME
		//
		if( goal != null && 
//				goal.distanceTo(position) * ENERGY_TO_WALK_PAVED < energyLevel ){
				(goal.distanceTo(position) + goal.distanceTo(home)) * ENERGY_TO_WALK_PAVED < energyLevel ){
			if( goal != oldGoal )
				path = null; // force a recalculation of path
			activity = ACTION_GO_TO_CENTER;
		}
		else{
			goal = null;
			activity = ACTION_STAY_HOME; // don't go out
		}
	}

	/**
	 * Unschedules the agent. Called once the agent has died.
	 */
	void die(HaitiFood state) {

		// stop the agent from ticking
		stopper.stop();

		// remove this agent from the population
		state.population.remove(this);
		state.peopleList.remove(this);
		
		state.deaths_total++;
		state.deaths_this_tick++;
	}

	@Override
	public void step(SimState state) {

		HaitiFood hf = (HaitiFood) state;

		// check that the agent hasn't died of low energy
		if (energyLevel <= 0) {
			die(hf);
			return;
		}

		// confirm that current goal is worthwhile/the easiest target
		if( timeSinceReevaluate > reevaluateInterval)
			checkGoal(hf);
		else
			timeSinceReevaluate++;

		//
		// MOVE depending on the goal and path information
		//
		
		// if the agent has no goal, it does not move.
		if (goal == null) {
			energyLevel -= ENERGY_TO_STAY; // update its energy level
			return; // not doing anything
		}

		// otherwise, the agent moves toward its goal. Depending on how it
		// moves, it expends more or less energy
		else {

			if( position.equals(goal) ) { // we have reached our goal! No need to proceed further
				checkGoal(hf); // force a reconsideration of what we should be doing
				return; // take a breather
			}
			
			// make sure we have a path to the goal!
			if (path == null) {
				AStar astar = new AStar();
				path = astar.astarPath(hf,
						(Node) hf.closestNodes.get(position.x, position.y),
						(Node) hf.closestNodes.get(goal.x, goal.y));
				if(path != null)
					path.add(goal);
			}

			
			// determine the best location to immediately move *toward*
			Location subgoal;
			
			// It's possible that the agent isn't close to a node that can take it to the center. 
			// In that case, the A* will return null. If this is so the agent should move toward 
			// the goal until such a node is found.
			if (path == null)  
				subgoal = goal;
			// Otherwise we have a path and should continue to move along it
			else{
				
				// have we reached the end of an edge? If so, move to the next edge
				if (path.get(0).equals(position) ){  
					path.remove(0);
				}
				
				// our current subgoal is the end of the current edge
				if( path.size() > 0 )
					subgoal = path.get(0);
				else
					subgoal = goal;
			}

			// calculate the next tile to move *to*
			Location nextTile = getNextTile(hf, subgoal);

			// get a list of the people currently in the new place. If the density of that space 
			// does not prohibit it, move there
			Bag density = hf.population.getObjectsAtLocation(nextTile.x, nextTile.y);
			if (density == null || density.size() < hf.maximumDensity) {

				energyLevel -= tileCost(position, hf);
				
				// transition between spaces
				hf.population.setObjectLocation(this, nextTile.x, nextTile.y);

				// update my position
				position.x = nextTile.x;
				position.y = nextTile.y;
			}
			// if we can't move to the new tile and we're in a riot, keep rioting
			else if(hf.population.getObjectsAtLocation(position.x, position.y).size() > hf.riotDensity)
				energyLevel -= ENERGY_TO_RIOT;
			// otherwise just stay put
			else
				energyLevel -= ENERGY_TO_STAY;

		}
		
		if(hf.population.getObjectsAtLocation(position.x, position.y).size() > hf.riotDensity)
			hf.rioting++;
	}

	/**
	 * Measures the cost to the agent of moving through the given tile
	 * @param loc - the tile
	 * @param hf
	 * @return the cost of moving through the given tile
	 */
	double tileCost(Location loc, HaitiFood hf){
		Bag people = hf.population.getObjectsAtLocation(loc.x, loc.y);
		if( people != null && people.size() > hf.riotDensity) return ENERGY_TO_RIOT;
		int roadType = hf.roads.get(loc.x, loc.y);
		if( roadType < hf.noRoadValue ) return ENERGY_TO_WALK_UNPAVED;
		else return ENERGY_TO_WALK_PAVED;
	}
	
	/**
	 * Given the subgoal toward which the agent is moving, determine the next tile in 
	 * the von Neumann neighborhood to which the agent should move, weighting roads
	 * tiles as preferable to non-roads
	 * 
	 * @param world
	 * @param subgoal
	 * @return
	 */
	Location getNextTile(HaitiFood world, Location subgoal) {

		// move in which direction?
		int moveX = 0, moveY = 0;
		int dx = subgoal.x - position.x;
		int dy = subgoal.y - position.y;
		if (dx < 0)
			moveX = -1;
		else if (dx > 0)
			moveX = 1;
		if (dy < 0)
			moveY = -1;
		else if (dy > 0)
			moveY = 1;

		// can either move in Y direction or X direction: see which is better
		Location xmove = (Location) world.locations.get(position.x + moveX, position.y);
		Location ymove = (Location) world.locations.get(position.x, position.y + moveY);
		
		boolean xmoveToRoad = ((Integer)world.roads.get(xmove.x, xmove.y)) > -1;
		boolean ymoveToRoad = ((Integer)world.roads.get(ymove.x, ymove.y)) > -1;
		
		if( moveX == 0 && moveY == 0){ // we are ON the subgoal, so don't move at all!
			// both are the same result, so just return the xmove (which is identical)
			return xmove;
		}
		else if(moveX == 0) // this means that moving in the x direction is not a valid move: it's +0
			return ymove;
		else if(moveY == 0) // this means that moving in the y direction is not a valid move: it's +0
			return xmove;
		else if( xmoveToRoad == ymoveToRoad ){ //equally good moves: pick randomly between them
			if( world.random.nextBoolean() ) return xmove;
			else return ymove;
		}
		else if( xmoveToRoad && moveX != 0) // x is a road: pick it
			return xmove;
		else if( ymoveToRoad && moveY != 0)// y is a road: pick it
			return ymove;
		else if( moveX != 0 ) // move in the better direction
			return xmove;
		else if( moveY != 0 ) // yes
			return ymove;
		else 
			return ymove; // no justification
	}

}