package haiti;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.util.ArrayList;

import com.vividsolutions.jts.geom.CoordinateSequence;
import com.vividsolutions.jts.geom.Envelope;
import com.vividsolutions.jts.geom.LineString;
import com.vividsolutions.jts.geom.MultiLineString;

import sim.engine.RandomSequence;
import sim.engine.SimState;
import sim.engine.Steppable;
import sim.engine.Stoppable;
import sim.engine.TentativeStep;
import sim.field.geo.GeomVectorField;
import sim.field.grid.IntGrid2D;
import sim.field.grid.ObjectGrid2D;
import sim.field.grid.SparseGrid2D;
import sim.field.network.Edge;
import sim.field.network.Network;
import sim.io.geo.ShapeFileImporter;
import sim.util.Bag;
import sim.util.geo.MasonGeometry;

@SuppressWarnings("restriction")
public class HaitiFood extends SimState {

	public IntGrid2D roads;
	public IntGrid2D destruction;
	public SparseGrid2D centers;
	public SparseGrid2D population;
	ArrayList<IntGrid2D> distanceGradients = new ArrayList<IntGrid2D>();

	public ObjectGrid2D locations;
	public SparseGrid2D nodes;
	public ObjectGrid2D closestNodes; // the road nodes closest to each of the
										// locations
	Network roadNetwork = new Network();
	public static int noRoadValue = 15;

	ArrayList<Center> centersList = new ArrayList<Center>();
	ArrayList<Agent> peopleList = new ArrayList<Agent>();
	public static int maximumDensity = 20;
	public static int riotDensity = 18;

	int centersInitialFood = -1;
	int energyPerFood = -1;
	
	int gridWidth;
	int gridHeight;

	// the scheduling order in which processes fire
	int resetOrder = 1;
	int centerOrder = 2;
	int personOrder = 3;
	int rumorOrder = 4;
	public static int reportOrder = 5;
	
	int deaths_total = 0;
	int deaths_this_tick = 0;
	int rioting = 0;

	// agent parameters 
	double enToStay = -1, enWalkPaved = -1, enWalkUnpav = -1, enRiot = -1; 
	int interval = -1;
	
	
	// Relief File Settings ///
	String reliefFile = null;
	String [] reliefFiles = new String [] {"haitiData/relief1.txt", "haitiData/reliefBETTA.txt", 
			"haitiData/reliefOKBETTA.txt", "haitiData/reliefBAD.txt", "haitiData/reliefSingle.txt"};
	String [] reliefFilesNames = new String [] {"Neutral", "Good", "Better", "Bad", "Single"};
	
	// making the Relief file modifiable
	int reliefFileIndex = 0;
	public int getReliefFileIndex(){ return reliefFileIndex; }
	public void setReliefFileIndex(int r){ reliefFileIndex = r; reliefFile = reliefFiles[r]; }
	public Object domReliefFileIndex() { return reliefFilesNames; }
	
	/** Constructor */
	public HaitiFood(long seed) {
		super(seed);
		
		roadsFile = "haitiData/roads1.txt";
		roadVectorFile ="haitiRoads/Haiti_all_roads_Clip.shp";
		destructionFile ="haitiData/destruction.txt";
		if(reliefFile == null)
			reliefFile ="haitiData/relief1.txt";
		popFile ="haitiData/pop.txt";

	}

	public HaitiFood(long seed, int maxDen, int riotDen, int initFood, int energyFood, double enToStay, 
			double enWalkPaved, double enWalkUnpav, double enRiot, int interval){
		super(seed);
		maximumDensity = maxDen;
		riotDensity = riotDen;
		
		centersInitialFood = initFood;
		energyPerFood = energyFood;
		
		this.enToStay= enToStay;
		this.enWalkPaved = enWalkPaved;
		this.enWalkUnpav = enWalkUnpav;
		this.enRiot = enRiot;
		this.interval = interval;

		roadsFile = "haitiData/roads1.txt";
		roadVectorFile = "haitiRoads/Haiti_all_roads_Clip.shp";
		destructionFile = "haitiData/destruction.txt"; 
		popFile = "haitiData/pop.txt";
		if (reliefFile == null)
			reliefFile = reliefFiles[0]; // pick the default
	}
	
	String roadsFile, roadVectorFile, destructionFile, popFile;
	/** Initialization */
	public void start() {
		super.start();

		// ---- read in data ----

		try {
			// --- ROADS ---

			// read in the raw roads raster (the situation "on the ground")
			System.out.println("reading roads layer...");
			roads = setupFromFile(roadsFile, noRoadValue);

			// store the information about the size of the simulation space
			gridWidth = roads.getWidth();
			gridHeight = roads.getHeight();

			// read in the road vector information (the way people *think* about
			// the road network)
			ShapeFileImporter importer = new ShapeFileImporter();
			GeomVectorField roadLinks = new GeomVectorField();
			importer.ingest( roadVectorFile, roadLinks, null);
			nodes = new SparseGrid2D(gridWidth, gridHeight);
			extractFromRoadLinks(roadLinks); // construct a network of roads

			// set up the locations and nearest node capability
			initializeLocations();
			closestNodes = setupNearestNodes();

			// --- DESTRUCTION ---

			// read in the destruction information
			System.out.println("reading destruction layer...");
			destruction = setupDestructionFromFile(destructionFile);

			// --- DISTRIBUTION CENTERS ---

			// read in the information about food distribution centers
			System.out.println("reading distribution centers layer...");
			centers = setupCentersFromFile(reliefFile);

			// set them up
			for (Center c : centersList) {
				c.loc = (Location) locations.get(c.loc.x, c.loc.y);
			}

			// ---- AGENTS ----
			System.out.println("reading population layer...");
			IntGrid2D tempPop = setupFromFile(popFile, 0);
			population = new SparseGrid2D(tempPop.getWidth(),
					tempPop.getHeight());
			populate(tempPop); // set it up

		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}

		// ---- set up rumors/information spread ----

		RumorMill rumorMill = new RumorMill();
		rumorMill.gridWidth = gridWidth;
		rumorMill.gridHeight = gridHeight;
		schedule.scheduleRepeating(rumorMill, rumorOrder, 1);

		// spread initial information
		triggerRumors();
		
		schedule.scheduleRepeating( new Steppable(){
			public void step(SimState state){
				deaths_this_tick = 0;
				rioting = 0;
			} 
		}, resetOrder, 1);
	}

	/**
	 * Converts information extracted from the shapefile into links determined
	 * by LineString subsequences
	 */
	void extractFromRoadLinks(GeomVectorField roadLinks) {
		Bag geoms = roadLinks.getGeometries();
		Envelope e = roadLinks.getMBR();
		double xmin = e.getMinX(), ymin = e.getMinY(), xmax = e.getMaxX(), ymax = e
				.getMaxY();
		int xcols = gridWidth - 1, ycols = gridHeight - 1;

		// extract each edge
		for (Object o : geoms) {

			MasonGeometry gm = (MasonGeometry) o;
			if (gm.getGeometry() instanceof LineString)
				readLineString((LineString) gm.getGeometry(), xcols, ycols,
						xmin, ymin, xmax, ymax);
			else if (gm.getGeometry() instanceof MultiLineString) {
				MultiLineString mls = (MultiLineString) gm.getGeometry();
				for (int i = 0; i < mls.getNumGeometries(); i++) {
					readLineString((LineString) mls.getGeometryN(i), xcols,
							ycols, xmin, ymin, xmax, ymax);
				}
			}
		}
	}

	/**
	 * Converts an individual linestring into a series of links and nodes in the
	 * network
	 * 
	 * @param geometry
	 * @param xcols - number of columns in the field
	 * @param ycols - number of rows in the field
	 * @param xmin - minimum x value in shapefile
	 * @param ymin - minimum y value in shapefile
	 * @param xmax - maximum x value in shapefile
	 * @param ymax - maximum y value in shapefile
	 */
	void readLineString(LineString geometry, int xcols, int ycols, double xmin,
			double ymin, double xmax, double ymax) {

		CoordinateSequence cs = geometry.getCoordinateSequence();

		// iterate over each pair of coordinates and establish a link between
		// them
		Node oldNode = null; // used to keep track of the last node referenced
		for (int i = 0; i < cs.size(); i++) {

			// calculate the location of the node in question
			double x = cs.getX(i), y = cs.getY(i);
			int xint = (int) Math.floor(xcols * (x - xmin) / (xmax - xmin)), yint = (int) (ycols - Math
					.floor(ycols * (y - ymin) / (ymax - ymin))); // REMEMBER TO FLIP THE Y VALUE

			if (xint >= gridWidth)
				continue;
			else if (yint >= gridHeight)
				continue;

			// find that node or establish it if it doesn't yet exist
			Bag ns = nodes.getObjectsAtLocation(xint, yint);
			Node n;
			if (ns == null) {
				n = new Node(new Location(xint, yint));
				nodes.setObjectLocation(n, xint, yint);
			} else
				n = (Node) ns.get(0);

			if (oldNode == n) // don't link a node to itself
				continue;

			// attach the node to the previous node in the chain (or continue if
			// this is the first node in the chain of links)

			if (i == 0) { // can't connect previous link to anything
				oldNode = n; // save this node for reference in the next link
				continue;
			}

			int weight = (int) n.loc.distanceTo(oldNode.loc); // weight is just
																// distance

			// create the new link and save it
			Edge e = new Edge(oldNode, n, weight);
			roadNetwork.addEdge(e);
			oldNode.links.add(e);
			n.links.add(e);

			oldNode = n; // save this node for reference in the next link
		}
	}

	// set up locations on the location grid for ease of reference
	void initializeLocations() {
		locations = new ObjectGrid2D(gridWidth, gridHeight);
		for (int i = 0; i < gridWidth; i++) {
			for (int j = 0; j < gridHeight; j++) {
				Location l = new Location(i, j);
				locations.set(i, j, l);
			}
		}
	}

	/**
	 * Trigger the initial rumors in a 5 tile area around the centers
	 */
	void triggerRumors() {
		int infoRadius = 5;
		
		  for(int i = 0; i < centersList.size(); i++){
			  Center c = centersList.get(i);
			  Bag seeFoodAtCenter = new Bag();
			  population.getNeighborsMaxDistance(c.loc.x, c.loc.y, infoRadius,
					  false, seeFoodAtCenter, null, null); 
			  for( Object o: seeFoodAtCenter){
				  Agent a = (Agent) o; 
				  a.centerInfo += Math.pow(2, i);
			  }
		  }
		  
	}

	void populate(IntGrid2D pop) {

		long forReference = 0;

		// initialize all pop holders
		for (int i = 0; i < pop.getWidth(); i++) {

			System.out.println("finished: " + i);

			for (int j = 0; j < pop.getHeight(); j++) {

				ArrayList<Agent> ps = new ArrayList<Agent>();

				// get the population
				int tile = pop.get(i, j);
				double tilePop = tile / 10000.; //this is a sample drawn from landscan data

				if (tilePop > 0) {
					forReference += tile;

					int intPop;

					// with equal probability, round up or down
					if (this.random.nextBoolean())
						intPop = (int) Math.floor(tilePop);
					else
						intPop = (int) Math.ceil(tilePop);

					Location here = new Location(i, j);
					int destructionLevel = destruction.get(i, j);

					for (int x = 0; x < Math.min(intPop, 12); x++) {
						Agent a;
						if(interval < 0)
							a = new Agent(here, here.copy(), destructionLevel);
						else
							a = new Agent(here, here.copy(), destructionLevel, enToStay, 
								enWalkPaved, enWalkUnpav, enRiot, interval);
						
						population.setObjectLocation(a, i, j);
						
			//			a.stopper = schedule.scheduleRepeating(a, personOrder, 1);
						
						peopleList.add(a);
					}
				}
			}
		}
		
		Steppable [] steppers = new Steppable [peopleList.size()];
		for(int i = 0; i < steppers.length; i++){
			steppers[i] = (Steppable) (peopleList.get(i));
			Agent a = (Agent) steppers[i];
			steppers[i] = new TentativeStep(a);
			a.stopper = (Stoppable) steppers[i];
		}
			
		RandomSequence seq = new RandomSequence(steppers);
		schedule.scheduleRepeating(seq, personOrder);
		
		System.out.println("Population Size: " + peopleList.size());
		System.out.println("Sum of tiles: " + forReference);
		if(interval < 0){
			enToStay = Agent.ENERGY_TO_STAY;
			enWalkPaved = Agent.ENERGY_TO_WALK_PAVED;
			enWalkUnpav = Agent.ENERGY_TO_WALK_UNPAVED;
			enRiot = Agent.ENERGY_TO_RIOT;
		}
			
	}

	/**
	 * @param filename
	 *            - the name of the file that holds the data
	 */
	IntGrid2D setupFromFile(String filename, int defaultValue) {

		IntGrid2D field = null;

		try { // to read in a file

			// Open the file
			FileInputStream fstream = new FileInputStream(filename);

			// Convert our input stream to a BufferedReader
			BufferedReader d = new BufferedReader(
					new InputStreamReader(fstream));

			// get the parameters from the file
			String s;
			int width = 0, height = 0;
			double nodata = -1;
			for (int i = 0; i < 6; i++) {

				s = d.readLine();

				// format the line appropriately
				String[] parts = s.split(" ", 2);
				String trimmed = parts[1].trim();

				// save the data in the appropriate place
				if (i == 1)
					height = Integer.parseInt(trimmed);
				else if (i == 0)
					width = Integer.parseInt(trimmed);
				else if (i == 5)
					nodata = Double.parseDouble(trimmed);
				else
					continue;
			}

			// set up the field to hold the data
			field = new IntGrid2D(width, height);

			// read in the data from the file and store it in tiles
			int i = 0, j = 0;
			while ((s = d.readLine()) != null) {
				String[] parts = s.split(" ");

				for (String p : parts) {

					int value = Integer.parseInt(p);
					if (value == nodata) // mark the tile as having no value
						value = defaultValue;

					// update the field
					field.set(j, i, value);
					j++; // increase the column count
				}

				j = 0; // reset the column count
				i++; // increase the row count
			}
		}
		// if it messes up, print out the error
		catch (Exception e) {
			System.out.println(e);
		}
		return field;
	}

	/**
	 * @param filename
	 *            - the name of the file that holds the data
	 */
	IntGrid2D setupDestructionFromFile(String filename) {

		IntGrid2D field = null;

		try { // to read in a file

			// Open the file
			FileInputStream fstream = new FileInputStream(filename);

			// Convert our input stream to a BufferedReader
			BufferedReader d = new BufferedReader(
					new InputStreamReader(fstream));

			// get the parameters from the file
			String s;
			int width = 0, height = 0;
			double nodata = -1;
			for (int i = 0; i < 6; i++) {

				s = d.readLine();

				// format the line appropriately
				String[] parts = s.split(" ", 2);
				String trimmed = parts[1].trim();

				// save the data in the appropriate place
				if (i == 1)
					height = Integer.parseInt(trimmed);
				else if (i == 0)
					width = Integer.parseInt(trimmed);
				else if (i == 5)
					nodata = Double.parseDouble(trimmed);
				else
					continue;
			}

			// set up the field to hold the data
			field = new IntGrid2D(width, height);

			// read in the data from the file and store it in tiles
			int i = 0, j = 0;
			while ((s = d.readLine()) != null) {
				String[] parts = s.split(" ");

				for (String p : parts) {

					int value = Integer.parseInt(p);
					if (value == nodata) // mark the tile as having no value
						value = 0;
					else if (value == 51) // no data/unclassified
						value = 0;
					else if (value == 102) // no damage
						value = 1;
					else if (value == 153) // visible damage
						value = 2;
					else if (value == 204) // moderate damage
						value = 3;
					else if (value == 255) // significant damage
						value = 4;
					else
						value = 0; // no data, by our scheme

					// update the field
					field.set(j, i, value);
					j++; // increase the column count
				}

				j = 0; // reset the column count
				i++; // increase the row count
			}
		}
		// if it messes up, print out the error
		catch (Exception e) {
			System.out.println(e);
		}
		return field;
	}

	/**
	 * @param filename - the name of the file that holds the data
	 * @param field - the field to be populated
	 */
	SparseGrid2D setupCentersFromFile(String filename) {

		SparseGrid2D field = null;

		try { // to read in a file

			// Open the file
			FileInputStream fstream = new FileInputStream(filename);

			// Convert our input stream to a BufferedReader
			BufferedReader d = new BufferedReader(
					new InputStreamReader(fstream));

			// get the parameters from the file
			String s;
			int width = 0, height = 0;
			double nodata = -1;
			for (int i = 0; i < 6; i++) {

				s = d.readLine();

				// format the line appropriately
				String[] parts = s.split(" ", 2);
				String trimmed = parts[1].trim();

				// save the data in the appropriate place
				if (i == 1)
					height = Integer.parseInt(trimmed);
				else if (i == 0)
					width = Integer.parseInt(trimmed);
				else if (i == 5)
					nodata = Double.parseDouble(trimmed);
				else
					continue;
			}

			// set up the field to hold the data
			field = new SparseGrid2D(width, height);

			// read in the data from the file and store it in tiles
			int i = 0, j = 0;
			while ((s = d.readLine()) != null) {
				String[] parts = s.split(" ");

				for (String p : parts) {

					int value = Integer.parseInt(p);
					if (value == 1) {
						// update the field
						Bag otherCenters = field.getNeighborsHamiltonianDistance( 
								j, i, 5, false, new Bag(), null, null);
						if(otherCenters.size() > 0)
						// there is already another center established here: we're describing the same center
							continue; 
						
						Center c;
						if(centersInitialFood < 0)
							c = new Center(j, i, 100); // IF YOU WANT TO INCREASE INITIAL FOOD ALLOCATION FOR CENTERS, HERE
						else
							c = new Center(j, i, centersInitialFood, energyPerFood);
						
						field.setObjectLocation(c, j, i);
						centersList.add(c);
						schedule.scheduleRepeating(c, centerOrder, 1);
					}
					j++; // increase the column count
				}

				j = 0; // reset the column count
				i++; // increase the row count
			}
			
			if(centersInitialFood < 0){
				centersInitialFood = 100;
				energyPerFood = Center.ENERGY_FROM_FOOD;
			}
		}
		// if it messes up, print out the error
		catch (Exception e) {
			System.out.println(e);
		}
		return field;
	}

	/** Main function allows simulation to be run in stand-alone, non-GUI mode */

	public static void main(String[] args) {
		doLoop(HaitiFood.class, args);
		System.exit(0);
	}

	/**
	 * Used to store information about the road network
	 */
	class Node {
		Location loc;
		ArrayList<Edge> links;

		public Node(Location l) {
			loc = l;
			links = new ArrayList<Edge>();
		}
	}

	/**
	 * Used to find the nearest node for each space
	 * 
	 */
	class Crawler {

		Node node;
		Location loc;

		public Crawler(Node n, Location l) {
			node = n;
			loc = l;
		}
	}

	/**
	 * Calculate the nodes nearest to each location and store the information
	 * 
	 * @param closestNodes - the field to populate
	 */
	ObjectGrid2D setupNearestNodes() {

		ObjectGrid2D closestNodes = new ObjectGrid2D(gridWidth, gridHeight);
		ArrayList<Crawler> crawlers = new ArrayList<Crawler>();

		for (Object o : roadNetwork.allNodes) {
			Node n = (Node) o;
			Crawler c = new Crawler(n, n.loc);
			crawlers.add(c);
		}

		// while there is unexplored space, continue!
		while (crawlers.size() > 0) {
			ArrayList<Crawler> nextGeneration = new ArrayList<Crawler>();

			// randomize the order in which cralwers are considered
			int size = crawlers.size();

			for (int i = 0; i < size; i++) {

				// randomly pick a remaining crawler
				int index = random.nextInt(crawlers.size());
				Crawler c = crawlers.remove(index);

				// check if the location has already been claimed
				Node n = (Node) closestNodes.get(c.loc.x, c.loc.y);

				if (n == null) { // found something new! Mark it and reproduce

					// set it
					closestNodes.set(c.loc.x, c.loc.y, c.node);

					// reproduce
					Bag neighbors = new Bag();
					locations.getNeighborsHamiltonianDistance(c.loc.x, c.loc.y,
							1, false, neighbors, null, null);
					for (Object o : neighbors) {
						Location l = (Location) o;
						if (l == c.loc)
							continue;
						Crawler newc = new Crawler(c.node, l);
						nextGeneration.add(newc);
					}
				}
				// otherwise just die
			}
			crawlers = nextGeneration;
		}
		return closestNodes;
	}
	
	/** Write the results out to file and clean up after the model */
	public void finish(){
		String report = "haitiResults.txt";
		try {
			// Convert our stream to a BufferedWriter
			BufferedWriter w = new BufferedWriter(new FileWriter(report, true));
			
			int totalNumberPeople = peopleList.size() + deaths_total;
			long totalEnergyInSystem = 0L;
			for(Agent a: peopleList)
				totalEnergyInSystem += a.energyLevel;
			
			int totalFoodLeft = 0;
			for(Center c: centersList)
				totalFoodLeft += c.foodLevel;
			
			// make a csv by replacing each '\t' with ','
			// popfile is output to tell you which scale you're using
	    	String output = popFile + "\t" + reliefFile + "\t" + maximumDensity + "\t" + riotDensity + "\t" 
	    		+ centersInitialFood + "\t" + energyPerFood+ "\t"
	    		+ enToStay + "\t" + enWalkPaved + "\t" + enWalkUnpav  + "\t" +  enRiot  + "\t" 
	    		+ interval + "\t" + schedule.getSteps() + "\t" + totalNumberPeople + "\t" + deaths_total + "\t" 
	    		+ totalEnergyInSystem + "\t" + centersList.size() + "\t" + totalFoodLeft;

	    	w.write( output );
	    	w.newLine();
	    	w.flush();
			
			w.close();

		} catch (Exception e) {
			System.err.println("File input error");
		}
    	
		
		kill(); 
	}
}