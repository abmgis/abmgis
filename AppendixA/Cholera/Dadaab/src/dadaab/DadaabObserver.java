/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package dadaab;

/**
 *
 * @author gmu
 */

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import sim.field.grid.*;

import net.sf.csv4j.CSVWriter;
import sim.engine.SimState;
import sim.engine.Steppable;
import sim.io.geo.ArcInfoASCGridExporter;
import sim.field.geo.GeomGridField;
import sim.field.geo.GeomGridField.GridDataType;
import sim.util.Bag;
// based on riftland worldobserver class
// thanks goes to mcoletti and jbasset

public class DadaabObserver implements Steppable{
    
    private BufferedWriter dataFileBuffer_; // output file buffer for dataCSVFile_
    private CSVWriter dataCSVFile_; // CSV file that contains run data
    
    private BufferedWriter dataFileBuffer_act; // output file buffer for dataCSVFile_
    private CSVWriter dataCSVFile_act; // CSV file that contains run data
    
    // hold by camp
     private BufferedWriter dataFileBuffer_camp; // output file buffer for dataCSVFile_
     private CSVWriter dataCSVFile_camp; 
     
     
     private BufferedWriter dataFileBuffer_cStatus; // output file buffer for dataCSVFile_
     private CSVWriter dataCSVFile_cStatus; 
    
    Bag choleraGridBag = new Bag();
    
    
    Dadaab d;
    
    public final static int ORDERING = 3;

     private int step = 0;
     private boolean writeGrid =false;
     
  DadaabObserver(Dadaab dadaab)
    {
//    	setup(world);
    	//<GCB>: you may want to adjust the number of columns based on these flags.
    	// both in createLogFile, and step
        d = null;
        startLogFile();
    }

    DadaabObserver()
    {
        startLogFile();
    }
   
     
   private void startLogFile()
    {
        // Create a CSV file to capture data for this run.
        try
        {
            createLogFile();

            // First line of file contains field names
            String [] header = new String [] {"Job","Step","Susciptable","Exposed","Infected","Recovered", "Death", "Total_vibrio_Cholerae"};
            dataCSVFile_.writeLine(header);
            
            String [] header_cStatus = new String [] {"Job","Step","Newly_Susciptable","Newly_Exposed","Newly_Infected","Newly_Recovered", "Death"};
            dataCSVFile_cStatus.writeLine(header_cStatus);
            // activity
            
             String [] header_act = new String [] {"Job","Step","total refugee", "At Home","School","Water", "Mosque",
                                                 "Market", "Food C.", "Health C.","Visit R.", "Social","Hygiene"};
                      
             dataCSVFile_act.writeLine(header_act);
             
              String [] header_camp = new String [] {"Job","Step","Total Pop","Dag_sus","Dag_exp", "Dag_inf","Dag_rec",
                  "Info_sus","Info_exp", "Info_inf","Info_rec","Hag_sus","Hag_exp", "Hag_inf","Hag_rec"};
              
              dataCSVFile_camp.writeLine(header_camp);
            
        }
        catch (IOException ex)
        {
            Logger.getLogger(Dadaab.class.getName()).log(Level.SEVERE, null, ex);
        }
    }
  
    int count = 0;
    public void step(SimState state)
    {
        d  = (Dadaab)state;
        
        String job = Long.toString(state.job());
        String numSuscpitable = Integer.toString(d.getNumberOfSuscipitable());
        String numExposed = Integer.toString(d.getNumberOfExposed());
        String numInfected = Integer.toString(d.getNumberOfInfected());
        String numRecovered = Integer.toString(d.getNumberOfRecovered());
        String numDeath  = Integer.toString(d.countDeath());
        String totVibroCh = Double.toString(d.getTotalBacterialLoad());
        
        //"At Home","School","Water", "Mosque","Market", "Food C.", "Health C.","Visit R.", "Social","Hygiene"
        String numTotAgent  = Integer.toString(d.allRefugees.getAllObjects().numObjs);
        String numAtHome  = Integer.toString(d.getTotalActivity()[0]);
        String numSchool  = Integer.toString(d.getTotalActivity()[1]);
        String numWater  = Integer.toString(d.getTotalActivity()[2]);
        String numMosque  = Integer.toString(d.getTotalActivity()[3]);
        String numMarket  = Integer.toString(d.getTotalActivity()[4]);
        String numFoodC  = Integer.toString(d.getTotalActivity()[5]);
        String numHealthC  = Integer.toString(d.getTotalActivity()[6]);
        String numVisitR = Integer.toString(d.getTotalActivity()[7]);
        String numSocail  = Integer.toString(d.getTotalActivity()[8]);
        String numHygeiene  = Integer.toString(d.getTotalActivity()[9]);
        
        String numSusDag =   Integer.toString(d.campSuscpitable[0]);
        String numExpDag =   Integer.toString(d.campExposed[0]);
        String numInfDag =   Integer.toString(d.campInfected[0]);
        String numRecDag =   Integer.toString(d.campRecovered[0]);
        
        String numSusInfo=   Integer.toString(d.campSuscpitable[1]);
        String numExpInfo=   Integer.toString(d.campExposed[1]);
        String numInfInfo =  Integer.toString(d.campInfected[1]);
        String numRecInfo =   Integer.toString(d.campRecovered[1]);
        
        String numSusHag =   Integer.toString(d.campSuscpitable[2]);
        String numExpHag =   Integer.toString(d.campExposed[2]);
        String numInfHag =   Integer.toString(d.campInfected[2]);
        String numRecHag =   Integer.toString(d.campRecovered[2]);
       
        // newly cholera cases
        String numSuscpitable_cS = Integer.toString(d.getNumberOfSuscipitableNewly());
        String numExposed_cS = Integer.toString(d.getNumberOfExposedNewly());
        String numInfected_cS = Integer.toString(d.getNumberOfInfectedNewly());
        String numRecovered_cS = Integer.toString(d.getNumberOfRecoveredNewly());
       
                 
        // when to export raster;- everyday at midnight
//        // writeGrid =true;
        if(d.schedule.getSteps() % 1440 ==5){
            writeGrid =true;
        }
        else {
            writeGrid =false;
        }
        //writeGrid =false;
        
        String [] data = new String [] {job, Integer.toString(this.step),numSuscpitable,numExposed, numInfected, numRecovered, numDeath, totVibroCh};
        String [] data_cS = new String [] {job, Integer.toString(this.step),numSuscpitable_cS,numExposed_cS, numInfected_cS, numRecovered_cS, numDeath};
        
        String [] data_act = new String [] {job, Integer.toString(this.step), numTotAgent, numAtHome, numSchool, numWater,
         numMosque,numMarket,numFoodC,numHealthC,numVisitR,numSocail,numHygeiene};
       
        String [] data_camp = new String[]{job,Integer.toString(this.step),numTotAgent,numSusDag,numExpDag,numInfDag,numRecDag,numSusInfo,numExpInfo,
                numInfInfo,numRecInfo,numSusHag,numExpHag,numInfHag,numRecHag};
                
        
        
        try
        {
            this.dataCSVFile_.writeLine(data);
            
            this.dataCSVFile_act.writeLine(data_act);
            
            this.dataCSVFile_camp.writeLine(data_camp);
            
            this.dataCSVFile_cStatus.writeLine(data_cS);
         
            // some trick to write grid every x step
            if(writeGrid ==true){
                count = count+1;
               long now = System.currentTimeMillis();
               String filename = String.format("%ty%tm%td%tH%tM%tS", now, now, now, now, now, now)
               + "d_"+ count+  "_choleraASC.asc";   
             
             BufferedWriter dataASCCholera = new BufferedWriter(new FileWriter(filename));   
            
             writeCholeraSpread();
             
             ArcInfoASCGridExporter.write(d.allCampGeoGrid, dataASCCholera);
             choleraGridBag.add(dataASCCholera);
        
            }
            
        }
        catch (IOException ex)
        {
            Logger.getLogger(DadaabObserver.class.getName()).log(Level.SEVERE, null, ex);
        }
        
        this.step++;
    }
    
     void finish()
    {
        try
        {
            this.dataFileBuffer_.close();
            this.dataFileBuffer_act.close();
            this.dataFileBuffer_camp.close();
            this.dataFileBuffer_cStatus.close();
            
            for(Object o:choleraGridBag){
                BufferedWriter bw = (BufferedWriter)o;
                bw.close();
            }
            
        }
        catch (IOException ex)
        {
            Logger.getLogger(DadaabObserver.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    
    private void createLogFile() throws IOException
    {
        long now = System.currentTimeMillis();
//
        String filename = String.format("%ty%tm%td%tH%tM%tS", now, now, now, now, now, now)
            + "d_cholera.csv";
//        // newly cholera cases
        String filename_cS = String.format("%ty%tm%td%tH%tM%tS", now, now, now, now, now, now)
            + "d_cholera_newly.csv";
//        
        String filename_act = String.format("%ty%tm%td%tH%tM%tS", now, now, now, now, now, now)
            + "d_activity.csv";
        
        String filename_camp = String.format("%ty%tm%td%tH%tM%tS", now, now, now, now, now, now)
            + "d_cholera_camp.csv";
       
        
        //cholera
        this.dataFileBuffer_ = new BufferedWriter(new FileWriter(filename));

        this.dataCSVFile_ = new CSVWriter(dataFileBuffer_);
        
        // activity
        this.dataFileBuffer_act = new BufferedWriter(new FileWriter(filename_act));

        this.dataCSVFile_act = new CSVWriter(dataFileBuffer_act);
        
        
        
        this.dataFileBuffer_camp = new BufferedWriter(new FileWriter(filename_camp));

        this.dataCSVFile_camp = new CSVWriter(dataFileBuffer_camp);
        
        // newly cholera cases
        this.dataFileBuffer_cStatus= new BufferedWriter(new FileWriter(filename_cS));
        this.dataCSVFile_cStatus =  new CSVWriter(dataFileBuffer_cStatus);
        
  
  
    }

    
//  
  public void writeCholeraSpread(){
      
     DoubleGrid2D grid = new DoubleGrid2D(d.allCamps.getWidth(),d.allCamps.getHeight());
      // first put all values zero
     
            for (int i = 0; i < d.allCamps.getWidth(); i++)
            {
                 for (int j = 0; j < d.allCamps.getHeight(); j++)
                  {
               
                FieldUnit faci = (FieldUnit) d.allCamps.get(i, j);
                if(faci.getCampID() > 0){
                    grid.field[i][j] = 0;
                }
              
            }
        }
     // then write the current refugee health status
      for(Object o:d.allRefugees.allObjects){
          Refugee r = (Refugee)o;
          double tot = grid.field[r.getPosition().getX()][r.getPosition().getY()] ;
          if(r.getHealthStatus()==3){
             grid.field[r.getPosition().getX()][r.getPosition().getY()] = tot + 1;
          }
          else{
              grid.field[r.getPosition().getX()][r.getPosition().getY()] = tot;
          }
          
          
      }
      
     d.allCampGeoGrid.setGrid(grid);
       
  }
    private void writeObject(java.io.ObjectOutputStream out)
        throws IOException
    {
        out.writeInt(step);

    }


    private void readObject(java.io.ObjectInputStream in)
        throws IOException, ClassNotFoundException
    {
        step = in.readInt();
         
        startLogFile();
    }
    

}

