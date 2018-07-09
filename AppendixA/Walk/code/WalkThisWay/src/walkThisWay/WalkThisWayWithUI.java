package walkThisWay;

import java.awt.Color;
import java.awt.Graphics2D;
import java.util.ArrayList;

import javax.swing.JFrame;

import org.jfree.data.xy.XYSeries;

import sim.display.Console;
import sim.display.Controller;
import sim.display.Display2D;
import sim.display.GUIState;
import sim.engine.SimState;
import sim.engine.Steppable;
import sim.portrayal.DrawInfo2D;
import sim.portrayal.grid.FastValueGridPortrayal2D;
import sim.portrayal.grid.SparseGridPortrayal2D;
import sim.portrayal.simple.RectanglePortrayal2D;
import sim.util.gui.SimpleColorMap;
import sim.util.media.chart.TimeSeriesChartGenerator;

/**
 * This is the class constructor. The GUIState that visualizes the simulation defined in WalkThisWay
 * 
 * @param state
 */

public class WalkThisWayWithUI extends GUIState {

	WalkThisWay pedWorld;
	public Display2D display;
	public JFrame displayFrame;

	// Portrayal data
	FastValueGridPortrayal2D tracePortrayal = new FastValueGridPortrayal2D("Traces");

	// The Floor grid does not change its values, so pass it true for immutable.
	FastValueGridPortrayal2D floorPortrayal = new FastValueGridPortrayal2D("Cost Surface", true);
	FastValueGridPortrayal2D baseFloorPortrayal = new FastValueGridPortrayal2D("Visual", true);
	FastValueGridPortrayal2D entrancePortrayal = new FastValueGridPortrayal2D("Entrances", true);
	FastValueGridPortrayal2D exitPortrayal = new FastValueGridPortrayal2D("Exits", true);
	
	Color entcol = new Color(255,0,0, 150), entcol2 = new Color(255,100,100, 150), 
		extcol = new Color(0,0,255, 150), extcol2 = new Color(100, 100, 255, 150);
	Color [] entranceColors = {new Color(0,0,0,0), entcol, entcol2, entcol, entcol2, entcol, 
			entcol2, entcol, entcol2, entcol, entcol2, entcol, entcol2, entcol, entcol2, entcol, entcol2}, 
	exitColors = {new Color(0,0,0,0), extcol, extcol2, extcol, extcol2, extcol, extcol2,  
			extcol, extcol2, extcol, extcol2, extcol, extcol2, extcol, extcol2, extcol, extcol2, extcol, extcol2};

	
	SparseGridPortrayal2D peoplePortrayal = new SparseGridPortrayal2D();

	// Chart Information

	TimeSeriesChartGenerator pedestrianSpeedChart = null;
	ArrayList<XYSeries> pedSpeedStats = null;

	TimeSeriesChartGenerator pedestrianDensityChart = null;
	ArrayList<XYSeries> pedDensityStats = null;

	// ***************************************************************************
	/**
	 * This is the class constructor.
	 * 
	 * @param state
	 */
	protected WalkThisWayWithUI(SimState state) {

		super(state);
		pedWorld = (WalkThisWay) state;

	} // End method. *************************************************************

	// ***************************************************************************
	/** Called when starting a new run of the simulation. Sets up the portrayals and chart data. */
	public void start() {

		super.start();

		// start chart metrics calculations
		// ---------------------------------------
		scheduleRepeatingImmediatelyBefore(new Steppable() {

			public void step(SimState state) // this stepper just does the math.
			{
				pedWorld.calcAverageSpeedAndDensity(); // calc avg ped speed & Dn.
			}

		});
		// end chart metrics calculations
		// -----------------------------------------

		// start pedestrians speed chart setup
		// ------------------------------------
		pedSpeedStats = new ArrayList<XYSeries>();
		pedSpeedStats.add(new XYSeries("Ave. Speed of Peds"));
		pedSpeedStats.add(new XYSeries("Ave. + Std Speed of Peds"));
		pedSpeedStats.add(new XYSeries("Ave. - Std Speed of Peds"));

		pedestrianSpeedChart.removeAllSeries();
		for (XYSeries xy : pedSpeedStats)
			pedestrianSpeedChart.addSeries(xy, null);

		scheduleRepeatingImmediatelyBefore(new Steppable() {
			public void step(SimState state) {
				// for each element in the list, get its value for display.
				double time = state.schedule.getTime();
				pedSpeedStats.get(0).add(time, pedWorld.averageSpeed, true);
				pedSpeedStats.get(1).add(time, pedWorld.averageSpeed + pedWorld.stdSpeed, true);
				pedSpeedStats.get(2).add(time, pedWorld.averageSpeed - pedWorld.stdSpeed, true);
			}
		});
		// end pedestrians speed chart setup
		// --------------------------------------

		// start pedestrians density chart setup
		// ----------------------------------
		pedDensityStats = new ArrayList<XYSeries>();
		pedDensityStats.add(new XYSeries("Ave. 1/Density of Peds"));
		pedDensityStats.add(new XYSeries("Ave + Std of 1/Density of Peds"));
		pedDensityStats.add(new XYSeries("Ave - Std of 1/Density of Peds"));

		pedestrianDensityChart.removeAllSeries();
		for (XYSeries xy : pedDensityStats)
			pedestrianDensityChart.addSeries(xy, null);

		scheduleRepeatingImmediatelyBefore(new Steppable() {
			public void step(SimState state) {
				double time = state.schedule.getTime();
				// for each element in the list, get its value for display.
				pedDensityStats.get(0).add(time, pedWorld.averageDensity, true);
				pedDensityStats.get(1).add(time, pedWorld.averageDensity + pedWorld.stdDensity, true);
				pedDensityStats.get(2).add(time, pedWorld.averageDensity - pedWorld.stdDensity, true);
			}
		});
		// end pedestrians speed & density chart setup
		// ----------------------------


		// Set up the portrayals
		SimpleColorMap floorColorMap = new SimpleColorMap(new Color[] { Color.cyan, Color.green }, 
				pedWorld.minGradient, pedWorld.maxGradient, Color.white, Color.black);
		floorPortrayal.setField(pedWorld.obstacles);
		floorPortrayal.setMap(floorColorMap);

		baseFloorPortrayal.setField(pedWorld.baseFloor);
		baseFloorPortrayal.setMap(new SimpleColorMap(1, 2, Color.black, Color.white));

		entrancePortrayal.setField(pedWorld.entranceGrid);
		entrancePortrayal.setMap(new SimpleColorMap(entranceColors));

		exitPortrayal.setField(pedWorld.exitGrid);
		exitPortrayal.setMap(new SimpleColorMap(exitColors));

		// Using the clearColor for all values of trace = 0 allows for them to not be painted.
		tracePortrayal.setField(pedWorld.traces);
		tracePortrayal.setMap(new SegmentedColorMap( new double []{0, 10, 15, 20}, 
				new Color[] { Color.black, Color.red, Color.yellow, Color.white}));

		peoplePortrayal.setField(pedWorld.people);
		peoplePortrayal.setPortrayalForAll(new RectanglePortrayal2D() {

			public void draw(Object object, Graphics2D graphics, DrawInfo2D info) {

				Pedestrian p = (Pedestrian) object;

				// works with the entryTimer, values GT zero are not yet in sim.
				if (p._getEntryTimer() <= 0) {
					paint = p.pedColor;
					scale = 1.0;
					super.draw(p, graphics, info);
				}
			}
		});

		// reschedule the display
		display.reset();
		display.repaint();
		display.setBackdrop(Color.black);

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/**
	 * Called when first beginning a run. Sets up the display
	 * windows, the JFrames, and the chart structure.
	 * 
	 * @see sim.display.GUIState#init(sim.display.Controller)
	 */
	public void init(Controller c) {

		super.init(c);

		// Display windows and JFrames

		// make a displayer
		display = new Display2D(800, 600, this);

		// turn off clipping
		display.setClipping(false);
		displayFrame = display.createFrame();
		displayFrame.setTitle("Display");
		c.registerFrame(displayFrame);
		displayFrame.setVisible(true);

		// do the attaching here
		display.attach(baseFloorPortrayal, "Architecture");
		display.attach(floorPortrayal, "Cost Surface");
		display.attach(tracePortrayal, "Trace");
		display.attach(entrancePortrayal, "Entrances");
		display.attach(exitPortrayal, "Exits");
		display.attach(peoplePortrayal, "People");

		// start pedestrians speed chart setup-------------------------------------
		pedestrianSpeedChart = new TimeSeriesChartGenerator();
		pedestrianSpeedChart.setTitle("Pedestrian Walking Speed");
		pedestrianSpeedChart.setYAxisLabel("Speed (m/s)");
		pedestrianSpeedChart.setXAxisLabel("Time");
		JFrame pedSpeedChartFrame = pedestrianSpeedChart.createFrame(this);
		pedSpeedChartFrame.pack();
		c.registerFrame(pedSpeedChartFrame);
		// end pedestrians speed chart setup---------------------------------------

		// start pedestrians 1/density chart setup---------------------------------
		pedestrianDensityChart = new TimeSeriesChartGenerator();
		pedestrianDensityChart.setTitle("Pedestrians 1/Density");
		pedestrianDensityChart.setYAxisLabel("Availability (m^2/ped)");
		pedestrianDensityChart.setXAxisLabel("Time");
		JFrame pedDensityChartFrame = pedestrianDensityChart.createFrame(this);
		pedDensityChartFrame.pack();
		c.registerFrame(pedDensityChartFrame);
		// end pedestrians 1/density chart setup-----------------------------------

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method does appropriate garbage collection. */

	public void quit() {

		super.quit();

		if (displayFrame != null)
			displayFrame.dispose();

		displayFrame = null;
		display = null;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method creates the "Model" tab in the GUI controller. */

	public Object getSimulationInspectedObject() {

		return state;

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method returns the name of the simulation. */

	public static String getName() {

		return "WalkThisWay";

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This is the main method. */

	public static void main(String[] args) {

		WalkThisWayWithUI simple = new WalkThisWayWithUI(
				new WalkThisWay(System.currentTimeMillis()));

		Console c = new Console(simple);
		c.setVisible(true);

	} // End method.
		// ***************************************************************************

	// ***************************************************************************
	/** This method does nothing. */

	public void template() {
	}
	// End method.
	// ***************************************************************************

}
