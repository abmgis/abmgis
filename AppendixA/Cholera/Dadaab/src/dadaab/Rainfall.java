/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package dadaab;

/**
 *
 * @author gmu
 */
import java.util.*;
import sim.util.*;
import sim.engine.*;

public class Rainfall implements Steppable {

    /**
     * rainfall modeling considers rainfall-intensity-frequency-duration (IDF)
     * intensity = amount of rainfall frequency - gaps between days - rain can
     * be happening every day or once in a week ... duration- how many minute
     * the rain stays water in a given field is accumulated in liters there is
     * some conversion of water based on cell resolution and amount of rain
     *
     */
    // any infra will block water flow
    public static final int ORDERING = 0; // rainfall schedules first
    // final  double area = 90.0 * 90.0;// meter square - cell resolution of the model
    // 1 m3 = 1000 litre;  vol= area * height
    // height (m) = vol/area * 1000
    final double areaUsed = 0.6; // 60% of area of the cell used for calculating volume
    final double coversionFactor = areaUsed * 90 * 90 * 1000.0; // area * litre 
    private double currentRain;
    private final double MAXVIBROFLOWWAtER = 50; //mm of rain in a field. if it is greater than this, all virbo will flood to next cell
    private int rainDay = 0;
    // private final double waterFlowRate = 0.8; // 80% of water flow at a given time from one parcel to other 
    private double totalBacterialLoad = 0;
    TimeManager tm = new TimeManager();
    // when the next rain day will be

    public void setRainDay(int r) {
        this.rainDay = r;
    }

    public int getRainDay() {
        return rainDay;
    }

    public void setCurrentRain(double r) {
        this.currentRain = r;
    }

    public double getCurrentRain() {
        return currentRain;
    }

    public void setTotalBacterialLoad(double r) {
        this.totalBacterialLoad = r;
    }

    public double getTotalBacterialLoad() {
        return totalBacterialLoad;
    }
    int rainDuration = 20;
    int rainMinute = 0; // updated every day randomly
    //jan,feb,mar,apr,may ,jun ,jul, aug, sep, oct,nov ,dec
    // private int[] juleanCalanderRegular = {1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335};

    public void recieveRain(Dadaab d) {
        // rain will fall in all fields except fields that are occupied by camps 
        // 
        //  double rain_liter = d.params.global.getRainfall_MM_Per_Minute() * 0.001 * coversionFactor; // 1m3 = 1000 litre, change rainf from mm to meter and multiply 1000

        double rain_liter = 0;
        double currentRain = 0;
        int startmonth = 181; // number start from 0,  ( 182-1) // start at july =182
        // start from x days 
        if ((int) d.schedule.getTime() % 1440 > rainMinute && (int) d.schedule.getTime() % 1440 <= (rainMinute + rainDuration)) {
           
            int indexA = tm.dayCount((int) d.schedule.getTime()) % 365;
            int indexSep = (indexA + startmonth) % 365;

            currentRain = d.dailyRain[indexSep] / (1.0 * rainDuration);
            rain_liter = currentRain * 0.001 * coversionFactor; // 1m3 = 1000 litre, change rainf from mm to meter and multiply 1000

        } else {
            rain_liter = 0;
        } // 1m3 = 1000 litre, change rainf from mm to meter and multiply 1000


       

        this.setCurrentRain(rain_liter);

        for (int x = 0; x < d.allCamps.getWidth(); x++) {
            for (int y = 0; y < d.allCamps.getHeight(); y++) {

                FieldUnit field = (FieldUnit) d.allCamps.get(x, y);

                // avoud camps - agent houses
                if (field.getFieldID() == 11 || field.getFieldID() == 12 || field.getFieldID() == 21 || field.getFieldID() == 22
                        || field.getFieldID() == 31 || field.getFieldID() == 32) {
                    field.setWater(0);

                } else {

                    double newWater = rain_liter + field.getWater();

                    if (newWater < 0) {
                        newWater = 0;
                    }
                    field.setWater(newWater);
                }// adding water on the field

            }
        }

    }

    /*
     * water flow is based on simple hydrology
     * water flows from high to low gradient
     * here moore neighborhood is considered
     * each cell cchek its neighbores - water flows from te center cell to its neighbors based on elevation gradient
     */
    public void drain(Dadaab d) {


        for (int x = 0; x < d.allCamps.getWidth(); x++) {
            for (int y = 0; y < d.allCamps.getHeight(); y++) {

                // ceter cell
                FieldUnit field = (FieldUnit) d.allCamps.field[x][y];

                
                // avoid camps
                if (field.getFieldID() == 11 || field.getFieldID() == 12 || field.getFieldID() == 21 || field.getFieldID() == 22
                        || field.getFieldID() == 31 || field.getFieldID() == 32) {
                    continue;
                }

                fieldDrainageSimple(field, d);

            }

        }

    }
    
//    public void fieldDrainage(FieldUnit field, Dadaab d){
//                 Bag n = new Bag();
//                   n.clear();
//                 get moore neighborhood
//
//                d.allCamps.getNeighborsMaxDistance(field.getX(), field.getY(), 1, false, n, null, null);
//
//                if (n.isEmpty() == true) {
//                    return;
//                }
//
//                 if field holds borehole avoid it, 
//                 no miz of water on borehole
//                if (d.boreHoles.contains(field) == true) {
//                    return;
//                }
//
//
//                for (Object obj : n) {
//
//                    FieldUnit nf = (FieldUnit) obj;
//
//                     water can not flow to itself
//                    if (nf.equals(field) == true) {
//                        continue;
//                    }
//                    if (nf.getWater() <= 0) {
//                        continue;
//                     }
//
//                     avoid camps or facility 
//                    if (nf.getFieldID() == 11 || nf.getFieldID() == 12 || nf.getFieldID() == 21 || nf.getFieldID() == 22
//                            || nf.getFieldID() == 31 || nf.getFieldID() == 32) {
//                        continue;
//                    }
//
//                     avoid borehole points
//
//                    if (d.boreHoles.contains(nf) == true) {
//                        continue;
//                    }
//
//
//                     volume  = area * height
//                     height  = volume/area
//
//                     elevation gradient consider the elevation of the field and water level
//                     water level = volume/area /
//                    pseudo elevation  = elevation + water level
//                    double rateFlowtoOtherCell = 0.6; // 60%
//                    double avoidW = 0;
//                    if (field.getX() == 0 || field.getY() == 0 || field.getX() >= 144 || field.getY() >= 268) {
//                        avoidW = 0;
//                    } else {
//                        avoidW = 1.0;
//                    }
//                    double h1 = field.getElevation() + (field.getWater() / coversionFactor); // pseudo elevation of center cell
//                    double h2 = (nf.getElevation() + rateFlowtoOtherCell * (nf.getWater() / coversionFactor));// pseudo elevation of center cell
//                    double diff = h2 - h1;
//                    double spaceWater = nf.getElevation()- h1;
//                   
//                    if (diff <= 0) {
//                        continue;
//                    }
//
//                    if (diff > 0) {
//                              double waterRemain = 0;
//                              double waterflow =0;
//                        if(rateFlowtoOtherCell * (nf.getWater() / coversionFactor) <= spaceWater ){
//                            waterRemain = 0;
//                            waterflow = field.getWater() + rateFlowtoOtherCell * nf.getWater();
//                        }
//                         else{
//                          waterRemain = nf.getWater() - (spaceWater * coversionFactor);
//                          waterflow = field.getWater()+ spaceWater * coversionFactor;
//                        }    
//                            
//                            
//                   
//                  
//
//                    if (waterRemain < 0) {
//                        waterRemain = 0;
//                    }
//                    double waterUpper = nf.getWater(); // hold for vibro calc
//                   
//                    nf.setWater(waterRemain * avoidW);
//                    field.setWater(waterflow * avoidW);
//
//
//
//                    double vibroflow = nf.getVibrioCholerae() * waterflow / (waterUpper + 1.0) * (1.0 - 1.0 / (1.0 + waterUpper));
//                    double virbroRemain = (nf.getVibrioCholerae() - vibroflow) * avoidW;
//                    if (virbroRemain < 0) {
//                        virbroRemain = 0;
//                    }
//
//                    nf.setVibrioCholerae(virbroRemain);
//                    field.setVibrioCholerae((field.getVibrioCholerae() + vibroflow) * avoidW);
//
//                    }
//
//
//                }
//        
//    }
    
    
    public void fieldDrainageSimple(FieldUnit field, Dadaab d){
         Bag n = new Bag();
                   n.clear();
                // get moore neighborhood

                d.allCamps.getNeighborsMaxDistance(field.getX(), field.getY(), 1, false, n, null, null);

                if (n.isEmpty() == true) {
                    return;
                }

                // if field holds borehole avoid it, 
                // no miz of water on borehole
                if (d.boreHoles.contains(field) == true) {
                    return;
                }


                for (Object obj : n) {

                    FieldUnit nf = (FieldUnit) obj;

                    // water can not flow to itself
                    if (nf.equals(field) == true) {
                        continue;
                    }
                    if (nf.getWater() <= 0) {
                        continue;
                     }

                    // avoid camps or facility 
                    if (nf.getFieldID() == 11 || nf.getFieldID() == 12 || nf.getFieldID() == 21 || nf.getFieldID() == 22
                            || nf.getFieldID() == 31 || nf.getFieldID() == 32) {
                        continue;
                    }

                    // avoid borehole points

                    if (d.boreHoles.contains(nf) == true) {
                        continue;
                    }
                   
                    double avoidW = 0;
                    if (field.getX() == 0 || field.getY() == 0 || field.getX() >= 144 || field.getY() >= 268) {
                        avoidW = 0;
                    } else {
                        avoidW = 1.0;
                    }
                    double h1 = field.getElevation(); // pseudo elevation of center cell
                    double h2 = nf.getElevation();// pseudo elevation of center cell
                    double virbThreshold  =  MAXVIBROFLOWWAtER *  0.001 * coversionFactor;
                    double diff = h2 - h1;
                    
                    if (diff <= 0) {
                        continue;
                    }

                    if (diff > 0) {
                              double waterRemain = 0;
                              double waterflow =0;
                              double waterUpper = nf.getWater(); // hold for vibro calc
                              double rateFlowtoOtherCell =  nf.getWater()* (1.0 - 1.0/(1+diff)); // 60%
                              waterRemain = nf.getWater() - rateFlowtoOtherCell;
                              waterflow = field.getWater() +rateFlowtoOtherCell;

                             if (waterRemain < 0) {
                                    waterRemain = 0;
                             }
                    
                   
                            nf.setWater(waterRemain * avoidW);
                            field.setWater(waterflow * avoidW);

                     
                     if(waterUpper >virbThreshold){
                         virbThreshold = waterUpper;
                     }

                    double vibroflow = nf.getVibrioCholerae() * rateFlowtoOtherCell / (virbThreshold) ;
                    double virbroRemain = (nf.getVibrioCholerae() - vibroflow) * avoidW;
                    if (virbroRemain < 0) {
                        virbroRemain = 0;
                    }

                    nf.setVibrioCholerae(virbroRemain);
                    field.setVibrioCholerae((field.getVibrioCholerae() + vibroflow) * avoidW);

                    }


                }
    }
    

    

    // only happens if there is water- if not seepage is 0
    public void waterAbsorbtion(Dadaab d) {

       for (int x = 0; x < d.allCamps.getWidth(); x++) {
            for (int y = 0; y < d.allCamps.getHeight(); y++) {


                FieldUnit field = (FieldUnit) d.allCamps.field[x][y];
               
                double w = 0;
                        
                       w = field.getWater() - (d.params.global.getAbsorbtionRatePerMinute() * coversionFactor * 0.001);
                if(w  <= 0){
                    field.setWater(0);
                }    
                else{
                    field.setWater(w);
                    
                }    
        
                if (x == 0 || y == 0 || x == 145 || y == 269) {
                    field.setWater(0);
                    field.setVibrioCholerae(0);
                }


            }
        }


    }

    // visualization of rain flows
    public void drawRiver(Dadaab d) {
        d.rainfallWater.clear();
        double totBac = 0;
        for (int x = 0; x < d.allCamps.getWidth(); x++) {
            for (int y = 0; y < d.allCamps.getHeight(); y++) {



                FieldUnit field = (FieldUnit) d.allCamps.field[x][y];
                d.rainfallGrid.field[field.getX()][field.getY()] = field.getWater();
//                
                totBac = totBac + field.getVibrioCholerae();
                //elevation
//                d.rainfallGrid.field[field.getX()][field.getY()] = field.getElevation();
//              

                //feces
                //        d.rainfallGrid.field[field.getX()][field.getY()] = field.getVibrioCholerae();
//              

                if (field.getWater() > d.params.global.getMaximumWaterRequirement()) {
                    d.rainfallWater.add(field);
                }
            }
        }
        setTotalBacterialLoad(totBac);
    }

    //
    public void step(SimState state) {

        Dadaab d = (Dadaab) state;
   
        if ((int) d.schedule.getTime() % 1440 == 1) {
            int interval = 1440 - (2 * rainDuration);
            rainMinute = 2 + d.random.nextInt(interval);
        }


        
        recieveRain(d);
        waterAbsorbtion(d);
        drain(d);
        drawRiver(d);




    }
}
