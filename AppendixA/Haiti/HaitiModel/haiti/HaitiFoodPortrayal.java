package haiti;

import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.geom.Rectangle2D;
import java.util.ArrayList;

import sim.portrayal.DrawInfo2D;
import sim.portrayal.simple.RectanglePortrayal2D;
import sim.util.MutableDouble;
import sim.util.gui.ColorMap;


class RoadsPortrayal extends RectanglePortrayal2D {

	// colormap for roads, which have values between 0 and 12
	public static ColorMap RoadsColor = new sim.util.gui.SimpleColorMap(
			0,50, new Color(100, 100, 50), new Color(0, 0, 0));

	Color rColor = new Color(100, 100, 50);
	
	public void draw(Object object, Graphics2D graphics, DrawInfo2D info)
	{
		if(object == null) return;
		
		Rectangle2D.Double draw = info.draw;
		final double width = draw.width*scale;
		final double height = draw.height*scale;

		final int x = (int)(draw.x - width / 2.0);
		final int y = (int)(draw.y - height / 2.0);
		final int w = (int)(width);
		final int h = (int)(height);

		MutableDouble i = (MutableDouble) object;
		if( i.intValue() > -1 ){
			graphics.setColor( RoadsColor.getColor(i.intValue()) );
			graphics.fillRect(x,y,w,h);				
		}
	}
}	


/* Color based on extent of damage, as defined by data sources */
class DestructionPortrayal extends RectanglePortrayal2D {

	public void draw(Object object, Graphics2D graphics, DrawInfo2D info)
	{
		if(object == null) return;
		
		Rectangle2D.Double draw = info.draw;
		final double width = draw.width*scale;
		final double height = draw.height*scale;

		final int x = (int)(draw.x - width / 2.0);
		final int y = (int)(draw.y - height / 2.0);
		final int w = (int)(width);
		final int h = (int)(height);

		// color based on extent of damage
		MutableDouble i = (MutableDouble) object;
		int value = i.intValue();
		if( value == 51 ) // no data / unclassified
			graphics.setColor( Color.gray );
		else if( value == 102 ) // no damage
			graphics.setColor( Color.green );
		else if( value == 153 ) // visible damage
			graphics.setColor( Color.yellow );
		else if( value == 204 ) // moderate damage
			graphics.setColor( Color.orange );
		else if( value == 255 ) // significant damage
			graphics.setColor( Color.red );
		graphics.fillRect(x,y,w,h);				
	}
}	

class CentersPortrayal extends RectanglePortrayal2D {
	
	public void draw(Object object, Graphics2D graphics, DrawInfo2D info)
	{
		if(object == null) return;
		
		scale = 10;
		
		Rectangle2D.Double draw = info.draw;
		final double width = scale;
		final double height = scale;
		
		final int x = (int)(draw.x - width / 2.0);
		final int y = (int)(draw.y - height / 2.0);
		final int w = (int)(width);
		final int h = (int)(height);

		Center c = (Center) object;
		if( c != null ){
			graphics.setColor( Color.blue );
			graphics.fillRect(x,y,w,h);				
		}
	}
}


class PeoplePortrayal extends RectanglePortrayal2D {
	
	// colormap for people in tile levels, which varies between 0 and 30
//	public static ColorMap PeopleColor = new sim.util.gui.SimpleColorMap(
//			0, 30, new Color(0, 0, 0, 0), new Color(255, 0, 0, 255));
	public static ColorMap PeopleColor = new sim.util.gui.SimpleColorMap(
			0, HaitiFood.maximumDensity, new Color(0, 0, 255, 200), new Color(255, 0, 0, 200));
	Color personColor = new Color(200, 100, 100, 20);

	public void draw(Object object, Graphics2D graphics, DrawInfo2D info)
	{
		if(object == null) return;
		
		Rectangle2D.Double draw = info.draw;
		final double width = draw.width*scale;
		final double height = draw.height*scale;

		final int x = (int)(draw.x - width / 2.0);
		final int y = (int)(draw.y - height / 2.0);
		final int w = (int)(width);
		final int h = (int)(height);

		graphics.setColor( personColor );
		graphics.fillRect(x,y,w,h);				
	}
}
/*
class DensityPortrayal  extends RectanglePortrayal2D {
	
	// colormap for people in tile levels, which varies between 0 and 30
//	public static ColorMap PeopleColor = new sim.util.gui.SimpleColorMap(
//			0, 30, new Color(0, 0, 0, 0), new Color(255, 0, 0, 255));
	public static ColorMap PeopleColor = new sim.util.gui.SimpleColorMap(
			0, HaitiFood.maximumDensity, new Color(0, 0, 255, 150), new Color(255, 0, 0, 150));
	Color personColor = new Color(200, 100, 100, 10);

	public void draw(Object object, Graphics2D graphics, DrawInfo2D info)
	{
		if(object == null) return;
		
		scale = 100;
		
		Rectangle2D.Double draw = info.draw;
		final double width = draw.width*scale;
		final double height = draw.height*scale;

		final int x = (int)(draw.x - width / 2.0);
		final int y = (int)(draw.y - height / 2.0);
		final int w = (int)(width);
		final int h = (int)(height);

		graphics.setColor( personColor );
		graphics.fillRect(x,y,w,h);				
	}
}
*/
class KnowledgePortrayal extends RectanglePortrayal2D {
	
	// colormap for people in tile levels, which varies between 0 and 30
//	public static ColorMap PeopleColor = new sim.util.gui.SimpleColorMap(
//			0, 30, new Color(0, 0, 0, 0), new Color(255, 0, 0, 255));

	public void draw(Object object, Graphics2D graphics, DrawInfo2D info)
	{
		if(object == null) return;
		
		Rectangle2D.Double draw = info.draw;
		final double width = draw.width*scale;
		final double height = draw.height*scale;

		final int x = (int)(draw.x - width / 2.0);
		final int y = (int)(draw.y - height / 2.0);
		final int w = (int)(width);
		final int h = (int)(height);

		if(((Agent)object).centerInfo > 0){
	//	if( ((Agent)object).centerInfo.size() > 0){
				graphics.setColor( Color.red );
				graphics.fillRect(x,y,w,h);				
				return;
		}
	}
}
