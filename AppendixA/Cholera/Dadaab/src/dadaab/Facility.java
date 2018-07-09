/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package dadaab;

/**
 *
 * @author gmu
 */

//al other facilities

import java.util.*;
import sim.util.*;
import sim.engine.*;

public class Facility implements Steppable,Valuable{
    
    //private int capacity  = 0; // if we need to limit the capacity of each facility
    private int facilityID; // id
    FieldUnit location; // location of the facility
    
    public boolean isInfected = false; // 
    public static final int ORDERING = 1; // schedule after rainfall
    private double infectionLevel= 0.0; // // if the facility is infected
    
    // capacity of the facility
//    public void setCapacity(int c){
//        this.capacity =c;
//    }
//    
//    public int getCapacity(){
//        return capacity;
//    }
    
    
    // what type of facility it is 
    public void setFacilityID(int id){
        this.facilityID = id;
    }
    
    public int getFacilityID(){
        return facilityID;
    }
    
    // location of the borehole
    public void setLoc(FieldUnit loc){
        this.location =  loc;
    }
    
    public FieldUnit getLoc(){
        return location;
    }
    
    // status of infection level - infected or not
    public void setIsInfected(boolean b){
        this.isInfected = b;
    }
    
    public boolean getIsInfected(){
        return isInfected;
    }
    
    
   
    // infection level of the borehole
    public void setInfectionLevel(double l){
        this.infectionLevel =l; // in liter
        
    }
    
    public double getInfectionLevel(){
        return infectionLevel;
       
    }
    
    public boolean isReachedCapacity(FieldUnit f,Dadaab d){
        if(f.getPatientCounter() >= d.params.global.getHeaalthFacilityCapacity()){
            return true;
        }
        else  return false;
    }
    // refill borehole each day
    //check also if infected level is set and change the level accordingly
    public void refillBorehole( Dadaab d){
    // only those borehole fields
        
        for(Object obj: d.boreHoles){
            FieldUnit f = (FieldUnit)obj;
            
            double water = f.getWater()+ d.params.global.getBoreHoleDischareRatePerMinute();
        
            if(water > d.params.global.getBoreholeWaterSupplyPerDay()){ // if it is above the capacity,
                  water = d.params.global.getBoreholeWaterSupplyPerDay(); // set the maximum capacity 
              }
                     
           f.setWater(water); 
           
           f.setVibrioCholerae(f.getFacility().getInfectionLevel()*water); // set the contamination level of the water
                                                                     // incase it is infected
           
         }
        
    } 
    // daily health center capacity
    public void resetPatientNumber(Dadaab d){
        for(Object obj: d.healthCenters){
            FieldUnit f = (FieldUnit)obj;
            f.setPatientCounter(0);
        }
    }
    
    public void step(SimState state)
    {
    
       Dadaab d = (Dadaab) state;
          refillBorehole(d); // refill the borehole 
          // everyday start from 0
        if(d.schedule.getSteps() % 1440 ==1){
            resetPatientNumber(d);
        }
    }
    
    // for visualization - based on facility id
    
     public double doubleValue() {

        return this.getFacilityID();
        
        
    }
    
    
}
