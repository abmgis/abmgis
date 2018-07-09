package haiti;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.geom.GeneralPath;
import java.awt.geom.Rectangle2D;
import java.util.ArrayList;

import javax.swing.JFrame;

import org.jfree.data.xy.XYSeries;

import sim.display.Console;
import sim.display.Controller;
import sim.display.Display2D;
import sim.display.GUIState;
import sim.engine.SimState;
import sim.engine.Steppable;
import sim.field.grid.IntGrid2D;
import sim.portrayal.DrawInfo2D;
import sim.portrayal.FieldPortrayal2D;
import sim.portrayal.SimplePortrayal2D;
import sim.portrayal.grid.FastObjectGridPortrayal2D;
import sim.portrayal.grid.FastValueGridPortrayal2D;
import sim.portrayal.grid.ObjectGridPortrayal2D;
import sim.portrayal.grid.SparseGridPortrayal2D;
import sim.portrayal.grid.ValueGridPortrayal2D;
import sim.portrayal.network.NetworkPortrayal2D;
import sim.portrayal.network.SimpleEdgePortrayal2D;
import sim.portrayal.network.SpatialNetwork2D;
import sim.portrayal.simple.RectanglePortrayal2D;
import sim.util.Bag;
import sim.util.gui.ColorMap;
import sim.util.gui.SimpleColorMap;
import sim.util.media.chart.TimeSeriesChartGenerator;

/**
 * the GUIState that visualizes the simulation defined in LandMarketWorld.java
 *
 */
public class HaitiFoodWithUI extends GUIState {

	HaitiFood haitifood;
	public Display2D display;
	public JFrame displayFrame;

	// portrayal data
	FastValueGridPortrayal2D roads = new FastValueGridPortrayal2D(true);
	FastValueGridPortrayal2D destruction = new FastValueGridPortrayal2D(true);
	SparseGridPortrayal2D centers = new SparseGridPortrayal2D();
	SparseGridPortrayal2D people = new SparseGridPortrayal2D();
	SparseGridPortrayal2D peopleKnow = new SparseGridPortrayal2D();

	ObjectGridPortrayal2D blah = new ObjectGridPortrayal2D();
	
	NetworkPortrayal2D roadMaps = new NetworkPortrayal2D();
	
	// chart information
	TimeSeriesChartGenerator agentActivityChart;
	TimeSeriesChartGenerator agentDeathChart;
	TimeSeriesChartGenerator centersFoodDistributionChart;
	TimeSeriesChartGenerator centersLocalDensityChart;
	TimeSeriesChartGenerator agentRiotChart;
	
	XYSeries numUrban;
	XYSeries numRioting;
	ArrayList <XYSeries> agentActivities;
	ArrayList <XYSeries> agentDeaths;
	ArrayList <XYSeries> centersFoodLevels;
	ArrayList <XYSeries> centersDensity;
	
	// This must be included to have model tab, which allows mid-simulation
	// modification of the coefficients
    public Object getSimulationInspectedObject() { return state; }  // non-volatile
    
	/**
	 * Constructor
	 * @param state
	 */
	protected HaitiFoodWithUI(SimState state) {
		super(state);
		haitifood = (HaitiFood) state;
	}

	/**
	 * Main function
	 * @param args
	 */
	public static void main(String[] args) {
		HaitiFoodWithUI simple = new HaitiFoodWithUI(new HaitiFood(System
				.currentTimeMillis()));
		Console c = new Console(simple);
		c.setVisible(true);
	}

	/**
	 * @return name of the simulation
	 */
	public static String getName() { return "HaitiFood"; }

	/**
	 * Called when starting a new run of the simulation. Sets up the portrayals
	 * and chart data.
	 */
	public void start() {
		super.start();

		// --- CHARTS ---
		

		
		// Agent Activities 
		
		// set up the chart info
		agentActivities = new ArrayList <XYSeries>();
		agentActivities.add(new XYSeries("Staying Home"));
		agentActivities.add(new XYSeries("Going to Center"));
		agentActivities.add(new XYSeries("Going Home"));
		agentActivityChart.removeAllSeries();
		for(XYSeries xy: agentActivities)
			agentActivityChart.addSeries(xy, null);

		// schedule the chart to take data
		state.schedule.scheduleRepeating( new Steppable(){
			public void step(SimState state){
				HaitiFood hf = (HaitiFood)state;
				double time = state.schedule.time();
				int [] sums = {0,0,0};
				for(Agent a: hf.peopleList)
					sums[a.activity] += 1;
				for(int i = 0; i < 3; i++)
					agentActivities.get(i).add( time, sums[i] ); 
			}
		}, HaitiFood.reportOrder, 1);

		// Agent Deaths 
		
		// set up the chart info
		agentDeaths = new ArrayList <XYSeries>();
		agentDeaths.add(new XYSeries("Cumulative"));
		agentDeaths.add(new XYSeries("This Tick"));
		agentDeathChart.removeAllSeries();
		for(XYSeries xy: agentDeaths)
			agentDeathChart.addSeries(xy, null);

		// schedule the chart to take data
		state.schedule.scheduleRepeating( new Steppable(){
			public void step(SimState state){
				HaitiFood hf = (HaitiFood)state;
				double time = state.schedule.time();
				agentDeaths.get(0).add(time, hf.deaths_total);
				agentDeaths.get(1).add(time, hf.deaths_this_tick);
			}
		}, HaitiFood.reportOrder, 1);

		// Centers Food Levels 
		
		// set up the chart info
		centersFoodLevels = new ArrayList <XYSeries>();
		for(int i = 0; i < haitifood.centersList.size(); i++)
			centersFoodLevels.add(new XYSeries("Center " + i));
		centersFoodDistributionChart.removeAllSeries();
		for(XYSeries xy: centersFoodLevels)
			centersFoodDistributionChart.addSeries(xy, null);

		// schedule the chart to take data
		state.schedule.scheduleRepeating( new Steppable(){
			public void step(SimState state){
				HaitiFood hf = (HaitiFood)state;
				double time = state.schedule.time();
				for(int i = 0; i < hf.centersList.size(); i++)
					centersFoodLevels.get(i).add( time, hf.centersList.get(i).foodLevel);
			}
		}, HaitiFood.reportOrder, 1);	
		
		// Centers Density 
		
		// set up the chart info
		centersDensity = new ArrayList <XYSeries>();
		for(int i = 0; i < haitifood.centersList.size(); i++)
			centersDensity.add(new XYSeries("Center " + i));
		centersLocalDensityChart.removeAllSeries();
		for(XYSeries xy: centersDensity)
			centersLocalDensityChart.addSeries(xy, null);

		// schedule the chart to take data
		state.schedule.scheduleRepeating( new Steppable(){
			public void step(SimState state){
				HaitiFood hf = (HaitiFood)state;
				double time = state.schedule.time();
				for(int i = 0; i < hf.centersList.size(); i++){
					Location centerLoc = hf.centersList.get(i).loc;
					Bag neighbors = new Bag();
					hf.population.getNeighborsHamiltonianDistance(
							centerLoc.x, centerLoc.y, 5, false, neighbors, null, null);
					if(neighbors == null)
						centersDensity.get(i).add( time, 0);
					else
						centersDensity.get(i).add( time, neighbors.size());
				}
			}
		}, HaitiFood.reportOrder, 1);	
		
		
		// Agents Rioting 
		
		// set up the chart info
		numRioting = new XYSeries("Agents Rioting");
		agentRiotChart.removeAllSeries();
		agentRiotChart.addSeries(numRioting, null);

		// schedule the chart to take data
		state.schedule.scheduleRepeating( new Steppable(){
			public void step(SimState state){
				HaitiFood hf = (HaitiFood)state;
				double time = state.schedule.time();
				numRioting.add(time, hf.rioting);
			}
		}, HaitiFood.reportOrder, 1);
		
		// --- PORTRAYALS ---
		
		// ROADS
		roads.setField( haitifood.roads );
        Color[] roadColors = new Color[HaitiFood.noRoadValue];
        for(int i = 0; i < roadColors.length - 1; i++)
        	roadColors[i] = new Color(50 + i * 10, i * 10, i * 10);
        roadColors[roadColors.length - 1] = new Color( 0,0,0,0);
		roads.setMap( new SimpleColorMap(roadColors) );
		roads.setPortrayalForAll( new RoadsPortrayal());

		// ROAD NETWORKS
		SpatialNetwork2D roadsSpatial = new SpatialNetwork2D(haitifood.nodes, haitifood.roadNetwork);
		roadMaps.setField( roadsSpatial );
		roadMaps.setPortrayalForAll( new SimpleEdgePortrayal2D() );
		
		// DESTRUCTION
		destruction.setField( haitifood.destruction );
        Color[] destructionColors = new Color[5];
        destructionColors[0] = Color.gray; // no data
        destructionColors[1] = Color.green; // no damage
        destructionColors[2] = Color.yellow; // visible damage
        destructionColors[3] = Color.orange; // moderate damage
        destructionColors[4] = Color.red; // significant damage                
        destruction.setMap(new SimpleColorMap(destructionColors));
		
        // CENTERS
		centers.setField( haitifood.centers );
		centers.setPortrayalForAll( new CentersPortrayal() );
		
		// PEOPLE
		people.setField( haitifood.population );
		people.setPortrayalForAll( new PeoplePortrayal() );

		// KNOWLEDGEABLE PEOPLE
		peopleKnow.setField( haitifood.population );
		peopleKnow.setPortrayalForAll( new KnowledgePortrayal() );
		
		
		// reschedule the displayer
		display.reset();
		display.setBackdrop( Color.white );

		// redraw the display
		display.repaint();
	}

	/**
	 * Called when first beginning a HaitiFoodWithUI. Sets up the display window,
	 * the JFrames, and the chart structure.
	 */
	public void init(Controller c) {
		super.init(c);

		// make the displayer
		display = new Display2D(900, 700, this, 1);
		// turn off clipping
		display.setClipping(false);

		displayFrame = display.createFrame();
		displayFrame.setTitle("HaitiFood Display");
		c.registerFrame(displayFrame); // register the frame so it appears in
										// the "Display" list
		displayFrame.setVisible(true);

		display.attach(destruction, "Destruction");
		display.attach(roads, "Roads");
		display.attach(people, "People");
//		display.attach(blah, "BLAH");
		display.attach(peopleKnow, "Knowledge");
		display.attach(centers, "Centers");
		display.attach( roadMaps, "Road Maps" );

		// charts
		agentActivityChart = new TimeSeriesChartGenerator();
		agentActivityChart.setTitle("Agent Activities");
		agentActivityChart.setRangeAxisLabel("Number of Agents");
		agentActivityChart.setDomainAxisLabel("Time");
		JFrame activityChartFrame = agentActivityChart.createFrame(this);
		activityChartFrame.setVisible(true);
		activityChartFrame.pack();
		c.registerFrame(activityChartFrame);

		agentDeathChart = new TimeSeriesChartGenerator();
		agentDeathChart.setTitle("Agent Deaths");
		agentDeathChart.setRangeAxisLabel("Number of Agents");
		agentDeathChart.setDomainAxisLabel("Time");
		JFrame deathChartFrame = agentDeathChart.createFrame(this);
		deathChartFrame.setVisible(true);
		deathChartFrame.pack();
		c.registerFrame(deathChartFrame);
		
		centersFoodDistributionChart = new TimeSeriesChartGenerator();
		centersFoodDistributionChart.setTitle("Centers Levels of Food");
		centersFoodDistributionChart.setRangeAxisLabel("Amount of food");
		centersFoodDistributionChart.setDomainAxisLabel("Time");
		JFrame centersFoodChartFrame = centersFoodDistributionChart.createFrame(this);
		centersFoodChartFrame.setVisible(true);
		centersFoodChartFrame.pack();
		c.registerFrame(centersFoodChartFrame);
		
		centersLocalDensityChart = new TimeSeriesChartGenerator();
		centersLocalDensityChart.setTitle("Density Around Centers");
		centersLocalDensityChart.setRangeAxisLabel("Number of Agents within 500m of the Center");
		centersLocalDensityChart.setDomainAxisLabel("Time");
		JFrame centersDensityChartFrame = centersLocalDensityChart.createFrame(this);
		centersDensityChartFrame.setVisible(true);
		centersDensityChartFrame.pack();
		c.registerFrame(centersDensityChartFrame);
		
		agentRiotChart = new TimeSeriesChartGenerator();
		agentRiotChart.setTitle("Number of Rioting Agents");
		agentRiotChart.setRangeAxisLabel("Number of Agents Rioting");
		agentRiotChart.setDomainAxisLabel("Time");
		JFrame agentRiotChartFrame = agentRiotChart.createFrame(this);
		agentRiotChartFrame.setVisible(true);
		agentRiotChartFrame.pack();
		c.registerFrame(agentRiotChartFrame);
	}

	/** called when quitting a simulation. Does appropriate garbage collection. */
	public void quit() {
		super.quit();

		if (displayFrame != null)
			displayFrame.dispose();
		displayFrame = null; // let gc
		display = null; // let gc
	}  
    
}