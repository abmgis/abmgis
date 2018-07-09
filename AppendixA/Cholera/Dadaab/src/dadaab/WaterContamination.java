///*
// * To change this template, choose Tools | Templates
// * and open the template in the editor.
// */
//package dadaab;
//
///**
// *
// * @author gmu
// */
//
//import java.util.*;
//import sim.util.*;
//import sim.engine.*;
//
//public class WaterContamination implements Steppable{
//    public static final int ORDERING = 1;
//    
//     TimeManager tm = new TimeManager();
//     
//   
// public WaterContamination(){
//     
// }  
// 
// 
// public void fillBorehole(FieldUnit f,Dadaab d){
//      
//     
//      double water = f.getWaterInBorehole() + d.getBoreHoleDischareRatePerMinute();
//      
//      if(water > d.getBoreholeWaterSupplyPerDay()){
//          water = d.getBoreholeWaterSupplyPerDay();
//      }     
//      
//     
//      f.setWaterInBorehole(water);
//      
//      
//  }  
//    
// 
//  public void fillRiver(FieldUnit f,Dadaab d){
//      
//      // depending on the frquency rain will fall
//     double water = f.getRiverFlowAcc() + (d.getRainfall() * d.random.nextDouble() * 10);         
//      f.setRiverFlowAcc(water);    
//  }
//  
//  public void poluteWaterSource(FieldUnit f, Dadaab d){
//       
//               int x = f.getX(); 
//               int y = f.getY();
//            
//           
//            double cv = 1.0;
//            Bag adjacent = d.allCamps.getNeighborsMaxDistance(x, y, 2,
//                                                    false, null, null, null);
//            // add the nearby virus in to river point
//            Iterator iter = adjacent.iterator();
//            
//            while(iter.hasNext())
//            {         
//                FieldUnit field = (FieldUnit)iter.next();
//                double v = 0.0;
//                
//                v = field.getVibrioCholerae();               
//                field.setVibrioCholerae(0);   
//                cv = cv + v;
//              
//            }
//           
//            f.setVibrioCholerae(cv);
//        
//       
//    }
//   // pollution level of water
//   private void pollutionLevel(FieldUnit f){
//       double p =0.0;
//        if(f.getFacilityID() ==2){
//            if(f.getWaterInBorehole() ==0){
//              p =f.getVibrioCholerae();  
//            }
//            else p = f.getVibrioCholerae()  /f.getWaterInBorehole();         
//            
//        }
//        else if(f.getRiverPointID() == 1){
//            if(f.getRiverFlowAcc() ==0){
//                p =f.getVibrioCholerae();
//            }
//            else p = f.getVibrioCholerae() /f.getRiverFlowAcc();
//        }
//        else p =0;
//        f.setPollutionLevel(p);
//       
//        
//        
//   }
//   
////   public void doWaterManagement(Dadaab d){
////      
////           if(this.getWaterSource().getFacilityID() == 2){
////                fillBorehole(d);
////            }
////            
////           else {
////               
////               if(isRaining(d) == true){                      
////                int rainHour = d.random.nextInt(24);
////                
////                if(rainHour == tm.currentHour((int)d.schedule.getSteps())){
////                      fillRiver( d);  
////
////                }
////              }
////            }
////          
////            poluteWaterSource(d);
////            pollutionLevel();  
////      
////     
////   }
//   
// public void doWaterManagement(Dadaab d){
//     int c =0;
//     for(Object w: d.waterSource){
//            FieldUnit waterS = (FieldUnit)w;  
//            if(waterS.getFacilityID() == 1){
//                fillBorehole(waterS, d);
//            }
//           
//            if(tm.dayCount((int)d.schedule.getSteps()) ==  1 || tm.dayCount((int)d.schedule.getSteps()) % d.getRainfallFrequencyInterval() == 0){ 
//             if(waterS.getRiverPointID() ==1){   
//                int rainHour = d.random.nextInt(24);
//                 if(rainHour == tm.currentHour((int)d.schedule.getSteps())){
//                  fillRiver(waterS, d);  
//                  c=1;
//                 }
//              }
//             
//                
//            }
//            if(c==1){
//            poluteWaterSource(waterS, d);
//            }
//          pollutionLevel(waterS);  
//     }   
//     
//         
// }  
// 
//
// 
// public void step(SimState state)
//    {
//    
//       Dadaab d = (Dadaab) state;
//        
//        doWaterManagement(d);
//       
//       
//    }
//}
