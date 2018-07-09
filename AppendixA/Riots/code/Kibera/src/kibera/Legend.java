package kibera;

import java.awt.BasicStroke;
import java.awt.Canvas;
import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.geom.Line2D;

public class Legend extends Canvas {
        
    public void paint(Graphics legend)
    {             
    	Graphics2D leg = (Graphics2D)legend;
    	leg.scale(0.7, 0.7);
    	Line2D line = new Line2D.Double(20, 60, 70, 70);
    	leg.setColor(Color.lightGray);
    	leg.setStroke(new BasicStroke(3));
    	leg.draw(line);

        // agent 
        leg.setColor(Color.blue);
        leg.fillOval(20, 150, 20, 20);
        
        leg.setColor(Color.red);
        leg.fillOval(20, 180, 20, 20);       
                
        //modeling world
        leg.setColor(Color.gray);
        leg.fillRect(20, 290, 30, 30);
         
        leg.setColor(Color.black);
        leg.drawRect(20, 330, 30, 30);
        
        //facilities       
        leg.setColor(Color.black);
        leg.drawRect(20, 430, 30, 30);
        
        leg.setColor(Color.black);      
        leg.drawRect(20, 470, 30, 30);
        
        leg.setColor(Color.black);      
        leg.drawRect(20, 510, 30, 30);
          
        Font f = new Font("Serif", Font.BOLD, 24);       
        leg.setFont(f);   
        
        leg.setColor(Color.black);
        
        leg.drawString("LEGEND", 60, 40);        
        
        Font f2 = new Font("Serif", Font.BOLD, 18);       
        leg.setFont(f2);   
        
        leg.setColor(Color.black);
        
        leg.drawString("Agent's Status", 20, 140);
        
        leg.drawString("Modeling World", 20, 285);
        leg.drawString("Facility", 20, 425);  
        
        Font f3 = new Font("Serif", Font.PLAIN, 20);       
        leg.setFont(f3);   
        
        leg.setColor(Color.black);
                
        leg.drawString("Road", 90, 80);
  
        leg.drawString("Peaceful", 70, 165);
        leg.drawString("Rebelling", 70, 195);
        
        leg.drawString("Kibera", 70, 315);
        leg.drawString("Surrounding Nairobi Region", 70, 350);
  
        leg.drawString("School", 70, 445);
        leg.drawString("Religious Facility", 70, 490);
        leg.drawString("Hospital", 70, 530);
              
    }
}
