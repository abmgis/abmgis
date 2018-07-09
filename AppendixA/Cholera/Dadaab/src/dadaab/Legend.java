/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package dadaab;

/**
 *
 * @author gmu
 */
import java.awt.Font;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.*;
import java.awt.geom.Line2D;
import javax.swing.*;

public class Legend extends Canvas {
    
    
    
    public void paint(Graphics legend)
    {
         
//        legend.setColor(Color.red);
//        legend.drawRect(10, 10, 260, 660);
//        
        
         Graphics2D leg = (Graphics2D)legend;
         leg.scale(0.7, 0.7);
         Line2D line = new Line2D.Double(20, 60, 70, 70);
         leg.setColor(Color.lightGray);
         leg.setStroke(new BasicStroke(3));
         leg.draw(line);
        
       
        // river
//         
//         legend.setColor(Color.blue);
//         legend.drawLine(20, 100, 70, 110);
//         
        // agent 
        leg.setColor(new Color(0,128,0));
        leg.fillOval(20, 150, 20, 20);
        
        leg.setColor(new Color(0,0,255)); //244, 165, 130
        leg.fillOval(20, 180, 20, 20);
        
        leg.setColor(new Color(255,0,0));
        leg.fillOval(20, 210, 20, 20);
        
        leg.setColor(new Color(102, 0, 102));
        leg.fillOval(20, 240, 20, 20);
         
        
        // camps
        leg.setColor(new Color(224, 255, 224));
        leg.fillRect(20, 290, 30, 30);
        
        leg.setColor(new Color(255, 180, 210));
        leg.fillRect(20, 330, 30, 30);
        
        leg.setColor(new Color(204, 204, 153));
        leg.fillRect(20, 370, 30, 30);
        
        
          // facilities
       
        leg.setColor(new Color(0,255,0));       
        leg.drawRect(20, 430, 30, 30);
        
        leg.setColor(new Color(0,128,255));       
        leg.drawRect(20, 470, 30, 30);
        
        leg.setColor(new Color(0,0,102));       
        leg.drawRect(20, 510, 30, 30);
        
        leg.setColor(new Color(0,102,102));       
        leg.drawRect(20, 550, 30, 30);
        
        leg.setColor(new Color(102,0,102));       
        leg.drawRect(20, 590, 30, 30);
        
        leg.setColor(new Color(255,0,0));       
        leg.drawRect(20,630, 30, 30);
        
       
       // Graphics2D fontL = (Graphics2D)legend;
        Font f = new Font("Serif", Font.BOLD, 24);       
        leg.setFont(f);   
        
        leg.setColor(Color.black);
        
        leg.drawString("LEGEND", 60, 40);
        
        
        Font f2 = new Font("Serif", Font.BOLD, 18);       
        leg.setFont(f2);   
        
        leg.setColor(Color.black);
        
        leg.drawString("Agent's Cholera Status", 20, 140);
        
        leg.drawString("Refugee Camps", 20, 285);
        leg.drawString("Facility", 20, 425);
        
   
        
        Font f3 = new Font("Serif", Font.PLAIN, 20);       
        leg.setFont(f3);   
        
        leg.setColor(Color.black);
        
        
        leg.drawString("Road", 90, 80);
        //legend.drawString("River", 90, 115);
        
        leg.drawString("Susceptible", 70, 165);
        leg.drawString("Exposed", 70, 195);
        leg.drawString("Infected", 70, 225);
        leg.drawString("Recovered", 70, 255);
        
        leg.drawString("Dagahaley", 70, 315);
        leg.drawString("Ifo", 70, 350);
        leg.drawString("Hagadera", 70, 390);
        
        leg.drawString("School", 70, 445);
        leg.drawString("Borehole", 70, 490);
        leg.drawString("Mosque", 70, 530);
        leg.drawString("Market", 70, 570);
        leg.drawString("Food Dist. Center", 70, 610);
        leg.drawString("Health Center", 70, 650);
        
       
        
        
                
                
    }
    
    
}
