package kibera;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics2D;

import javax.swing.JFrame;

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartFrame;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.axis.NumberAxis;
import org.jfree.chart.plot.CategoryPlot;
import org.jfree.chart.plot.PlotOrientation;

import kibera.Resident.Identity;

import sim.display.Console;
import sim.display.Controller;
import sim.display.Display2D;
import sim.display.GUIState;
import sim.portrayal.DrawInfo2D;
import sim.portrayal.FieldPortrayal2D;
import sim.portrayal.continuous.ContinuousPortrayal2D;
import sim.portrayal.geo.GeomPortrayal;
import sim.portrayal.geo.GeomVectorFieldPortrayal;
import sim.portrayal.grid.ObjectGridPortrayal2D;
import sim.portrayal.grid.SparseGridPortrayal2D;
import sim.portrayal.network.NetworkPortrayal2D;
import sim.portrayal.network.SimpleEdgePortrayal2D;
import sim.portrayal.network.SpatialNetwork2D;
import sim.portrayal.simple.OvalPortrayal2D;
import sim.portrayal.simple.RectanglePortrayal2D;

public class KiberaWithUI extends GUIState {

	Display2D display;
	JFrame displayFrame;
	
	Kibera kibera;
		   
	public KiberaWithUI()
	{
		super(new Kibera(System.currentTimeMillis()));
		kibera = (Kibera)state;
	}
	
	public static String getName() { return "Kibera"; }
	public Object getSimulationInspectedObject() { return state; }
	
	
	@Override
	public void start()
	{
		super.start();
		setupPortrayals();
	}
	
	public void setupPortrayals()
	{
		display.detatchAll();
		
		FieldPortrayal2D landPortrayal = new ObjectGridPortrayal2D();
		landPortrayal.setField(kibera.landGrid);
		//landPortrayal.setPortrayalForAll(new RectanglePortrayal2D(Color.LIGHT_GRAY));
		landPortrayal.setPortrayalForAll(new LandPortrayal());
		//display.attach(landPortrayal, "Land");

	    SimpleEdgePortrayal2D testPathEdgePortrayal = new SimpleEdgePortrayal2D(Color.lightGray, null);
	    NetworkPortrayal2D testPathPortrayal = new NetworkPortrayal2D();
	    testPathEdgePortrayal.setBaseWidth(1.5);
	    testPathPortrayal.setField(new SpatialNetwork2D(kibera.testPathField, kibera.testPathNetwork));
	    testPathPortrayal.setPortrayalForAll(testPathEdgePortrayal);
	    //display.attach(testPathPortrayal, "TestPath");
	    
	    FieldPortrayal2D businessPortrayal = new SparseGridPortrayal2D();
	    businessPortrayal.setField(kibera.businessGrid);
	    businessPortrayal.setPortrayalForAll(new RectanglePortrayal2D(Color.red, 1.5, false));
	    display.attach(businessPortrayal, "Businesses");
	    
	    FieldPortrayal2D housePortrayal = new SparseGridPortrayal2D();
	    housePortrayal.setField(kibera.houseGrid);
	    housePortrayal.setPortrayalForAll(new RectanglePortrayal2D(Color.orange, 1.5, false));
	    display.attach(housePortrayal, "Houses");
		
		ContinuousPortrayal2D residentPortrayal = new ContinuousPortrayal2D();
		residentPortrayal.setField(kibera.world);
		residentPortrayal.setPortrayalForAll(new ResidentPortrayal());
		display.attach(residentPortrayal, "Residents");				
		
		FieldPortrayal2D roadPortrayal = new ObjectGridPortrayal2D();
		roadPortrayal.setField(kibera.landGrid);
		roadPortrayal.setPortrayalForAll(new RoadPortrayal());		
		//display.attach(roadPortrayal, "Roads");	
		
		FieldPortrayal2D facilityPortrayal = new SparseGridPortrayal2D();
		facilityPortrayal.setField(kibera.facilityGrid);
		facilityPortrayal.setPortrayalForAll(new OvalPortrayal2D(Color.black, 1.5));
		display.attach(facilityPortrayal, "Facilities");
		
		FieldPortrayal2D healthFacilityPortrayal = new SparseGridPortrayal2D();
		healthFacilityPortrayal.setField(kibera.healthFacilityGrid);
		healthFacilityPortrayal.setPortrayalForAll(new OvalPortrayal2D(Color.blue, 1.5));
		display.attach(healthFacilityPortrayal, "HealthFacilities");
		
		FieldPortrayal2D religiousFacilityPortrayal = new SparseGridPortrayal2D();
		religiousFacilityPortrayal.setField(kibera.religiousFacilityGrid);
		religiousFacilityPortrayal.setPortrayalForAll(new OvalPortrayal2D(Color.black, 1.5));
		display.attach(religiousFacilityPortrayal, "ReligiousFacilities");
		
		GeomVectorFieldPortrayal roadLinkPortrayal = new GeomVectorFieldPortrayal();
	    roadLinkPortrayal.setField(kibera.roadLinks);
	    roadLinkPortrayal.setPortrayalForAll(new GeomPortrayal(Color.black, false));
	    display.attach(roadLinkPortrayal, "Roads");
	    	    	    
		display.reset();
		display.setBackdrop(Color.white);
		// redraw the display
		display.repaint();	    
	}
	
	/*
	 * ResidentPortrayal gives residents of different ethnicity a different color
	 */
	class ResidentPortrayal extends RectanglePortrayal2D
	{
		public void draw(Object object, Graphics2D graphics, DrawInfo2D info)
		{
			if(object == null) 
			{
				System.out.println("null");
				return;
			}
			
			Resident r = (Resident) object;
			//graphics.setColor(Color.blue);
			Resident.Identity identity = r.getCurrentIdentity();
			boolean rumor = r.heardRumor();
			
			
			/*if (r.heardRumor()) {
				graphics.setColor(Color.yellow);
				
				paint = graphics.getColor();
				super.draw(r, graphics, info);
			}
			
			if (r.getCurrentIdentity() != null) {
				if(r.getCurrentIdentity() == Identity.Rebel) {
					graphics.setColor(Color.red);
				}
			//}
				/*else {
					graphics.setColor(Color.blue);
				}*/
			//}
						
			if ( r.getEthnicity() != null ) 
			{			
				if( r.getEthnicity() == ((Kibera)state).getEthnicities(0))
					graphics.setColor(Color.blue);
				else if( r.getEthnicity() == ((Kibera)state).getEthnicities(1))
					graphics.setColor(Color.black);
				else if( r.getEthnicity() == ((Kibera)state).getEthnicities(2))
					graphics.setColor(Color.red);
				else if( r.getEthnicity() == ((Kibera)state).getEthnicities(3))
					graphics.setColor(Color.blue);
				else if( r.getEthnicity() == ((Kibera)state).getEthnicities(4))
					graphics.setColor(Color.lightGray);
				else if( r.getEthnicity() == ((Kibera)state).getEthnicities(5))
					graphics.setColor(Color.cyan);
				else if( r.getEthnicity() == ((Kibera)state).getEthnicities(6))
					graphics.setColor(Color.green);
				else if( r.getEthnicity() == ((Kibera)state).getEthnicities(7))
					graphics.setColor(Color.pink);
				else if( r.getEthnicity() == ((Kibera)state).getEthnicities(8))
					graphics.setColor(Color.magenta);
				else if( r.getEthnicity() == ((Kibera)state).getEthnicities(9))
					graphics.setColor(Color.yellow);
				else if( r.getEthnicity() == ((Kibera)state).getEthnicities(10))
					graphics.setColor(Color.black);
				else if( r.getEthnicity() == ((Kibera)state).getEthnicities(11))
					graphics.setColor(Color.darkGray);
				else return;
			}
			
			
			paint = graphics.getColor();
			super.draw(r, graphics, info);
		}
	}
	
	/*
	 * LandPortrayal creates the Kibera landscape and makes each neighborhood a different color
	 */
	class LandPortrayal extends RectanglePortrayal2D 
	{	
		public void draw(Object object, Graphics2D graphics, DrawInfo2D info)
		{
			if(object == null) 
			{
				System.out.println("null");
				return;
			}
			
			Parcel p = (Parcel) object;
			
			if ( p.getNeighborhood() != null ) 
			{			
				if( p.getNeighborhood().getNeighborhoodID() == 1)
					graphics.setColor(Color.lightGray);
				else if( p.getNeighborhood().getNeighborhoodID() == 2)
					graphics.setColor(Color.yellow);
				else if( p.getNeighborhood().getNeighborhoodID() == 3)
					graphics.setColor(Color.red);
				else if( p.getNeighborhood().getNeighborhoodID() == 4)
					graphics.setColor(Color.blue);
				else if( p.getNeighborhood().getNeighborhoodID() == 5)
					graphics.setColor(Color.lightGray);
				else if( p.getNeighborhood().getNeighborhoodID() == 6)
					graphics.setColor(Color.cyan);
				else if( p.getNeighborhood().getNeighborhoodID() == 7)
					graphics.setColor(Color.green);
				else if( p.getNeighborhood().getNeighborhoodID() == 8)
					graphics.setColor(Color.pink);
				else if( p.getNeighborhood().getNeighborhoodID() == 9)
					graphics.setColor(Color.magenta);
				else if( p.getNeighborhood().getNeighborhoodID() == 10)
					graphics.setColor(Color.yellow);
				else if( p.getNeighborhood().getNeighborhoodID() == 11)
					graphics.setColor(Color.black);
				else if( p.getNeighborhood().getNeighborhoodID() == 12)
					graphics.setColor(Color.darkGray);
				else if( p.getNeighborhood().getNeighborhoodID() == 13)
					graphics.setColor(Color.red);
				else if( p.getNeighborhood().getNeighborhoodID() == 14)
					graphics.setColor(Color.green);
				else if( p.getNeighborhood().getNeighborhoodID() == 15)
					graphics.setColor(Color.blue);
				else
					return;
				
				paint = graphics.getColor();
				super.draw( p, graphics, info);
			}
		}
	}
	
	class RoadPortrayal extends RectanglePortrayal2D 
	{	
		public void draw(Object object, Graphics2D graphics, DrawInfo2D info)
		{
			if(object == null) 
			{
				System.out.println("null");
				return;
			}
			
			Parcel p = (Parcel) object;
			
			if ( p.getRoadID() == 0 ) 			
				graphics.setColor(Color.LIGHT_GRAY);
			else
				return;
			
			paint = graphics.getColor();
			super.draw( p, graphics, info);
		}
	}

	
	@Override
	public void init(Controller c) 
	{
		super.init(c);
		
		display = new Display2D(1029, 612, this); //need to change this to width and height of file
		displayFrame = display.createFrame();
		c.registerFrame(displayFrame);
		displayFrame.setVisible(true);	
		
	    // Portray activity chart
        JFreeChart chart = ChartFactory.createBarChart("Resident's Activity", "Activity", "Percentage", ((Kibera) this.state).dataset, PlotOrientation.VERTICAL, false, false, false);
        chart.setBackgroundPaint(Color.WHITE);
        chart.getTitle().setPaint(Color.BLACK);

        CategoryPlot p = chart.getCategoryPlot();
        p.setBackgroundPaint(Color.WHITE);
        p.setRangeGridlinePaint(Color.red);

        // set the range axis to display integers only...  
        NumberAxis rangeAxis = (NumberAxis) p.getRangeAxis();
        rangeAxis.setStandardTickUnits(NumberAxis.createIntegerTickUnits());
        int max = 100; //((Dadaab) this.state).getInitialRefugeeNumber();
        rangeAxis.setRange(0, max);

        ChartFrame frame = new ChartFrame("Activity Chart", chart);
        frame.setVisible(true);
        frame.setSize(400, 350);

        frame.pack();
        c.registerFrame(frame);
        
		//portray legend
        Dimension dl = new Dimension(300,425);
        /*Legend legend = new Legend();
        legend.setSize(dl);
        
        JFrame legendframe = new JFrame();
        legendframe.setVisible(true);
        legendframe.setPreferredSize(dl);
        legendframe.setSize(300, 500);
        
        legendframe.setBackground(Color.white);
        legendframe.setTitle("Legend");
        legendframe.getContentPane().add(legend);   
        legendframe.pack();
        c.registerFrame(legendframe);*/
	}
	
	public static void main(String[] args) 
	{
		KiberaWithUI kbUI = new KiberaWithUI();
		Console c = new Console(kbUI);
		c.setVisible(true);
	}
	
	public void quit()
	{
		super.quit();

		if (displayFrame!=null) displayFrame.dispose();
		displayFrame = null;
		display = null;
		
	}


}
