/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package dadaab;

/**
 *
 * @author gmu
 */
import sim.util.*;

public class Activity {
    
    /*
     * activity of each agent
     * including staying at home there are 10 types of activities
     * each activity is related with location. agent go to each activity 
     */
    final public static int STAY_HOME = 0;
    final public static int SCHOOL = 1; 
    final public static int BOREHOLE_OR_RIVER = 2; // 
    final public static int MOSQUE = 3;
    final public static int MARKET = 4;
    final public static int FOOD_CENTER = 5;
    final public static int HEALTH_CENTER = 6;
    final public static int SOCIAL_RELATIVES = 7;
    final public static int VISIT_SOCIAL = 8;
    final public static int VISIT_LATRINE = 9;
    
    // best location is mainly determine by distance
    // near is best
    public FieldUnit bestActivityLocation(Refugee ref, FieldUnit position, int id, Dadaab d) {
       
        
       // FieldUnit potLoc = null;
        
     
        if (id == STAY_HOME) {

            return ref.getHome();
            //System.out.println("home" + newL.getCampID());

        } 
         else if (id == SCHOOL){
            return betstLoc (ref.getHome(), d.schooles,d);
        }
         
         else if (id == BOREHOLE_OR_RIVER) {
           // System.out.println("borehole" + nearestWaterSource(ref, position, d));
            return nearestWaterSource(ref.getHome(), d);

        } 
         else if(id == MOSQUE){
            return betstLoc (ref.getHome(), d.mosques,d);
        }
         
         else if (id == MARKET){
            return betstLoc (ref.getHome(), d.market,d);
        }
          
        else if(id == FOOD_CENTER){
            return betstLoc (ref.getHome(), d.foodCenter,d);
        }
        
         
        else if (id == HEALTH_CENTER){
            return betstLoc (ref.getHome(), d.healthCenters,d);
        }
        
        else if (id == SOCIAL_RELATIVES) {
           // System.out.println("camp");
            
            int l=ref.getFamily().getRelativesLocation().numObjs;
            
            if(l == 0){
                return ref.getHome();
            }
            else return ((FieldUnit)(ref.getFamily().getRelativesLocation().objs[d.random.nextInt(l)]));

        } 
        
        else if (id == VISIT_SOCIAL) {
          //  System.out.println("camp");
            return socialize(ref, d);

        } 
        else if (id == VISIT_LATRINE) {

//            ref.setLatrineField(this.openLatrine(ref, d));

            return this.openLatrine(ref, d);

        } 
        
        else {
            return ref.getHome();
        }
      // return newL;

    }
     
    
    private FieldUnit betstLoc (FieldUnit fLoc, Bag fieldBag, Dadaab d){
            Bag newLoc = new Bag();
        
            double bestScoreSoFar = Double.POSITIVE_INFINITY;
            for (int i = 0; i < fieldBag.numObjs; i++) {
                FieldUnit potLoc = ((FieldUnit) fieldBag.objs[i]);

                double fScore = fLoc.distanceTo(potLoc);
                if (fScore > bestScoreSoFar) {
                    continue;
                }

                if (fScore <= bestScoreSoFar) {
                    bestScoreSoFar = fScore;
                    newLoc.clear();
                }
                newLoc.add(potLoc);


            }
            FieldUnit f = null;
            if (newLoc != null) {
                int winningIndex = 0;
                if (newLoc.numObjs >= 1) {
                    winningIndex = d.random.nextInt(newLoc.numObjs);
                }
                //System.out.println("other" + newLoc.numObjs);
              f= (FieldUnit) newLoc.objs[winningIndex];

            }
            return f;
    }

    // Haiti project
    public FieldUnit getNextTile(Dadaab dadaab, FieldUnit subgoal, FieldUnit position) {

        // move in which direction?
        int moveX = 0, moveY = 0;
        int dx = subgoal.getX() - position.getX();
        int dy = subgoal.getY() - position.getY();
        if (dx < 0) {
            moveX = -1;
        } else if (dx > 0) {
            moveX = 1;
        }
        if (dy < 0) {
            moveY = -1;
        } else if (dy > 0) {
            moveY = 1;
        }
        //((FieldUnit) o).loc

        // can either move in Y direction or X direction: see which is better
        FieldUnit xmove = ((FieldUnit) dadaab.allCamps.field[position.getX() + moveX][position.getY()]);
        FieldUnit ymove = ((FieldUnit) dadaab.allCamps.field[position.getX()][position.getY() + moveY]);

        boolean xmoveToRoad = ((Integer) dadaab.roadGrid.get(xmove.getX(), xmove.getY())) > 0;
        boolean ymoveToRoad = ((Integer) dadaab.roadGrid.get(ymove.getX(), ymove.getX())) > 0;

        if (moveX == 0 && moveY == 0) { // we are ON the subgoal, so don't move at all!
            // both are the same result, so just return the xmove (which is identical)
            return xmove;
        } else if (moveX == 0) // this means that moving in the x direction is not a valid move: it's +0
        {
            return ymove;
        } else if (moveY == 0) // this means that moving in the y direction is not a valid move: it's +0
        {
            return xmove;
        } else if (xmoveToRoad == ymoveToRoad) { //equally good moves: pick randomly between them
            if (dadaab.random.nextBoolean()) {
                return xmove;
            } else {
                return ymove;
            }
        } else if (xmoveToRoad && moveX != 0) // x is a road: pick it
        {
            return xmove;
        } else if (ymoveToRoad && moveY != 0)// y is a road: pick it
        {
            return ymove;
        } else if (moveX != 0) // move in the better direction
        {
            return xmove;
        } else if (moveY != 0) // yes
        {
            return ymove;
        } else {
            return ymove; // no justification
        }
    }
  
    // three camp sites in the model
    // agent select one camp which is not their camp randomly
    private FieldUnit socialize(Refugee ref, Dadaab d) {
      
        Bag potential = new Bag();
        FieldUnit newLoc= null;
        potential.clear();
        
        // socialize - visit friend or any place in
        // potential = d.campSites;

        int camp = ref.getHome().getCampID(); // get camp id
        
        // select any camp site but not the camp that belong to the agent
        for (Object campsite : d.campSites) {
             FieldUnit cmp = ((FieldUnit) campsite);
            if (cmp.getCampID() == camp && cmp.equals(ref.getHome())!=true && cmp.getRefugeeHH().numObjs >0) {
                potential.add(cmp); // potential locations to visit
            }
        }
        
//        if(potential.isEmpty() ==true){
//            System.out.println("empty");
//        }
        if(potential.numObjs==1){
            newLoc = (FieldUnit)potential.objs[0];
        }
        else{
            newLoc = (FieldUnit)potential.objs[d.random.nextInt(potential.numObjs)];
        }
       
            return newLoc;
    }
    
    
    // if the camp has laterine use it otherwise
    // open latine - usually is a bit far from home - should open
    // children use around
    // age < 4 use home

    // select best location for open latrine
    private FieldUnit openLatrine(Refugee ref, Dadaab d) {
        Bag potential = new Bag();
        
         potential.clear();
        FieldUnit loc = null;
       
        // if agent has laterine, agent use it// // if you are too young 
        if (ref.getFamily().getHasLaterine() == true ||ref.getAge() < 5) {
            loc = ref.getHome();
        } 
        // 
        else {
               // potential location is within the distance given in parapeter
                Bag adjacent = d.allCamps.getNeighborsMaxDistance(ref.getHome().getX(), ref.getHome().getY(), d.params.global.getMaxDistanceLaterine(),
                        false, null, null, null);
                for (Object l : adjacent) {
                    FieldUnit lt = (FieldUnit) l;
                    if (lt.getFieldID() == 0) {
                        potential.add(lt);
                    }


                }
                // pick one of the potential location randomly
                if (potential.isEmpty() == true){
                    //System.out.println("null");
                    loc=  null;
                }
                else loc = (FieldUnit) potential.objs[d.random.nextInt(potential.numObjs)];
      

        }
        
        
        return loc;
    }
    
    
    // find the nearest water points
     public FieldUnit nearestWaterPoint(FieldUnit f, Dadaab d){
         
            return betstLoc(f,d.rainfallWater,d);
    }
    
   // search nearest borehold 
   // this is useful if one of the borehole is empty
   // agent will selct another borehole nearest from the current 
  private FieldUnit nearestBorehole(FieldUnit f, Dadaab d){
      
            return betstLoc (f, d.boreHoles,d);
  }
    
  //   select water source either from borehole or rainfall water points
  // agent preference weight and distance affect the choice
  
  public FieldUnit nearestWaterSource( FieldUnit f, Dadaab d){
      FieldUnit fieldP =  null;
      
      double preference_river = 0.0;
      double preference_borehole = 0.0;
      
      //incase no water point field to select, preference is 0
      if(nearestWaterPoint(f,d) == null){
          preference_river = 0.0;
      }
      // preference depend on inverse distance and  preference weight
      else { 
          preference_river = (1.0 / (1.0+Math.log(1+f.distanceTo(nearestWaterPoint(f,d))))) * d.params.global.getWaterSourcePreference_River() + (0.2 *d.random.nextDouble()); 
      }
      
      if(nearestBorehole(f,d) == null){
       preference_borehole  =0.0;
      }
      
      else {
          preference_borehole = (1.0 /(1.0+Math.log(1+f.distanceTo(nearestBorehole(f,d)))))* d.params.global.getWaterSourcePreference_Borehole()+ (0.2 *d.random.nextDouble());
      }
      
      if (preference_river > preference_borehole){
         fieldP =nearestWaterPoint(f,d);
      }
      
      else {
          fieldP = nearestBorehole(f,d);
      }
      return fieldP;
      
  }
}
