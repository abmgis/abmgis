package walkThisWay;

import java.util.ArrayList;
import java.awt.Color;
import java.awt.Point;
import java.lang.Long;
import java.util.Random;

import sim.engine.SimState;
import sim.engine.Steppable;
import sim.engine.Stoppable;
import sim.field.grid.IntGrid2D;
import sim.util.Bag;
import sim.util.DoubleBag;
import sim.util.Int2D;
import sim.util.Int3D;
import sim.util.IntBag;
import sim.util.MutableInt2D;

//
//*****************************************************************************
// Pedestrian

public class Pedestrian implements Steppable {

	Stoppable stopper;

	// a list of four potentially tag properties taken from the pedestrian XML.
	String id = null; // temp store for an ID ref & must be null at start.
	String desc = ""; // temporary storage for a description.

	int oldLocX = 0; // used at least by GroupStatistics, this track position.
	int oldLocY = 0; // used at least by GroupStatistics, this track position.
	int locX = 0; // temporary storage for a description.
	int locY = 0; // temporary storage for a description.

	public int vision = 0;
	public int numNeighbors = 0;
	private int movement = 3; // Current movement distance allowed.
	private int maxMovement = 3; // Max. distance an agent can move in one step.
	private int maxVision = 0; // Max. planning distance of the agent.
	private int entryTimer = 0; // LT 0 = started, 0 = start now, GT 0 =
								// waiting.

	// New Stuff for group identity
	public Color pedColor = null; // individual peds have color.

	// New Stuff for separation of vision & movement
	// ***NOTE*** Replace Point w/ MASON MutableInt2D which has built-in
	// functions
	public Point targetDestination = null;
	public int headingVectorX = 0;
	public int headingVectorY = 0;
	IntGrid2D myGradient = null;
	
	// Reevaluate target destination after this many timesteps.
	public int targetTimerMax;
	public int targetTimer = 0;

	public double averageSpeed = 1.5;
	public double averageDensity = 7.25; // m^2/ped = 1/density
	public double alpha = 0.66; // EWMA, ave. over 7 steps: = 2 / (N+1)

	ArrayList <Int3D> path = new ArrayList <Int3D> ();
	private static final long serialVersionUID = 1L;

	// **********************DEBUGGING***********
	boolean verbose = false;

	// ***************************************************************************
	/** This is the Pedestrian class constructor. */

	public Pedestrian(Int2D location, int sight, int entryTimePoint) {

		id = Long.toHexString(new Random().nextLong()); // random hex ID.
		desc = "none";
		locX = location.x;
		locY = location.y;
		oldLocX = locX;
		oldLocY = locY;
		// LT 0 = started, 1 = start now, GT 0 = waiting to start.
		entryTimer = entryTimePoint;
		vision = sight;
		maxVision = vision;
		numNeighbors = (2 * vision + 1) * (2 * vision + 1);
		// Put in a simple check to make sure that movement is not above vision.
		if (movement > vision) {
			movement = vision;
		}
		if (maxMovement > maxVision) {
			maxMovement = maxVision;
		}

		// Initialize my target to the current location.
		targetDestination = new Point(locX, locY);
		targetTimer = 0;
		targetTimerMax = vision / maxMovement * 2;

		pedColor = Color.blue; // individual peds have a color.

	} // End method.
		// ***************************************************************************

	public Pedestrian(Int2D location, IntGrid2D gradient, int sight, int entryTimePoint) {

		id = Long.toHexString(new Random().nextLong()); // random hex ID.
		desc = "none";
		locX = location.x;
		locY = location.y;
		oldLocX = locX;
		oldLocY = locY;
		myGradient = gradient;
		
		// LT 0 = started, 1 = start now, GT 0 = waiting to start.
		entryTimer = entryTimePoint;
		vision = sight;
		maxVision = vision;
		numNeighbors = (2 * vision + 1) * (2 * vision + 1);
		// Put in a simple check to make sure that movement is not above vision.
		if (movement > vision) {
			movement = vision;
		}
		if (maxMovement > maxVision) {
			maxMovement = maxVision;
		}

		// Initialize my target to the current location.
		targetDestination = new Point(location.x, location.y);
		targetTimer = 0;
		targetTimerMax = vision / maxMovement * 2;

		pedColor = Color.blue; // individual peds have a color.

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/**
	 * WARNING: This is a long method. Among other things this method uses
	 * pedestrian location to determine which TCenter doorway is about to be
	 * used and then sets the TCPeds GLOBAL variables for counts of how many
	 * peds entered each door.
	 */

	@Override
	public void step(SimState state) {

		// Here is the state of the world
		WalkThisWay world = (WalkThisWay) state;

		// Find out the current location of this pedestrian
		Int2D loc = world.people.getObjectLocation(this);

		path.add(new Int3D(loc.x, loc.y, (int)state.schedule.getSteps()));
		

		// LTE 0 = started and GT 0 = waiting to start.
		entryTimer--; // decr timer each time this ped is call to step.

		if (entryTimer <= 0) {

			// let this pedestrian participate in the sim.
			if (entryTimer < 0)
				entryTimer = 0; // control the limit to 0;

			// If we're within the record-keeping portion of the sim, increase the trace on the 
			// IntGrid2D at our current location
			double time = world.schedule.getTime();
			if(time >= world.startKeepingRecords && time <= world.endKeepingRecords)
				world.traces.field[loc.x][loc.y]++;

			// Check to see if the agent is about to enter the TCenter.
//			if (world.floor.field[loc.x][loc.y] == world.minGradient) {
			if (myGradient.field[loc.x][loc.y] == world.minGradient) {
				// NOTE: this is unique to the TCenter.
				final int BETWEEN_ENTRIES = 382;// pnt hf-way East-West btwn
												// entries.

				// Check which entry way the pedestrian has entered.
				int temp = 0; // a temp var for dealing with the counters.
				/*
				 * if (loc.x < BETWEEN_ENTRIES) // test more westerly first. {
				 * temp = world.entryCountersList.get(0); // quick copy.
				 * world.entryCountersList.set(0, ++temp); // qck increment and
				 * store. } else { temp = world.entryCountersList.get(1); //
				 * quick copy. world.entryCountersList.set(1, ++temp); // quick
				 * incrmnt and store. }
				 */
				// Remove from the simulation
				world.people.remove(this);
				world.recordOfPaths.add(path);
				return;
			}

			// ---------------------------------------------------------------------

			// *****DEBUGGING*******
			if (verbose) {
				System.out.println("\nStart of Step Method");
				System.out.println("Current Location = " + loc);
			}
			// ****DEBUGGING*******

			// If ped needs to replan
			if (replan(loc, targetDestination, world)) {
				// *****DEBUGGING*******
				if (verbose) {
					System.out
							.println("Peds needs to replan & find new trgt dstntn");
				}
				// ****DEBUGGING*******

				targetDestination = this.findTargetDestinationNew(world, loc);
				/*
				 * //Increase the vision & movement if it's below max values if
				 * (vision <= maxVision / 2) { vision *= 2; if (movement <=
				 * maxMovement / 2) { movement *= 2; } else if (movement >
				 * maxMovement /2 && movement < maxMovement) { movement =
				 * maxMovement; } } else if (vision > maxVision /2 && vision <
				 * maxVision) { vision = maxVision; movement = maxMovement; }
				 * targetDestination = findTargetDestination(world, loc);
				 * targetTimer = 0; targetTimerMax = vision / movement * 2 + 1;
				 */
			}

			// *****DEBUGGING*******
			if (verbose) {
				System.out.println("Back in Step Method");
				System.out.println("Current Location = " + loc + ", target = "
						+ targetDestination);
			}
			// ****DEBUGGING*******

			// Set the heading vector based upon targetDestination & current
			// location. I use two variables since the Int2D in MASON is
			// immutable & can't be changed
			headingVectorX = (targetDestination.x - loc.x);
			// **NOTE** NEGATIVE SIGN ADDED.
			// This is to account for grid decreasing in y value as you go
			// vertically up
			headingVectorY = -1 * (targetDestination.y - loc.y);

			// Now find my possible movement locations
			// I'm thinking I just find the available tile that has the largest
			// dotproduct with headingVectorX assuming that it is positive.
			// Otherwise just find the lowest gradient tile to go to.
			Int2D newLoc = findNewLocation(world, loc, maxMovement);

			double dist = loc.distance(newLoc);

			world.totalDistanceTraveled += dist;// update distance traveled of
												// agent

			if(time >= world.startKeepingRecords && time <= world.endKeepingRecords)
				world.totalPedSteps++;// update number of steps

			// Now move to this location & update information
			world.people.setObjectLocation(this, newLoc);
			locX = newLoc.x; // update ped's grid X property.
			locY = newLoc.y; // update ped's grid Y property.

			// Calculate the distance moved and therefore speed.
			// 0.5 * because we want meters/sec & not grids/sec.
			double currentSpeed = 0.5 * loc.distance(locX * 1.0, locY * 1.0);
			// double currentSpeed = 0.5 * Math.sqrt((locX - loc.x) *
			// (locX - loc.x)*1.0 + 1.0*
			// (locY - loc.y)*(locY - loc.y));
			averageSpeed = alpha * currentSpeed + (1 - alpha) * averageSpeed;

			// If I've taken too long to achieve my target, set target to
			// current location. This will cause retargeting the next step.
			// I've made this to be adaptive so that people don't get stuck.
			// This probably needs to be made to adaptively grow back to the
			// planningVision set at the start of the run.
			// targetTimer++;
			// if (targetTimer > targetTimerMax)
			// {
			// vision = 1;
			// movement = 1;
			/*
			 * //Change the vision, but not movement if (vision >=
			 * 2*maxMovement) { vision /= 2; targetTimerMax = vision / movement
			 * * 2; } //Change the vision and the movement else if (vision > 1
			 * && vision < 2*maxMovement) { vision--; if (vision < movement) {
			 * movement = vision; } }
			 */
			// Find a new target which uses the new vision & reset the timer.
			// targetDestination = findTargetDestination(world, loc);
			// targetTimer = 0;
			// targetTimerMax = vision/movement * 2;
			// }

			// Schedule self to update next turn
			// Order of the update is proportional to the distance from the
			// exit,
			// e.g., gradient of grid.

		} // end of the entryTimer test.

		world.schedule.scheduleOnce(this,
//				(int) (1 + world.floor.field[loc.x][loc.y]));
				(int) (1 + myGradient.field[loc.x][loc.y]));

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/*
	 * Determine if the pedestrian needs to replan, i.e., choose a new target
	 * destination.
	 */
	private boolean replan(Int2D loc, Point target, WalkThisWay world) {
		// Replan if
		// 1). Arrived at target destination (original code)
		// 2). Near the target destination, but target is occupied
		// 3). Current location's floor value is lower than target's floor value
		// 4). Line of sight has an obstruction.

		if (target.x == loc.x && target.y == loc.y) {
			return true;
		} else if ((target.x - loc.x) * (target.x - loc.x) + (target.y - loc.y)
				* (target.y - loc.y) <= this.maxMovement * this.maxMovement
				&& world.people.getObjectsAtLocation(target.x, target.y) != null) {
			return true;
//		} else if (world.floor.field[loc.x][loc.y] <= world.floor.field[target.x][target.y]) {
		} else if (myGradient.field[loc.x][loc.y] <= myGradient.field[target.x][target.y]) {
			return true;
		}
		// Only check line of sight periodically
		else if (world.random.nextDouble() < 0.2) {
			if (this.checkLineOfSight(world, loc, target) > 0) {
				return true;
			}
		}
		// else
		// {
		// return false;
		// }

		return false;
	} // End method
		// ***************************************************************************

	// BUG -- this needs a bunch of work.
	// Ideas - Switch to MutableInt2D which has a dot function built in.
	// Ideas - Fix the maxSpeed which seems to be in m/s and not grid/s.
	// This may explain the slow speed.
	// Ideas - Density should be calculated at a fixed distance from loc
	// and perhaps only looking in front of person.
	// ***************************************************************************
	private Int2D findNewLocation(WalkThisWay world, Int2D loc,
			int maxDistance) {
		int numMovementNeighbors = (2 * maxDistance + 1)
				* (2 * maxDistance + 1);

//		DoubleBag nearbyGradients = new DoubleBag(numMovementNeighbors);
		IntBag nearbyGradients = new IntBag(numMovementNeighbors);
		IntBag nearbyX = new IntBag(numMovementNeighbors);
		IntBag nearbyY = new IntBag(numMovementNeighbors);

		// Store the maximum dotproduct between heading & tile
		double maxDotProduct = 0;
		Bag maxDotProducts = new Bag();
		// Add my current location to the bag. That way I can choose not
		// to move if there is no location with a higher dot product.
		maxDotProducts.add(new Int2D(loc.x, loc.y));

		// Get nearby neighbors
		getNeighbors(world, loc, maxDistance, world.getNeighborhoodType(),
				nearbyGradients, nearbyX, nearbyY);

		// I'm thinking to loop through and determine the density.
		// This will determine the distance that can be traveled this step.
		int countLocalPeds = 0;
		for (int i = 0; i < nearbyX.numObjs; i++) {
			int tileX = nearbyX.objs[i];
			int tileY = nearbyY.objs[i];

			countLocalPeds += world.people.numObjectsAtLocation(tileX, tileY);
		}

		// Castle, 2007a has chart of speed vs. available space (m^2/person).
		// Multiple by 0.25 since each grid is 0.25 m^2.
		double availableSpace = nearbyX.numObjs * 0.25 / countLocalPeds;
		// Multiple by factor of 2 to convert from m/s into # of grids per
		// second.
		double maxSpeed = walkingSpeed(availableSpace) * 2;
		//maxSpeed = 3.0; // use this if you want unrestricted speed.
		
		// Keep track of average 1 / density.
		averageDensity = alpha * availableSpace + (1 - alpha) * averageDensity;

		// Now loop through nearby tiles & find dotproduct with heading
		for (int i = 0; i < nearbyX.numObjs; i++) {
			int tileX = nearbyX.objs[i];
			int tileY = nearbyY.objs[i];

			// Distance vector between the current location & this tile
			// I use two variables since the Int2D in MASON is immutable
			// & can't be changed
			int distanceX = (tileX - loc.x);
			// **NOTE** NEGATIVE SIGN ADDED.
			// This is to account for grid decreasing in y value as you go
			// vertically up
			int distanceY = -1 * (tileY - loc.y);

			double distanceSquared = distanceX * distanceX * 1.0 + distanceY
					* distanceY * 1.0;

			// Look at tile as long as it is unoccupied and is a walkable area
			// BUG -- It looks like maxSpeed is in m/s, but is not converted to
			// grids.
			if (world.people.numObjectsAtLocation(tileX, tileY) == 0
					//&& world.floor.get(tileX, tileY) > 0.0
					&& myGradient.get(tileX, tileY) > 0.0
					&& world.obstacles.get(tileX, tileY) <= 0.0
					&& distanceSquared <= maxSpeed * maxSpeed) {
				// This tile is my target destination. So choose it.
				if (tileX == targetDestination.x
						&& tileY == targetDestination.y) {
					maxDotProduct = Double.MAX_VALUE;
					maxDotProducts.clear();
					maxDotProducts.add(new Int2D(tileX, tileY));
				} else {
					// Find the dotproduct with the heading from
					// targetDestination
					double dotProduct = distanceX * headingVectorX + distanceY
							* headingVectorY;

					// I'm collection locations that have the maximum dot
					// product
					// This may be more than one location, so I use a bag.
					if (dotProduct > maxDotProduct) {
						maxDotProducts.clear();
						maxDotProduct = dotProduct;
						maxDotProducts.add(new Int2D(tileX, tileY));
					} else if (dotProduct == maxDotProduct) {
						maxDotProducts.add(new Int2D(tileX, tileY));
					}
				}
			}
		}

		// Found a new grid cell that is both available and desirable.
		// Randomly select among the free grids that had the greatest dot
		// product
		// among my neighbors
		if (maxDotProducts.numObjs == 1) {
			return (Int2D) maxDotProducts.get(0);
		} else if (maxDotProducts.numObjs > 1) {
			// Select the tile that has the lowest gradient.
			double minGrad = 999999;
			int minGradIndex = world.random.nextInt(maxDotProducts.numObjs);

			for (int i = 0; i < maxDotProducts.numObjs; i++) {
				Int2D currentLocation = (Int2D) maxDotProducts.get(i);
				if (myGradient.field[currentLocation.x][currentLocation.y] < minGrad 
						&& world.obstacles.field[currentLocation.x][currentLocation.y] <= 0.) {
//				if (world.floor.field[currentLocation.x][currentLocation.y] < minGrad) {
					minGrad = myGradient.field[currentLocation.x][currentLocation.y];
//					minGrad = world.floor.field[currentLocation.x][currentLocation.y];
					minGradIndex = i;
				}
			}
			return (Int2D) maxDotProducts.get(minGradIndex);
		} else {
			return null;
		}

		/**
		 * if (maxDotProducts.numObjs > 0) { //select randomly from the eligible
		 * neighbors int tileNr = world.random.nextInt(maxDotProducts.numObjs);
		 * return (Int2D) maxDotProducts.get(tileNr); } else { return null; }
		 */
	} // End method findNewLocation
		// *****************************************************************************

	// ***************************************************************************
	// Method to consolidate the searching of nearby neighbors. Previously, the
	// code had two spots (findNewLocation & findNewTarget) where I did a nearby
	// search. I discovered that I changed the code in one place, but not the
	// other. So it makes sense to consolidate the code. This will also allow
	// for a GUI parameter to pick which neighbors (max, Hamiltonian, Hexagonal,
	// or circle) to get.
	// ***************************************************************************
	private void getNeighbors(WalkThisWay world, Int2D loc,
//			int maxDistance, int neighborhood, DoubleBag nearbyGradients,
			int maxDistance, int neighborhood, IntBag nearbyGradients,
			IntBag nearbyX, IntBag nearbyY) {
		if (neighborhood == 0) {
//			world.floor.getNeighborsMaxDistance(loc.x, loc.y, maxDistance,
			myGradient.getNeighborsMaxDistance(loc.x, loc.y, maxDistance,
					false, nearbyGradients, nearbyX, nearbyY);
		} else if (neighborhood == 1) {
//			world.floor.getNeighborsHamiltonianDistance(loc.x, loc.y,
			myGradient.getNeighborsHamiltonianDistance(loc.x, loc.y,
					maxDistance, false, nearbyGradients, nearbyX, nearbyY);
		} else if (neighborhood == 2) {
//			world.floor.getNeighborsHamiltonianDistance(loc.x, loc.y,
			myGradient.getNeighborsHamiltonianDistance(loc.x, loc.y,
					maxDistance, false, nearbyGradients, nearbyX, nearbyY);
		} else if (neighborhood == 3) {
			// Get all neighbors within max distance (square shape)
//			world.floor.getNeighborsMaxDistance(loc.x, loc.y, maxDistance,
			myGradient.getNeighborsMaxDistance(loc.x, loc.y, maxDistance,
					false, nearbyGradients, nearbyX, nearbyY);

			// Create some temporary bags.
//			DoubleBag tempGradients = new DoubleBag(nearbyGradients.numObjs);
			IntBag tempGradients = new IntBag(nearbyGradients.numObjs);
			IntBag tempNearbyX = new IntBag(nearbyX.numObjs);
			IntBag tempNearbyY = new IntBag(nearbyY.numObjs);

			for (int i = 0; i < nearbyX.numObjs; i++) {
				// Calculate the distance from the current location, loc to tile
				double distanceSquared = loc.distanceSq(1.0 * nearbyX.objs[i],
						1.0 * nearbyY.objs[i]);

				// Store the tile info if within max distance.
				if (distanceSquared <= maxDistance * maxDistance * 1.0) {
					tempGradients.add(nearbyGradients.objs[i]);
					tempNearbyX.add(nearbyX.objs[i]);
					tempNearbyY.add(nearbyY.objs[i]);
				}
			}

			// Now copy the temp bags into the original bags.
			nearbyGradients.clear();
			nearbyGradients.addAll(tempGradients);
			nearbyX.clear();
			nearbyX.addAll(tempNearbyX);
			nearbyY.clear();
			nearbyY.addAll(tempNearbyY);
		} // end "circle"
		else // Default is to use the "Max" method
		{
//			world.floor.getNeighborsMaxDistance(loc.x, loc.y, maxDistance,
			myGradient.getNeighborsMaxDistance(loc.x, loc.y, maxDistance,
					false, nearbyGradients, nearbyX, nearbyY);
			System.out.println("Neighborhood type didn't match.  Using 'Max'");
		}
	} // End getNeighbors() method.
		// *************************************************************************

	// ***************************************************************************
	// *Calculate the allowed walking speed based upon the meters squared / ped.
	// Based upon the graph from Andrew (Castle, 2007a).
	private double walkingSpeed(double availableSpace) {
		if (availableSpace >= 1.402)
			return 1.5;
		else if (availableSpace >= 1.308 && availableSpace < 1.402)
			return 1.445;
		else if (availableSpace >= 1.22 && availableSpace < 1.308)
			return 1.39;
		else if (availableSpace >= 1.14 && availableSpace < 1.22)
			return 1.335;
		else if (availableSpace >= 1.05 && availableSpace < 1.14)
			return 1.28;
		else if (availableSpace >= 0.95 && availableSpace < 1.05)
			return 1.1875;
		else if (availableSpace >= 0.85 && availableSpace < 0.95)
			return 1.125;
		else if (availableSpace >= 0.75 && availableSpace < 0.85)
			return 1.0625;
		else if (availableSpace >= 0.65 && availableSpace < 0.75)
			return 0.9375;
		else if (availableSpace >= 0.55 && availableSpace < 0.65)
			return 0.8125;
		else if (availableSpace >= 0.45 && availableSpace < 0.55)
			return 0.6875;
		else
			return 0.5;
	} // End method
		// ***************************************************************************

	// ***************************************************************************
	// Finds the lowest floor value within vision distance.
	// This methods checks the line of sight between the current location &
	// target. If there is an obstruction, then change the peds vision to the
	// distance to the obstruction and try again. Keep going till a target is
	// found with a clean line of sight. To help with computational speed, I
	// do NOT reset the vision back to the maximum. Instead I scale it back up
	// by a factor of 2 each time until the maximum vision is reached.
	private Point findTargetDestinationNew(WalkThisWay world, Int2D loc) {
		// *****DEBUGGING*******
		if (verbose) {
			System.out.println("Start of findTargetDestinationNew");
			System.out.println("Current Location = " + loc);
		}
		// ****DEBUGGING*******

//		double currentHeight = world.floor.field[loc.x][loc.y];
		double currentHeight = myGradient.field[loc.x][loc.y];
		boolean findNewTarget = true;
		Point newTargetDestination = null;

		// *****DEBUGGING******
		int counter = 0;
		// *****DEBUGGING******

		while (findNewTarget) {
			// *****DEBUGGING*******
			counter++;
			if (verbose) {
				System.out.println("Inside while loop, counter = " + counter + ", vision = " + vision);
			}
			// ****DEBUGGING*******

			int numberOfNeighbors = (2 * vision + 1) * (2 * vision + 1);
			// Find out who my neighbors are
			// Create bags to store x,y, gradient of my neighbors.
//			DoubleBag nearbyGradients = new DoubleBag(numberOfNeighbors);
			IntBag nearbyGradients = new IntBag(numberOfNeighbors);
			IntBag nearbyX = new IntBag(numberOfNeighbors);
			IntBag nearbyY = new IntBag(numberOfNeighbors);

			// Store minimum height and its location
			double minHeight = currentHeight;
			Bag minGrids = new Bag();
			minGrids.add(new Point(loc.x, loc.y));

			// Get the nearby neighbors
			getNeighbors(world, loc, vision, world.getNeighborhoodType(),
					nearbyGradients, nearbyX, nearbyY);

			// Now loop through grids cells in vision & find lowest gradient
			// This will become the new targetDestination.
			for (int i = 0; i < nearbyGradients.numObjs; i++) {
				
				// Skip over this nearby grid if already occupied by a pedestrian
				// This works as long as people contains only pedestrian objects!
				// Also skip if tile is out-of-bounds.
				if (world.people.numObjectsAtLocation(nearbyX.objs[i], nearbyY.objs[i]) > 0
//						|| world.floor.field[nearbyX.objs[i]][nearbyY.objs[i]] < 1) {
						|| myGradient.field[nearbyX.objs[i]][nearbyY.objs[i]] < 1
						|| world.obstacles.field[nearbyX.objs[i]][nearbyY.objs[i]] > 0) {
					continue;
				}
				// A new minimum gradient has been found. Flush out the minGrids bag.
				// The gradient needs to be greater than or equal to minGradient of
				// the walkable area. Remember that the out of bounds are given a
				// value of 0 so that they can be displayed as a different color
//				else if (world.floor.field[nearbyX.objs[i]][nearbyY.objs[i]] < minHeight
//						&& world.floor.field[nearbyX.objs[i]][nearbyY.objs[i]] >= world.minGradient) {
				else if (myGradient.field[nearbyX.objs[i]][nearbyY.objs[i]] < minHeight
						&& myGradient.field[nearbyX.objs[i]][nearbyY.objs[i]] >= world.minGradient
						&& world.obstacles.field[nearbyX.objs[i]][nearbyY.objs[i]] <= 0.) {
					minGrids.clear();
//					minHeight = world.floor.field[nearbyX.objs[i]][nearbyY.objs[i]];
					minHeight = myGradient.field[nearbyX.objs[i]][nearbyY.objs[i]];
					minGrids.add(new Point(nearbyX.objs[i], nearbyY.objs[i]));
				}
				// Current tile has the same height as the minimum. Add it to the bag of minGrids
//				else if (world.floor.field[nearbyX.objs[i]][nearbyY.objs[i]] == minHeight) {
				else if (myGradient.field[nearbyX.objs[i]][nearbyY.objs[i]] == minHeight
						&& world.obstacles.field[nearbyX.objs[i]][nearbyY.objs[i]] <= 0.) {
					minGrids.add(new Point(nearbyX.objs[i], nearbyY.objs[i]));
				}
			} // End for loop

			// *****DEBUGGING*******
			if (verbose) {
				System.out.println("Size of minGrids = " + minGrids.size()
						+ ", check each for line of sight clearance");
			}
			// ****DEBUGGING*******

			// Check these potential targets to ensure that they have line-of-sight.
			// If none have a direct line-of-sight, then reduce the vision and go back
			// to the top of the while loop. Store all targets with no obstruction
			// in the Bag potentialTargets.
			Bag potentialTargets = new Bag();
			int minNewVision = this.maxVision;

			for (int j = 0; j < minGrids.numObjs; j++) {
				// *****DEBUGGING*******
				if (verbose) {
					System.out.println("Checking minGrids number " + j);
				}
				// ****DEBUGGING*******

				int obstructionDistance = checkLineOfSight(world, loc,
						(Point) minGrids.objs[j]);

				// *****DEBUGGING*******
				if (verbose) {
					System.out.println("Back in findTargetDestinationNew, minGrid " + j
									+ " has obstructionDistance = " + obstructionDistance);
				}
				// ****DEBUGGING*******

				// This potential target destination has line of sight.
				if (obstructionDistance == 0) {
					potentialTargets.add(minGrids.objs[j]);
				}
				// This potential target destination has an obstruction.
				// Record its distance to the obstruction.
				else {
					if (obstructionDistance < minNewVision) {
						minNewVision = obstructionDistance;

						// *****DEBUGGING*******
						if (verbose) {
							System.out.println("Set minNewVision to obstructionDistance, minNewVision = " + minNewVision);
						}
						// ****DEBUGGING*******

					}
				} // End else statement
			} // End for loop through potential new targets

			// *****DEBUGGING*******
			if (verbose) {
				System.out.println("# of minGrids with no obstruction = " + potentialTargets.size());
			}
			// ****DEBUGGING*******

			// We found at least one viable target destination
			if (potentialTargets.numObjs > 0) {
				// select randomly from the eligible neighbors
				int tileNr = world.random.nextInt(potentialTargets.numObjs);
				// Assign new point to new target destination
				newTargetDestination = (Point) potentialTargets.get(tileNr);

				// *****DEBUGGING*******
				if (verbose) {
					System.out.println("New Target Destination found, " + newTargetDestination);
				}
				// ****DEBUGGING*******

				// Reset the findNewTarget boolean controlling while loop
				findNewTarget = false;
			}
			// All potential targets had obstruction. Set vision to minNewVision
			else {
				// Need to put in extra stuff for when the vision is less than
				// minNewVision. Otherwise we were getting stuck in infinite
				// loop
				// for max & hex neighborhood.
				if (vision <= minNewVision) {
					vision--;
				} else {
					vision = minNewVision;
				}
				if (vision < 1) {
					vision = 1;
				}

				// *****DEBUGGING*******
				if (verbose) {
					System.out.println("No target destination found, set vision to minNewVision, " + vision);
				}
				// ****DEBUGGING*******
			}

		} // End while loop

		// Scale the vision back up by a factor of 2 until the max is reached.
		vision *= 2;
		if (vision > maxVision) {
			vision = this.maxVision;
		}
		// Reset the vision back to its maximum.
		// vision = maxVision;

		// *****DEBUGGING*******
		if (verbose) {
			System.out.println("End of findTargetDestinationNew, target = " + newTargetDestination + ", vision = " + vision);
		}
		// ****DEBUGGING*******

		return newTargetDestination;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	// Checks the line of sight between the peds current location, loc, and a
	// potential new target location, target.
	// Returns 0 if the line of sight is clear
	// Returns non-zero for the distance to the closest point of obstruction to
	// current location.
	private int checkLineOfSight(WalkThisWay world, Int2D loc, Point target) {

		// *****DEBUGGING*******
		if (verbose) {
			System.out.println("Start of checkLineOfSight Method");
			System.out.println("Current Location = " + loc + ", target = "
					+ target);
		}
		// ****DEBUGGING*******

		int obstructionDistance = 0; // this is what will be returned
		// Store the x,y pairs that comprise the line of sight.
		ArrayList<Int2D> lineOfSight = new ArrayList<Int2D>();

		// -------------------------------------------------------------------------
		// Fill up the array list storing the points to check for obstructions
		// If the y-distance is greater, then sweep through y values.
		if (Math.abs(loc.x - target.x) < Math.abs(loc.y - target.y)) {
			for (int i = 1; i <= Math.abs(target.y - loc.y); i++) {
				int y;
				if (target.y > loc.y)
					y = loc.y + i;
				else
					y = loc.y - i;
				int x = (int) ((1.0 * target.x - loc.x) / (target.y - loc.y)
						* (y - loc.y) + loc.x);
				lineOfSight.add(new Int2D(x, y));
			}
		} else // sweep through the x values
		{
			for (int i = 1; i <= Math.abs(target.x - loc.x); i++) {
				int x;
				if (target.x > loc.x)
					x = loc.x + i;
				else
					x = loc.x - i;
				int y = (int) ((1.0 * target.y - loc.y) / (target.x - loc.x)
						* (x - loc.x) + loc.y);
				lineOfSight.add(new Int2D(x, y));
			}
		}
		// -------------------------------------------------------------------------

		// Now simply check the floor field values for 0.0 along line of sight
		int k = 0;
		while (k < lineOfSight.size()) {
			int x = lineOfSight.get(k).x;
			int y = lineOfSight.get(k).y;
			// *****DEBUGGING*******
			if (verbose) {
				System.out.println("checkLineOfSight while loop, counter = "
						+ k + ", [x,y] = " + "[" + x + ", " + y + "]");
			}
			// ****DEBUGGING*******

			// We found an obstruction.
			if( world.obstacles.field[x][y] > 0) {
//			if (myGradient.field[x][y] == 0.0) {
//			if (world.floor.field[x][y] == 0.0) {
				obstructionDistance = (int) Math.sqrt((x - loc.x) * (x - loc.x)
						+ (y - loc.y) * (y - loc.y));
				k = lineOfSight.size();

				// *****DEBUGGING*******
				if (verbose) {
					System.out.println("Obstruction found at [" + x + ", " + y
							+ "]," + " obstructionDistance = "
							+ obstructionDistance + ", floor value = "
							//+ world.floor.field[x][y]);
							+ myGradient.field[x][y]);
				}
				// ****DEBUGGING*******

			}
			k++;
		}

		return obstructionDistance;
	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	// Finds the lowest floor value within vision distance.
	private Point findTargetDestination(WalkThisWay world, Int2D loc) {
//		double currentHeight = world.floor.field[loc.x][loc.y];
		double currentHeight = myGradient.field[loc.x][loc.y];

		// Find out who my neighbors are
		// Create bags to store x,y, gradient of my neighbors.
//		DoubleBag nearbyGradients = new DoubleBag(numNeighbors);
		IntBag nearbyGradients = new IntBag(numNeighbors);
		IntBag nearbyX = new IntBag(numNeighbors);
		IntBag nearbyY = new IntBag(numNeighbors);

		// Store minimum height and its location
		double minHeight = currentHeight;
		Bag minGrids = new Bag();
		minGrids.add(new Point(loc.x, loc.y));

		// Get the nearby neighbors
		getNeighbors(world, loc, vision, world.getNeighborhoodType(),
				nearbyGradients, nearbyX, nearbyY);

		// Now loop through grids cells in vision & find lowest gradient
		// This will become the new targetDestination.
		for (int i = 0; i < nearbyGradients.numObjs; i++) {
			// Skip over this nearby grid if already occupied by a pedestrian
			// This works as long as people contains only pedestrian objects!
			// Also skip if tile is out-of-bounds.
			if (world.people.numObjectsAtLocation(nearbyX.objs[i],
					nearbyY.objs[i]) > 0
					|| world.obstacles.field[nearbyX.objs[i]][nearbyY.objs[i]] > 0.
//					|| world.floor.field[nearbyX.objs[i]][nearbyY.objs[i]] < 1) {
					|| myGradient.field[nearbyX.objs[i]][nearbyY.objs[i]] < 1) {
				continue;
			}
			// A new minimum gradient has been found. Flush out the minGrids
			// bag.
			// The gradient needs to be greater than or equal to minGradient of
			// the walkable area. Remember that the out of bounds are given a
			// value of 0 so that they can be displayed as a different color
//			else if (world.floor.field[nearbyX.objs[i]][nearbyY.objs[i]] < minHeight
//					&& world.floor.field[nearbyX.objs[i]][nearbyY.objs[i]] >= world.minGradient) {
			else if (myGradient.field[nearbyX.objs[i]][nearbyY.objs[i]] < minHeight
					&& myGradient.field[nearbyX.objs[i]][nearbyY.objs[i]] >= world.minGradient) {
				minGrids.clear();
//				minHeight = world.floor.field[nearbyX.objs[i]][nearbyY.objs[i]];
				minHeight = myGradient.field[nearbyX.objs[i]][nearbyY.objs[i]];
				minGrids.add(new Point(nearbyX.objs[i], nearbyY.objs[i]));
			}
			// Current tile has the same height as the minimum. Add it to the
			// bag of minGrids
//			else if (world.floor.field[nearbyX.objs[i]][nearbyY.objs[i]] == minHeight) {
			else if (myGradient.field[nearbyX.objs[i]][nearbyY.objs[i]] == minHeight) {
				minGrids.add(new Point(nearbyX.objs[i], nearbyY.objs[i]));
			}
		} // End for loop

		// Found a new grid cell that is both available and desirable.
		// Randomly select among the free grids that had the lowest gradient
		// among my neighbors
		if (minGrids.numObjs > 0) {
			// select randomly from the eligible neighbors
			int tileNr = world.random.nextInt(minGrids.numObjs);
			return (Point) minGrids.get(tileNr);
		} else {
			return null;
		}
	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method returns the ped ID. */

	public String getId() {

		return id;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method returns the ped description. */

	public String getDesc() {

		return desc;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method sets the description string. Used by sensor for detection. */

	public void setDesc(String desc) {

		this.desc = desc;

	} // End method
		// ***************************************************************************

	// ***************************************************************************
	/** The method returns the ped x coordinate. */

	public int getLocX() {

		return locX;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method returns the ped y coordinate. */

	public int getLocY() {

		return locY;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** The method returns the ped X old coordinate. */

	public int _getOldLocX() {

		return oldLocX;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** The method sets the ped X old coordinate. */

	public void _setOldLocX(int newOldLocX) {

		oldLocX = newOldLocX;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method returns the ped Y old coordinate. */

	public int _getOldLocY() {

		return oldLocY;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method sets the ped Y old coordinate. */

	public void _setOldLocY(int newOldLocY) {

		oldLocY = newOldLocY;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method gets the ped targetDestination. */

	public Point getTargetDestination() {
		return targetDestination;
	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method gets the ped x-component heading. */

	public int getHeadingVectorX() {
		return headingVectorX;
	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method gets the ped y-component heading. */

	public int getHeadingVectorY() {
		return headingVectorY;
	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method returns the current vision distance allowed */

	public int getVision() {
		return vision;
	}

	// End method.
	// ***************************************************************************

	// ***************************************************************************
	/** This returns the current movement distance allowed */

	public int getMovement() {
		return movement;
	}

	// End method.
	// ***************************************************************************

	// ***************************************************************************
	/** This returns the current target timer */

	public int getTargetTimer() {
		return targetTimer;
	}

	// End method.
	// ***************************************************************************

	// ***************************************************************************
	/** This returns the current target timer */

	public int getTargetTimerMax() {
		return targetTimerMax;
	}

	// End method.
	// ***************************************************************************

	// ***************************************************************************
	/** This returns the averageSpeed. */

	public double getAverageSpeed() {
		return averageSpeed;
	}

	// End method.
	// ***************************************************************************

	// ***************************************************************************
	/** This returns the averageDensity - actually 1/density (m^2/ped). */

	public double getAverageDensity() {
		return averageDensity;
	}

	// End method.
	// ***************************************************************************

	// ***************************************************************************
	/** This returns the alpha. */

	public double getAlpha() {
		return alpha;
	}

	// End method.
	// ***************************************************************************

	// ***************************************************************************
	/** This returns the alpha to set. */

	public void setAlpha(double alpha) {
		this.alpha = alpha;
	}

	// End method.
	// ***************************************************************************

	// ***************************************************************************
	/** This sets the pedestrians entry time value. */

	public void _setEntryTimer(int startTime) {
		this.entryTimer = startTime;
	}

	// End method.
	// ***************************************************************************

	// ***************************************************************************
	/** This gets the pedestrians entry time value. */

	public int _getEntryTimer() {
		return this.entryTimer;
	}

	// End method.
	// ***************************************************************************

	// ***************************************************************************
	/** This method gets the verbose control. */

	public boolean isVerbose() {

		return verbose;

	}

	// End method.
	// ***************************************************************************

	// ***************************************************************************
	/** This method sets the verbose control. */

	public void setVerbose(boolean verbose) {

		this.verbose = verbose;

	}

	// End method.
	// ***************************************************************************

}
